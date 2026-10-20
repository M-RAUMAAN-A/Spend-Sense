# Comprehensive checks for SpendSense helpers.
# Run from the SpendSense project root:
# source("backend/data_manager.R")
# source("backend/analytics.R")
# source("backend/insights.R")
# source("tests/test_analytics.R")

# --- Setup test data ---
sample_tx <- data.frame(
  id = c("A", "B", "C", "D"),
  date = as.Date(c("2026-10-01", "2026-10-01", "2026-10-02", "2026-10-05")),
  description = c("Lunch", "Bus", "Book", "Movie"),
  category = c("Food", "Transport", "Education", "Entertainment"),
  amount = c(120, 30, 250, 200),
  payment_method = c("UPI", "Cash", "UPI", "Debit card"),
  notes = c("", "", "", ""),
  stringsAsFactors = FALSE
)

empty_tx <- data.frame(
  id = character(), date = as.Date(character()), description = character(),
  category = character(), amount = numeric(), payment_method = character(),
  notes = character(), stringsAsFactors = FALSE
)

sample_budgets <- data.frame(
  month = c("2026-10", "2026-10", "2026-09"),
  category = c("ALL", "Food", "ALL"),
  amount = c(5000, 1500, 4000),
  stringsAsFactors = FALSE
)

# --- Test: total_spent ---
stopifnot(total_spent(sample_tx) == 600)
stopifnot(total_spent(empty_tx) == 0)
stopifnot(total_spent(sample_tx[1, , drop = FALSE]) == 120)
cat("PASS: total_spent\n")

# --- Test: category_spending ---
cs <- category_spending(sample_tx)
stopifnot(nrow(cs) == 4)
stopifnot(sum(cs$amount) == 600)
cat("PASS: category_spending\n")

# --- Test: daily_spending ---
ds <- daily_spending(sample_tx)
stopifnot(nrow(ds) == 3)  # Oct 1 has 2 transactions
stopifnot(sum(ds$amount) == 600)
cat("PASS: daily_spending\n")

# --- Test: monthly_spending ---
ms <- monthly_spending(sample_tx)
stopifnot(nrow(ms) == 1)
stopifnot(ms$amount == 600)
cat("PASS: monthly_spending\n")

# --- Test: month_key ---
stopifnot(month_key(as.Date("2026-10-12")) == "2026-10")
stopifnot(month_key(as.Date("2026-01-01")) == "2026-01")
cat("PASS: month_key\n")

# --- Test: month_label ---
stopifnot(month_label("2026-10") == "October 2026")
stopifnot(month_label(NA) == "No month selected")
stopifnot(month_label("") == "No month selected")
stopifnot(month_label(NULL) == "No month selected")
stopifnot(month_label(c("2026-10", "2026-11")) == "No month selected")
cat("PASS: month_label\n")

# --- Test: monthly_budget ---
stopifnot(monthly_budget(sample_budgets, "2026-10") == 5000)
stopifnot(monthly_budget(sample_budgets, "2026-09") == 4000)
stopifnot(monthly_budget(sample_budgets, "2026-08") == 8000)  # default
cat("PASS: monthly_budget\n")

# --- Test: transactions_for_month ---
oct_tx <- transactions_for_month(sample_tx, "2026-10")
stopifnot(nrow(oct_tx) == 4)
sep_tx <- transactions_for_month(sample_tx, "2026-09")
stopifnot(nrow(sep_tx) == 0)
cat("PASS: transactions_for_month\n")

# --- Test: average_transaction ---
stopifnot(average_transaction(sample_tx) == 150)
stopifnot(average_transaction(empty_tx) == 0)
cat("PASS: average_transaction\n")

# --- Test: currency ---
stopifnot(currency(1000) == "\u20B91,000.00")
stopifnot(currency(0) == "\u20B90.00")
stopifnot(currency(NA) == "\u20B90.00")
cat("PASS: currency\n")

# --- Test: generate_insights ---
ins <- generate_insights(sample_tx, 5000, sample_tx, "2026-10")
stopifnot(length(ins) >= 2)
stopifnot(any(grepl("largest spending category", ins)))
cat("PASS: generate_insights (basic)\n")

ins_empty <- generate_insights(empty_tx, 5000, empty_tx, "2026-10")
stopifnot(length(ins_empty) == 2)
stopifnot(any(grepl("No expenses recorded", ins_empty)))
cat("PASS: generate_insights (empty)\n")

ins_over <- generate_insights(sample_tx, 100, sample_tx, "2026-10")
stopifnot(any(grepl("Budget exceeded", ins_over)))
cat("PASS: generate_insights (over budget)\n")

# --- Test: category_monthly_spending ---
cms <- category_monthly_spending(sample_tx)
stopifnot(nrow(cms) == 4)
stopifnot(all(c("month", "category", "amount") %in% names(cms)))
cat("PASS: category_monthly_spending\n")

cat("\n=== All SpendSense tests passed! ===\n")