# Rule-based insights (no AI or external service)
generate_insights <- function(transactions, budget, all_transactions = transactions, month = NULL) {
  out <- character()
  spent <- total_spent(transactions)
  remaining <- budget - spent

  if (!nrow(transactions)) {
    return(c("No expenses recorded for this month yet. Add a transaction to start seeing your spending patterns.",
             paste("Your current monthly budget is", currency(budget), ".")))
  }

  # --- Budget usage ---
  if (budget > 0 && spent > budget) {
    out <- c(out, paste0("Budget exceeded by ", currency(spent - budget),
                         ". Review optional purchases and adjust your plan if needed."))
  } else if (budget > 0 && spent >= 0.8 * budget) {
    out <- c(out, paste0("You have used ", round(100 * spent / budget),
                         "% of your monthly budget. About ", currency(remaining), " remains."))
  } else if (budget > 0) {
    out <- c(out, paste0("You have used ", round(100 * spent / budget),
                         "% of your monthly budget, with ", currency(remaining), " remaining."))
  }

  # --- Top category ---
  cats <- category_spending(transactions)
  if (nrow(cats)) {
    top <- cats[which.max(cats$amount), , drop = FALSE]
    pct_cat <- round(100 * top$amount / spent)
    out <- c(out, paste0(top$category, " is your largest spending category at ",
                         currency(top$amount), " (", pct_cat, "% of this month's spending)."))
  }

  # --- Biggest single transaction vs average ---
  if (nrow(transactions) >= 2) {
    avg <- average_transaction(transactions)
    biggest <- transactions[which.max(transactions$amount), , drop = FALSE]
    if (biggest$amount > 2 * avg) {
      out <- c(out, paste0("Your largest single transaction was ", currency(biggest$amount),
                           " for \"", biggest$description, "\". Check whether it was expected."))
    }
  }

  # --- Day-of-week pattern ---
  if (nrow(transactions) >= 3) {
    transactions$dow <- weekdays(transactions$date)
    dow_totals <- aggregate(amount ~ dow, data = transactions, FUN = sum, na.rm = TRUE)
    top_dow <- dow_totals[which.max(dow_totals$amount), ]
    out <- c(out, paste0("You tend to spend the most on ", top_dow$dow,
                         " (", currency(top_dow$amount), " total)."))
  }

  # --- Weekend vs weekday ---
  if (nrow(transactions) >= 3) {
    transactions$is_weekend <- weekdays(transactions$date) %in% c("Saturday", "Sunday")
    weekend_spent <- sum(transactions$amount[transactions$is_weekend], na.rm = TRUE)
    weekday_spent <- spent - weekend_spent
    if (weekend_spent > weekday_spent && weekend_spent > 0) {
      out <- c(out, paste0("Weekend spending (", currency(weekend_spent),
                           ") is higher than weekday spending (", currency(weekday_spent), ")."))
    }
  }

  # --- Month-over-month comparison ---
  if (!is.null(month) && nrow(all_transactions)) {
    prev_date <- as.Date(paste0(month, "-01")) - 1
    prev_month <- month_key(prev_date)
    previous <- transactions_for_month(all_transactions, prev_month)
    if (nrow(previous)) {
      prev_spent <- total_spent(previous)
      if (prev_spent > 0) {
        change <- spent - prev_spent
        pct <- round(abs(change) / prev_spent * 100)
        direction <- if (change > 0) "higher" else "lower"
        out <- c(out, paste0("Spending is ", pct, "% ", direction,
                             " than ", month_label(prev_month), "."))
      }
    }
  }

  # --- Category budget warnings ---
  if (!is.null(month) && nrow(all_transactions)) {
    all_months <- transactions_for_month(all_transactions, month)
    cat_spend <- category_spending(all_months)
    # budgets for this month
    month_budgets <- all_transactions  # placeholder; actual budget lookup done in server
  }

  unique(out)
}