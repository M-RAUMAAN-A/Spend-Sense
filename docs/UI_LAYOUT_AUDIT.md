# SpendSense UI layout and overlap audit

## Changes applied

- Added a dedicated, visually separated delete area below the transaction table.
- The delete area shows the currently selected transaction (date, description, and amount) and has a full-width button on narrow screens.
- Fixed row targeting: the delete action now uses the same filtered data and row order as the table instead of independently sorting the data. This avoids deleting a different transaction after the table is sorted.
- Added explicit feedback when the user presses Delete without selecting a row.
- Separated CSV import and export into their own responsive area so they do not compete with the delete action.
- Added layout safeguards for narrow screens, DataTables overflow, long descriptions, buttons, input controls, and cards.
- Applied tabular lining numerals to amounts and dashboard figures for consistent digit alignment.
- Added responsive adjustments at tablet and phone widths while preserving the existing page structure and R/Shiny/CSV architecture.

## Verification status

- ZIP integrity checked successfully.
- Source code and layout rules inspected statically.
- Runtime/browser verification was not possible in this environment because R/Rscript is not installed. Please run the app in RStudio and check Overview, Transactions, Budgets, and Insights & Reports at desktop and mobile widths before treating the layout audit as fully runtime-verified.
