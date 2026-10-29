* models.do
* Replicates the R panel models in Stata, to show the same results in both tools.
* Run after the R scripts have created data/clean/panel.csv.
* Set the working directory to the project root first, e.g.:
*   cd "C:/Users/you/Documents/growth-drivers-panel"

clear all
set more off

import delimited "data/clean/panel.csv", clear

* Panel setup: countries by year
encode iso3c, gen(country_id)
xtset country_id year

local x log_gdppc_l1 investment_l1 trade_l1 infl_log_l1 pop_growth_l1 gov_cons_l1 fdi_l1 resources_l1

* 1. Pooled OLS, errors clustered by country
regress growth `x', vce(cluster country_id)
estimates store pooled

* 2. Fixed effects with year dummies (two-way), clustered errors
xtreg growth `x' i.year, fe vce(cluster country_id)
estimates store fe

* 3. Random effects, clustered errors
xtreg growth `x', re vce(cluster country_id)
estimates store re

* 4. Hausman test (needs the non-robust versions)
quietly xtreg growth `x', fe
estimates store fe_h
quietly xtreg growth `x', re
estimates store re_h
hausman fe_h re_h

* 5. Side-by-side table (install once with: ssc install estout)
capture which esttab
if _rc == 0 {
    esttab pooled fe re, se star(* 0.10 ** 0.05 *** 0.01) ///
        keep(`x') mtitles("Pooled" "FE (two-way)" "RE") ///
        title("GDP per capita growth, Sub-Saharan Africa")
    esttab pooled fe re using "output/tables/stata_models.rtf", replace ///
        se star(* 0.10 ** 0.05 *** 0.01) keep(`x') mtitles("Pooled" "FE (two-way)" "RE")
}
else {
    estimates table pooled fe re, keep(`x') b(%9.3f) se star
}
