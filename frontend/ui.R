# User interface for SpendSense
library(shiny)
library(bslib)
library(DT)

ui <- page_sidebar(
  title = div(class = "brand", span(class = "brand-mark", "S"), "SpendSense"),
  theme = bs_theme(
    version = 5,
    bootswatch = "minty",
    primary = "#168A80",
    secondary = "#6C7A89",
    success = "#198754",
    base_font = font_google("DM Sans"),
    heading_font = font_google("Playfair Display")
  ),
  sidebar = sidebar(
    width = 260,
    open = "desktop",
    h5("WORKSPACE"),
    navset_pill_list(
      id = "page",
      nav_panel("Overview", value = "overview", icon = icon("chart-pie")),
      nav_panel("Transactions", value = "transactions", icon = icon("receipt")),
      nav_panel("Budgets", value = "budgets", icon = icon("bullseye")),
      nav_panel("Insights & Reports", value = "insights", icon = icon("lightbulb"))
    ),
    hr(),
    div(class = "sidebar-note",
        strong("Your money, clearer."),
        p("Track habits, set limits, and make informed choices.")
    )
  ),
  tags$head(
    tags$link(rel = "stylesheet", type = "text/css", href = "frontend/styles.css"),
    tags$meta(name = "viewport", content = "width=device-width, initial-scale=1")
  ),
  div(class = "page-intro",
      div(h2(textOutput("page_heading", inline = TRUE)),
          p("A simple picture of where your money goes.", class = "muted")),
      div(class = "period-control",
          selectInput("month", NULL, choices = NULL, width = "190px")
      )
  ),
  # Overview
  conditionalPanel(
    condition = "input.page == 'overview'",
    fluidRow(
      column(3, div(class = "metric-card", div(class = "metric-label", "Total spent"),
                    h3(textOutput("metric_spent", inline = TRUE)),
                    div(class = "metric-foot", textOutput("metric_spent_note", inline = TRUE)))),
      column(3, div(class = "metric-card", div(class = "metric-label", "Monthly budget"),
                    h3(textOutput("metric_budget", inline = TRUE)),
                    div(class = "metric-foot", "Your planned spending limit"))),
      column(3, div(class = "metric-card", div(class = "metric-label", "Budget remaining"),
                    h3(textOutput("metric_remaining", inline = TRUE)),
                    div(class = "metric-foot", textOutput("metric_remaining_note", inline = TRUE)))),
      column(3, div(class = "metric-card", div(class = "metric-label", "Transactions"),
                    h3(textOutput("metric_count", inline = TRUE)),
                    div(class = "metric-foot", "Recorded this month")))
    ),
    fluidRow(
      column(7, card(class = "panel-card", card_header("Spending over time"),
                     plotOutput("daily_plot", height = "280px"))),
      column(5, card(class = "panel-card", card_header("Where your money goes"),
                     plotOutput("category_plot", height = "280px")))
    ),
    fluidRow(
      column(7, card(class = "panel-card", card_header("Recent transactions"),
                     DTOutput("recent_table"))),
      column(5, card(class = "panel-card", card_header("SpendSense insight"),
                     uiOutput("overview_insight"),
                     hr(),
                     div(class = "muted small", "Insights are based on the transactions recorded in this app.")))
    )
  ),
  # Transactions
  conditionalPanel(
    condition = "input.page == 'transactions'",
    fluidRow(
      column(4, card(class = "panel-card",
        card_header("Add a transaction"),
        textInput("description", "Description", placeholder = "e.g. Lunch at college"),
        numericInput("amount", "Amount (₹)", value = 100, min = 1, step = 1),
        dateInput("transaction_date", "Date", value = Sys.Date(), max = Sys.Date()),
        selectInput("category", "Category", choices = NULL),
        selectInput("payment_method", "Payment method",
                    choices = c("UPI", "Cash", "Debit card", "Credit card", "Bank transfer", "Other")),
        textAreaInput("notes", "Notes (optional)", rows = 2),
        actionButton("add_transaction", "Add transaction", class = "btn-primary w-100"),
        br(), br(),
        div(class = "muted small", "New entries are saved to data/transactions.csv.")
      )),
      column(8, card(class = "panel-card",
        card_header("Transaction history"),
        fluidRow(
          column(6, selectInput("filter_category", "Filter by category", choices = "All")),
          column(6, textInput("search_transaction", "Search description", placeholder = "Type to search"))
        ),
        div(class = "transaction-table-wrap", DTOutput("transactions_table")),
        div(class = "delete-zone",
            div(class = "delete-zone-copy",
                strong("Delete a transaction"),
                p("Select one row in the table first. Deletion is permanent.", class = "muted small"),
                uiOutput("selected_transaction_summary")
            ),
            actionButton("delete_selected", "Delete selected",
                         class = "btn-outline-danger delete-button", icon = icon("trash"))
        ),
        div(class = "transaction-file-tools",
            div(class = "import-tool",
                fileInput("import_csv", "Import transactions from CSV", accept = ".csv"),
                p(class = "muted small", "CSV needs date, description, category, amount, and payment_method columns.")
            ),
            div(class = "export-tool",
                downloadButton("download_transactions", "Export transactions CSV", class = "btn-outline-primary")
            )
        )
      ))
    )
  ),
  # Budgets
  conditionalPanel(
    condition = "input.page == 'budgets'",
    fluidRow(
      column(5, card(class = "panel-card",
        card_header("Set your monthly budget"),
        numericInput("monthly_budget_input", "Monthly spending limit (₹)", value = 8000, min = 0, step = 500),
        actionButton("save_monthly_budget", "Save monthly budget", class = "btn-primary"),
        hr(),
        h5("Category limits"),
        selectInput("budget_category", "Category", choices = NULL),
        numericInput("category_budget_input", "Category limit (₹)", value = 1500, min = 0, step = 100),
        actionButton("save_category_budget", "Save category limit", class = "btn-outline-primary")
      )),
      column(7, card(class = "panel-card", card_header("Budget progress"),
                     uiOutput("budget_progress"),
                     hr(),
                     DTOutput("budget_table")))
    )
  ),
  # Insights
  conditionalPanel(
    condition = "input.page == 'insights'",
    fluidRow(
      column(12, card(class = "panel-card", card_header("Your spending insights"),
                      uiOutput("insights_list")))
    ),
    fluidRow(
      column(6, card(class = "panel-card", card_header("Monthly spending comparison"),
                     plotOutput("monthly_plot", height = "300px"))),
      column(6, card(class = "panel-card", card_header("Payment method breakdown"),
                     plotOutput("payment_plot", height = "300px")))
    ),
    # NEW: Category trend chart
    fluidRow(
      column(12, card(class = "panel-card", card_header("Category spending trend"),
                      plotOutput("category_trend_plot", height = "300px")))
    ),
    fluidRow(
      column(12, card(class = "panel-card", card_header("Export a report"),
                      p("Download the selected month's transactions for your own records or project demonstration."),
                      downloadButton("download_report", "Download monthly report", class = "btn-primary")))
    )
  ),
  footer = div(class = "app-footer", "SpendSense • R + Shiny • CSV-based local project"),
  window_title = "SpendSense | Personal Expense Analyzer"
)