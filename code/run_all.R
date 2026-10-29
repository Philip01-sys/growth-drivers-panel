# run_all.R
# Reproduces the whole project from raw data to final tables and figures.
# Run from the project root: source("code/run_all.R")

source("code/00_setup.R")
source("code/01_download.R")
source("code/02_clean.R")
source("code/03_explore.R")
source("code/04_models.R")

message("All done. Render the report with: quarto render report/report.qmd")
