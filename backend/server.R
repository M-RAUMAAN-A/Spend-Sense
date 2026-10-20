# Reactive application logic
library(shiny)
library(ggplot2)
library(dplyr)
library(DT)

# Define %||% operator (was missing — caused runtime errors)
`%||%` <- function(a, b) if (is.null(a)) b else a

server <- function(input, output, session) {
  ensure_data_files()
  rv <- reactiveValues(refresh = 0, notice = NULL, error = NULL)

  transactions <- reactive({
    rv$refresh
    read_transactions()
  })
  budgets <- reactive({
    rv$refresh
    read_budgets()
  })
  categories <- reactive({
    rv$refresh
    read_categories()
  })

  observe({
    x <- transactions()
    keys <- unique(c(month_key(Sys.Date()), if (nrow(x)) month_key(x$date) else character()))
    keys <- sort(unique(keys), decreasing = TRUE)
    labels <- stats::setNames(keys, vapply(keys, month_label, character(1)))
    updateSelectInput(session, "month", choices = labels, selected = keys[1])
    cats <- categories()
    updateSelectInput(session, "category", choices = cats)
    updateSelectInput(session, "budget_category", choices = cats)
    updateSelectInput(session, "filter_category", choices = c("All", cats))
  })

  selected_month <- reactive({
    req(input$month)
    input$month
  })
  month_data <- reactive(transactions_for_month(transactions(), selected_month()))
  current_budget <- reactive(monthly_budget(budgets(), selected_month()))
  money <- function(x) currency(x)

  output$page_heading <- renderText({
    switch(input$page %||% "overview",
           overview = "Your overview",
           transactions = "Transactions",
           budgets = "Budget planner",
           insights = "Insights & reports",
           "Your overview")
  })

  output$metric_spent <- renderText(money(total_spent(month_data())))
  output$metric_budget <- renderText(money(current_budget()))
  output$metric_remaining <- renderText(money(current_budget() - total_spent(month_data())))
  output$metric_count <- renderText(nrow(month_data()))
  output$metric_spent_note <- renderText({
    if (current_budget() > 0) paste0(round(100 * total_spent(month_data()) / current_budget()), "% of budget used")
    else "Set a budget to track progress"
  })
  output$metric_remaining_note <- renderText({
    if (current_budget() - total_spent(month_data()) < 0) "Over budget"
    else "Available this month"
  })

  output$daily_plot <- renderPlot({
    d <- daily_spending(month_data())
    validate(need(nrow(d) > 0, "Add transactions to see your daily spending."))
    ggplot(d, aes(x = date, y = amount)) +
      geom_col(fill = "#168A80", width = 0.75) +
      scale_y_continuous(labels = function(x) paste0("\u20B9", scales::comma(x))) +
      labs(x = NULL, y = "Amount spent", subtitle = month_label(selected_month())) +
      theme_minimal(base_size = 12) +
      theme(panel.grid.minor = element_blank(), axis.text.x = element_text(angle = 35, hjust = 1))
  })

  output$category_plot <- renderPlot({
    d <- category_spending(month_data())
    validate(need(nrow(d) > 0, "Add transactions to see category breakdown."))
    ggplot(d, aes(x = reorder(category, amount), y = amount, fill = category)) +
      geom_col(show.legend = FALSE, width = 0.7) +
      coord_flip() +
      scale_y_continuous(labels = function(x) paste0("\u20B9", scales::comma(x))) +
      scale_fill_brewer(palette = "Set2") +
      labs(x = NULL, y = "Amount spent") +
      theme_minimal(base_size = 12) +
      theme(panel.grid.minor = element_blank())
  })

  output$recent_table <- renderDT({
    d <- month_data()
    if (nrow(d)) d <- d[order(d$date, decreasing = TRUE), , drop = FALSE]
    d <- head(d, 6)
    if (nrow(d)) {
      d$date <- format(d$date, "%d %b %Y")
      d$amount <- vapply(d$amount, money, character(1))
      d <- d[, c("date", "description", "category", "amount"), drop = FALSE]
    }
    datatable(d, rownames = FALSE, options = list(dom = "t", pageLength = 6, ordering = FALSE),
              colnames = c("Date", "Description", "Category", "Amount"))
  })

  output$overview_insight <- renderUI({
    items <- generate_insights(month_data(), current_budget(), transactions(), selected_month())
    tagList(lapply(items, function(item) div(class = "insight-item", icon("circle-check"), span(item))))
  })

  # One shared filtered data frame keeps the table, selection preview, and delete action aligned.
  visible_transactions <- reactive({
    d <- transactions()
    if (nrow(d) && !is.null(input$filter_category) && input$filter_category != "All") {
      d <- d[d$category == input$filter_category, , drop = FALSE]
    }
    q <- tolower(trimws(input$search_transaction %||% ""))
    if (nrow(d) && nzchar(q)) {
      d <- d[grepl(q, tolower(d$description), fixed = TRUE), , drop = FALSE]
    }
    d
  })

  output$transactions_table <- renderDT({
    d <- visible_transactions()
    if (nrow(d)) {
      # Preserve source row order. DT reports selected row indexes against this data,
      # even when the user changes the client-side sort order.
      d$date <- as.character(d$date)
      d <- d[, c("id", "date", "description", "category", "amount", "payment_method", "notes"), drop = FALSE]
    }
    DT::datatable(d, rownames = FALSE, selection = list(mode = "single", target = "row"),
                  options = list(pageLength = 8, scrollX = TRUE, autoWidth = FALSE, ordering = TRUE,
                                 order = list(list(1, "desc")),
                                 columnDefs = list(list(width = "70px", targets = 0))),
                  colnames = c("ID", "Date", "Description", "Category", "Amount", "Payment method", "Notes"),
                  class = "stripe hover compact") |>
      DT::formatCurrency("amount", currency = "₹", digits = 2, mark = ",", dec.mark = ".")
  })

  output$selected_transaction_summary <- renderUI({
    sel <- input$transactions_table_rows_selected
    d <- visible_transactions()
    if (is.null(sel) || length(sel) != 1 || is.na(sel) || sel < 1 || sel > nrow(d)) {
      return(span("No transaction selected.", class = "selection-empty"))
    }
    row <- d[as.integer(sel), , drop = FALSE]
    div(class = "selected-transaction",
        span(format(row$date, "%d %b %Y"), class = "selected-date"),
        strong(as.character(row$description)),
        span(currency(row$amount), class = "selected-amount"))
  })

  # --- Add transaction ---
  observeEvent(input$add_transaction, {
    tryCatch({
      add_transaction(input$description, input$transaction_date, input$category,
                      input$amount, input$payment_method, input$notes %||% "")
      rv$refresh <- rv$refresh + 1
      updateTextInput(session, "description", value = "")
      updateTextAreaInput(session, "notes", value = "")
      updateNumericInput(session, "amount", value = 100)
      showNotification("Transaction saved.", type = "message")
    }, error = function(e) showNotification(conditionMessage(e), type = "error", duration = 6))
  })

  # Delete by the selected row's stable ID, using the exact filtered data order shown to DT.
  observeEvent(input$delete_selected, {
    sel <- input$transactions_table_rows_selected
    d <- visible_transactions()
    if (is.null(sel) || length(sel) != 1 || is.na(sel) || sel < 1 || sel > nrow(d)) {
      showNotification("Select one transaction in the table before deleting.", type = "warning", duration = 5)
      return()
    }
    tryCatch({
      row_to_delete <- d[as.integer(sel), , drop = FALSE]
      delete_transaction(row_to_delete$id[[1]])
      rv$refresh <- rv$refresh + 1
      showNotification(paste("Deleted:", row_to_delete$description[[1]]), type = "message")
    }, error = function(e) showNotification(conditionMessage(e), type = "error", duration = 6))
  })

  # --- Save monthly budget ---
  observeEvent(input$save_monthly_budget, {
    tryCatch({
      save_budget(selected_month(), "ALL", input$monthly_budget_input)
      rv$refresh <- rv$refresh + 1
      showNotification("Monthly budget saved.", type = "message")
    }, error = function(e) showNotification(conditionMessage(e), type = "error"))
  })

  # --- Save category budget ---
  observeEvent(input$save_category_budget, {
    tryCatch({
      save_budget(selected_month(), input$budget_category, input$category_budget_input)
      rv$refresh <- rv$refresh + 1
      showNotification("Category budget saved.", type = "message")
    }, error = function(e) showNotification(conditionMessage(e), type = "error"))
  })

  # --- Budget progress bar ---
  output$budget_progress <- renderUI({
    x <- month_data()
    monthly <- current_budget()
    spent <- total_spent(x)
    pct <- if (monthly > 0) min(100, round(spent / monthly * 100)) else 0
    bar_class <- if (spent > monthly) "bg-danger" else if (pct >= 80) "bg-warning" else "bg-success"
    tagList(
      h5(paste("Monthly budget:", money(monthly))),
      div(class = "progress",
          div(class = paste("progress-bar", bar_class),
              style = paste0("width:", pct, "%"), role = "progressbar",
              `aria-valuenow` = pct, `aria-valuemin` = 0, `aria-valuemax` = 100,
              paste0(pct, "% used"))),
      p(class = "muted", paste(money(spent), "spent \u2022", money(monthly - spent), "remaining"))
    )
  })

  # --- FIXED: Budget table with proper NA handling ---
  output$budget_table <- renderDT({
    cat_spend <- category_spending(month_data())
    b <- budgets()
    cat_b <- b[b$month == selected_month() & b$category != "ALL", , drop = FALSE]

    if (nrow(cat_spend)) {
      names(cat_spend)[names(cat_spend) == "amount"] <- "spent"
      cat_spend <- merge(cat_spend, cat_b[, c("category", "amount"), drop = FALSE],
                         by = "category", all.x = TRUE)
      names(cat_spend)[names(cat_spend) == "amount"] <- "budget"

      # Handle NA budgets properly BEFORE formatting
      cat_spend$budget_num <- cat_spend$budget
      cat_spend$budget_num[is.na(cat_spend$budget_num)] <- 0
      cat_spend$remaining_num <- cat_spend$budget_num - cat_spend$spent

      # Format for display
      cat_spend$spent <- vapply(cat_spend$spent, money, character(1))
      cat_spend$budget <- ifelse(cat_spend$budget_num == 0, "Not set",
                                  vapply(cat_spend$budget_num, money, character(1)))
      cat_spend$remaining <- vapply(cat_spend$remaining_num, money, character(1))

      cat_spend <- cat_spend[, c("category", "spent", "budget", "remaining"), drop = FALSE]
    } else {
      cat_spend <- data.frame(category = character(), spent = character(),
                              budget = character(), remaining = character())
    }
    datatable(cat_spend, rownames = FALSE, options = list(pageLength = 8, dom = "tip"),
              colnames = c("Category", "Spent", "Category budget", "Remaining"))
  })

  # --- Insights list ---
  output$insights_list <- renderUI({
    items <- generate_insights(month_data(), current_budget(), transactions(), selected_month())
    tagList(lapply(items, function(item) div(class = "insight-card", icon("lightbulb"), span(item))))
  })

  # --- Monthly comparison plot ---
  output$monthly_plot <- renderPlot({
    d <- monthly_spending(transactions())
    validate(need(nrow(d) > 0, "Add transactions to see monthly comparisons."))
    d <- tail(d[order(d$month), , drop = FALSE], 8)
    d$label <- vapply(d$month, month_label, character(1))
    ggplot(d, aes(x = reorder(label, month), y = amount)) +
      geom_col(fill = "#168A80", width = 0.7) + coord_flip() +
      scale_y_continuous(labels = function(x) paste0("\u20B9", scales::comma(x))) +
      labs(x = NULL, y = "Total spent") + theme_minimal(base_size = 12)
  })

  # --- FIXED: Payment plot with na.rm ---
  output$payment_plot <- renderPlot({
    d <- month_data()
    validate(need(nrow(d) > 0, "Add transactions to see payment methods."))
    d <- aggregate(amount ~ payment_method, data = d, FUN = sum, na.rm = TRUE)
    ggplot(d, aes(x = "", y = amount, fill = payment_method)) +
      geom_col(width = 1, color = "white") + coord_polar("y") +
      labs(x = NULL, y = NULL, fill = "Payment method") +
      theme_void(base_size = 12)
  })

  # --- NEW: Category trend plot across months ---
  output$category_trend_plot <- renderPlot({
    d <- category_monthly_spending(transactions())
    validate(need(nrow(d) > 0, "Add transactions to see category trends."))
    # Show top 5 categories by total spending
    top_cats <- names(sort(tapply(d$amount, d$category, sum), decreasing = TRUE))[1:5]
    d <- d[d$category %in% top_cats, , drop = FALSE]
    d$label <- vapply(d$month, month_label, character(1))
    # Combined trend + scatter: lines show direction; points preserve each monthly observation.
    d <- d[order(d$category, d$month), , drop = FALSE]
    ggplot(d, aes(x = month, y = amount, color = category, group = category)) +
      geom_line(linewidth = 0.8, alpha = 0.75, na.rm = TRUE) +
      geom_point(size = 3.2, alpha = 0.95, position = position_jitter(width = 0.035, height = 0)) +
      scale_y_continuous(labels = function(x) paste0("\u20B9", scales::comma(x))) +
      scale_color_manual(values = c("#245E50", "#C86F59", "#C4A23D", "#6286A0", "#8C6B91", "#78916B")) +
      labs(x = NULL, y = "Amount spent", color = "Category") +
      theme_minimal(base_size = 12) +
      theme(panel.grid.minor = element_blank(), panel.grid.major = element_line(color = "#E5E4D9"),
            axis.text.x = element_text(angle = 35, hjust = 1), legend.position = "bottom")
  })

  # --- FIXED: Import CSV with future-date validation ---
  observeEvent(input$import_csv, {
    req(input$import_csv)
    tryCatch({
      imported <- utils::read.csv(input$import_csv$datapath, stringsAsFactors = FALSE,
                                  check.names = FALSE, fileEncoding = "UTF-8-BOM", strip.white = TRUE)
      # Normalize common spreadsheet headers (case, spaces, punctuation and UTF-8 BOM).
      names(imported) <- tolower(gsub("[^a-z0-9]+", "_", trimws(sub("^\ufeff", "", names(imported)))))
      names(imported) <- gsub("^_|_$", "", names(imported))
      aliases <- c(transaction_date = "date", expense_date = "date", item = "description",
                   title = "description", payment = "payment_method", paymentmode = "payment_method",
                   payment_mode = "payment_method", notes_optional = "notes")
      for (nm in names(aliases)) if (nm %in% names(imported) && !aliases[[nm]] %in% names(imported)) {
        names(imported)[names(imported) == nm] <- aliases[[nm]]
      }
      needed <- c("date", "description", "category", "amount", "payment_method")
      if (!all(needed %in% names(imported))) stop(paste("CSV needs these columns (header names are case-insensitive):", paste(needed, collapse = ", ")))
      raw_date <- trimws(as.character(imported$date))
      parsed_date <- suppressWarnings(as.Date(raw_date, format = "%Y-%m-%d"))
      bad_date <- is.na(parsed_date)
      if (any(bad_date)) parsed_date[bad_date] <- suppressWarnings(as.Date(raw_date[bad_date], format = "%d/%m/%Y"))
      bad_date <- is.na(parsed_date)
      if (any(bad_date)) parsed_date[bad_date] <- suppressWarnings(as.Date(raw_date[bad_date], format = "%m/%d/%Y"))
      imported$date <- parsed_date
      raw_amount <- gsub("[₹,[:space:]]", "", as.character(imported$amount))
      imported$amount <- suppressWarnings(as.numeric(raw_amount))
      imported$description <- trimws(as.character(imported$description))
      imported$category <- trimws(as.character(imported$category))
      imported$payment_method <- trimws(as.character(imported$payment_method))
      if (anyNA(imported$date) || anyNA(imported$amount) || any(!is.finite(imported$amount)) ||
          any(imported$amount <= 0) || any(!nzchar(imported$description))) {
        stop("Check the CSV: dates must be YYYY-MM-DD, DD/MM/YYYY or MM/DD/YYYY; amounts must be positive numbers (₹ and commas are allowed).")
      }
      # NEW: block future dates in import too
      if (any(imported$date > Sys.Date())) {
        stop("CSV contains future-dated transactions. Please remove them and try again.")
      }
      if (any(!imported$category %in% categories())) stop("CSV contains a category not listed in data/categories.csv.")
      # NEW: validate payment methods in import
      if (any(!imported$payment_method %in% ALLOWED_PAYMENT_METHODS)) {
        stop(paste("CSV contains invalid payment methods. Allowed values:",
                   paste(ALLOWED_PAYMENT_METHODS, collapse = ", ")))
      }
      old <- transactions()
      imported$id <- paste0("IMP-", seq_len(nrow(imported)), "-", format(Sys.time(), "%Y%m%d%H%M%S"))
      if (!"notes" %in% names(imported)) imported$notes <- ""
      imported <- imported[, names(old), drop = FALSE]
      combined <- rbind(old, imported)
      write_transactions(combined)
      rv$refresh <- rv$refresh + 1
      showNotification(paste(nrow(imported), "transactions imported."), type = "message")
    }, error = function(e) showNotification(conditionMessage(e), type = "error", duration = 8))
  })

  # --- Export transactions ---
  output$download_transactions <- downloadHandler(
    filename = function() paste0("spendsense-transactions-", Sys.Date(), ".csv"),
    content = function(file) write.csv(transactions(), file, row.names = FALSE, na = "")
  )

  # --- Export monthly report ---
  output$download_report <- downloadHandler(
    filename = function() paste0("spendsense-report-", selected_month(), ".csv"),
    content = function(file) {
      d <- month_data()
      d$date <- as.character(d$date)
      write.csv(d, file, row.names = FALSE, na = "")
    }
  )

  # --- Update budget input when month changes ---
  observeEvent(input$month, {
    updateNumericInput(session, "monthly_budget_input", value = current_budget())
  }, ignoreInit = TRUE)
}