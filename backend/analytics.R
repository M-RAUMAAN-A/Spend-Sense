# Calculations used by dashboard cards and charts
month_key <- function(date) format(as.Date(date), "%Y-%m")

month_label <- function(key) {
  if (length(key) != 1) return("No month selected")
  if (is.na(key) || !nzchar(key)) return("No month selected")
  format(as.Date(paste0(key, "-01")), "%B %Y")
}

transactions_for_month <- function(transactions, month) {
  if (!nrow(transactions)) return(transactions)
  transactions[!is.na(transactions$date) & month_key(transactions$date) == month, , drop = FALSE]
}

total_spent <- function(transactions) {
  if (!nrow(transactions)) return(0)
  sum(transactions$amount, na.rm = TRUE)
}

monthly_budget <- function(budgets, month) {
  rows <- budgets[budgets$month == month & budgets$category == "ALL", , drop = FALSE]
  if (!nrow(rows)) return(8000)
  as.numeric(rows$amount[nrow(rows)])
}

category_spending <- function(transactions) {
  if (!nrow(transactions)) return(data.frame(category = character(), amount = numeric()))
  aggregate(amount ~ category, data = transactions, FUN = sum, na.rm = TRUE)
}

daily_spending <- function(transactions) {
  if (!nrow(transactions)) return(data.frame(date = as.Date(character()), amount = numeric()))
  aggregate(amount ~ date, data = transactions, FUN = sum, na.rm = TRUE)
}

monthly_spending <- function(transactions) {
  if (!nrow(transactions)) return(data.frame(month = character(), amount = numeric()))
  transactions$month <- month_key(transactions$date)
  aggregate(amount ~ month, data = transactions, FUN = sum, na.rm = TRUE)
}

# NEW: average transaction size for insights
average_transaction <- function(transactions) {
  if (!nrow(transactions)) return(0)
  mean(transactions$amount, na.rm = TRUE)
}

# NEW: spending by category across all months (for trend chart)
category_monthly_spending <- function(transactions) {
  if (!nrow(transactions)) {
    return(data.frame(month = character(), category = character(), amount = numeric()))
  }
  transactions$month <- month_key(transactions$date)
  aggregate(amount ~ month + category, data = transactions, FUN = sum, na.rm = TRUE)
}

currency <- function(x) {
  x <- suppressWarnings(as.numeric(x))
  x[is.na(x)] <- 0
  paste0("\u20B9", format(round(x, 2), big.mark = ",", nsmall = 2, trim = TRUE))
}