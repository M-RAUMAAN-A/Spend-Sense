# SpendSense — How to Use It (Beginner Guide)

## A. Install once

1. Install R from https://cran.r-project.org/
2. (Recommended) Install RStudio Desktop from https://posit.co/download/rstudio-desktop/
3. Extract the `SpendSense.zip` file to a folder you can find easily, such as `C:\\college\\Mini Project\\SpendSense`.
4. Open RStudio.
5. In RStudio, choose **File → Open File**, then open `app.R` inside the extracted SpendSense folder.
6. In the R console, install packages:

```r
install.packages(c("shiny", "bslib", "ggplot2", "dplyr", "DT", "readr", "lubridate", "scales"))
```

Wait until installation finishes. You usually only need to do this once.

## B. Start SpendSense

**Method 1 — RStudio**
- Make sure the RStudio working directory is the `SpendSense` folder.
- Open `app.R`.
- Click **Run App** near the top of the editor.

**Method 2 — R console**
Run these commands from the SpendSense project folder:

```r
setwd("C:/college/Mini Project/SpendSense")
shiny::runApp()
```

Change the path if you extracted the ZIP somewhere else.

## C. Use each section

### Overview
See total spending, budget, remaining amount, number of transactions, daily spending chart, category chart, recent transactions, and a short insight.

### Transactions
- Enter a description such as `Lunch`.
- Enter the amount in rupees.
- Choose the date, category, and payment method.
- Click **Add transaction**.
- Use the category filter and search box to narrow the transaction table.
- Import or export CSV files using the controls on this page.

### Budgets
- Choose the month from the dropdown at the top.
- Enter your overall monthly spending limit and click **Save monthly budget**.
- Choose a category, set its limit, and click **Save category limit**.
- The progress section compares recorded spending with your monthly budget.

### Insights & Reports
Review spending observations, compare months, inspect payment methods, and download the selected month's CSV report.

## D. Understand the sample data

The included data is fictional. It exists so that the dashboard has something to show immediately. You can keep it for a presentation or back up the CSV files and replace the rows with your own test data.

## E. Important files

- `data/transactions.csv`: expenses
- `data/budgets.csv`: budgets
- `data/categories.csv`: category names
- `backend/data_manager.R`: code that reads/writes the CSV files
- `backend/analytics.R`: calculations behind totals and charts
- `backend/insights.R`: rule-based messages
- `frontend/ui.R`: page layout
- `frontend/styles.css`: colors, spacing, and responsive styling

## F. If something goes wrong

- If R says a package is missing, install it with `install.packages("package_name")`.
- If the app cannot find `backend/` or `frontend/`, you probably started it from the wrong folder. Set the working directory to the folder containing `app.R`.
- If a chart is blank, check that the selected month has transaction rows.
- If you are changing CSV files by hand, keep all required column names and save dates as `YYYY-MM-DD`.
- If in doubt, stop the app, make a backup of `data/`, and restart it.


### CSV import format
Use a CSV with headers `date,description,category,amount,payment_method,notes`. The first five are required; `notes` is optional. Header capitalization and spaces are accepted. Dates can be `YYYY-MM-DD`, `DD/MM/YYYY`, or `MM/DD/YYYY`. Amounts may be plain numbers such as `1250.50` or formatted with commas/currency symbols such as `₹1,250.50`. Avoid mixing ambiguous date formats in one file.
