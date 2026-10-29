# 02_clean.R
# Turns the raw WDI download into an analysis-ready panel.
# Input:  data/raw/wdi_raw.csv
# Output: data/clean/panel.csv, output/tables/missing_data.csv

library(dplyr)
library(readr)

raw <- read_csv("data/raw/wdi_raw.csv", show_col_types = FALSE)

# 1. Keep Sub-Saharan African countries only (drops regional aggregates)
ssa <- raw |>
  filter(region == "Sub-Saharan Africa") |>
  select(country, iso3c, year, income, growth, gdppc, investment, trade,
         inflation, pop_growth, gov_cons, fdi, resources) |>
  arrange(iso3c, year)

# 2. Record missing data before any cleaning (goes in the report)
missing_table <- ssa |>
  summarise(across(growth:resources, ~ round(100 * mean(is.na(.x)), 1))) |>
  tidyr::pivot_longer(everything(), names_to = "variable", values_to = "pct_missing") |>
  arrange(desc(pct_missing))

dir.create("output/tables", recursive = TRUE, showWarnings = FALSE)
write_csv(missing_table, "output/tables/missing_data.csv")

# 3. Transformations
#    - Inflation is heavily skewed (hyperinflation episodes), so use log(1 + rate).
#    - Regressors are lagged one year: this year's growth is explained by last
#      year's conditions, which reduces reverse causality.
#    - Log of lagged GDP per capita tests convergence (poorer countries growing faster).
panel <- ssa |>
  group_by(iso3c) |>
  mutate(
    infl_log       = log1p(pmax(inflation, -99) / 100),
    log_gdppc_l1   = log(dplyr::lag(gdppc)),
    investment_l1  = dplyr::lag(investment),
    trade_l1       = dplyr::lag(trade),
    infl_log_l1    = dplyr::lag(infl_log),
    pop_growth_l1  = dplyr::lag(pop_growth),
    gov_cons_l1    = dplyr::lag(gov_cons),
    fdi_l1         = dplyr::lag(fdi),
    resources_l1   = dplyr::lag(resources)
  ) |>
  ungroup()

# 4. Keep countries with at least 15 years of growth data
keep <- panel |>
  group_by(iso3c) |>
  summarise(n_growth = sum(!is.na(growth))) |>
  filter(n_growth >= 15) |>
  pull(iso3c)

panel <- panel |> filter(iso3c %in% keep)

dir.create("data/clean", recursive = TRUE, showWarnings = FALSE)
write_csv(panel, "data/clean/panel.csv")

message("Clean panel: ", n_distinct(panel$iso3c), " countries, ",
        min(panel$year), "-", max(panel$year), ", ", nrow(panel), " rows")
