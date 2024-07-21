version 17
disp "DateTime: $S_DATE $S_TIME"

************
* SCRIPT: 2_clean_data.do
* PURPOSE: This do file cleans the NCHS multiple cause of death and IPUMS census datasets.
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

**********************************************************************
******** 5% sample of 1990 US Census of Population from IPUMS ********
**********************************************************************

// Generate collapsed data by gender

use "$PROJ_PATH/analysis/processed/intermediate/ipums/usa_00083_extract.dta", clear

gsort year state 
gen population = 1

* Ensure no missing values
tab sex, m
tab race, m

local gender_1 "men_only"
local gender_2 "women_only"

gcollapse (sum) population [fweight = perwt], by(year state birthyear sex)
	
tempfile by_gender
save `by_gender', replace

// Create data sets with unique set of each variable to generate balanced panel 

foreach var in year birthyear state sex {	

	use `var' using `by_gender', clear 
	gduplicates drop 
	gsort `var'
	tempfile `var'list
	save ``var'list', replace 

}

clear 
use `yearlist'
cross using `birthyearlist'
cross using `statelist'
cross using `sexlist'
tempfile crosslist 
save `crosslist', replace

foreach x in 1 2 {
	
	use `by_gender', clear
		
	fmerge 1:1 year state birthyear sex using `crosslist', assert(2 3) nogen 
	recode population (mis = 0)
	
	keep if sex == `x'
	
	gsort year state birthyear
	
	save "$PROJ_PATH/analysis/processed/intermediate/ipums/usa_00083_extract_collapsed_`gender_`x''.dta", replace

}


// Generate collapsed data by race 
local race_1 "white_only"
local race_2 "non_white_only"

use "$PROJ_PATH/analysis/processed/intermediate/ipums/usa_00083_extract.dta", clear

tab race, m

// Initially code race based on general race codes
gen white = (race == 1)
gen non_white = (race != 1)

// Recode race to white vs. non-white 
replace race = 1 if white == 1
replace race = 2 if non_white == 1

gsort year state 
gen population = 1

gcollapse (sum) population [fweight = perwt], by(year state birthyear race)

tempfile by_race 
save `by_race', replace 

// Create data sets with unique set of each variable to generate balanced panel 
foreach var in year birthyear state race {	

	use `var' using `by_race', clear 
	gduplicates drop 
	gsort `var'
	tempfile `var'list
	save ``var'list', replace 

}

clear 
use `yearlist'
cross using `birthyearlist'
cross using `statelist'
cross using `racelist'
tempfile crosslist 
save `crosslist', replace

foreach x in 1 2 {
	
	use `by_race', clear
	
	fmerge 1:1 year state birthyear race using `crosslist', assert(2 3) nogen 
	recode population (mis = 0)
	
	keep if race == `x'
	
	gsort year state birthyear
	
	save "$PROJ_PATH/analysis/processed/intermediate/ipums/usa_00083_extract_collapsed_`race_`x''.dta", replace

}


// Generate collapsed data for all individuals

// Create data sets with unique set of each variable to generate balanced panel 
foreach var in year birthyear state {	

	use `var' using "$PROJ_PATH/analysis/processed/intermediate/ipums/usa_00083_extract.dta", clear 
	gduplicates drop 
	gsort `var'
	tempfile `var'list
	save ``var'list', replace 

}

clear 
use `yearlist'
cross using `birthyearlist'
cross using `statelist'
tempfile crosslist 
save `crosslist', replace

use "$PROJ_PATH/analysis/processed/intermediate/ipums/usa_00083_extract.dta", clear

gsort year state 
gen population = 1

gcollapse (sum) population [fweight=perwt], by(state birthyear year)

fmerge 1:1 year state birthyear using `crosslist', assert(2 3) nogen 
recode population (mis = 0)

gsort year state birthyear
save "$PROJ_PATH/analysis/processed/intermediate/ipums/usa_00083_extract_collapsed.dta", replace


// Validate that totals by sex match overall totals
local gender_1 "men_only"
local gender_2 "women_only"

clear
foreach x in 1 2 {
	append using "$PROJ_PATH/analysis/processed/intermediate/ipums/usa_00083_extract_collapsed_`gender_`x''.dta"
}
gcollapse (sum) population, by(year state birthyear)
gsort year state birthyear

cf _all using "$PROJ_PATH/analysis/processed/intermediate/ipums/usa_00083_extract_collapsed.dta"



*************************************************************************
******** NCHS Vital Statistics Multiple Cause-of-Death from NBER ********
*************************************************************************
* NOTE: ICD-9 codes are used for 1979-1998, and ICD-10 codes for 1999-2004

// Run code to clean ICD codes for 1999 to 2004

forvalues y = 1999(1)2004 {
	use state birthyear year age sex race ucod ucr113 using "$PROJ_PATH/analysis/processed/intermediate/nber_mortality_mcod/mort`y'_extract.dta", clear
	
	tempfile mort`y'_select
	save `mort`y'_select', replace
}
clear 
forvalues y = 1999(1)2004 {
	append using `mort`y'_select'
}

// All cause 
gen deaths = 1 
				
// Create main cause of death categories: Heart, stroke, cancer and motor vehicle accidents 
gen heart = 0
gen stroke = 0
gen cancer = 0
gen mv_acc = 0

// Create additional cause of death categories 
gen resp = 0
gen alcohol = 0
gen drugs = 0
gen homicide = 0
gen suicide = 0
gen accident = 0
gen external = 0

// Heart disease
forval i = 0(1)99 {
	replace heart = 1 if ucod == "I0`i'"
}

assert heart == 1 if regexm(ucod,"^I0") 

forval i = 11(2)13 {
	replace heart = 1 if ucod == "I`i'"
}

forval i = 0(1)9 {
	replace heart = 1 if ucod == "I11`i'"
	replace heart = 1 if ucod == "I13`i'"
}

assert heart == 1 if regexm(ucod,"^I11") 
assert heart == 1 if regexm(ucod,"^I13")

forval i = 20(1)51 {
	replace heart = 1 if ucod == "I`i'"
}

forval i = 200(1)519 {
	replace heart = 1 if ucod == "I`i'"
}

forval i = 20(1)51 {
	assert heart == 1 if regexm(ucod,"^I`i'")
}

// Check that coding of heart disease matches 113 recodes 
assert inrange(ucr113,54,68) if heart == 1
assert !inrange(ucr113,54,68) if heart == 0


// Cancer (malignant neoplasms) 
gen xcode = substr(ucod,1,1)
replace cancer = 1 if xcode == "C"
drop xcode

// Check that coding of cancer matches 113 recodes 
assert inrange(ucr113,19,43) if cancer == 1
assert !inrange(ucr113,19,43) if cancer == 0


// Stroke 
forval i = 0(1)9 {
	replace stroke = 1 if regexm(ucod,"^I6`i'")
}

// Check that coding of stroke matches 113 recodes 
assert stroke == 1 if ucr113 == 70
assert stroke == 0 if ucr113 != 70
		
		
// Motor vehicle accidents (MVA)
	* NOTE: Need to exclude "Other land transport accidents" (code 115) and "Water, air and space, and other and unspecified transport accidents and their sequelae" (code 116)
	
replace mv_acc = 1 if (inlist(substr(ucod,1,2), "V0","V1","V2","V3","V4","V5","V6","V7","V8")) 
replace mv_acc = 0 if (inlist(substr(ucod,1,3), "V01","V05","V06","V10","V11","V15","V16","V17","V18")) 
replace mv_acc = 0 if (inlist(substr(ucod,1,4), "V091","V093","V094","V095","V096","V097","V098","V099"))
replace mv_acc = 0 if (inlist(substr(ucod,1,4), "V193","V198","V199"))
replace mv_acc = 0 if (inlist(substr(ucod,1,4), "V800","V801","V802","V806","V807","V808","V809"))
replace mv_acc = 0 if (inlist(substr(ucod,1,4), "V812","V813","V814","V815","V816","V817","V818","V819"))
replace mv_acc = 0 if (inlist(substr(ucod,1,4), "V822","V823","V824","V825","V826","V827","V828","V829"))
replace mv_acc = 0 if (inlist(substr(ucod,1,4), "V879","V889","V891","V893","V899"))

// Check that coding of MVA matches 113 recodes 
gen alt_mv_acc = (ucr113 == 114)
assert mv_acc == alt_mv_acc
drop alt_mv_acc

// Upper respiratory 
replace resp = 1 if 	inlist(substr(ucod,1,3), "J40","J41","J42","J43","J44","J45","J46","J47")

// Alcohol 
replace alcohol = 1 if 	inlist(substr(ucod,1,3), "F10","K70","T51") | ///
						inlist(substr(ucod,1,4), "E244","G312","G621","G721","I426","K292","K852","K860","R780")

// Drugs
replace drugs = 1 if 	inlist(substr(ucod,1,3), "F11","F12","F13","F14","F15","F16","F17") | ///
						inlist(substr(ucod,1,3), "F18","F19","F55","T40","T41","T43")

// Homicide
replace homicide = 1 if inlist(substr(ucod,1,3), "X85","X86","X87","X88","X89") | ///
						inlist(substr(ucod,1,2),"X9","Y0")

// Suicide
replace suicide = 1 if 	inlist(substr(ucod,1,2), "X6","X7","Y1","Y2") | ///
						inlist(substr(ucod,1,3), "X80","X81","X82","X83","X84") | ///
						inlist(substr(ucod,1,3), "Y30","Y31","Y32","Y33","Y34") | ///
						inlist(substr(ucod,1,4), "Y870")
						
// Accidents 
replace accident = 1 if inlist(substr(ucod,1,2), "V9","X0","X1","X2","X3","X4","X5") | ///
						inlist(substr(ucod,1,1), "W") | ///
						inlist(substr(ucod,1,3), "V05","V15") | /// 
						inlist(substr(ucod,1,4), "V806","V812","V813","V814","V815","V816","V817","V818","V819")

// External 
replace external = 1 if inlist(substr(ucod,1,1), "V","W","X","Y","Z") | ///
						mv_acc == 1 | alcohol == 1 | drugs == 1 | homicide == 1 | suicide == 1 | accident == 1

// Internal 
gen internal = (external == 0)

// Internal minus top 3
gen int_other = (internal == 1 & heart == 0 & stroke == 0 & cancer == 0)

		
order year state birthyear age sex race 
drop ucod ucr113  

// Collapse data 
ds state birthyear year age sex race, not 
local cod_varlist "`r(varlist)'"

collapse (sum) `cod_varlist', by(state birthyear year age sex race)

tempfile mort_collapse_1999_2004
save `mort_collapse_1999_2004', replace 


// Run code to clean ICD codes for 1979 to 1998

forvalues y = 1979(1)1998 {
	use state birthyear year age sex race ucod ucr72 using "$PROJ_PATH/analysis/processed/intermediate/nber_mortality_mcod/mort`y'_extract.dta", clear
	
	tempfile mort`y'_select
	save `mort`y'_select', replace
}
clear 
forvalues y = 1979(1)1998 {
	append using `mort`y'_select'
}

// All-Cause Mortality - Everything
gen deaths = 1 
				
// Create main cause of death categories: Heart, stroke, cancer and motor vehicle accidents 
gen heart = 0
gen stroke = 0
gen cancer = 0
gen mv_acc = 0

// Create additional cause of death categories 
gen resp = 0
gen alcohol = 0
gen drugs = 0
gen homicide = 0
gen suicide = 0
gen accident = 0
gen external = 0

gen icd_num = substr(ucod,1,3)
destring icd_num, replace

// Heart disease
replace heart = 1 if inrange(icd_num,390,398) | icd_num == 402 | icd_num == 404 | inrange(icd_num,410,429)

// Stroke 
replace stroke = 1 if inrange(icd_num,430,434) | inrange(icd_num,436,438)

// Cancer 
replace cancer = 1 if inrange(icd_num,140,208) // Includes neoplasms of lymphatic and hematopoietic tissues

// Motor vehicle accidents 
replace mv_acc = 1 if inrange(icd_num,810,825)
assert mv_acc == 1 if (inlist(substr(ucod,1,2), "81") | inlist(substr(ucod,1,3), "820","821","822","823","824","825"))
assert mv_acc == 0 if !(inlist(substr(ucod,1,2), "81") | inlist(substr(ucod,1,3), "820","821","822","823","824","825"))
		
// Upper respiratory 
replace resp = 1 if 	inrange(icd_num,490,494) | icd_num == 496

// Alcohol 
replace alcohol = 1 if 	inlist(substr(ucod,1,3), "291","303") | ///
						inlist(substr(ucod,1,4), "3050","3575","4255","5353","5710","5711","5712","5713","7903")

// Drugs
replace drugs = 1 if 	inlist(substr(ucod,1,3), "292","304") | ///
						inlist(substr(ucod,1,4), "3321","3576","3051","3052","3053","3054") | ///
						inlist(substr(ucod,1,4), "3055","3056","3057","3058","3059")

// Homicide
replace homicide = 1 if inlist(substr(ucod,1,2), "96")

// Suicide
replace suicide = 1 if 	inlist(substr(ucod,1,2), "95", "98")
						
// Accidents 
replace accident = 1 if inlist(substr(ucod,1,3), "826","827","828","829") | ///
						inlist(substr(ucod,1,2), "80", "83", "84", "85", "86", "88") | ///
						inlist(substr(ucod,1,2), "89", "90", "91", "92")

// External 
replace external = 1 if icd_num >= 800 | ///
						mv_acc == 1 | alcohol == 1 | drugs == 1 | homicide == 1 | suicide == 1 | accident == 1

// Internal 
gen internal = (external == 0)

// Internal minus top 3
gen int_other = (internal == 1 & heart == 0 & stroke == 0 & cancer == 0)

order year state birthyear age sex race
drop ucod ucr72 icd_num 

// Collapse data 
ds state birthyear year age sex race, not 
local cod_varlist "`r(varlist)'"

collapse (sum) `cod_varlist', by(state birthyear year age sex race)

tempfile mort_collapse_1979_1998
save `mort_collapse_1979_1998', replace

clear 
append using `mort_collapse_1979_1998'
append using `mort_collapse_1999_2004'

tempfile both_sexes_all_races
save `both_sexes_all_races', replace

// Generate collapsed data by gender
local gender_1 "men"
local gender_2 "women"

foreach x in 1 2 {
	
	use `both_sexes_all_races' if sex == `x', clear
	
	ds state birthyear year age sex race, not 
	local cod_varlist "`r(varlist)'"
	collapse (sum) `cod_varlist', by(state birthyear year age sex)
	
	// Label variables 
	la var deaths "All-Cause"
	la var heart "Heart Disease"
	la var stroke "Stroke"
	la var cancer "Cancer"
	la var mv_acc "Motor Vehicle Accident"

	la var resp "Chronic Lower Respiratory"
	la var alcohol "Alcohol"
	la var drugs "Drug"
	la var homicide "Homicide"
	la var suicide "Suicide"
	la var accident "Accident"
	la var external "External"
	la var internal "Interal"
	la var int_other "Internal Excl. Top 3"

	// Fill in missing observations
	tempfile missing_input
	save `missing_input', replace
	
	foreach var of varlist state birthyear year {

		use `var' using `missing_input', clear
		gduplicates drop
		tempfile `var'
		save ``var'', replace
	}
	
	clear
	use `state', clear 
	cross using `birthyear'
	cross using `year'
	
	gen age = year - birthyear
	gen sex = `x'
	
	merge 1:1 state birthyear year age sex using `missing_input', assert(1 3) nogen
	
	ds state birthyear year age sex, not 
	recode `r(varlist)' (mis = 0)
	
	sort state birthyear year 
	desc, f 
	
	save "$PROJ_PATH/analysis/processed/intermediate/nchs/state_level_deaths_by_age_from_nchs_`gender_`x''_only.dta", replace
}

// Generate collapsed data by race 
local race_1 "white"
local race_2 "non_white"

foreach x in 1 2 {
	
	use `both_sexes_all_races', clear
	
	// Race - code as white/nonwhite 
	destring race, replace
	assert !missing(race)
	replace race = 2 if race != 1
	
	keep if race == `x'
	
	ds state birthyear year age sex race, not 
	local cod_varlist "`r(varlist)'"
	collapse (sum) `cod_varlist', by(state birthyear year age race)
	
	// Label variables 
	la var deaths "All-Cause"
	la var heart "Heart Disease"
	la var stroke "Stroke"
	la var cancer "Cancer"
	la var mv_acc "Motor Vehicle Accident"

	la var resp "Chronic Lower Respiratory"
	la var alcohol "Alcohol"
	la var drugs "Drug"
	la var homicide "Homicide"
	la var suicide "Suicide"
	la var accident "Accident"
	la var external "External"
	la var internal "Interal"
	la var int_other "Internal Excl. Top 3"

	// Fill in missing observations
	tempfile missing_input
	save `missing_input', replace
	
	foreach var of varlist state birthyear year {

		use `var' using `missing_input', clear
		gduplicates drop
		tempfile `var'
		save ``var'', replace
	}
	
	clear
	use `state', clear 
	cross using `birthyear'
	cross using `year'
	
	gen age = year - birthyear
	gen race = `x'
	
	merge 1:1 state birthyear year age race using `missing_input', assert(1 3) nogen
	
	ds state birthyear year age race, not 
	recode `r(varlist)' (mis = 0)
	
	sort state birthyear year 
	desc, f 
	
	save "$PROJ_PATH/analysis/processed/intermediate/nchs/state_level_deaths_by_age_from_nchs_`race_`x''_only.dta", replace
	
}

// Generate collapsed data for full population

use `both_sexes_all_races', clear
ds state birthyear year age sex race, not 
local cod_varlist "`r(varlist)'"

collapse (sum) `cod_varlist', by(state birthyear year age)

// Label variables 
la var deaths "All-Cause"
la var heart "Heart Disease"
la var stroke "Stroke"
la var cancer "Cancer"
la var mv_acc "Motor Vehicle Accident"

la var resp "Chronic Lower Respiratory"
la var alcohol "Alcohol"
la var drugs "Drug"
la var homicide "Homicide"
la var suicide "Suicide"
la var accident "Accident"
la var external "External"
la var internal "Interal"
la var int_other "Internal Excl. Top 3"

// Fill in missing observations

tempfile missing_input
save `missing_input', replace

foreach var of varlist state birthyear year {

	use `var' using `missing_input', clear
	gduplicates drop
	tempfile `var'
	save ``var'', replace
}

clear
use `state', clear 
cross using `birthyear'
cross using `year'

gen age = year - birthyear

merge 1:1 state birthyear year age using `missing_input', assert(1 3) nogen

ds state birthyear year age, not 
recode `r(varlist)' (mis = 0)

sort state birthyear year 
desc, f 

save "$PROJ_PATH/analysis/processed/intermediate/nchs/state_level_deaths_by_age_from_nchs.dta", replace
	
	
// Validate that totals by sex match overall totals
local gender_1 "men"
local gender_2 "women"

clear
foreach x in 1 2 {
	append using "$PROJ_PATH/analysis/processed/intermediate/nchs/state_level_deaths_by_age_from_nchs_`gender_`x''_only.dta"
}

ds state birthyear year age sex, not 
local cod_varlist "`r(varlist)'"

collapse (sum) `cod_varlist', by(state birthyear year age)
sort state birthyear year age

cf _all using "$PROJ_PATH/analysis/processed/intermediate/nchs/state_level_deaths_by_age_from_nchs.dta"

disp "DateTime: $S_DATE $S_TIME"

* EOF