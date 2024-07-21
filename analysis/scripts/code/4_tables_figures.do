version 17
disp "DateTime: $S_DATE $S_TIME"

************
* SCRIPT: 4_tables_figures.do
* PURPOSE: This do file combines the data sets in preparation for running the analysis
************

************
* Code begins
************

// Select the years of mortality data
local start_year_deaths_nchs 	1990
local end_year_deaths_nchs		2004

// Settings for figures
graph set window fontface 		"Roboto Light"
graph set ps fontface 			"Roboto Light"
graph set eps fontface 			"Roboto Light"

// Specification parameters 
local weight					"alive_jan01"
local absvar					"birthyear##year state##year"
local clustervar 				"state_birthyear" 
local controls					"log_grants log_stinc"
local ybar_sample				"!missing(time_treated) & birthyear <= 1933" 
local treated					"treated"

// Settings for tables
local booktabs_default_options	"booktabs b(%12.3f) se(%12.3f) collabels(none) drop(*) f gaps label mlabels(none) nolines nomtitles nonum noobs nostar substitute(\_ _)"

// Settings for aggregating event study estimates 
local scaled_coef 		"(L0event + L1event + L2event + L3event + L4event)/5"
local scaled_coef_last 	"(L0event + L1event + L2event + L3event)/4"
local comtype 			"lincom"

// --------------------- Create Figure 1a: Apparent ethanol consumption ---------------------

// Source: https://pubs.niaaa.nih.gov/publications/surveillance117/tab1_19.htm

clear
set obs 30
gen year = _n + 1911
gen ethanol = .
replace ethanol = 2.56 if year <= 1915
replace ethanol = 1.96 if year >= 1916 & year <= 1919
replace ethanol = 0.97 if year == 1934
replace ethanol = 1.20 if year == 1935
replace ethanol = 1.50 if year == 1936
replace ethanol = 1.59 if year == 1937
replace ethanol = 1.47 if year == 1938
replace ethanol = 1.51 if year == 1939
replace ethanol = 1.56 if year == 1940
replace ethanol = 1.70 if year == 1941

gen y1 = 0.25 in 1
gen y2 = 0.25 in 1
gen x1 = 1920 in 1 
gen x2 = 1933 in 1 

// Create plot
twoway ///
	|| connected ethanol year if year <= 1919, lw(1.0) col("230 65 115") msymbol(none) lp(solid) /// connect estimates
	|| connected ethanol year if year >= 1934, lw(1.0) col("230 65 115") msymbol(none) lp(solid) ///
	|| pcbarrow y1 x1 y2 x2, lwidth(1) lpattern(longdash) col(gs7) msize(7) barbsize(7) ///
		xlab(1915(5)1940, nogrid labsize(6) angle(0)) ///
		ylab(0(0.5)3.0, nogrid labs(6) angle(0) format(%03.1f)) ///
		legend(off) ///
		xtitle("Year", size(6) height(7)) ///
		ytitle("", size(6)) ///
		subtitle("Apparent per capita ethanol consumption", size(6) pos(11)) ///
		xline(1920, lpattern(dash) lcolor(gs7) lwidth(1)) ///		
		xline(1933, lpattern(dash) lcolor(gs7) lwidth(1)) ///
		xsize(8) ///
		graphregion(fcolor(white) ifcolor(white) ilcolor(white) color(white)) plotregion(style(none) fcolor(white) ilcolor(white) ifcolor(white) color(white)) bgcolor(white) ///
		text(0.5 1926.4 "Federal Prohibition", size(large) placement(center))
		
graph export "$PROJ_PATH/analysis/output/main/figure_1a_ethanol_consumption.png", as(png) height(2400) replace

// --------------------- Create Figure 1b: Roll out of wet treatment --------------------

use "$PROJ_PATH/analysis/processed/data/data_for_analysis_nchs.dta" if year >= `start_year_deaths_nchs' & year <= `end_year_deaths_nchs', clear

sum year
assert r(min) == 1990 & r(max) == 2004
sum birthyear 
assert r(min) == 1930 & r(max) == 1941

// Generate DiD treatment variable
estreat, treatvar(wet) time(birthyear) location(state) cutoff(0)

// Split population by treatment status 
gen long wet_pop = spop*(wet == 1)
gen long dry_pop = spop*(wet == 0)

// Collapse data 
collapse (sum) wet_pop dry_pop, by(birthyear)

// Create treated population share to plot
gen wet_pop_shr = wet_pop/(wet_pop + dry_pop)

gen y1 = 0 in 1
gen y2 = 0 in 1
gen x1 = 1930 in 1 
gen x2 = 1934 in 1 

// Create plot
twoway ///
	|| connected wet_pop_shr birthyear if birthyear >= 1934, lw(1.0) col("230 65 115") msymbol(none) lp(solid) /// connect estimates
	|| pcbarrow y1 x1 y2 x2, lw(1.0) col("230 65 115") mstyle(none) lp(solid) /// connect estimates
		xlab(1930(2)1941, nogrid labsize(6) angle(0)) ///
		ylab(0(0.2)1.0, nogrid labs(6) angle(0) format(%03.1f)) ///
		legend(off) ///
		xtitle("Year", size(6) height(7)) ///
		ytitle("", size(6)) ///
		subtitle("Share of US population treated by year", size(6) pos(11)) ///
		xline(1934, lpattern(dash) lcolor(gs7) lwidth(1)) ///
		xsize(8) ///
		graphregion(fcolor(white) ifcolor(white) ilcolor(white) color(white)) plotregion(style(none) fcolor(white) ilcolor(white) ifcolor(white) color(white)) bgcolor(white) 
		
graph export "$PROJ_PATH/analysis/output/main/figure_1b_shr_pop_treated.png", as(png) height(2400) replace

// --------------------- Create Figure 1c: Map of first year treated by state ---------------------
// --------------------- Create Figure C2: Map of continuous variation in wet status by state ---------------------

// Run code to create maps in R 
rscript using "$PROJ_PATH/analysis/scripts/programs/create_maps.R", rpath($RSCRIPT_PATH)

// --------------------- Create Figure 1d: Mortality with age partialled out ---------------------

// Set dependent variable 
local depvar "y1_deaths"

// Main sample specifications 
use "$PROJ_PATH/analysis/processed/data/data_for_analysis_nchs.dta" if year >= `start_year_deaths_nchs' & year <= `end_year_deaths_nchs', clear

sum year
assert r(min) == 1990 & r(max) == 2004
sum birthyear 
assert r(min) == 1930 & r(max) == 1941

// Generate DiD treatment variable
estreat, treatvar(wet) time(birthyear) location(state) cutoff(0)

// Partial out age and death year effects 
reghdfe `depvar' [aw = `weight'], absorb(age) vce(cluster `clustervar') residuals(partial_`depvar')

// Collapse mean death rates
gcollapse (mean) state_dr = `depvar' partial_state_dr = partial_`depvar' [aw = `weight'], by(birthyear ever_treated)

// Set figure width
local fig_width 8
local yvar "partial_state_dr"
local yscale ""

twoway ///
 || connected `yvar' birthyear if ever_treated == 0, lw(.5) lcolor("black") lp(longdash) msymbol(none) ///
 || connected `yvar' birthyear if ever_treated == 1, lw(1) lcolor("230 65 115") lp(line) msymbol(none) ///
		xlab(1930(2)1940, nogrid valuelabel labsize(6) angle(0)) ///
		ylab(`yscale', nogrid labsize(6) angle(0) format(%3.1f)) ///
		xtitle("Birth Year", size(6) height(7)) ///
		ytitle("", size(6)) ///
		subtitle("Average state-level age-adjusted mortality rate by treatment status", size(6) pos(11)) ///
		xline(1934, lpattern(dash) lcolor(gs7) lwidth(1)) ///
		xsize(8) ///
		legend(off) ///
		graphregion(fcolor(white) ifcolor(white) ilcolor(white) color(white)) plotregion(style(none) fcolor(white) ilcolor(white) ifcolor(white) color(white)) bgcolor(white) ///
		text(2 1930 "States with no individuals", size(large) placement(right)) ///
		text(1.5 1930 "treated at birth", size(large) placement(right)) ///		
		text(-0.25 1930 "States with individuals", size(large) placement(right)) ///
		text(-0.75 1930 "treated at birth", size(large) placement(right))
	
graph export "$PROJ_PATH/analysis/output/main/figure_1d_resid_death_by_birthyear.png", as(png) height(2400) replace


// --------------------- Figure 2: Plot main event study estimates ---------------------

// Loop through depvars 
	* Panel A: All-cause mortality
	* Panel B: Heart disease
	* Panel C: Stroke
	* Panel D: Cancer
	
	* Appendix Figure A3: Motor Vehicle Accidents
	
local cod_depvar_list "deaths heart stroke cancer mv_acc"
tokenize `cod_depvar_list'
local max_val: word count `cod_depvar_list'

forvalues n = 1(1)`max_val' { 
	
	use "$PROJ_PATH/analysis/processed/data/data_for_analysis_nchs.dta" if year >= `start_year_deaths_nchs' & year <= `end_year_deaths_nchs', clear
	
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
	drop F1event // normalize K=-1 to zero

	// Estimation
	reghdfe `depvar' F*event L*event [aw = `weight'], absorb(`absvar') vce(cluster `clustervar')
	test (F2event = 0) (F3event = 0) (F4event = 0) (F5event = 0) (F6event = 0) (F7event = 0) (F8event = 0)
	
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
	
	if "`depvar'" == "y1_mv_acc"  | "`depvar'" == "y1_stroke" {
		local ybar = "0" + "`ybar'" 
	}

	// Storing estimates for later
	matrix sa_b = e(b_iw)
	matrix sa_v = e(V_iw)
	
	// Add zero
	local colnames : colnames sa_b 
	matrix sa_b = (0,sa_b)
	matrix colnames sa_b = F1event `colnames'	

	// Separate location for appendix sub-figure
	if `n' > 4 {
		local folder "appendix"
	}
	else {
		local folder "main"
	}
	
	// Position of sample mean text 
	if "`depvar'" == "y1_deaths" {
		local height 2
		local figpart "2a"
	}
	else if "`depvar'" == "y1_heart" {
		local height 0.65
		local figpart "2b"
	}
	else if "`depvar'" == "y1_stroke" {
		local height 0.2
		local figpart "2c"
	}
	else if "`depvar'" == "y1_cancer" {
		local height 0.6
		local figpart "2d"
	}
	else if "`depvar'" == "y1_mv_acc" {
		local height 0.04
		local figpart "a2"
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
			ylab(, labsize(6) angle(0) format(%03.2f) nogrid notick) ///
			xscale(extend) yscale(extend) ///
			xsize(8) ///
			legend(order(1 "Sun and Abraham (2021)" 3 "TWFE OLS") rows(1) position(6) size(6) region(style(none))) ///
			xline(-0.5, lcolor(gs8) lpattern(dash)) yline(0, lcolor(gs8)) graphregion(color(white)) bgcolor(white)  ///
			text(`height' -4 "Mean of Y: `ybar'", size(large) placement(right)) ///
		) ///
		lag_opt1(msymbol(O) color(cranberry)) lag_ci_opt1(color(cranberry)) ///
		lag_opt2(msymbol(D) color(navy)) lag_ci_opt2(color(navy))

	graph export "$PROJ_PATH/analysis/output/`folder'/figure_`figpart'_event_study_``n''.png", as(png) height(2400) replace
	
}



// --------------------- Table 1: Baseline and Robustness DiD specifications with All-Cause Mortality ---------------------

eststo drop *

// Set dependent variable 
local depvar "y1_deaths"

// Main sample specifications 
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

// Column 1: eventstudyinteract of Sun and Abraham (2021) with no controls
eststo p1_c1: eventstudyinteract `depvar' L*event F*event [aw = `weight'], cohort(time_treated) control_cohort(never_treated) absorb(`absvar') vce(cluster `clustervar')
	
	matrix b = e(b_iw)
	matrix V = e(V_iw)
	ereturn post b V

	// Extract mean of Y among not yet treated observations (alternative: pre repeal)
	sum `depvar' if `ybar_sample'
	local ybar = r(mean)
	
	lincomestadd2 `scaled_coef', comtype(`comtype') statname("pct_efct_") omitstars column(1)
	local treated =  r(estimate)
	estaddstat pcteffect, using(`treated') y(`ybar') comtype(`comtype') column(1)


// Column 2: eventstudyinteract of Sun and Abraham (2021) with controls
eststo p1_c2: eventstudyinteract `depvar' L*event F*event [aw = `weight'], cohort(time_treated) control_cohort(never_treated) absorb(`absvar') vce(cluster `clustervar') covariates(`controls')

	matrix b = e(b_iw)
	matrix V = e(V_iw)
	ereturn post b V

	// Extract mean of Y among not yet treated observations (alternative: pre repeal)
	sum `depvar' if `ybar_sample'	
	local ybar = r(mean)
	
	lincomestadd2 `scaled_coef', comtype(`comtype') statname("pct_efct_") omitstars column(2)
	local treated =  r(estimate)
	estaddstat pcteffect, using(`treated') y(`ybar') comtype(`comtype') column(2)


// Column 3: Last treated as control instead of never treated 
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

// eventstudyinteract of Sun and Abraham (2021)
eststo p1_c3: eventstudyinteract `depvar' L*event F*event [aw = `weight'], vce(cluster `clustervar') absorb(`absvar') cohort(time_treated) control_cohort(last_treated) covariates(`controls')

	matrix b = e(b_iw)
	matrix V = e(V_iw)
	ereturn post b V

	// Extract mean of Y among not yet treated observations (alternative: pre repeal)
	sum `depvar' if `ybar_sample'	
	local ybar = r(mean)
		
	lincomestadd2 `scaled_coef_last', comtype(`comtype') statname("pct_efct_") omitstars column(3)
	local treated =  r(estimate)
	estaddstat pcteffect, using(`treated') y(`ybar') comtype(`comtype') column(3)
	
	
// Column 4: Limit only to state-level transitions 
use "$PROJ_PATH/analysis/processed/data/data_for_analysis_nchs.dta" if year >= `start_year_deaths_nchs' & year <= `end_year_deaths_nchs', clear

// Generate DiD treatment variable for only full transitions
estreat, treatvar(wet) time(birthyear) location(state) cutoff(1)

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

eststo p1_c4: eventstudyinteract `depvar' L*event F*event [aw = `weight'], cohort(time_treated) control_cohort(never_treated) absorb(`absvar') vce(cluster `clustervar') covariates(`controls')

	matrix b = e(b_iw)
	matrix V = e(V_iw)
	ereturn post b V

	// Extract mean of Y among not yet treated observations (alternative: pre repeal)
	sum `depvar' if `ybar_sample'	
	local ybar = r(mean)
	
	lincomestadd2 `scaled_coef', comtype(`comtype') statname("pct_efct_") omitstars column(4)
	local treated =  r(estimate)
	estaddstat pcteffect, using(`treated') y(`ybar') comtype(`comtype') column(4)


// Column 5: Treated only if > 0.5
use "$PROJ_PATH/analysis/processed/data/data_for_analysis_nchs.dta" if year >= `start_year_deaths_nchs' & year <= `end_year_deaths_nchs', clear

// Generate DiD treatment variable for majority transitions
estreat, treatvar(wet) time(birthyear) location(state) cutoff(0.5)

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

eststo p1_c5: eventstudyinteract `depvar' L*event F*event [aw = `weight'], cohort(time_treated) control_cohort(never_treated) absorb(`absvar') vce(cluster `clustervar') covariates(`controls')

	matrix b = e(b_iw)
	matrix V = e(V_iw)
	ereturn post b V

	// Extract mean of Y among not yet treated observations (alternative: pre repeal)
	sum `depvar' if `ybar_sample'	
	local ybar = r(mean)
	
	lincomestadd2 `scaled_coef', comtype(`comtype') statname("pct_efct_") omitstars column(5)
	local treated =  r(estimate)
	estaddstat pcteffect, using(`treated') y(`ybar') comtype(`comtype') column(5)

		
// Column 6: eventstudyinteract of Sun and Abraham (2021) with controls and state-level clustering
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

eststo p1_c6: eventstudyinteract `depvar' L*event F*event [aw = `weight'], vce(cluster state) absorb(`absvar') cohort(time_treated) control_cohort(never_treated) covariates(`controls')

	matrix b = e(b_iw)
	matrix V = e(V_iw)
	ereturn post b V

	// Extract mean of Y among not yet treated observations (alternative: pre repeal)
	sum `depvar' if `ybar_sample'	
	local ybar = r(mean)
		
	lincomestadd2 `scaled_coef', comtype(`comtype') statname("pct_efct_") omitstars column(6)
	local treated =  r(estimate)
	estaddstat pcteffect, using(`treated') y(`ybar') comtype(`comtype') column(6)


// Prepare table

* Set number of columns
local ncols 6

// Set column headers
local colhead_1 "Baseline \\ No Controls"
local colhead_2 "Baseline \\ With Controls"
local colhead_3 "Last Treated \\ as Controls"
local colhead_4 "State-Level \\ Transitions"
local colhead_5 "Majority \\ Transitions"
local colhead_6 "State-Level \\ Clustering"

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
	
	if `n' == 1 {
		
		local sob_yob_controls "`sob_yob_controls' &"	
	}
	else {
		
		local sob_yob_controls "`sob_yob_controls' &\multicolumn{1}{c}{$\checkmark$}"	
	}
	
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
 using "$PROJ_PATH/analysis/output/main/table_1_aggregate_event_study_regressions.tex", `booktabs_default_options' replace
posthead("`numbers_main' `estimators'")
stats(pct_efct_b pct_efct_se pct_efct_t ymean pct_effect N, fmt(0 0 0 %9.2f %9.1f %9.0fc) labels("\midrule\addlinespace\hspace{.5cm} Wet status (=1)" "~" "~" "\addlinespace\hspace{.5cm} Mean of Y" "\hspace{.5cm} Percent effect relative to mean" "\hspace{.5cm} Observations") layout(@ @ @ @ @ "\multicolumn{1}{c}{@}"))
postfoot("\midrule `yob_dob_fe' `sob_dob_fe' `sob_yob_controls'");
#delimit cr

eststo drop *



// --------------------- Table 2: Baseline DiD specification with All-Cause and Cause-Specific Mortality ---------------------

eststo drop *

// Set dependent variable 
local cod_depvar_list 	"deaths heart stroke cancer mv_acc"
tokenize `cod_depvar_list'
local n_max: word count `cod_depvar_list'

forvalues n = 1/`n_max' {
	
	local depvar "y1_``n''"
	
	// Main sample specifications 
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

la var heart "Heart \\ Disease"
la var mv_acc "Motor Vehicle \\ Accidents "

local numbers_main ""
local estimators ""
local yob_dob_fe "Year of birth by death year FEs"
local sob_dob_fe "State of birth by death year FEs"
local sob_yob_controls "State by year of birth controls"

forvalues n = 1(1)`n_max' {
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
local colsep = `n_max' + 1

// Make table 
#delimit ;
esttab p1_c* // 
 using "$PROJ_PATH/analysis/output/main/table_2_cause_of_death.tex", `booktabs_default_options' replace 
posthead("`numbers_main' `estimators'")
stats(pct_efct_b pct_efct_se pct_efct_t ymean pct_effect N, fmt(0 0 0 %9.2f %9.1f %9.0fc) labels("\midrule\addlinespace\hspace{.5cm} Wet status (=1)" "~" "~" "\addlinespace\hspace{.5cm} Mean of Y" "\hspace{.5cm} Percent effect relative to mean" "\hspace{.5cm} Observations") layout(@ @ @ @ @ "\multicolumn{1}{c}{@}"))
postfoot("\midrule `yob_dob_fe' `sob_dob_fe' `sob_yob_controls'");
#delimit cr

eststo drop *



// --------------------- Table 3: Heterogeneity by Gender and Race with All-Cause Mortality ---------------------

eststo drop *

// Set dependent variable 
local depvar "y1_deaths"

// Women 
use "$PROJ_PATH/analysis/processed/data/data_for_analysis_nchs_women_only.dta" if year >= `start_year_deaths_nchs' & year <= `end_year_deaths_nchs', clear

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

// eventstudyinteract of Sun and Abraham (2021)
eststo p1_c1: eventstudyinteract `depvar' L*event F*event [aw = `weight'], cohort(time_treated) control_cohort(never_treated) absorb(`absvar') vce(cluster `clustervar') covariates(`controls')

	matrix b = e(b_iw)
	matrix V = e(V_iw)
	ereturn post b V

	// Extract mean of Y among not yet treated observations (alternative: pre repeal)
	sum `depvar' if `ybar_sample'	
	local ybar = r(mean)
	
	lincomestadd2 `scaled_coef', comtype(`comtype') statname("pct_efct_") omitstars column(1)
	local treated =  r(estimate)
	estaddstat pcteffect, using(`treated') y(`ybar') comtype(`comtype') column(1)



// Men
use "$PROJ_PATH/analysis/processed/data/data_for_analysis_nchs_men_only.dta" if year >= `start_year_deaths_nchs' & year <= `end_year_deaths_nchs', clear

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

// eventstudyinteract of Sun and Abraham (2021)
eststo p1_c2: eventstudyinteract `depvar' L*event F*event [aw = `weight'], cohort(time_treated) control_cohort(never_treated) absorb(`absvar') vce(cluster `clustervar') covariates(`controls')

	matrix b = e(b_iw)
	matrix V = e(V_iw)
	ereturn post b V

	// Extract mean of Y among not yet treated observations (alternative: pre repeal)
	sum `depvar' if `ybar_sample'	
	local ybar = r(mean)
	
	lincomestadd2 `scaled_coef', comtype(`comtype') statname("pct_efct_") omitstars column(2)
	local treated =  r(estimate)
	estaddstat pcteffect, using(`treated') y(`ybar') comtype(`comtype') column(2)

	

// Non-White
use "$PROJ_PATH/analysis/processed/data/data_for_analysis_nchs_non_white_only.dta" if year >= `start_year_deaths_nchs' & year <= `end_year_deaths_nchs', clear

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

// eventstudyinteract of Sun and Abraham (2021)
eststo p1_c3: eventstudyinteract `depvar' L*event F*event [aw = `weight'], cohort(time_treated) control_cohort(never_treated) absorb(`absvar') vce(cluster `clustervar') covariates(`controls')

	matrix b = e(b_iw)
	matrix V = e(V_iw)
	ereturn post b V

	// Extract mean of Y among not yet treated observations (alternative: pre repeal)
	sum `depvar' if `ybar_sample'	
	local ybar = r(mean)
	
	lincomestadd2 `scaled_coef', comtype(`comtype') statname("pct_efct_") omitstars column(3)
	local treated =  r(estimate)
	estaddstat pcteffect, using(`treated') y(`ybar') comtype(`comtype') column(3)


	
// White
use "$PROJ_PATH/analysis/processed/data/data_for_analysis_nchs_white_only.dta" if year >= `start_year_deaths_nchs' & year <= `end_year_deaths_nchs', clear

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

// eventstudyinteract of Sun and Abraham (2021)
eststo p1_c4: eventstudyinteract `depvar' L*event F*event [aw = `weight'], cohort(time_treated) control_cohort(never_treated) absorb(`absvar') vce(cluster `clustervar') covariates(`controls')

	matrix b = e(b_iw)
	matrix V = e(V_iw)
	ereturn post b V

	// Extract mean of Y among not yet treated observations (alternative: pre repeal)
	sum `depvar' if `ybar_sample'	
	local ybar = r(mean)
	
	lincomestadd2 `scaled_coef', comtype(`comtype') statname("pct_efct_") omitstars column(4)
	local treated =  r(estimate)
	estaddstat pcteffect, using(`treated') y(`ybar') comtype(`comtype') column(4)



// Prepare table

* Set number of columns
local ncols 4

* Set column headers
local colhead_1 "Women"
local colhead_2 "Men"
local colhead_3 "Non-White"
local colhead_4 "White"

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
 using "$PROJ_PATH/analysis/output/main/table_3_heterogeneity.tex", `booktabs_default_options' replace 
posthead("`numbers_main' `estimators'")
stats(pct_efct_b pct_efct_se pct_efct_t ymean pct_effect N, fmt(0 0 0 %9.2f %9.1f %9.0fc) labels("\midrule\addlinespace\hspace{.5cm} Wet status (=1)" "~" "~" "\addlinespace\hspace{.5cm} Mean of Y" "\hspace{.5cm} Percent effect relative to mean" "\hspace{.5cm} Observations") layout(@ @ @ @ @ "\multicolumn{1}{c}{@}"))
postfoot("\midrule `yob_dob_fe' `sob_dob_fe' `sob_yob_controls'");
#delimit cr

eststo drop *

disp "DateTime: $S_DATE $S_TIME"

* EOF