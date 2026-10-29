# 04_models.R
# Panel regressions of GDP per capita growth on lagged macro conditions.
# Input:  data/clean/panel.csv
# Output: output/tables/models.csv, output/tables/hausman.csv,
#         output/figures/coefficients.png

library(dplyr)
library(readr)
library(ggplot2)
library(plm)
library(lmtest)
library(sandwich)

panel <- read_csv("data/clean/panel.csv", show_col_types = FALSE)
pdata <- pdata.frame(as.data.frame(panel), index = c("iso3c", "year"))

f <- growth ~ log_gdppc_l1 + investment_l1 + trade_l1 + infl_log_l1 +
  pop_growth_l1 + gov_cons_l1 + fdi_l1 + resources_l1

# 1. Three standard specifications
pooled <- plm(f, data = pdata, model = "pooling")
fe     <- plm(f, data = pdata, model = "within", effect = "twoways")  # country + year effects
fe_ind <- plm(f, data = pdata, model = "within", effect = "individual")
re     <- plm(f, data = pdata, model = "random", effect = "individual")

# 2. Hausman test: if p < 0.05, fixed effects are preferred over random effects
haus <- phtest(fe_ind, re)
hausman <- data.frame(
  statistic = round(unname(haus$statistic), 2),
  df        = unname(haus$parameter),
  p_value   = signif(haus$p.value, 3),
  preferred = ifelse(haus$p.value < 0.05, "Fixed effects", "Random effects")
)
write_csv(hausman, "output/tables/hausman.csv")

# 3. Standard errors clustered by country (robust to heteroskedasticity and
#    serial correlation within a country)
tidy_plm <- function(model, name) {
  ct <- coeftest(model, vcov = vcovHC(model, method = "arellano", type = "HC1", cluster = "group"))
  data.frame(
    model    = name,
    term     = rownames(ct),
    estimate = ct[, 1],
    std_error = ct[, 2],
    p_value  = ct[, 4],
    row.names = NULL
  )
}

results <- bind_rows(
  tidy_plm(pooled, "Pooled OLS"),
  tidy_plm(fe,     "Fixed effects (country + year)"),
  tidy_plm(re,     "Random effects")
) |>
  filter(term != "(Intercept)") |>
  mutate(stars = case_when(p_value < 0.01 ~ "***", p_value < 0.05 ~ "**",
                           p_value < 0.1 ~ "*", TRUE ~ ""))

fit <- data.frame(
  model = c("Pooled OLS", "Fixed effects (country + year)", "Random effects"),
  n_obs = c(nobs(pooled), nobs(fe), nobs(re)),
  n_countries = c(pdim(pooled)$nT$n, pdim(fe)$nT$n, pdim(re)$nT$n),
  r2_within_or_overall = round(c(summary(pooled)$r.squared["rsq"],
                                 summary(fe)$r.squared["rsq"],
                                 summary(re)$r.squared["rsq"]), 3)
)

write_csv(mutate(results, across(estimate:p_value, ~ signif(.x, 3))), "output/tables/models.csv")
write_csv(fit, "output/tables/model_fit.csv")

# 4. Robustness: Driscoll-Kraay errors (also robust to shocks common to all countries)
dk <- coeftest(fe, vcov = vcovSCC(fe, type = "HC1", maxlag = 2))
write_csv(data.frame(term = rownames(dk), estimate = signif(dk[, 1], 3),
                     std_error = signif(dk[, 2], 3), p_value = signif(dk[, 4], 3)),
          "output/tables/fe_driscoll_kraay.csv")

# 5. Coefficient plot for the preferred model (fixed effects)
labels <- c(
  log_gdppc_l1 = "Log GDP per capita (t-1)", investment_l1 = "Investment, % GDP (t-1)",
  trade_l1 = "Trade, % GDP (t-1)", infl_log_l1 = "Log inflation (t-1)",
  pop_growth_l1 = "Population growth (t-1)", gov_cons_l1 = "Gov. consumption, % GDP (t-1)",
  fdi_l1 = "FDI inflows, % GDP (t-1)", resources_l1 = "Resource rents, % GDP (t-1)"
)

coef_df <- results |>
  filter(model == "Fixed effects (country + year)") |>
  mutate(label = labels[term],
         low = estimate - 1.96 * std_error, high = estimate + 1.96 * std_error)

p <- ggplot(coef_df, aes(estimate, reorder(label, estimate))) +
  geom_vline(xintercept = 0, linetype = "dashed") +
  geom_errorbar(aes(xmin = low, xmax = high), width = 0.2, colour = "grey40", orientation = "y") +
  geom_point(size = 3, colour = "#1b7837") +
  labs(title = "What moves next year's growth?",
       subtitle = "Fixed effects (country + year), 95% intervals clustered by country",
       x = "Change in GDP per capita growth (percentage points)", y = NULL,
       caption = "Source: World Bank WDI, author's estimates") +
  theme_minimal(base_size = 12)

ggsave("output/figures/coefficients.png", p, width = 8, height = 5, dpi = 150)

print(hausman)
print(fit)
message("Models done. See output/tables/ and output/figures/coefficients.png")
