# 03_explore.R
# Summary statistics and the headline charts for the README and report.
# Input:  data/clean/panel.csv
# Output: output/tables/summary_stats.csv, output/figures/*.png

library(dplyr)
library(tidyr)
library(readr)
library(ggplot2)

panel <- read_csv("data/clean/panel.csv", show_col_types = FALSE)
focus <- "NGA"   # country highlighted in the charts (change to any ISO3 code)
focus_name <- unique(panel$country[panel$iso3c == focus])

dir.create("output/figures", recursive = TRUE, showWarnings = FALSE)
theme_set(theme_minimal(base_size = 12))

# 1. Summary statistics
summary_stats <- panel |>
  select(growth, investment, trade, inflation, pop_growth, gov_cons, fdi, resources) |>
  pivot_longer(everything(), names_to = "variable") |>
  group_by(variable) |>
  summarise(
    n      = sum(!is.na(value)),
    mean   = mean(value, na.rm = TRUE),
    sd     = sd(value, na.rm = TRUE),
    median = median(value, na.rm = TRUE),
    min    = min(value, na.rm = TRUE),
    max    = max(value, na.rm = TRUE)
  ) |>
  mutate(across(mean:max, ~ round(.x, 2)))

write_csv(summary_stats, "output/tables/summary_stats.csv")

# 2. Growth over time: regional median and middle 50% band, focus country on top
trend <- panel |>
  group_by(year) |>
  summarise(
    median = median(growth, na.rm = TRUE),
    p25    = quantile(growth, 0.25, na.rm = TRUE),
    p75    = quantile(growth, 0.75, na.rm = TRUE)
  )

p1 <- ggplot(trend, aes(year)) +
  geom_ribbon(aes(ymin = p25, ymax = p75), fill = "grey85") +
  geom_line(aes(y = median, colour = "Regional median"), linewidth = 1) +
  geom_line(data = filter(panel, iso3c == focus),
            aes(y = growth, colour = focus_name),
            linewidth = 1) +
  geom_hline(yintercept = 0, linetype = "dashed") +
  scale_colour_manual(values = setNames(c("grey30", "#1b7837"), c("Regional median", focus_name)),
                      name = NULL) +
  labs(title = "GDP per capita growth, Sub-Saharan Africa",
       subtitle = "Grey band = middle 50% of countries",
       x = NULL, y = "Annual growth (%)",
       caption = "Source: World Bank WDI") +
  theme(legend.position = "top")

ggsave("output/figures/growth_trend.png", p1, width = 8, height = 4.5, dpi = 150)

# 3. Investment vs growth, country averages
avg <- panel |>
  group_by(iso3c, country) |>
  summarise(growth = mean(growth, na.rm = TRUE),
            investment = mean(investment, na.rm = TRUE), .groups = "drop")

p2 <- ggplot(avg, aes(investment, growth)) +
  geom_smooth(method = "lm", se = TRUE, colour = "grey40", fill = "grey85") +
  geom_point(size = 2.5, alpha = 0.8) +
  geom_point(data = filter(avg, iso3c == focus), colour = "#1b7837", size = 4) +
  geom_text(data = filter(avg, iso3c == focus), aes(label = country),
            colour = "#1b7837", vjust = -1, fontface = "bold") +
  # Once you have run the models, rewrite this title as the finding,
  # e.g. "Countries that invest more grow faster" (only if the data shows it).
  labs(title = "Investment and growth across Sub-Saharan Africa",
       subtitle = "Each dot is one country, averaged over 2000-2023",
       x = "Gross capital formation (% of GDP)", y = "Average GDP per capita growth (%)",
       caption = "Source: World Bank WDI")

ggsave("output/figures/investment_vs_growth.png", p2, width = 8, height = 5, dpi = 150)

message("Saved summary table and 2 figures.")
