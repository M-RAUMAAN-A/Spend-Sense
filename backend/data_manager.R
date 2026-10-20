# CSV persistence and validation helpers
DATA_DIR <- file.path("data")
TRANSACTIONS_FILE <- file.path(DATA_DIR, "transactions.csv")
BUDGETS_FILE <- file.path(DATA_DIR, "budgets.csv")
CATEGORIES_FILE <- file.path(DATA_DIR, "categories.csv")

ALLOWED_PAYMENT_METHODS <- c("UPI", "Cash", "Debit card", "Credit card", "Bank transfer", "Other")

default_categories <- data.frame(
  category = c("Food", "Transport", "Education", "Shopping", "Bills",
               "Entertainment", "Health", "Personal care", "Other"),
  description = c("Meals, snacks, groceries", "Bus, metro, fuel, rides",
                  "Books, stationery, courses", "Clothes and purchases",
                  "Phone, internet, utilities", "Movies and subscriptions",
                  "Medicines and appointments", "Daily personal items", "Other expenses"),
  stringsAsFactors = FALSE
)

ensure_data_files <- function() {
  if (!dir.exists(DATA_DIR)) dir.create(DATA_DIR, recursive = TRUE)
  if (!file.exists(CATEGORIES_FILE)) {
    utils::write.csv(default_categories, CATEGORIES_FILE, row.names = FALSE, na = "")
  }
  if (!file.exists(TRANSACTIONS_FILE)) {
    empty_transactions <- data.frame(
      id = character(), date = character(), description = character(),
      category = character(), amount = numeric(), payment_method = character(),
      notes = character(), stringsAsFactors = FALSE
    )
    utils::write.csv(empty_transactions, TRANSACTIONS_FILE, row.names = FALSE, na = "")
  }
  if (!file.exists(BUDGETS_FILE)) {
    empty_budgets <- data.frame(
      month = character(), category = character(), amount = numeric(),
      stringsAsFactors = FALSE
    )
    utils::write.csv(empty_budgets, BUDGETS_FILE, row.names = FALSE, na = "")
  }
  invisible(TRUE)
}

read_transactions <- function() {
  ensure_data_files()
  x <- tryCatch(utils::read.csv(TRANSACTIONS_FILE, stringsAsFactors = FALSE), error = function(e) NULL)
  required <- c("id", "date", "description", "category", "amount", "payment_method", "notes")
  if (is.null(x) || !all(required %in% names(x))) {
    stop("transactions.csv has an invalid format. Restore the sample file or see README.md.")
  }
  x$date <- as.Date(x$date)
  x$amount <- suppressWarnings(as.numeric(x$amount))
  x$description[is.na(x$description)] <- ""
  x$notes[is.na(x$notes)] <- ""
  x
}

write_transactions <- function(x) {
  ensure_data_files()
  x$date <- as.character(as.Date(x$date))
  utils::write.csv(x, TRANSACTIONS_FILE, row.names = FALSE, na = "")
  invisible(TRUE)
}

read_budgets <- function() {
  ensure_data_files()
  x <- utils::read.csv(BUDGETS_FILE, stringsAsFactors = FALSE)
  if (!all(c("month", "category", "amount") %in% names(x))) {
    stop("budgets.csv has an invalid format.")
  }
  x$amount <- suppressWarnings(as.numeric(x$amount))
  x
}

write_budgets <- function(x) {
  ensure_data_files()
  utils::write.csv(x, BUDGETS_FILE, row.names = FALSE, na = "")
  invisible(TRUE)
}

read_categories <- function() {
  ensure_data_files()
  x <- utils::read.csv(CATEGORIES_FILE, stringsAsFactors = FALSE)
  if (!"category" %in% names(x)) stop("categories.csv must include a category column.")
  unique(as.character(x$category))
}

add_transaction <- function(description, date, category, amount, payment_method, notes = "") {
  description <- trimws(as.character(description))
  amount <- suppressWarnings(as.numeric(amount))
  if (!nzchar(description)) stop("Please enter a description.")
  if (length(amount) != 1 || is.na(amount) || !is.finite(amount) || amount <= 0) {
    stop("Amount must be a number greater than zero.")
  }
  date <- as.Date(date)
  if (is.na(date)) stop("Please choose a valid date.")
  if (date > Sys.Date()) stop("Future-dated transactions are not allowed in this version.")
  if (!category %in% read_categories()) stop("Please choose a valid category.")
  # NEW: validate payment method
  payment_method <- as.character(payment_method)
  if (!payment_method %in% ALLOWED_PAYMENT_METHODS) {
    stop("Please choose a valid payment method.")
  }
  x <- read_transactions()
  new_row <- data.frame(
    id = paste0("TX-", format(Sys.time(), "%Y%m%d%H%M%S"), "-", sprintf("%04d", sample.int(9999, 1))),
    date = date, description = description, category = category,
    amount = amount, payment_method = payment_method,
    notes = as.character(notes), stringsAsFactors = FALSE
  )
  x <- rbind(x, new_row)
  write_transactions(x)
  invisible(new_row)
}

delete_transaction <- function(id) {
  x <- read_transactions()
  if (!id %in% x$id) stop("Transaction not found.")
  x <- x[x$id != id, , drop = FALSE]
  write_transactions(x)
  invisible(TRUE)
}

save_budget <- function(month, category, amount) {
  amount <- suppressWarnings(as.numeric(amount))
  if (length(amount) != 1 || is.na(amount) || !is.finite(amount) || amount < 0) {
    stop("Budget must be zero or a positive number.")
  }
  x <- read_budgets()
  x <- x[!(x$month == month & x$category == category), , drop = FALSE]
  x <- rbind(x, data.frame(month = month, category = category, amount = amount,
                           stringsAsFactors = FALSE))
  write_budgets(x)
  invisible(TRUE)
}

# NEW: delete a budget entry
delete_budget <- function(month, category) {
  x <- read_budgets()
  x <- x[!(x$month == month & x$category == category), , drop = FALSE]
  write_budgets(x)
  invisible(TRUE)
}