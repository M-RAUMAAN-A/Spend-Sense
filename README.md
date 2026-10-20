# SpendSense — Smart Personal Expense Analyzer

SpendSense is a college mini-project built with **R, Shiny, ggplot2, and CSV files**. It helps students track expenses, plan budgets, visualize spending patterns, and export monthly reports.

- **No SQL database**
- **No AI features**
- Local CSV files are the persistent storage
- Light, clean dashboard with teal accents

## 1. Folder guide

```text
SpendSense/
├── app.R                    # Main application entry point
├── frontend/
│   ├── ui.R                 # Shiny pages, inputs, layout
│   └── styles.css           # Visual styling
├── backend/
│   ├── server.R             # Reactive behavior and event handlers
│   ├── data_manager.R       # CSV reading, writing, validation
│   ├── analytics.R          # Totals and chart calculations
│   └── insights.R           # Rule-based spending messages
├── data/
│   ├── transactions.csv     # Example expense records
│   ├── budgets.csv          # Monthly/category budget records
│   └── categories.csv       # Allowed expense categories
├── tests/
│   └── test_analytics.R     # Basic calculation checks
├── docs/
│   └── PROJECT_OVERVIEW.md  # Short project documentation
├── HOW_TO_USE.md            # Beginner-friendly launch guide
└── README.md
```

## 2. Requirements

Install **R** (4.2 or newer recommended) and optionally **RStudio**. Internet is needed only to install packages the first time.

Open RStudio, set the working directory to the extracted `SpendSense` folder, and run:

```r
install.packages(c(
  "shiny", "bslib", "ggplot2", "dplyr",
  "DT", "readr", "lubridate", "scales"
))
```

The app checks for its required packages when it starts.

## 3. Run the app

In RStudio, open `app.R` and click **Run App**.

Or open the R console with the working directory set to this folder and run:

```r
shiny::runApp()
```

Your browser should open the local SpendSense dashboard. It runs on your own computer; it is not automatically published on the internet.

## 4. First demonstration

1. Open **Overview** and inspect the sample monthly cards and charts.
2. Go to **Transactions** and add a small test expense.
3. Confirm that the dashboard charts and totals update.
4. Go to **Budgets** and set a monthly limit, for example ₹8,000.
5. Save a category budget, such as ₹1,500 for Food.
6. Open **Insights & Reports** and review the rule-based messages.
7. Export a CSV report to demonstrate data portability.

The included sample data is fictional and intended only for demonstration.

## 5. CSV format

### `transactions.csv`

Required columns:

`id,date,description,category,amount,payment_method,notes`

- Dates use `YYYY-MM-DD`.
- Amounts are positive numbers in Indian rupees.
- Categories must match `data/categories.csv`.
- Do not rename or remove the column headers.

### `budgets.csv`

Columns:

`month,category,amount`

- `month` uses `YYYY-MM`.
- Use category `ALL` for the overall monthly budget.
- Use a real category name for a category-specific budget.

### `categories.csv`

Columns:

`category,description`

Add new categories here before importing transactions that use them.

## 6. Import and export

Use **Transactions → Import transactions from CSV**. The imported file must include `date`, `description`, `category`, `amount`, and `payment_method` (headers are case-insensitive; spaces and punctuation are normalized). Dates may use `YYYY-MM-DD`, `DD/MM/YYYY`, or `MM/DD/YYYY`. Amounts may include ₹ and comma separators. Categories and payment methods must match the values supported by the app. An optional `notes` column is supported. The transaction table supports column sorting; click a header to sort.

Use the export buttons to download transaction data or the selected month's report.

## 7. Data safety

The app writes changes into the CSV files under `data/`. Make a copy of this folder before experimenting with large imports. Do not store bank passwords, account numbers, or other sensitive credentials in this project. This is a local educational tracker, not a bank-connected financial service.

## 8. Known scope and limitations

- Budgets default to ₹8,000 for months with no saved overall budget; save your preferred amount in the Budget Planner.
- Spending insights are transparent rule-based messages, not AI or professional financial advice.
- The project is designed for a single local user. It does not include login, cloud sync, or multi-user access control.
- Check the imported CSV preview/headers before importing. Keep a backup of the data files.

## 9. Troubleshooting

**Package missing:** Run the `install.packages(...)` command above, then restart the app.

**App says CSV format is invalid:** Restore the original CSV from the ZIP or make sure the required headers are unchanged.

**Charts are empty:** Select a month containing transactions, or add an expense.

**Changes do not appear:** Stop the app and run `shiny::runApp()` again. Confirm that you started the app from the SpendSense root folder.

## 10. Academic project summary

**Problem:** Students may lose track of small purchases and have difficulty understanding their spending patterns.

**Solution:** SpendSense records expenses, compares them with budgets, visualizes spending patterns, and creates understandable rule-based insights.

**R concepts demonstrated:** data frames, CSV input/output, functions, validation, aggregation, date handling, and data visualization.

**Future enhancements:** transaction editing/deletion, recurring expenses, savings goals, more robust import preview, and automated tests.
