# 01_download.R
# Downloads the raw panel from the World Bank World Development Indicators (WDI).
# Output: data/raw/wdi_raw.csv
# Needs an internet connection. Takes about a minute.

library(WDI)

# Variable names on the left, WDI indicator codes on the right.
indicators <- c(
  growth     = "NY.GDP.PCAP.KD.ZG",    # GDP per capita growth (annual %)      -> outcome
  gdppc      = "NY.GDP.PCAP.KD",       # GDP per capita (constant 2015 US$)    -> convergence
  investment = "NE.GDI.TOTL.ZS",       # Gross capital formation (% of GDP)
  trade      = "NE.TRD.GNFS.ZS",       # Trade openness: exports + imports (% of GDP)
  inflation  = "FP.CPI.TOTL.ZG",       # Inflation, consumer prices (annual %)
  pop_growth = "SP.POP.GROW",          # Population growth (annual %)
  gov_cons   = "NE.CON.GOVT.ZS",       # Government consumption (% of GDP)
  fdi        = "BX.KLT.DINV.WD.GD.ZS", # FDI, net inflows (% of GDP)
  resources  = "NY.GDP.TOTL.RT.ZS"     # Natural resource rents (% of GDP)
)

raw <- WDI(
  country   = "all",
  indicator = indicators,
  start     = 2000,
  end       = 2023,
  extra     = TRUE   # adds region and income group, used to select countries
)

dir.create("data/raw", recursive = TRUE, showWarnings = FALSE)
write.csv(raw, "data/raw/wdi_raw.csv", row.names = FALSE)

message("Saved ", nrow(raw), " rows to data/raw/wdi_raw.csv (downloaded ", Sys.Date(), ")")
