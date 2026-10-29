# 00_setup.R
# Installs the packages this project needs. Run once.
# Run every script from the project root (open growth-drivers-panel.Rproj in RStudio).

packages <- c(
  "WDI",       # World Bank World Development Indicators API
  "dplyr", "tidyr", "readr",
  "ggplot2",
  "plm",       # panel data models (pooled, fixed effects, random effects)
  "lmtest", "sandwich",  # robust and clustered standard errors
  "knitr",     # tables in the Quarto report
  "here",      # finds the project root from the report
  "renv"       # locks package versions so anyone can reproduce the results
)

missing <- packages[!packages %in% rownames(installed.packages())]
if (length(missing) > 0) install.packages(missing)

# Optional, once you are happy the project runs:
# renv::init()   # creates renv.lock, commit it to GitHub

for (d in c("data/raw", "data/clean", "output/figures", "output/tables")) {
  dir.create(d, recursive = TRUE, showWarnings = FALSE)
}

message("Setup complete.")
