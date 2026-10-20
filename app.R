# SpendSense - Smart Personal Expense Analyzer
# Entry point: run this file from the SpendSense project root with shiny::runApp()

required_packages <- c("shiny", "bslib", "ggplot2", "dplyr", "DT", "scales")
missing_packages <- required_packages[
  !vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)
]
if (length(missing_packages)) {
  stop(
    "Please install the missing packages first: ",
    paste(missing_packages, collapse = ", "),
    "\nRun install.packages(c(",
    paste(sprintf('"%s"', missing_packages), collapse = ", "),
    ")) in R."
  )
}

source(file.path("backend", "data_manager.R"), local = TRUE)
source(file.path("backend", "analytics.R"), local = TRUE)
source(file.path("backend", "insights.R"), local = TRUE)
shiny::addResourcePath("frontend", normalizePath("frontend", winslash = "/", mustWork = TRUE))
source(file.path("frontend", "ui.R"), local = TRUE)
source(file.path("backend", "server.R"), local = TRUE)

shinyApp(ui = ui, server = server)