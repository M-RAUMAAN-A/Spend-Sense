# SpendSense Project Overview

## Title
SpendSense — Smart Personal Expense Analyzer

## Problem statement
Students often make frequent small purchases but may not have a clear picture of their total spending, largest expense categories, or remaining monthly allowance.

## Objective
Build a local interactive dashboard that records expenses, compares spending with a budget, and presents understandable visual summaries.

## Main modules
1. **Frontend:** Shiny pages, forms, tables, navigation, and styling.
2. **Backend data manager:** CSV persistence and input validation.
3. **Analytics:** Monthly totals, category totals, daily totals, and payment-method summaries.
4. **Insights:** Transparent rules that identify budget usage, the largest category, and comparison with the previous month.
5. **Reports:** CSV export for transactions and a selected month.

## Charts
- Daily expense bar chart
- Category spending bar chart
- Monthly spending comparison
- Payment method doughnut-style chart

## Technology
R, Shiny, bslib, ggplot2, dplyr, DT, and CSV files.

## Data flow
User input → validation → CSV storage → analytics functions → reactive dashboard → charts and reports.

## Scope
The project is a single-user educational application. It does not connect to bank accounts, require SQL, or use AI.

## Demo script
1. Open the dashboard and point out the summary cards.
2. Add a transaction and show the totals update.
3. Set a monthly budget.
4. Open insights and explain how the rules produce messages.
5. Export the month report.
