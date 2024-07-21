version 17
disp "DateTime: $S_DATE $S_TIME"

************
* SCRIPT: 3_combine_data.do
* PURPOSE: This do file combines the data sets in preparation for running the analysis
************

************
* Code begins
************

// Select the range of birth years 
local start_year_births 		1930
local end_year_births			1941

// Select the years of mortality data
local start_year_deaths_nchs 	1979
local end_year_deaths_nchs		2004

// Select starting year for cumulative data 
local start_year_deaths_main	1990

************************************************************************
******** Create state of birth by birth year by death year data ********
************************************************************************

// Create separate datasets for:
	* Pooled analysis
	* Men only
	* Women only
	* White only
	* Non-White only

local suffix_0 ""
local suffix_1 "_men_only"
local suffix_2 "_women_only"
local suffix_3 "_white_only"
local suffix_4 "_non_white_only"

forvalues index = 0(1)4 {
	
	if `index' == 1 | `index' == 2 {
		local split_var "sex"
	}
	else if `index' == 3 | `index' == 4 {
		local split_var "race"
	}
	else {
		local split_var ""
	}
	
	use "$PROJ_PATH/analysis/processed/intermediate/ipums/usa_00083_extract_collapsed`suffix_`index''.dta", clear
	
	// Merge in state birthyear deaths by year for sample period
	merge 1:1 state birthyear year using "$PROJ_PATH/analysis/processed/intermediate/nchs/state_level_deaths_by_age_from_nchs`suffix_`index''.dta", assert(2 3) nogen 

	ds state birthyear year population `split_var', not 
	local cod_varlist "`r(varlist)'"

	// Merge in prohibition status by birthyear and state
	merge m:1 state birthyear using "$PROJ_PATH/analysis/processed/intermediate/prohibition/prohibition_status_by_state_1933-1941_modified.dta", assert(1 3) nogen keepusing(wet)
	tab birthyear if missing(wet)
	recode wet (mis = 0)

	// Merge in New Deal data by birthyear and state 
	merge m:1 state birthyear using "$PROJ_PATH/analysis/processed/intermediate/new_deal/new_deal_grants_by_state_1930_1941.dta", assert(1 3) nogen keepusing(tot_grants_ex_transfers spop)

	// Create log of New Deal grants 
	gen log_grants = ln(tot_grants_ex_transfers)
	
	// Merge in state-level personal income per capita 
	merge m:1 state birthyear using "$PROJ_PATH/analysis/processed/intermediate/great_depression/state_personal_income_per_capita_1930-1941.dta", assert(1 3) nogen keepusing(stincome)

	// Create log dollars for state personal income per capital variable 
	gen log_stinc = ln(stincome)

	// Estimate surviving cohort size for 1990 to 2004 using 1990 estimated population as baseline
	// 		- Year convention: deaths are within a year; census/APS is Jan 1 (even though really May 1)
	// 		- Assume population is as of 01 Jan 1990;  assume deaths occur during the calendar year

	gsort state birthyear year
	gen temp_pop1990 = population if year == 1990
	gegen population1990 = max(temp_pop1990), by(state birthyear)

	// Make cumulative deaths since 1990
	by state birthyear: gen cumulative_deaths = sum(deaths*(year >= 1990))

	by state birthyear: gen alive_jan01 = population1990 - cumulative_deaths[_n-1] if year > 1990
	replace alive_jan01 = population1990 if year == 1990

	drop temp_pop1990 population1990 cumulative_deaths 

	// Estimate surviving cohort size for 1979 to 1989 

	gsort + state + birthyear - year 
	gen temp_pop1990 = population if year == 1990
	gegen population1990 = max(temp_pop1990), by(state birthyear)

	// Make cumulative deaths from 1989 backwards
	by state birthyear: gen cumulative_deaths = sum(deaths*(year < 1990))
	by state birthyear: replace alive_jan01 = population1990 + cumulative_deaths if year < 1990

	drop temp_pop1990 population1990 cumulative_deaths 

	// Ensure population is not negative 
	replace alive_jan01 = 0 if alive_jan01 < 0 

	// Generate mortality outcome variables 
	foreach var of varlist `cod_varlist' {
		
		// If no one is alive, no one can die 
		replace `var' = 0 if alive_jan01 == 0

		// Express as deaths per 1000 surviving population
		gen y1_`var' = 1000*`var'/alive_jan01
	}

	// State law switchers
		//	1934: Arizona, California, Indiana, Nevada, South Dakota (5 states)
		// 	1935: Delaware, Idaho, Iowa, Montana, South Carolina, Utah, Wyoming (7 states)
		//	1937: ND
	gen state_switcher = 0
	replace state_switcher = 1	if state == 4 | state == 6 | state == 18 | state == 32 | state == 46
	replace state_switcher = 1	if state == 10 | state == 16 | state == 19 | state == 30 | state == 45 | state == 49 | state == 56
	replace state_switcher = 1 	if state == 38
	tab state state_switcher

	// Generate clustering variable
	gen state_birthyear = birthyear*100 + state

	order state birthyear state_birthyear year `split_var' alive_jan01 `cod_varlist' y1_*
	desc, f
	compress

	save "$PROJ_PATH/analysis/processed/data/data_for_analysis_nchs`suffix_`index''.dta", replace
	
}


**************************************
******** Create data for maps ********
**************************************

// Figure 1c: Map of first year treated by state 
use "$PROJ_PATH/analysis/processed/data/data_for_analysis_nchs.dta" if year >= `start_year_deaths_main' & year <= `end_year_deaths_nchs', clear

// Generate DiD treatment variable
estreat, treatvar(wet) time(birthyear) location(state) cutoff(0)

// Generate first treated year
egen first_year = min(time_treated), by(state)

keep state first_year
gduplicates drop
tab first_year, m

// Categorical roll out variable for main map
gen wet_cat = 0
replace wet_cat = 1 if first_year == 1938
replace wet_cat = 2 if first_year == 1937
replace wet_cat = 3 if first_year == 1935
replace wet_cat = 4 if first_year == 1934

gen wet_cat_label = ""
replace wet_cat_label = "Always dry" if wet_cat == 0
replace wet_cat_label = "1938" if wet_cat == 1
replace wet_cat_label = "1937" if wet_cat == 2
replace wet_cat_label = "1935" if wet_cat == 3
replace wet_cat_label = "1934" if wet_cat == 4

save "$PROJ_PATH/analysis/processed/data/map_input.dta", replace


// Figure AX: Map of first year treated by county 

// Load raw data set from EJ paper
use "$PROJ_PATH/analysis/raw/prohibition/prohibition_status_by_state_1933-1942.dta", clear
desc, f 

// Restrict to years of interest 
keep if year >= `start_year_births' & year <= `end_year_births' 

// Keep the variables we need 
keep fips status year stfips statename cname 

// Let's use the raw status variable to determine treatment status 
tab status, m 

gen wet = (status == "wet")
gen dry = (status == "dry" | status == "drish")

assert wet + dry == 1
drop dry 

rename year birthyear

// Generate DiD treatment variable
estreat, treatvar(wet) time(birthyear) location(fips) cutoff(0)

// Generate first treated year
egen first_year = min(time_treated), by(fips)

keep fips first_year
gduplicates drop
tab first_year, m

// Categorical roll out variable for main map
gen wet_cat = 0
replace wet_cat = 1 if first_year >= 1938 & !missing(first_year)
replace wet_cat = 2 if first_year == 1937
replace wet_cat = 3 if first_year == 1935
replace wet_cat = 4 if first_year == 1934

gen wet_cat_label = ""
replace wet_cat_label = "Always dry" if wet_cat == 0
replace wet_cat_label = "1938 or later" if wet_cat == 1
replace wet_cat_label = "1937" if wet_cat == 2
replace wet_cat_label = "1935" if wet_cat == 3
replace wet_cat_label = "1934" if wet_cat == 4

save "$PROJ_PATH/analysis/processed/data/county_map_input.dta", replace


// Figure Ax: Map of continuous variation in wet status by state
use "$PROJ_PATH/analysis/processed/data/data_for_analysis_nchs.dta" if year >= `start_year_deaths_main' & year <= `end_year_deaths_nchs', clear

// Generate DiD treatment variable
estreat, treatvar(wet) time(birthyear) location(state) cutoff(0)

// Use years when all states have turned wet in our sample 
keep if birthyear >= 1938 & birthyear <= 1941

gegen avg_wet = mean(wet), by(state)
keep state avg_wet 
gduplicates drop

gen wet_cat = 0
replace wet_cat = 5 if avg_wet == 1
replace wet_cat = 4 if avg_wet >= 0.75 & avg_wet < 1
replace wet_cat = 3 if avg_wet >= 0.5 & avg_wet < 0.75
replace wet_cat = 2 if avg_wet > 0 & avg_wet < 0.5
replace wet_cat = 1 if avg_wet == 0

gen wet_cat_label = ""
replace wet_cat_label = "100% wet" if wet_cat == 5
replace wet_cat_label = "75% to 99% wet" if wet_cat == 4
replace wet_cat_label = "50% to 74% wet" if wet_cat == 3
replace wet_cat_label = "1% to 49% wet" if wet_cat == 2
replace wet_cat_label = "0% wet" if wet_cat == 1

save "$PROJ_PATH/analysis/processed/data/map_input_continuous.dta", replace


**************************************************************************
******** Create collapsed data following Goodman-Bacon (2021) AER ********
**************************************************************************

// Overall 
use "$PROJ_PATH/analysis/processed/intermediate/nchs/state_level_deaths_by_age_from_nchs.dta" if year >= `start_year_deaths_main', clear

ds year state birthyear age, not 
local cod_varlist "`r(varlist)'"

collapse (sum) `cod_varlist', by(state birthyear)

gen year = `start_year_deaths_main'
order year 

// Label variables 
la var birthyear "Birth year"
la var year "Follow up base year"

la var deaths "All-Cause"
la var heart "Heart"
la var stroke "Stroke"
la var cancer "Cancer"
la var mv_acc "MVA"

la var resp "Chronic Lower Respiratory"
la var alcohol "Alcohol"
la var drugs "Drug"
la var homicide "Homicide"
la var suicide "Suicide"
la var accident "Accident"
la var external "External"
la var internal "Interal"
la var int_other "Internal Excl. Top 3"

desc, f
compress

save "$PROJ_PATH/analysis/processed/intermediate/nchs/state_level_cumulative_deaths_from_nchs.dta", replace

// By gender 

local gender_1 "men"
local gender_2 "women"

clear
foreach x in 1 2 {
	
	use "$PROJ_PATH/analysis/processed/intermediate/nchs/state_level_deaths_by_age_from_nchs_`gender_`x''_only.dta" if year >= `start_year_deaths_main', clear

	ds year state birthyear age sex, not 
	local cod_varlist "`r(varlist)'"

	collapse (sum) `cod_varlist', by(state birthyear sex)

	gen year = `start_year_deaths_main'
	order year 

	// Label variables 
	la var birthyear "Birth year"
	la var year "Follow up base year"

	la var deaths "All-Cause"
	la var heart "Heart"
	la var stroke "Stroke"
	la var cancer "Cancer"
	la var mv_acc "MVA"
	
	la var resp "Chronic Lower Respiratory"
	la var alcohol "Alcohol"
	la var drugs "Drug"
	la var homicide "Homicide"
	la var suicide "Suicide"
	la var accident "Accident"
	la var external "External"
	la var internal "Interal"
	la var int_other "Internal Excl. Top 3"

	desc, f
	compress

	save "$PROJ_PATH/analysis/processed/intermediate/nchs/state_level_cumulative_deaths_from_nchs_`gender_`x''_only.dta", replace

}


// By race 

local race_1 "white"
local race_2 "non_white"

foreach x in 1 2 {
	
	use "$PROJ_PATH/analysis/processed/intermediate/nchs/state_level_deaths_by_age_from_nchs_`race_`x''_only.dta" if year >= `start_year_deaths_main', clear

	ds year state birthyear age race, not 
	local cod_varlist "`r(varlist)'"

	collapse (sum) `cod_varlist', by(state birthyear race)

	gen year = `start_year_deaths_main'
	order year 

	// Label variables 
	la var birthyear "Birth year"
	la var year "Follow up base year"

	la var deaths "All-Cause"
	la var heart "Heart"
	la var stroke "Stroke"
	la var cancer "Cancer"
	la var mv_acc "MVA"
	
	la var resp "Chronic Lower Respiratory"
	la var alcohol "Alcohol"
	la var drugs "Drug"
	la var homicide "Homicide"
	la var suicide "Suicide"
	la var accident "Accident"
	la var external "External"
	la var internal "Interal"
	la var int_other "Internal Excl. Top 3"


	desc, f
	compress

	save "$PROJ_PATH/analysis/processed/intermediate/nchs/state_level_cumulative_deaths_from_nchs_`race_`x''_only.dta", replace
}

// Create separate datasets for:
	* Pooled analysis
	* Men only
	* Women only
	* White only
	* Non-White only

local suffix_0 ""
local suffix_1 "_men_only"
local suffix_2 "_women_only"
local suffix_3 "_white_only"
local suffix_4 "_non_white_only"

forvalues index = 0(1)4 {
	
	if `index' == 1 | `index' == 2 {
		local split_var "sex"
	}
	else if `index' == 3 | `index' == 4 {
		local split_var "race"
	}
	else {
		local split_var ""
	}
	
		// Get population at baseline from year-by-year analysis data 
	use "$PROJ_PATH/analysis/processed/data/data_for_analysis_nchs`suffix_`index''.dta", clear
	keep state birthyear year `split_var' alive_jan01
	rename alive_jan01 population 

	// Restrict birth years 
	keep if birthyear >= `start_year_births' & birthyear <= `end_year_births'
	
	// Restrict death years 
	keep if year == `start_year_deaths_main'

	// Merge in state birthyear deaths by year for sample period
	merge 1:1 state birthyear year using "$PROJ_PATH/analysis/processed/intermediate/nchs/state_level_cumulative_deaths_from_nchs`suffix_`index''.dta", assert(2 3) nogen 

	ds state birthyear year population `split_var', not 
	local cod_varlist "`r(varlist)'"

	// Merge in prohibition status by birthyear and state
	merge 1:1 state birthyear using "$PROJ_PATH/analysis/processed/intermediate/prohibition/prohibition_status_by_state_1933-1941_modified.dta", assert(1 3) nogen keepusing(wet)
	tab birthyear if missing(wet)
	recode wet (mis = 0)

	// Merge in New Deal data by birthyear and state 
	merge 1:1 state birthyear using "$PROJ_PATH/analysis/processed/intermediate/new_deal/new_deal_grants_by_state_1930_1941.dta", assert(1 3) nogen keepusing(tot_grants_ex_transfers spop)

	// Create log of New Deal grants 
	gen log_grants = ln(tot_grants_ex_transfers)
	
	// Merge in state-level personal income per capita 
	merge 1:1 state birthyear using "$PROJ_PATH/analysis/processed/intermediate/great_depression/state_personal_income_per_capita_1930-1941.dta", assert(1 3) nogen keepusing(stincome)

	// Create log dollars for state personal income per capital variable 
	gen log_stinc = ln(stincome)

	// Restrict birth years 
	keep if birthyear >= `start_year_births' & birthyear <= `end_year_births'

	// State law switchers
		//	1934: Arizona, California, Indiana, Nevada, South Dakota (5 states)
		// 	1935: Delaware, Idaho, Iowa, Montana, South Carolina, Utah, Wyoming (7 states)
		//	1937: ND
	gen state_switcher = 0
	replace state_switcher = 1	if state == 4 | state == 6 | state == 18 | state == 32 | state == 46
	replace state_switcher = 1	if state == 10 | state == 16 | state == 19 | state == 30 | state == 45 | state == 49 | state == 56
	replace state_switcher = 1 	if state == 38
	tab state state_switcher

	// Assume population is as of 01 Jan 1990;  assume deaths occur during the calendar year
	gsort state birthyear year
	rename population alive_jan01

	// Generate mortality outcomes
	foreach var of varlist `cod_varlist' {
		
		// If no one is alive, no one can die 
		replace `var' = 0 if alive_jan01 == 0

		// Top code at 1000 since max number of deaths is number of people alive at baseline
		gen y1_`var' = min(1000,1000*`var'/alive_jan01)
	}

	// Generate clustering variable
	gen state_birthyear = birthyear*100 + state

	order state birthyear state_birthyear year `split_var' alive_jan01 `cod_varlist' y1_*
	desc, f
	compress

	save "$PROJ_PATH/analysis/processed/data/data_for_cumulative_analysis_nchs`suffix_`index''.dta", replace

}

disp "DateTime: $S_DATE $S_TIME"

* EOF 