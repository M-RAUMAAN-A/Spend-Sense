# SpendSense sample CSV scenarios

These are fictional demo datasets for presentations and testing. They are separate from the live files in `data/` and do not replace your existing transactions.

## Files

1. `01_balanced_student_budget.csv` — ordinary student expenses spread across categories, useful for showing routine tracking.
2. `02_overspending_shopping.csv` — several large shopping purchases, useful for demonstrating category comparisons and budget warnings (set a suitable budget in the app).
3. `03_mixed_payments_recurring_costs.csv` — August–October transactions with recurring bills and multiple payment methods, useful for trends and payment-method analysis.

## How to use

1. Start SpendSense and open **Transactions**.
2. Use the CSV import control and select one file from this folder.
3. Review the imported rows and open **Overview**, **Budgets**, or **Insights & Reports** to demonstrate the available views.
4. Back up your current `data/transactions.csv` before importing if you need to preserve your existing demo data.

All files use the same transaction columns as the app's existing CSV: `id,date,description,category,amount,payment_method,notes`. Dates use `YYYY-MM-DD`, amounts are plain numeric rupee values, and category/payment labels match the sample app data. Import behaviour depends on the app's configured import mode (replace vs append).
