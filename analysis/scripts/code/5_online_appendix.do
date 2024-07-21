version 17
disp "DateTime: $S_DATE $S_TIME"

************
* SCRIPT: 5_online_appendix.do
* PURPOSE: This do file combines the data sets in preparation for running the analysis in the online appendix
************

************
* Code begins
************

// Select the range of birth years 
local start_year_births 		1930
local end_year_births			1941

// Select the years of mortality data
local start_year_deaths_nchs 	1990
local end_year_deaths_nchs		2004

// Use different start year for extended panel 
local extended_start_year 1979

// Settings for figures
graph set window fontface 		"Roboto Light"
graph set ps fontface 			"Roboto Light"
graph set eps fontface 			"Roboto Light"

// Specification parameters 
local weight					"alive_jan01"
local absvar					"birthyear##year state##year"
local unit_id					"state"
local time_id					"birthyear"
local clustervar 				"state_birthyear" 
local controls					"log_grants log_stinc"
local ybar_sample				"!missing(time_treated) & birthyear <= 1933" 
local treated					"treated"

// Causes of death for outcomes
local cod_depvar_list "deaths heart stroke cancer"
tokenize `cod_depvar_list'
local max_val: word count `cod_depvar_list'

// Settings for tables
local booktabs_default_options	"booktabs b(%12.3f) se(%12.3f) collabels(none) drop(*) f gaps label mlabels(none) nolines nomtitles nonum noobs nostar substitute(\_ _)"

// Settings for aggregating event study estimates 
local scaled_coef 		"(L0event + L1event + L2event + L3event + L4event)/5"
local scaled_coef_last 	"(L0event + L1event + L2event + L3event)/4"
local comtype 			"lincom"

// --------------------- Figure A1: Plot number of treated units in each event-time bin ---------------------

eststo drop *
use "$PROJ_PATH/analysis/processed/data/data_for_analysis_nchs.dta" if year >= `start_year_deaths_nchs' & year <= `end_year_deaths_nchs', clear

// Collapse to birth year by state panel 
keep state birthyear wet 
gduplicates drop 

// Generate DiD treatment variable
estreat, treatvar(wet) time(birthyear) location(state) cutoff(0)

// time_treated is a variable for unit-specific treatment years (never-treated: time_treated == missing)
tab time_treated, m

// store largest leads and lags
capture drop event_time_bacon
gen event_time_bacon = birthyear - time_treated

tab event_time_bacon
sum event_time_bacon

local t_min = r(min)
local t_max = r(max)

drop event_time_bacon

create_treated_bins, ///
	low_event_cap(`t_min') ///
	high_event_cap(`t_max') ///
	output_file_name("$PROJ_PATH/analysis/output/appendix/figure_a1_n_treated_units") ///
	time_variable(birthyear) ///
	id_variable(state) 



// --------------------- Figure A3: Robustness of main event study estimates with controls ---------------------

// Loop through depvars 
	* Panel A: All-cause mortality
	* Panel B: Heart disease
	* Panel C: Stroke
	* Panel D: Cancer
			
local cod_depvar_list "deaths heart stroke cancer" 
tokenize `cod_depvar_list'
local max_val: word count `cod_depvar_list'

forvalues n = 1(1)`max_val' { 

	// Dependent variable
	local depvar "y1_``n''"
	
	// (1) Baseline with controls 
	use "$PROJ_PATH/analysis/processed/data/data_for_analysis_nchs.dta" if year >= `start_year_deaths_nchs' & year <= `end_year_deaths_nchs', clear
		
	// Generate DiD treatment variable
	estreat, treatvar(wet) time(birthyear) location(state) cutoff(0)

	// store largest leads and lags
	capture drop event_time_bacon
	gen event_time_bacon = birthyear - time_treated

	tab event_time_bacon
	sum event_time_bacon

	local t_min = abs(r(min))
	local t_max = abs(r(max))

	cap drop F*event L*event

	// dummy for the latest- or never-treated cohort
	gen never_treated = missing(time_treated)

	forvalues l = 0/`t_max' {
		gen L`l'event = event_time_bacon ==`l'
	}
	forvalues l = 1/`t_min' {
		gen F`l'event = event_time_bacon ==-`l'
	}
	drop F1event // normalize K = -1 to zero

	// Estimation
	eventstudyinteract `depvar' L*event F*event [aw = `weight'], cohort(time_treated) control_cohort(never_treated) absorb(`absvar') vce(cluster `clustervar') covariates(`controls')

	// Storing estimates for later
	matrix sa_b = e(b_iw)
	matrix sa_v = e(V_iw)

	
	
	// (2) Last treated as control instead of never treated 
	use "$PROJ_PATH/analysis/processed/data/data_for_analysis_nchs.dta" if year >= `start_year_deaths_nchs' & year <= `end_year_deaths_nchs', clear

	// Generate DiD treatment variable
	estreat, treatvar(wet) time(birthyear) location(state) cutoff(0)

	// Create variable for last treated group
	egen last_treated_year = max(time_treated)
	gen last_treated = (time_treated == last_treated_year)
	tab state if last_treated == 1

	// Drop years when last treated group is treated
	drop if birthyear >= last_treated_year 
	
	// store largest leads and lags
	capture drop event_time_bacon
	gen event_time_bacon = birthyear - time_treated

	tab event_time_bacon
	sum event_time_bacon

	local t_min = abs(r(min))
	local t_max = abs(r(max))

	cap drop F*event L*event

	// dummy for the latest- or never-treated cohort
	gen never_treated = missing(time_treated)

	forvalues l = 0/`t_max' {
		gen L`l'event = event_time_bacon ==`l'
	}
	forvalues l = 1/`t_min' {
		gen F`l'event = event_time_bacon ==-`l'
	}
	drop F1event // normalize K = -1 to zero

	// Estimation
	eventstudyinteract `depvar' L*event F*event [aw = `weight'], cohort(time_treated) control_cohort(last_treated)  absorb(`absvar') vce(cluster `clustervar') covariates(`controls')

	// Storing estimates for later
	matrix sa_b_last = e(b_iw)
	matrix sa_v_last = e(V_iw)
	
	
	
	// (3) Limit only to state-level transitions
	use "$PROJ_PATH/analysis/processed/data/data_for_analysis_nchs.dta" if year >= `start_year_deaths_nchs' & year <= `end_year_deaths_nchs', clear

	// Generate DiD treatment variable
	estreat, treatvar(wet) time(birthyear) location(state) cutoff(0)
	
	// Drop states that go entirely wet via local option elections
	drop if state_switcher == 0 & !missing(time_treated)
	
	// store largest leads and lags
	capture drop event_time_bacon
	gen event_time_bacon = birthyear - time_treated

	tab event_time_bacon
	sum event_time_bacon

	local t_min = abs(r(min))
	local t_max = abs(r(max))

	cap drop F*event L*event

	// dummy for the latest- or never-treated cohort
	gen never_treated = missing(time_treated)

	forvalues l = 0/`t_max' {
		gen L`l'event = event_time_bacon ==`l'
	}
	forvalues l = 1/`t_min' {
		gen F`l'event = event_time_bacon ==-`l'
	}
	drop F1event // normalize K = -1 to zero

	// Estimation
	eventstudyinteract `depvar' L*event F*event [aw = `weight'], cohort(time_treated) control_cohort(never_treated)  absorb(`absvar') vce(cluster `clustervar') covariates(`controls')

	// Storing estimates for later
	matrix sa_b_state = e(b_iw)
	matrix sa_v_state = e(V_iw)
	
	

	// (4) Treated only if > 0.5
	use "$PROJ_PATH/analysis/processed/data/data_for_analysis_nchs.dta" if year >= `start_year_deaths_nchs' & year <= `end_year_deaths_nchs', clear

	// Generate DiD treatment variable
	estreat, treatvar(wet) time(birthyear) location(state) cutoff(0.5)
	
	// Drop states that go entirely wet via local option elections
	drop if state_switcher == 0 & !missing(time_treated)
	
	// store largest leads and lags
	capture drop event_time_bacon
	gen event_time_bacon = birthyear - time_treated

	tab event_time_bacon
	sum event_time_bacon

	local t_min = abs(r(min))
	local t_max = abs(r(max))

	cap drop F*event L*event

	// dummy for the latest- or never-treated cohort
	gen never_treated = missing(time_treated)

	forvalues l = 0/`t_max' {
		gen L`l'event = event_time_bacon ==`l'
	}
	forvalues l = 1/`t_min' {
		gen F`l'event = event_time_bacon ==-`l'
	}
	drop F1event // normalize K = -1 to zero

	// Estimation
	eventstudyinteract `depvar' L*event F*event [aw = `weight'], cohort(time_treated) control_cohort(never_treated)  absorb(`absvar') vce(cluster `clustervar') covariates(`controls')

	// Storing estimates for later
	matrix sa_b_majority = e(b_iw)
	matrix sa_v_majority = e(V_iw)
	
	

	// (5) State-level clustering
	use "$PROJ_PATH/analysis/processed/data/data_for_analysis_nchs.dta" if year >= `start_year_deaths_nchs' & year <= `end_year_deaths_nchs', clear
		
	// Generate DiD treatment variable
	estreat, treatvar(wet) time(birthyear) location(state) cutoff(0)

	// store largest leads and lags
	capture drop event_time_bacon
	gen event_time_bacon = birthyear - time_treated

	tab event_time_bacon
	sum event_time_bacon

	local t_min = abs(r(min))
	local t_max = abs(r(max))

	cap drop F*event L*event

	// dummy for the latest- or never-treated cohort
	gen never_treated = missing(time_treated)

	forvalues l = 0/`t_max' {
		gen L`l'event = event_time_bacon ==`l'
	}
	forvalues l = 1/`t_min' {
		gen F`l'event = event_time_bacon ==-`l'
	}
	drop F1event // normalize K = -1 to zero

	// Estimation
	eventstudyinteract `depvar' L*event F*event [aw = `weight'], cohort(time_treated) control_cohort(never_treated) absorb(`absvar') vce(cluster state) covariates(`controls')

	// Storing estimates for later
	matrix sa_b_cluster = e(b_iw)
	matrix sa_v_cluster = e(V_iw)
	
	// Add zero
	local colnames : colnames sa_b_state 
	matrix sa_b_state = (0,sa_b_state)
	matrix colnames sa_b_state = F1event `colnames'	
	
	// Figure panels 
	if `n' == 1 {
		local figpan "a"
	}
	else if `n' == 2 {
		local figpan "b"
	}
	else if `n' == 3 {
		local figpan "c"
	}
	else if `n' == 4 {
		local figpan "d"
	}
	
	// Dependent variable label 
	la var `depvar' "`: var label ``n''' Mortality per 1,000 Population"

	// Create event study plot	
	event_plot sa_b#sa_v sa_b_last#sa_v_last sa_b_state#sa_v_state sa_b_majority#sa_v_majority sa_b_cluster#sa_v_cluster, ///
		stub_lag(L#event L#event L#event L#event L#event) stub_lead(F#event F#event F#event F#event F#event) ///
		plottype(scatter) ciplottype(rcap) ///
		together perturb(-0.3(0.15)0.3) trimlead(4) trimlag(4) noautolegend ///
		graph_opt( ///
			subtitle("`: var label `depvar''", size(6) pos(11)) ///
			xtitle("Years since state becomes wet", size(6) height(7)) ///
			ytitle("Average causal effect", size(6)) ///
			xlabel(-4(1)4, nogrid notick  labsize(6)) ///
			ylab(`y_range', labsize(6) angle(0) format(%03.2f) nogrid notick) ///
			xscale(extend) yscale(extend) ///
			xsize(8) ///
			legend(order(1 "Baseline + controls" 3 "Last treated as control" 5 "State transitions" 7 "Majority transitions" 9 "Cluster at state level") rows(2) position(6) size(6) region(style(none))) ///
			xline(-0.5, lcolor(gs8) lpattern(dash)) yline(0, lcolor(gs8)) graphregion(color(white)) bgcolor(white)  ///
		) ///
		lag_opt1(msymbol(O) color(cranberry)) lag_ci_opt1(color(cranberry)) ///
		lag_opt2(msymbol(D) color(navy)) lag_ci_opt2(color(navy)) ///
		lag_opt3(msymbol(T) color(forest_green)) lag_ci_opt3(color(forest_green)) ///
		lag_opt4(msymbol(S) color(dkorange)) lag_ci_opt4(color(dkorange)) ///
		lag_opt5(msymbol(Th) color(purple)) lag_ci_opt5(color(purple))
		
	graph export "$PROJ_PATH/analysis/output/appendix/figure_a3`figpan'_es_robust_controls_``n''.png", as(png) height(2400) replace
	
}


// --------------------- Table A1: Crosswalk of ICD9 and ICD10 for Cause-Specific Mortality ---------------------

capture file close myfile
file open myfile using "$PROJ_PATH/analysis/output/appendix/table_a1_icd_crosswalk.tex", write text replace 
file write myfile "\multicolumn{1}{c}{Cause-specific death} &\multicolumn{1}{c}{ICD9} &\multicolumn{1}{c}{ICD10} \\" _n
file write myfile "\addlinespace\midrule" _n
file write myfile "Heart disease & 390–8, 402, 404, 410–29 & I00–09, 11, 13, 20–51 \\" _n
file write myfile "\addlinespace Stroke (cerebrovascular disease) & 430–434, 436–438 & I60–69 \\" _n
file write myfile "\addlinespace Cancer & 140–208 & C00–97 \\" _n
file write myfile "\addlinespace Motor vehicle accident & E810–25 & V02–04, 09.0, 09.2, 12–14, \\" _n 
file write myfile "&& 19.0–19.2, 19.4–19.6, 20–79, \\" _n
file write myfile "&& 80.3–80.5, 81.0–81.1, 82.0–82.1, \\" _n
file write myfile "&& 83–86, 87.0–87.8, 88.0–88.8, \\" _n
file write myfile "&& 89.0, 89.2\\" _n
file close myfile


// --------------------- Table A2: Bounding infant deaths by year --------------------------------------------------

// Get infant mortality from EJ paper
use year fips indth bir using "$PROJ_PATH/analysis/raw/prohibition/full19301942.dta", clear
gen state = floor(fips/1000)
collapse (sum) indth bir, by(year state)
keep if year >= 1930 & year <= 1941 
rename year birthyear
tempfile imr 
save `imr', replace

// Load mortality data for 1990 to 2004 from NCHS 
use "$PROJ_PATH/analysis/processed/data/data_for_analysis_nchs.dta" if year >= `start_year_deaths_nchs' & year <= `end_year_deaths_nchs', clear

// Merge in infant deaths 
merge m:1 state birthyear using `imr', keep(1 3) keepusing(indth bir)

tab state if _merge == 1
tab birthyear if _merge == 1

drop _merge 

* Bounding exercise:
	* Jacks, Pendakur and Shigeoka find that the repeal of Federal Prohibition increased infant mortality by 4%
	* indth = observed infant mortality
	* Infant deaths attributable to repeal: indth - indth/1.04 in treated state-years 
	
// Add infant deaths distributed across years of death in proportion to actual deaths
gsort state birthyear year 
egen total_deaths = total(deaths), by(state birthyear)
gen deaths_plusinf = deaths + (indth - indth/1.04)*(wet > 0 & !missing(wet))*deaths/total_deaths
drop total_deaths


// Estimate surviving cohort size for 1990 to 2004 using 1990 estimated population as baseline
// 		- Year convention: deaths are within a year; census/APS is Jan 1 (even though really May 1)
// 		- Assume population is as of 01 Jan 1990;  assume deaths occur during the calendar year

gsort state birthyear year
gen temp_pop1990 = alive_jan01 + (indth - indth/1.04)*(wet > 0 & !missing(wet)) if year == `start_year_deaths_nchs'
gegen population1990 = max(temp_pop1990), by(state birthyear)

// Make cumulative deaths since 1990
by state birthyear: gen cumulative_deaths = sum(deaths*(year >= 1990))

by state birthyear: gen alive_jan01_plusinf = population1990 - cumulative_deaths[_n-1] if year > 1990
replace alive_jan01_plusinf = population1990 if year == 1990

drop temp_pop1990 population1990 cumulative_deaths 

// Ensure population is not negative 
replace alive_jan01_plusinf = 0 if alive_jan01_plusinf < 0 

// Adjust dependent variable by adding infants only to denominator
gen y1_deaths_adjust_denom = min(1000,1000*deaths/(alive_jan01_plusinf))
sum y1_deaths_adjust_denom, d 

// Adjust dependent variable by adding infants to numerator and denominator 
gen y1_deaths_plusinf = min(1000,1000*deaths_plusinf/(alive_jan01_plusinf))
sum y1_deaths_plusinf, d


// Generate DiD treatment variable
estreat, treatvar(wet) time(birthyear) location(state) cutoff(0)

// store largest leads and lags
capture drop event_time_bacon
gen event_time_bacon = birthyear - time_treated

tab event_time_bacon
sum event_time_bacon

local t_min = abs(r(min))
local t_max = abs(r(max))

cap drop F*event L*event

// dummy for the latest- or never-treated cohort
gen never_treated = missing(time_treated)

forvalues l = 0/`t_max' {
	gen L`l'event = event_time_bacon ==`l'
}
forvalues l = 1/`t_min' {
	gen F`l'event = event_time_bacon ==-`l'
}
drop F1event // normalize K = -1 to zero

// Run eventstudyinteract of Sun and Abraham (2021) with controls
di "`controls'"


***** Column 1: Main estimates from Table D1 column 1 *****

// Choose y variable 
local bounding_depvar 	"y1_deaths"
local bounding_weight	"[aw = alive_jan01]"

eststo p1_c1: eventstudyinteract `bounding_depvar' L*event F*event `bounding_weight', cohort(time_treated) control_cohort(never_treated) absorb(`absvar') vce(cluster `clustervar') covariates(`controls')

matrix b = e(b_iw)
matrix V = e(V_iw)
ereturn post b V

// Extract mean of Y among not yet treated observations (alternative: pre repeal)
sum `bounding_depvar' if `ybar_sample'	
local ybar = r(mean)

lincomestadd2 `scaled_coef', comtype(`comtype') statname("pct_efct_") omitstars column(1)
local treated =  r(estimate)
estaddstat pcteffect, using(`treated') y(`ybar') comtype(`comtype') column(1)


***** Column 2: Drop South Dakota and Texas because we don't observe infant mortality throughout our sample *****

* Drop Texas and South Dakota 
drop if state == 46 | state == 48

eststo p1_c2: eventstudyinteract `bounding_depvar' L*event F*event `bounding_weight', cohort(time_treated) control_cohort(never_treated) absorb(`absvar') vce(cluster `clustervar') covariates(`controls')

matrix b = e(b_iw)
matrix V = e(V_iw)
ereturn post b V

// Extract mean of Y among not yet treated observations (alternative: pre repeal)
sum `bounding_depvar' if `ybar_sample'	
local ybar = r(mean)

lincomestadd2 `scaled_coef', comtype(`comtype') statname("pct_efct_") omitstars column(2)
local treated =  r(estimate)
estaddstat pcteffect, using(`treated') y(`ybar') comtype(`comtype') column(2)


***** Column 3: Use 1990 population + treated infant deaths as weights *****

local bounding_weight	"[aw = alive_jan01_plusinf]"

eststo p1_c3: eventstudyinteract `bounding_depvar' L*event F*event `bounding_weight', cohort(time_treated) control_cohort(never_treated) absorb(`absvar') vce(cluster `clustervar') covariates(`controls')

matrix b = e(b_iw)
matrix V = e(V_iw)
ereturn post b V

// Extract mean of Y among not yet treated observations (alternative: pre repeal)
sum `bounding_depvar' if `ybar_sample'	
local ybar = r(mean)

lincomestadd2 `scaled_coef', comtype(`comtype') statname("pct_efct_") omitstars column(3)
local treated =  r(estimate)
estaddstat pcteffect, using(`treated') y(`ybar') comtype(`comtype') column(3)


***** Column 4: Use 1990 population + treated infant deaths as weights and in denominator *****

local bounding_depvar 	"y1_deaths_adjust_denom"

eststo p1_c4: eventstudyinteract `bounding_depvar' L*event F*event `bounding_weight', cohort(time_treated) control_cohort(never_treated) absorb(`absvar') vce(cluster `clustervar') covariates(`controls')

matrix b = e(b_iw)
matrix V = e(V_iw)
ereturn post b V

// Extract mean of Y among not yet treated observations (alternative: pre repeal)
sum `bounding_depvar' if `ybar_sample'	
local ybar = r(mean)

lincomestadd2 `scaled_coef', comtype(`comtype') statname("pct_efct_") omitstars column(4)
local treated =  r(estimate)
estaddstat pcteffect, using(`treated') y(`ybar') comtype(`comtype') column(4)

***** Column 5: Use 1990 population + treated infant deaths as weights and in numerator/denominator *****

local bounding_depvar 	"y1_deaths_plusinf"

eststo p1_c5: eventstudyinteract `bounding_depvar' L*event F*event `bounding_weight', cohort(time_treated) control_cohort(never_treated) absorb(`absvar') vce(cluster `clustervar') covariates(`controls')

matrix b = e(b_iw)
matrix V = e(V_iw)
ereturn post b V

// Extract mean of Y among not yet treated observations (alternative: pre repeal)
sum `bounding_depvar' if `ybar_sample'	
local ybar = r(mean)

lincomestadd2 `scaled_coef', comtype(`comtype') statname("pct_efct_") omitstars column(5)
local treated =  r(estimate)
estaddstat pcteffect, using(`treated') y(`ybar') comtype(`comtype') column(5)



// Prepare table

* Set number of columns
local ncols 5

// Set group header 
local group_header "&&&\multicolumn{3}{c}{Add Repeal-induced infant deaths to:} \\ \cmidrule(lr){4-6}"

// Set column headers
local colhead_1 "Baseline with \\ controls from \\ Table~\ref{tab:es-main-specs} Col. (2)"
local colhead_2 "Cols. (2) to (5) \\ drop states: \\ SD + TX"
local colhead_3 "Regression \\ weights"
local colhead_4 "Weights + \\ cohort size in \\ denominator of Y"
local colhead_5 "Weights + \\ cohort size + \\ later-life deaths"

local numbers_main ""
local estimators ""
local yob_dob_fe "Year of birth by death year FEs"
local sob_dob_fe "State of birth by death year FEs"
local sob_yob_controls "State by year of birth controls"

forvalues n = 1(1)`ncols' {
	local numbers_main "`numbers_main' &\multicolumn{1}{c}{(`n')}"
	local estimators "`estimators' &\multicolumn{1}{c}{\shortstack{`colhead_`n''}}"
	local yob_dob_fe "`yob_dob_fe' &\multicolumn{1}{c}{$\checkmark$}"
	local sob_dob_fe "`sob_dob_fe' &\multicolumn{1}{c}{$\checkmark$}"
	local sob_yob_controls "`sob_yob_controls' &\multicolumn{1}{c}{$\checkmark$}"	
}
local numbers_main "`numbers_main' \\"
local estimators "`estimators' \\"
local yob_dob_fe "`yob_dob_fe' \\"
local sob_dob_fe "`sob_dob_fe' \\"
local sob_yob_controls "`sob_yob_controls' \\"
local colsep = `ncols' + 1

// Make table 
#delimit ;
esttab p1_c* // 
 using "$PROJ_PATH/analysis/output/appendix/table_a2_bounding_infant_deaths_by_year_1990_start.tex", `booktabs_default_options' replace
posthead("`numbers_main' `estimators'")
stats(pct_efct_b pct_efct_se pct_efct_t ymean pct_effect N, fmt(0 0 0 %9.2f %9.1f %9.0fc) labels("\midrule\addlinespace\hspace{.5cm} Wet status (=1)" "~" "~" "\addlinespace\hspace{.5cm} Mean of Y" "\hspace{.5cm} Percent effect relative to mean" "\hspace{.5cm} Observations") layout(@ @ @ @ @ "\multicolumn{1}{c}{@}"))
postfoot("\midrule `yob_dob_fe' `sob_dob_fe' `sob_yob_controls'");
#delimit cr

eststo drop *



// --------------------- Table A3: Life-cycle mortality A_bst 1940-1990 --------------------------------------------

// Load cumulative mortality data for 1990 to 2004 from NCHS 
use "$PROJ_PATH/analysis/processed/data/data_for_cumulative_analysis_nchs.dta" if year >= `start_year_deaths_nchs' & year <= `end_year_deaths_nchs', clear

// Generate DiD treatment variable
estreat, treatvar(wet) time(birthyear) location(state) cutoff(0)

// store largest leads and lags
capture drop event_time_bacon
gen event_time_bacon = birthyear - time_treated

tab event_time_bacon
sum event_time_bacon

local t_min = abs(r(min))
local t_max = abs(r(max))

cap drop F*event L*event

// dummy for the latest- or never-treated cohort
gen never_treated = missing(time_treated)

forvalues l = 0/`t_max' {
	gen L`l'event = event_time_bacon ==`l'
}
forvalues l = 1/`t_min' {
	gen F`l'event = event_time_bacon ==-`l'
}
drop F1event // normalize K = -1 to zero

// Run eventstudyinteract of Sun and Abraham (2021) with controls
di "`controls'"


***** Column 1: Main estimates from Table D1 column 1 *****

// Choose y variable 
local bounding_depvar 	"y1_deaths"
local bounding_weight	"[aw = alive_jan01]"

eststo p1_c1: eventstudyinteract `bounding_depvar' L*event F*event `bounding_weight', cohort(time_treated) control_cohort(never_treated) absorb(`unit_id' `time_id') vce(cluster `unit_id') covariates(`controls')

matrix b = e(b_iw)
matrix V = e(V_iw)
ereturn post b V

// Extract mean of Y among not yet treated observations (alternative: pre repeal)
sum `bounding_depvar' if `ybar_sample'	
local ybar = r(mean)

lincomestadd2 `scaled_coef', comtype(`comtype') statname("pct_efct_") omitstars column(1)
local treated =  r(estimate)
estaddstat pcteffect, using(`treated') y(`ybar') comtype(`comtype') column(1)


***** Column 2: Drop Washington state because not in 1950 census *****

// Drop Washington State 
eststo p1_c2: eventstudyinteract `bounding_depvar' L*event F*event `bounding_weight' if state != 53, cohort(time_treated) control_cohort(never_treated) absorb(`unit_id' `time_id') vce(cluster `unit_id') covariates(`controls')

matrix b = e(b_iw)
matrix V = e(V_iw)
ereturn post b V

// Extract mean of Y among not yet treated observations (alternative: pre repeal)
sum `bounding_depvar' if `ybar_sample' & state != 53
local ybar = r(mean)

lincomestadd2 `scaled_coef', comtype(`comtype') statname("pct_efct_") omitstars column(2)
local treated =  r(estimate)
estaddstat pcteffect, using(`treated') y(`ybar') comtype(`comtype') column(2)


***** Column 3: Drop 1940-41 birth cohorts because not in 1940 census *****

// Drop 1940 and 1941 cohorts 
drop if birthyear == 1940 | birthyear == 1941

eststo p1_c3: eventstudyinteract `bounding_depvar' L*event F*event `bounding_weight', cohort(time_treated) control_cohort(never_treated) absorb(`unit_id' `time_id') vce(cluster `unit_id') covariates(`controls')

matrix b = e(b_iw)
matrix V = e(V_iw)
ereturn post b V

// Extract mean of Y among not yet treated observations (alternative: pre repeal)
sum `bounding_depvar' if `ybar_sample'	
local ybar = r(mean)

lincomestadd2 `scaled_coef', comtype(`comtype') statname("pct_efct_") omitstars column(3)
local treated =  r(estimate)
estaddstat pcteffect, using(`treated') y(`ybar') comtype(`comtype') column(3)



********************************************************************
// Column 4: Run A_bst analysis - 1950 to 1990
********************************************************************

use "$PROJ_PATH/analysis/processed/data/data_for_cumulative_analysis_nchs.dta", clear
fmerge 1:1 state birthyear using "$PROJ_PATH/analysis/processed/intermediate/ipums/usa_00089_extract_1950_100_pct_collapsed.dta", keepusing(population) assert(3) nogen

// Drop Washington State 
drop if state == 53

// Surviving population from 1941 birth cohort for Oregon suspiciously low 
	* Most implausible cases of cohort sizes from 1950 census are for 1931, 1940, and 1941 birth cohorts
	* Likely age-heaping issue
	* Just ignore population for these cohorts and interpolate 
	
gsort state birthyear 
replace population = . if population - alive_jan01 < 0 
by state: ipolate population birthyear, gen(temp_pop) epolate 
replace population = temp_pop if population == . 
drop temp_pop 

// If population in 1950 is much smaller than surviving cohort size in 1990, assume surviving cohort size is overstated and replace with 1950 population 
replace alive_jan01 = population if population - alive_jan01 < 0

// Generate deaths between 1950 and 1990
gen deaths_50to90 = population - alive_jan01
sum deaths_50to90, d

gen y1_deaths_50to90 = min(1000,1000*deaths_50to90/population)
sum y1_deaths_50to90, d


// Choose y variable 
local bounding_depvar 	"y1_deaths_50to90"
local bounding_weight	"[aw = population]" 

// Generate DiD treatment variable
estreat, treatvar(wet) time(birthyear) location(state) cutoff(0)

// store largest leads and lags
capture drop event_time_bacon
gen event_time_bacon = birthyear - time_treated

tab event_time_bacon
sum event_time_bacon

local t_min = abs(r(min))
local t_max = abs(r(max))

cap drop F*event L*event

// dummy for the latest- or never-treated cohort
gen never_treated = missing(time_treated)

forvalues l = 0/`t_max' {
	gen L`l'event = event_time_bacon ==`l'
}
forvalues l = 1/`t_min' {
	gen F`l'event = event_time_bacon ==-`l'
}
drop F1event // normalize K = -1 to zero

di "`controls'"

// eventstudyinteract of Sun and Abraham (2021) with controls
eststo p1_c4: eventstudyinteract `bounding_depvar' L*event F*event `bounding_weight', cohort(time_treated) control_cohort(never_treated) absorb(`unit_id' `time_id') vce(cluster `unit_id') covariates(`controls')

matrix b = e(b_iw)
matrix V = e(V_iw)
ereturn post b V

// Extract mean of Y among not yet treated observations (alternative: pre repeal)
sum `bounding_depvar' if `ybar_sample'	
local ybar = r(mean)

lincomestadd2 `scaled_coef', comtype(`comtype') statname("pct_efct_") omitstars column(4)
local treated =  r(estimate)
estaddstat pcteffect, using(`treated') y(`ybar') comtype(`comtype') column(4)

********************************************************************
// Column 5: Run A_bst analysis - 1940 to 1990
********************************************************************

use "$PROJ_PATH/analysis/processed/data/data_for_cumulative_analysis_nchs.dta", clear

// Drop 1940 and 1941 cohorts 
drop if birthyear == 1940 | birthyear == 1941

fmerge 1:1 state birthyear using "$PROJ_PATH/analysis/processed/intermediate/ipums/usa_00090_extract_1940_100_pct_collapsed.dta", keepusing(population) assert(2 3) keep(3) nogen

// If surviving population low, just ignore population for these cohorts and interpolate 
gsort state birthyear 
replace population = . if population - alive_jan01 < 0 
by state: ipolate population birthyear, gen(temp_pop) epolate 
replace population = temp_pop if population == . 
drop temp_pop 

// If population in 1950 is much smaller than surviving cohort size in 1990, assume surviving cohort size is overstated and replace with 1950 population 
replace alive_jan01 = population if population - alive_jan01 < 0

// Generate deaths between 1940 and 1990
gen deaths_40to90 = population - alive_jan01
sum deaths_40to90, d

gen y1_deaths_40to90 = min(1000,1000*deaths_40to90/population)
sum y1_deaths_40to90, d


// Choose y variable 
local bounding_depvar 	"y1_deaths_40to90"
local bounding_weight	"[aw = population]" 

// Generate DiD treatment variable
estreat, treatvar(wet) time(birthyear) location(state) cutoff(0)

// store largest leads and lags
capture drop event_time_bacon
gen event_time_bacon = birthyear - time_treated

tab event_time_bacon
sum event_time_bacon

local t_min = abs(r(min))
local t_max = abs(r(max))

cap drop F*event L*event

// dummy for the latest- or never-treated cohort
gen never_treated = missing(time_treated)

forvalues l = 0/`t_max' {
	gen L`l'event = event_time_bacon ==`l'
}
forvalues l = 1/`t_min' {
	gen F`l'event = event_time_bacon ==-`l'
}
drop F1event // normalize K = -1 to zero

di "`controls'"

// eventstudyinteract of Sun and Abraham (2021) with controls
eststo p1_c5: eventstudyinteract `bounding_depvar' L*event F*event `bounding_weight', cohort(time_treated) control_cohort(never_treated) absorb(`unit_id' `time_id') vce(cluster `unit_id') covariates(`controls')

matrix b = e(b_iw)
matrix V = e(V_iw)
ereturn post b V

// Extract mean of Y among not yet treated observations (alternative: pre repeal)
sum `bounding_depvar' if `ybar_sample'	
local ybar = r(mean)

lincomestadd2 `scaled_coef', comtype(`comtype') statname("pct_efct_") omitstars column(5)
local treated =  r(estimate)
estaddstat pcteffect, using(`treated') y(`ybar') comtype(`comtype') column(5)

********************************************************************
// Column 6: Run A_bst analysis - 1950 to 1979
********************************************************************

// Load mortality data for 1979 to 2004 from NCHS 
use "$PROJ_PATH/analysis/processed/intermediate/nchs/state_level_deaths_by_age_from_nchs.dta" if year >= `extended_start_year', clear

ds year state birthyear age, not 
local cod_varlist "`r(varlist)'"

collapse (sum) `cod_varlist', by(state birthyear)

gen year = `extended_start_year'
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

tempfile cumulative_1979
save `cumulative_1979', replace 



// Get population at baseline from year-by-year analysis data 
use "$PROJ_PATH/analysis/processed/data/data_for_analysis_nchs.dta", clear
keep state birthyear year alive_jan01
rename alive_jan01 population 

// Restrict birth years 
keep if birthyear >= `start_year_births' & birthyear <= `end_year_births'

// Restrict death years 
keep if year == `extended_start_year'

// Merge in state birthyear deaths by year for sample period
merge 1:1 state birthyear year using `cumulative_1979', assert(2 3) nogen 

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

// Assume population is as of 01 Jan 1979;  assume deaths occur during the calendar year
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

order state birthyear state_birthyear year alive_jan01 `cod_varlist' y1_*
desc, f
compress


fmerge 1:1 state birthyear using "$PROJ_PATH/analysis/processed/intermediate/ipums/usa_00089_extract_1950_100_pct_collapsed.dta", keepusing(population) assert(3) nogen

// Drop Washington State 
drop if state == 53

// Surviving population from 1941 birth cohort for Oregon suspiciously low 
	* Most implausible cases of cohort sizes from 1950 census are for 1931, 1940, and 1941 birth cohorts
	* Likely age-heaping issue
	* Just ignore population for these cohorts and interpolate 
	
gsort state birthyear 
replace population = . if population - alive_jan01 < 0 
by state: ipolate population birthyear, gen(temp_pop) epolate 
replace population = temp_pop if population == . 
drop temp_pop 

// If population in 1950 is much smaller than surviving cohort size in 1979, assume surviving cohort size is overstated and replace with 1950 population 
replace alive_jan01 = population if population - alive_jan01 < 0

// Generate deaths between 1950 and 1979
gen deaths_50to79 = population - alive_jan01
sum deaths_50to79, d

gen y1_deaths_50to79 = min(1000,1000*deaths_50to79/population)
sum y1_deaths_50to79, d


// Choose y variable 
local bounding_depvar 	"y1_deaths_50to79"
local bounding_weight	"[aw = population]" 

// Generate DiD treatment variable
estreat, treatvar(wet) time(birthyear) location(state) cutoff(0)

// store largest leads and lags
capture drop event_time_bacon
gen event_time_bacon = birthyear - time_treated

tab event_time_bacon
sum event_time_bacon

local t_min = abs(r(min))
local t_max = abs(r(max))

cap drop F*event L*event

// dummy for the latest- or never-treated cohort
gen never_treated = missing(time_treated)

forvalues l = 0/`t_max' {
	gen L`l'event = event_time_bacon ==`l'
}
forvalues l = 1/`t_min' {
	gen F`l'event = event_time_bacon ==-`l'
}
drop F1event // normalize K = -1 to zero

di "`controls'"

// eventstudyinteract of Sun and Abraham (2021) with controls
eststo p1_c6: eventstudyinteract `bounding_depvar' L*event F*event `bounding_weight', cohort(time_treated) control_cohort(never_treated) absorb(`unit_id' `time_id') vce(cluster `unit_id') covariates(`controls')

matrix b = e(b_iw)
matrix V = e(V_iw)
ereturn post b V

// Extract mean of Y among not yet treated observations (alternative: pre repeal)
sum `bounding_depvar' if `ybar_sample'	
local ybar = r(mean)

lincomestadd2 `scaled_coef', comtype(`comtype') statname("pct_efct_") omitstars column(6)
local treated =  r(estimate)
estaddstat pcteffect, using(`treated') y(`ybar') comtype(`comtype') column(6)


********************************************************************
// Column 7: Run A_bst analysis - 1940 to 1979
********************************************************************

// Load mortality data for 1979 to 2004 from NCHS 
use "$PROJ_PATH/analysis/processed/intermediate/nchs/state_level_deaths_by_age_from_nchs.dta" if year >= `extended_start_year', clear

ds year state birthyear age, not 
local cod_varlist "`r(varlist)'"

collapse (sum) `cod_varlist', by(state birthyear)

gen year = `extended_start_year'
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

tempfile cumulative_1979
save `cumulative_1979', replace 



// Get population at baseline from year-by-year analysis data 
use "$PROJ_PATH/analysis/processed/data/data_for_analysis_nchs.dta", clear
keep state birthyear year alive_jan01
rename alive_jan01 population 

// Restrict birth years 
keep if birthyear >= `start_year_births' & birthyear <= `end_year_births'

// Restrict death years 
keep if year == `extended_start_year'

// Merge in state birthyear deaths by year for sample period
merge 1:1 state birthyear year using `cumulative_1979', assert(2 3) nogen 

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

// Assume population is as of 01 Jan 1979;  assume deaths occur during the calendar year
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

order state birthyear state_birthyear year alive_jan01 `cod_varlist' y1_*
desc, f
compress

// Drop 1940 and 1941 cohorts 
drop if birthyear == 1940 | birthyear == 1941

fmerge 1:1 state birthyear using "$PROJ_PATH/analysis/processed/intermediate/ipums/usa_00090_extract_1940_100_pct_collapsed.dta", keepusing(population) assert(2 3) keep(3) nogen

// If surviving population low, just ignore population for these cohorts and interpolate 
gsort state birthyear 
replace population = . if population - alive_jan01 < 0 
by state: ipolate population birthyear, gen(temp_pop) epolate 
replace population = temp_pop if population == . 
drop temp_pop 

// If population in 1950 is much smaller than surviving cohort size in 1979, assume surviving cohort size is overstated and replace with 1950 population 
replace alive_jan01 = population if population - alive_jan01 < 0

// Generate deaths between 1940 and 1979
gen deaths_40to79 = population - alive_jan01
sum deaths_40to79, d

gen y1_deaths_40to79 = min(1000,1000*deaths_40to79/population)
sum y1_deaths_40to79, d


// Choose y variable 
local bounding_depvar 	"y1_deaths_40to79"
local bounding_weight	"[aw = population]" 

// Generate DiD treatment variable
estreat, treatvar(wet) time(birthyear) location(state) cutoff(0)

// store largest leads and lags
capture drop event_time_bacon
gen event_time_bacon = birthyear - time_treated

tab event_time_bacon
sum event_time_bacon

local t_min = abs(r(min))
local t_max = abs(r(max))

cap drop F*event L*event

// dummy for the latest- or never-treated cohort
gen never_treated = missing(time_treated)

forvalues l = 0/`t_max' {
	gen L`l'event = event_time_bacon ==`l'
}
forvalues l = 1/`t_min' {
	gen F`l'event = event_time_bacon ==-`l'
}
drop F1event // normalize K = -1 to zero

di "`controls'"

// eventstudyinteract of Sun and Abraham (2021) with controls
eststo p1_c7: eventstudyinteract `bounding_depvar' L*event F*event `bounding_weight', cohort(time_treated) control_cohort(never_treated) absorb(`unit_id' `time_id') vce(cluster `unit_id') covariates(`controls')

matrix b = e(b_iw)
matrix V = e(V_iw)
ereturn post b V

// Extract mean of Y among not yet treated observations (alternative: pre repeal)
sum `bounding_depvar' if `ybar_sample'	
local ybar = r(mean)

lincomestadd2 `scaled_coef', comtype(`comtype') statname("pct_efct_") omitstars column(7)
local treated =  r(estimate)
estaddstat pcteffect, using(`treated') y(`ybar') comtype(`comtype') column(7)

// Prepare table

* Set number of columns
local ncols 7

// Set group header 
local group_header "&\multicolumn{3}{c}{Robustness to sample restrictions} &\multicolumn{4}{c}{Y: Mortality rate between years s and t per population in year s} \\ \cmidrule(lr){2-4}\cmidrule(lr){5-8}"

// Set column headers
local colhead_1 "Baseline with \\ controls from \\ Table~\ref{tab:did-cumulative-mortality} Col. (2)"
local colhead_2 "Cols (2), \\ (4), (6) \\ Drop WA"
local colhead_3 "Cols. (3), (5), (7) \\ Drop 1940-41 \\ birth cohorts"
local colhead_4 "1950-- \\ 1990"
local colhead_5 "1940-- \\ 1990"
local colhead_6 "1950-- \\ 1979"
local colhead_7 "1940-- \\ 1979"

local numbers_main ""
local estimators ""
local yob_dob_fe "Year of birth by death year FEs"
local sob_dob_fe "State of birth by death year FEs"
local sob_yob_controls "State by year of birth controls"

forvalues n = 1(1)`ncols' {
	local numbers_main "`numbers_main' &\multicolumn{1}{c}{(`n')}"
	local estimators "`estimators' &\multicolumn{1}{c}{\shortstack{`colhead_`n''}}"
	local yob_dob_fe "`yob_dob_fe' &\multicolumn{1}{c}{$\checkmark$}"
	local sob_dob_fe "`sob_dob_fe' &\multicolumn{1}{c}{$\checkmark$}"
	local sob_yob_controls "`sob_yob_controls' &\multicolumn{1}{c}{$\checkmark$}"
}
local numbers_main "`numbers_main' \\"
local estimators "`estimators' \\"
local yob_dob_fe "`yob_dob_fe' \\"
local sob_dob_fe "`sob_dob_fe' \\"
local sob_yob_controls "`sob_yob_controls' \\"
local colsep = `ncols' + 1


// Make table 
#delimit ;
esttab p1_c* // 
 using "$PROJ_PATH/analysis/output/appendix/table_a3_life_cycle_mortality.tex", `booktabs_default_options' replace
posthead("`numbers_main' `group_header' `estimators'")
stats(pct_efct_b pct_efct_se pct_efct_t ymean pct_effect N, fmt(0 0 0 %9.2f %9.1f %9.0fc) labels("\midrule\addlinespace\hspace{.5cm} Wet status (=1)" "~" "~" "\addlinespace\hspace{.5cm} Mean of Y" "\hspace{.5cm} Percent effect relative to mean" "\hspace{.5cm} Observations") layout(@ @ @ @ @ "\multicolumn{1}{c}{@}"))
postfoot("\midrule `yob_dob_fe' `sob_dob_fe' `sob_yob_controls'");
#delimit cr

eststo drop *



// --------------------- Figure B1: Plot heterogeneity event study estimates in extended panel ---------------------

local weight "alive_jan01"

// Loop through depvars 
	* Panel A: All-cause mortality
	* Panel B: Heart disease
	* Panel C: Stroke
	* Panel D: Cancer
	
local cod_depvar_list "deaths heart stroke cancer" 
tokenize `cod_depvar_list'
local max_val: word count `cod_depvar_list'
	
eststo drop *
forvalues n = 1(1)`max_val' { 
	
	use "$PROJ_PATH/analysis/processed/data/data_for_analysis_nchs.dta" if year >= `extended_start_year' & year <= `end_year_deaths_nchs', clear
	
	// Dependent variable
	local depvar "y1_``n''"
	la var `depvar' "`: var label ``n''' Mortality per 1,000 Population"

	// Generate DiD treatment variable
	estreat, treatvar(wet) time(birthyear) location(state) cutoff(0)

	// time_treated is a variable for unit-specific treatment years (never-treated: time_treated == missing)
	tab time_treated, m

	// store largest leads and lags
	capture drop event_time_bacon
	gen event_time_bacon = birthyear - time_treated

	tab event_time_bacon
	sum event_time_bacon

	local t_min = abs(r(min))
	local t_max = abs(r(max))
	
	// TWFE OLS estimation

	// Create never treated indicator that equals one if a unit never received treatment and zero if it did.
	gen no_treat = missing(time_treated)

	// Preparation
	sum time_treated
	forvalues l = 0/`t_max' {
		gen L`l'event = event_time_bacon ==`l'
		replace L`l'event = 0 if no_treat == 1
	}
	forvalues l = 1/`t_min' {
		gen F`l'event = event_time_bacon == -`l'
		replace F`l'event = 0 if no_treat == 1
	}
	drop F1event // normalize K = -1 to zero

	// Estimation
	reghdfe `depvar' F*event L*event [aw = `weight'], absorb(`absvar') vce(cluster `clustervar')

	// Saving estimates for later
	estimates store ols


	// eventstudyinteract of Sun and Abraham (2021)

	// Preparation
	cap drop F*event L*event

	// dummy for the latest- or never-treated cohort
	gen never_treated = missing(time_treated)

	forvalues l = 0/`t_max' {
		gen L`l'event = event_time_bacon ==`l'
	}
	forvalues l = 1/`t_min' {
		gen F`l'event = event_time_bacon ==-`l'
	}
	drop F1event // normalize K = -1 to zero

	// Estimation
	eventstudyinteract `depvar' L*event F*event [aw = `weight'], cohort(time_treated) control_cohort(never_treated) absorb(`absvar') vce(cluster `clustervar')

	// Extract mean of Y among not yet treated observations
	sum `depvar' if `ybar_sample'
	local ybar = round(r(mean),0.01)
	
	if "`depvar'" == "y1_stroke" {
		local ybar = "0" + "`ybar'" 
	}
	
	// Storing estimates for later
	matrix sa_b = e(b_iw)
	matrix sa_v = e(V_iw)
	
	// Add zero
	local colnames : colnames sa_b 
	matrix sa_b = (0,sa_b)
	matrix colnames sa_b = F1event `colnames'	

	// Position of sample mean text 
	    
	if "`depvar'" == "y1_deaths" {
		local height 1.5
		local figpan "a"
	}
	else if "`depvar'" == "y1_heart" {
		local height 0.6
		local figpan "b"
	}
	else if "`depvar'" == "y1_stroke" {
		local height 0.1
		local figpan "c"
	}
	else if "`depvar'" == "y1_cancer" {
		local height 0.4
		local figpan "d"
	}

	event_plot sa_b#sa_v ols, ///
		stub_lag(L#event L#event) stub_lead(F#event F#event) ///
		plottype(scatter) ciplottype(rcap) ///
		together trimlead(4) trimlag(4) noautolegend ///
		graph_opt( ///
			subtitle("`: var label `depvar''", size(6) pos(11)) ///
			xtitle("Years since state becomes wet", size(6) height(7)) ///
			ytitle("Average causal effect", size(6)) ///
			xlabel(-4(1)4, nogrid notick  labsize(6)) ///
			ylab(`y_range', labsize(6) angle(0) format(%03.2f) nogrid notick) ///
			xscale(extend) yscale(extend) ///
			xsize(8) ///
			legend(order(1 "Sun and Abraham (2021)" 3 "TWFE OLS") rows(1) position(6) size(6) region(style(none))) ///
			xline(-0.5, lcolor(gs8) lpattern(dash)) yline(0, lcolor(gs8)) graphregion(color(white)) bgcolor(white)  ///
			text(`height' -4 "Mean of Y: `ybar'", size(large) placement(right)) ///
		) ///
		lag_opt1(msymbol(O) color(cranberry)) lag_ci_opt1(color(cranberry)) ///
		lag_opt2(msymbol(D) color(navy)) lag_ci_opt2(color(navy))

	graph export "$PROJ_PATH/analysis/output/appendix/figure_b1`figpan'_es_extended_panel_``n''.png", as(png) height(2400) replace
	
}

// --------------------- Table B1: DiD specification with All-Cause and Cause-Specific Mortality in Extended Panel ---------------------

local cod_depvar_list "deaths heart stroke cancer" 
tokenize `cod_depvar_list'
local max_val: word count `cod_depvar_list'

eststo drop *
forvalues n = 1/`max_val' {
	
	local depvar "y1_``n''"
	
	// Main sample specifications 
	use "$PROJ_PATH/analysis/processed/data/data_for_analysis_nchs.dta" if year >= `extended_start_year' & year <= `end_year_deaths_nchs', clear

	// Generate DiD treatment variable
	estreat, treatvar(wet) time(birthyear) location(state) cutoff(0)

	// store largest leads and lags
	capture drop event_time_bacon
	gen event_time_bacon = birthyear - time_treated

	tab event_time_bacon
	sum event_time_bacon

	local t_min = abs(r(min))
	local t_max = abs(r(max))

	cap drop F*event L*event

	// dummy for the latest- or never-treated cohort
	gen never_treated = missing(time_treated)

	forvalues l = 0/`t_max' {
		gen L`l'event = event_time_bacon ==`l'
	}
	forvalues l = 1/`t_min' {
		gen F`l'event = event_time_bacon ==-`l'
	}
	drop F1event // normalize K = -1 to zero

	// eventstudyinteract of Sun and Abraham (2021) with controls
	eststo p1_c`n': eventstudyinteract `depvar' L*event F*event [aw = `weight'], cohort(time_treated) control_cohort(never_treated) absorb(`absvar') vce(cluster `clustervar') covariates(`controls')

	matrix b = e(b_iw)
	matrix V = e(V_iw)
	ereturn post b V

	// Extract mean of Y among not yet treated observations (alternative: pre repeal)
	sum `depvar' if `ybar_sample'	
	local ybar = r(mean)
	
	lincomestadd2 `scaled_coef', comtype(`comtype') statname("pct_efct_") omitstars column(`n')
	local treated =  r(estimate)
	estaddstat pcteffect, using(`treated') y(`ybar') comtype(`comtype') column(`n')

}

// Prepare table
local numbers_main ""
local estimators ""
local yob_dob_fe "Year of birth by death year FEs"
local sob_dob_fe "State of birth by death year FEs"
local sob_yob_controls "State by year of birth controls"

forvalues n = 1(1)`max_val' {
	local numbers_main "`numbers_main' &\multicolumn{1}{c}{(`n')}"
	local estimators "`estimators' &\multicolumn{1}{c}{\shortstack{`: var label ``n'''}}"
	local yob_dob_fe "`yob_dob_fe' &\multicolumn{1}{c}{$\checkmark$}"
	local sob_dob_fe "`sob_dob_fe' &\multicolumn{1}{c}{$\checkmark$}"
	local sob_yob_controls "`sob_yob_controls' &\multicolumn{1}{c}{$\checkmark$}"	
}
local numbers_main "`numbers_main' \\"
local estimators "`estimators' \\"
local yob_dob_fe "`yob_dob_fe' \\"
local sob_dob_fe "`sob_dob_fe' \\"
local sob_yob_controls "`sob_yob_controls' \\"
local colsep = `max_val' + 1

// Make table 
#delimit ;
esttab p1_c* // 
 using "$PROJ_PATH/analysis/output/appendix/table_b1_extended_panel.tex", `booktabs_default_options' replace 
posthead("`numbers_main' `estimators'")
stats(pct_efct_b pct_efct_se pct_efct_t ymean pct_effect N, fmt(0 0 0 %9.2f %9.1f %9.0fc) labels("\midrule\addlinespace\hspace{.5cm} Wet status (=1)" "~" "~" "\addlinespace\hspace{.5cm} Mean of Y" "\hspace{.5cm} Percent effect relative to mean" "\hspace{.5cm} Observations") layout(@ @ @ @ @ "\multicolumn{1}{c}{@}"))
postfoot("\midrule `yob_dob_fe' `sob_dob_fe' `sob_yob_controls'");
#delimit cr


// --------------------- Figure C1: Map of county level treatment ---------------------

// Run code to create county map in R 
rscript using "$PROJ_PATH/analysis/scripts/programs/create_county_map.R", rpath($RSCRIPT_PATH) 

	
// --------------------- Table C1: DiD specification with Cause-Specific Mortality for Continuous Treatment ---------------------

local cod_depvar_list "deaths heart stroke cancer" 
tokenize `cod_depvar_list'
local max_val: word count `cod_depvar_list'

eststo drop *
forvalues n = 1/`max_val' {
	
	local depvar "y1_``n''"

	use "$PROJ_PATH/analysis/processed/data/data_for_analysis_nchs.dta" if year >= `start_year_deaths_nchs' & year <= `end_year_deaths_nchs', clear

	// Generate DiD treatment variable
	estreat, treatvar(wet) time(birthyear) location(state) cutoff(0)

	// time_treated is a variable for unit-specific treatment years (never-treated: time_treated == missing)
	tab time_treated, m
	gen never_treated = missing(time_treated)

	// TWFE 
	eststo p1_c`n': reghdfe `depvar' wet `controls' [aw = `weight'], absorb(`absvar') vce(cluster `clustervar')
	
	matrix b = r(table)
	csdid_estadd wet, statname("pct_efct_") omitstars
	
	// Extract mean of Y among not yet treated observations (alternative: pre repeal)
	sum `depvar' if `ybar_sample'	
	local ybar = r(mean)	
	
	estaddstat pcteffect, using(wet) y(`ybar') coef("b") column(`n') 
		
}

// Prepare table
local numbers_main ""
local estimators ""
local yob_dob_fe "Year of birth by death year FEs"
local sob_dob_fe "State of birth by death year FEs"
local sob_yob_controls "State by year of birth controls"

forvalues n = 1(1)`max_val' {
	local numbers_main "`numbers_main' &\multicolumn{1}{c}{(`n')}"
	local estimators "`estimators' &\multicolumn{1}{c}{\shortstack{`: var label ``n'''}}"
	local yob_dob_fe "`yob_dob_fe' &\multicolumn{1}{c}{$\checkmark$}"
	local sob_dob_fe "`sob_dob_fe' &\multicolumn{1}{c}{$\checkmark$}"
	local sob_yob_controls "`sob_yob_controls' &\multicolumn{1}{c}{$\checkmark$}"		
}
local numbers_main "`numbers_main' \\"
local estimators "`estimators' \\"
local yob_dob_fe "`yob_dob_fe' \\"
local sob_dob_fe "`sob_dob_fe' \\"
local sob_yob_controls "`sob_yob_controls' \\"
local colsep = `max_val' + 1

// Make table 
#delimit ;
esttab p1_c* // 
 using "$PROJ_PATH/analysis/output/appendix/table_c1_continuous_treatment.tex", `booktabs_default_options' replace 
posthead("`numbers_main' `estimators'")
stats(pct_efct_b pct_efct_se pct_efct_t ymean pct_effect N, fmt(0 0 0 %9.2f %9.1f %9.0fc) labels("\midrule\addlinespace\hspace{.5cm} Fetal exposure to wet status (=1)" "~" "~" "\addlinespace\hspace{.5cm} Mean of Y" "\hspace{.5cm} Percent effect" "\hspace{.5cm} Observations") layout(@ @ @ @ @ "\multicolumn{1}{c}{@}"))
postfoot("\midrule `yob_dob_fe' `sob_dob_fe' `sob_yob_controls'");
#delimit cr

eststo drop *



// --------------------- Figure D1: Plot event study estimates with cumulative mortality by cause of death ---------------------

// Set seed for controlled randomness in did_multiplegt of de Chaisemartin and D'Haultfoeuille (2020)
set seed 12345

// Loop through depvars 
	* Panel A: All-cause mortality
	* Panel B: Heart disease
	* Panel C: Stroke
	* Panel D: Cancer
	
local cod_depvar_list "deaths heart stroke cancer" 
tokenize `cod_depvar_list'
local max_val: word count `cod_depvar_list'

eststo drop *
forvalues n = 1(1)`max_val' { 
	
	use "$PROJ_PATH/analysis/processed/data/data_for_cumulative_analysis_nchs.dta" if year >= `start_year_deaths_nchs' & year <= `end_year_deaths_nchs', clear
	
	// Dependent variable
	local depvar "y1_``n''"
	la var `depvar' "Cumulative `: var label ``n''' Mortality per 1,000 Population"

	// Generate DiD treatment variable
	estreat, treatvar(wet) time(birthyear) location(state) cutoff(0)

	// time_treated is a variable for unit-specific treatment years (never-treated: time_treated == missing)
	tab time_treated, m

	// store largest leads and lags
	capture drop event_time_bacon
	gen event_time_bacon = birthyear - time_treated

	tab event_time_bacon
	sum event_time_bacon

	local t_min = abs(r(min))
	local t_max = abs(r(max))
	
	// did_multiplegt of de Chaisemartin and D'Haultfoeuille (2020)
	did_multiplegt `depvar' `unit_id' `time_id' treated, robust_dynamic dynamic(`t_max') placebo(4) longdiff_placebo breps(100) cluster(`unit_id') `wgt'
	matrix dcdh_b = e(estimates)
	matrix dcdh_v = e(variances)

	// csdid of Callaway and Sant'Anna (2020) 
	gen gvar = cond(time_treated > 0 & !missing(time_treated), time_treated, 0) // group variable as required for the csdid command
	tab gvar, m
	csdid `depvar' `iw', ivar(`unit_id') time(`time_id') gvar(gvar) agg(event)
	matrix cs_b = e(b)
	matrix cs_v = e(V)
	
	// TWFE OLS estimation

	// Create never treated indicator that equals one if a unit never received treatment and zero if it did.
	gen no_treat = missing(time_treated)

	// Preparation
	sum time_treated
	forvalues l = 0/`t_max' {
		gen L`l'event = event_time_bacon == `l'
		replace L`l'event = 0 if no_treat == 1
	}
	forvalues l = 1/`t_min' {
		gen F`l'event = event_time_bacon == -`l'
		replace F`l'event = 0 if no_treat == 1
	}
	drop F1event // normalize K = -1 to zero

	// Estimation
	reghdfe `depvar' F*event L*event [aw = `weight'], absorb(`unit_id' `time_id') vce(cluster `unit_id')

	// Saving estimates for later
	estimates store ols

	// eventstudyinteract of Sun and Abraham (2020)

	// Preparation
	cap drop F*event L*event

	// dummy for the latest- or never-treated cohort
	gen never_treated = missing(time_treated)

	forvalues l = 0/`t_max' {
		gen L`l'event = event_time_bacon == `l'
	}
	forvalues l = 1/`t_min' {
		gen F`l'event = event_time_bacon == -`l'
	}
	drop F1event // normalize K = -1 to zero

	// Estimation
	eventstudyinteract `depvar' L*event F*event [aw = `weight'], vce(cluster `unit_id') absorb(`unit_id' `time_id') cohort(time_treated) control_cohort(never_treated)

	// Extract mean of Y among not yet treated observations (alternative: pre repeal)
	sum `depvar' if `ybar_sample'
	local ybar = round(r(mean),0.01)
	
	// Storing estimates for later
	matrix sa_b = e(b_iw)
	matrix sa_v = e(V_iw)

	// Add zero 
	local colnames : colnames sa_b 
	matrix sa_b = (0,sa_b)
	matrix colnames sa_b = F1event `colnames'

	
	// Position of sample mean text     
	if "`depvar'" == "y1_deaths" {
		local height 20
		local figpan "a"
	}
	else if "`depvar'" == "y1_heart" {
		local height 10
		local figpan "b"
	}
	else if "`depvar'" == "y1_stroke" {
		local height 3
		local figpan "c"
	}
	else if "`depvar'" == "y1_cancer" {
		local height 10
		local figpan "d"
	}
	
	event_plot sa_b#sa_v ols dcdh_b#dcdh_v cs_b#cs_v, ///
		stub_lag(L#event L#event Effect_# Tp#) stub_lead(F#event F#event Placebo_# Tm#) ///
		plottype(scatter) ciplottype(rcap) ///
		together perturb(-0.15(0.1)0.15) trimlead(4) trimlag(4) noautolegend ///
		graph_opt( ///
			subtitle("`: var label `depvar''", size(6) pos(11)) ///
			xtitle("Years since state becomes wet", size(6) height(7)) ///
			ytitle("Average causal effect", size(6)) ///
			xlabel(-4(1)4, nogrid notick labsize(6)) ///
			ylab(`y_range', labsize(6) angle(0) format(%3.0f) nogrid notick) ///
			xscale(extend) yscale(extend) ///
			xsize(8) ///
			legend(order(1 "Sun and Abraham (2021)" 3 "TWFE OLS" 5 "de Chaisemartin-D'Haultfoeuille (2020)" ///
				7 "Callaway and Sant'Anna (2021)") size(5) rows(2) position(6) region(style(none))) ///
			xline(-0.5, lcolor(gs8) lpattern(dash)) yline(0, lcolor(gs8)) graphregion(color(white)) bgcolor(white)  ///
			text(`height' -4 "Mean of Y: `ybar'", size(large) placement(right)) ///
		) ///
		lag_opt1(msymbol(O) color(cranberry)) lag_ci_opt1(color(cranberry)) ///
		lag_opt2(msymbol(D) color(navy)) lag_ci_opt2(color(navy)) ///
		lag_opt3(msymbol(T) color(forest_green)) lag_ci_opt3(color(forest_green)) ///
		lag_opt4(msymbol(S) color(dkorange)) lag_ci_opt4(color(dkorange))
		
	graph export "$PROJ_PATH/analysis/output/appendix/figure_d1`figpan'_es_cumulative_``n''.png", as(png) height(2400) replace
	
}



// --------------------- Table D1: Aggregate event study specification with cumulative all-cause and cause-specific mortality ---------------------

local cod_depvar_list "deaths heart stroke cancer" 
tokenize `cod_depvar_list'
local max_val: word count `cod_depvar_list'

eststo drop *
forvalues n = 1/`max_val' {
	
	local depvar "y1_``n''"
	
	// Main sample specifications 
	use "$PROJ_PATH/analysis/processed/data/data_for_cumulative_analysis_nchs.dta" if year >= `start_year_deaths_nchs' & year <= `end_year_deaths_nchs', clear

	// Generate DiD treatment variable
	estreat, treatvar(wet) time(birthyear) location(state) cutoff(0)

	// store largest leads and lags
	capture drop event_time_bacon
	gen event_time_bacon = birthyear - time_treated

	tab event_time_bacon
	sum event_time_bacon

	local t_min = abs(r(min))
	local t_max = abs(r(max))

	cap drop F*event L*event

	// dummy for the latest- or never-treated cohort
	gen never_treated = missing(time_treated)

	forvalues l = 0/`t_max' {
		gen L`l'event = event_time_bacon ==`l'
	}
	forvalues l = 1/`t_min' {
		gen F`l'event = event_time_bacon ==-`l'
	}
	drop F1event // normalize K = -1 to zero

	// eventstudyinteract of Sun and Abraham (2021) with controls
	eststo p1_c`n': eventstudyinteract `depvar' L*event F*event [aw = `weight'], cohort(time_treated) control_cohort(never_treated) absorb(`unit_id' `time_id') vce(cluster `unit_id') covariates(`controls')

	matrix b = e(b_iw)
	matrix V = e(V_iw)
	ereturn post b V

	// Extract mean of Y among not yet treated observations (alternative: pre repeal)
	sum `depvar' if `ybar_sample'	
	local ybar = r(mean)
	
	lincomestadd2 `scaled_coef', comtype(`comtype') statname("pct_efct_") omitstars column(`n')
	local treated =  r(estimate)
	estaddstat pcteffect, using(`treated') y(`ybar') comtype(`comtype') column(`n')
}

// Prepare table
local numbers_main ""
local estimators ""
local yob_fe "Year of birth FEs"
local sob_fe "State of birth FEs"
local sob_yob_controls "State by year of birth controls"

forvalues n = 1(1)`max_val' {
	local numbers_main "`numbers_main' &\multicolumn{1}{c}{(`n')}"
	local estimators "`estimators' &\multicolumn{1}{c}{\shortstack{`: var label ``n'''}}"
	local yob_fe "`yob_fe' &\multicolumn{1}{c}{$\checkmark$}"
	local sob_fe "`sob_fe' &\multicolumn{1}{c}{$\checkmark$}"
	local sob_yob_controls "`sob_yob_controls' &\multicolumn{1}{c}{$\checkmark$}"	
}
local numbers_main "`numbers_main' \\"
local estimators "`estimators' \\"
local yob_fe "`yob_fe' \\"
local sob_fe "`sob_fe' \\"
local sob_yob_controls "`sob_yob_controls' \\"
local colsep = `max_val' + 1

// Make table 
#delimit ;
esttab p1_c* // 
 using "$PROJ_PATH/analysis/output/appendix/table_d1_cumulative.tex", `booktabs_default_options' replace 
posthead("`numbers_main' `estimators'")
stats(pct_efct_b pct_efct_se pct_efct_t ymean pct_effect N, fmt(0 0 0 %9.2f %9.1f %9.0fc) labels("\midrule\addlinespace\hspace{.5cm} Wet status (=1)" "~" "~" "\addlinespace\hspace{.5cm} Mean of Y" "\hspace{.5cm} Percent effect relative to mean" "\hspace{.5cm} Observations") layout(@ @ @ @ @ "\multicolumn{1}{c}{@}"))
postfoot("\midrule `yob_fe' `sob_fe' `sob_yob_controls'");
#delimit cr

eststo drop *


// --------------------- Figure E1: Plot heterogeneity event study estimates ---------------------

// Loop through sub-groups
	* Panel A: Female
	* Panel B: Male
	* Panel C: Non-White
	* Panel D: White 
	
local suffix_1 "women_only"
local suffix_2 "men_only"
local suffix_3 "non_white_only"
local suffix_4 "white_only"

local subpop_1 "Female"
local subpop_2 "Male"
local subpop_3 "Non-White"
local subpop_4 "White"

forvalues n = 1(1)4 { 
	
	use "$PROJ_PATH/analysis/processed/data/data_for_analysis_nchs_`suffix_`n''.dta" if year >= `start_year_deaths_nchs' & year <= `end_year_deaths_nchs', clear
	
	// Dependent variable
	local depvar "y1_deaths"
	la var `depvar' "All-Cause Mortality per 1,000 `subpop_`n'' Population"

	// Generate DiD treatment variable
	estreat, treatvar(wet) time(birthyear) location(state) cutoff(0)

	// time_treated is a variable for unit-specific treatment years (never-treated: time_treated == missing)
	tab time_treated, m

	// store largest leads and lags
	capture drop event_time_bacon
	gen event_time_bacon = birthyear - time_treated

	tab event_time_bacon
	sum event_time_bacon

	local t_min = abs(r(min))
	local t_max = abs(r(max))
	
	// TWFE OLS estimation

	// Create never treated indicator that equals one if a unit never received treatment and zero if it did.
	gen no_treat = missing(time_treated)

	// Preparation
	sum time_treated
	forvalues l = 0/`t_max' {
		gen L`l'event = event_time_bacon ==`l'
		replace L`l'event = 0 if no_treat == 1
	}
	forvalues l = 1/`t_min' {
		gen F`l'event = event_time_bacon == -`l'
		replace F`l'event = 0 if no_treat == 1
	}
	drop F1event // normalize K=-1 to zero

	// Estimation
	reghdfe `depvar' F*event L*event [aw = `weight'], absorb(`absvar') vce(cluster `clustervar')

	// Saving estimates for later
	estimates store ols



	// eventstudyinteract of Sun and Abraham (2021)

	// Preparation
	cap drop F*event L*event

	// dummy for the latest- or never-treated cohort
	gen never_treated = missing(time_treated)

	forvalues l = 0/`t_max' {
		gen L`l'event = event_time_bacon ==`l'
	}
	forvalues l = 1/`t_min' {
		gen F`l'event = event_time_bacon ==-`l'
	}
	drop F1event // normalize K = -1 to zero

	// Estimation
	eventstudyinteract `depvar' L*event F*event [aw = `weight'], cohort(time_treated) control_cohort(never_treated) absorb(`absvar') vce(cluster `clustervar')

	// Extract mean of Y among not yet treated observations (alternative: pre repeal)
	sum `depvar' if `ybar_sample'
	local ybar = round(r(mean),0.01)
	
	// Storing estimates for later
	matrix sa_b = e(b_iw)
	matrix sa_v = e(V_iw)
	
	// Add zero
	local colnames : colnames sa_b 
	matrix sa_b = (0,sa_b)
	matrix colnames sa_b = F1event `colnames'	

	// Position of sample mean text     
	if `n' == 1 {
		local height 1
		local figpan "a"
	}
	else if `n' == 2 {
		local height 4
		local figpan "b"
	}
	else if `n' == 3 {
		local height 4
		local figpan "c"
	}
	else if `n' == 4 {
		local height 1.5
		local figpan "d"
	}
	
	event_plot sa_b#sa_v ols, ///
		stub_lag(L#event L#event) stub_lead(F#event F#event) ///
		plottype(scatter) ciplottype(rcap) ///
		together trimlead(4) trimlag(4) noautolegend ///
		graph_opt( ///
			subtitle("`: var label `depvar''", size(6) pos(11)) ///
			xtitle("Years since state becomes wet", size(6) height(7)) ///
			ytitle("Average causal effect", size(6)) ///
			xlabel(-4(1)4, nogrid notick  labsize(6)) ///
			ylab(`y_range', labsize(6) angle(0) format(%03.2f) nogrid notick) ///
			xscale(extend) yscale(extend) ///
			xsize(8) ///
			legend(order(1 "Sun and Abraham (2021)" 3 "TWFE OLS") rows(1) position(6) size(6) region(style(none))) ///
			xline(-0.5, lcolor(gs8) lpattern(dash)) yline(0, lcolor(gs8)) graphregion(color(white)) bgcolor(white)  ///
			text(`height' -4 "Mean of Y: `ybar'", size(large) placement(right)) ///
		) ///
		lag_opt1(msymbol(O) color(cranberry)) lag_ci_opt1(color(cranberry)) ///
		lag_opt2(msymbol(D) color(navy)) lag_ci_opt2(color(navy))

	graph export "$PROJ_PATH/analysis/output/appendix/figure_e1`figpan'_event_study_`suffix_`n''.png", as(png) height(2400) replace
	
}

// Remove temp shapefiles 
cap rm "$PROJ_PATH/analysis/processed/temp/nhgis0032_shape.zip"
cap rm "$PROJ_PATH/analysis/processed/temp/nhgis0033_shape.zip"

local filelist : dir "$PROJ_PATH/analysis/processed/temp/nhgis0032_shape" files "*", respectcase
foreach file in `filelist' {
	cap rm "$PROJ_PATH/analysis/processed/temp/nhgis0032_shape/`file'"
}

local filelist : dir "$PROJ_PATH/analysis/processed/temp/nhgis0033_shape" files "*", respectcase
foreach file in `filelist' {
	cap rm "$PROJ_PATH/analysis/processed/temp/nhgis0033_shape/`file'"
}

cap rmdir "$PROJ_PATH/analysis/processed/temp/nhgis0032_shape"
cap rmdir "$PROJ_PATH/analysis/processed/temp/nhgis0033_shape"

disp "DateTime: $S_DATE $S_TIME"

* EOF