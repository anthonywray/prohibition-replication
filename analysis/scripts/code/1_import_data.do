version 17
disp "DateTime: $S_DATE $S_TIME"

************
* SCRIPT: 1_import_data.do
* PURPOSE: This do file extracts and processes raw data files and saves them in .dta format.
************

************
* NOTE:
* Extracts from IPUMS USA complete count census data cannot be included in the repository
	* and must first be downloaded. See README for instructions.
* Replicators must modify the file names of the 1940 and 1950 census extracts here:
	* Data should be extracted in .dat format 
	* Files do not need to be unzipped and can be added in .gz format 

local filename_1940 "usa_00090"
local filename_1950 "usa_00089"

************
* Code begins
************

// Select the range of birth years 
local start_year_births 		1930
local end_year_births			1941

// Select the years of mortality data
local start_year_deaths_nchs 	1979
local end_year_deaths_nchs		2004

// Restrict to US-born individuals, excluding AK, DC, and HI
local state_restrictions "state <= 56 & state != 2 & state != 11 & state != 15"

*****************************************************************************************************
// Extract raw prohibition data from Jacks, Pendakur and Shigeoka (2021) EJ replication package *****
*****************************************************************************************************

// Load raw data set from EJ paper
use "$PROJ_PATH/analysis/raw/prohibition/prohibition_status_by_state_1933-1942.dta", clear
desc, f 

// Restrict to years of interest 
keep if year >= `start_year_births' & year <= `end_year_births' 

// Keep the variables we need 
keep stfips statename year bir status totpop

// Let's use the raw status variable to determine treatment status 
tab status, m 

gen wet = (status == "wet")
gen dry = (status == "dry" | status == "drish")

assert wet + dry == 1
drop dry 

// Collapse data to state level weighted by total population
gcollapse (sum) stpop = totpop births = bir, by(stfips statename year wet)
gegen total_births = total(births), by(stfips year) 
gegen total_pop = total(stpop), by(stfips year) 
replace wet = wet*stpop/total_pop
gcollapse (sum) wet = wet stpop = stpop births = births, by(stfips statename year)

sum wet, d
assert wet >= 0 & wet <= 1

// Check which states are always dry 
gegen temp_status = max(wet), by(stfips)
tab statename if temp_status == 0
drop temp_status 

rename year birthyear
rename stfips state

la var statename "State"
la var state "State FIPS code"
la var birthyear "Birth year"
la var births "Number of births"
la var stpop "Population"
la var wet "Share of birth in wet counties"

compress
order statename state birthyear births stpop wet 
gsort state birthyear
xtset state birthyear
desc, f

save "$PROJ_PATH/analysis/processed/intermediate/prohibition/prohibition_status_by_state_1933-1941_modified.dta", replace



***************************************************
******** NCHS to FIPS state code crosswalk ********
***************************************************

use nchs_state fipsst statename using "$PROJ_PATH/analysis/raw/nber/nchs2fips_county1990.dta", clear
gduplicates drop
destring nchs_state fipsst, replace
rename fipsst state
keep if state <= 56

* Add DC
count
local n = r(N) + 1
set obs `n'
count
replace nchs_state = 9 in `r(N)'
replace state = 11 in `r(N)'
replace statename = "District of Columbia" in `r(N)'
sort nchs_state

save "$PROJ_PATH/analysis/processed/intermediate/nber/nchs2fips_xwk.dta", replace



*********************************************************
******** USPS State Abbreviations and FIPS Codes ********
*********************************************************

* Load state abbreviation crosswalk and restrict to U.S. states

use "$PROJ_PATH/analysis/raw/bls/stateabb.dta", clear
keep if statefip <= 56
rename statefip state
save "$PROJ_PATH/analysis/processed/intermediate/bls/st2fips_xwk.dta", replace



*******************************************************
******** New Deal funding from Fishback (2015) ********
*******************************************************

// Load raw data set from Fishback (2015)
use "$PROJ_PATH/analysis/raw/new_deal/reh3041.dta", clear
desc, f 

order state* year
gsort statename year

keep statename year grantogrmtran spop
rename year birthyear
rename grantogrmtran tot_grants_ex_transfers

// Convert to per capita variables 
replace tot_grants_ex_transfers = tot_grants_ex_transfers/spop

// Rename states 
replace statename = "Connecticut" if statename == "Connect"
replace statename = "Massachusetts" if statename == "Massa"
replace statename = "New Hampshire" if statename == "New Hamp"
replace statename = "North Carolina" if statename == "North Carol"
replace statename = "Rhode Island" if statename == "Rhode"
replace statename = "South Carolina" if statename == "South Carol"
replace statename = "Tennessee" if statename == "Tennesse"
replace statename = "West Virginia" if statename == "West virginia"
replace statename = "Wisconsin" if statename == "Wiscon"

// Merge in state FIPS codes 
fmerge m:1 statename using "$PROJ_PATH/analysis/processed/intermediate/nber/nchs2fips_xwk.dta", assert(2 3) keep (3) nogen keepusing(state)

compress
order statename state birthyear tot_grants_ex_transfers

gsort state birthyear
xtset state birthyear

la var statename "State"
la var state "State FIPS code"
la var birthyear "Birth year"
la var tot_grants_ex_transfers "Total New Deal grants minus transfers per capita"

desc, f
save "$PROJ_PATH/analysis/processed/intermediate/new_deal/new_deal_grants_by_state_1930_1941.dta", replace



*****************************************************************
******** State-level personal income per capita from BEA ********
*****************************************************************

// Load state-level personal income per capita data from Jacks 
import excel using "$PROJ_PATH/analysis/raw/great_depression/State-level personal income per capita, 1929-2018.xlsx", firstrow clear
rename state statename
rename year birthyear 

// Merge in state FIPS codes 
fmerge m:1 statename using "$PROJ_PATH/analysis/processed/intermediate/nber/nchs2fips_xwk.dta", assert(2 3) keep(3) nogen keepusing(state)

// Restrict years
keep if birthyear >= `start_year_births' & birthyear <= `end_year_births' 

compress
order statename state birthyear stincome

gsort state birthyear
xtset state birthyear

la var statename "State"
la var state "State FIPS code"
la var birthyear "Birth year"
la var stincome "State-level personal income per capita"

desc, f
save "$PROJ_PATH/analysis/processed/intermediate/great_depression/state_personal_income_per_capita_1930-1941.dta", replace



**********************************************************************
******** 5% sample of 1990 US Census of Population from IPUMS ********
**********************************************************************

// Unzip IPUMS extract 
cp "$PROJ_PATH/analysis/raw/ipums/usa_00083.dat.gz" "$PROJ_PATH/analysis/processed/temp/usa_00083.dat.gz"
shell "$ZIP_PATH" x "$PROJ_PATH/analysis/processed/temp/usa_00083.dat.gz" -o"$PROJ_PATH/analysis/processed/temp" -aoa

clear
quietly infix             ///
  int     year     1-4    ///
  long    sample   5-10   ///
  double  serial   11-18  ///
  double  hhwt     19-28  ///
  double  cluster  29-41  ///
  double  strata   42-53  ///
  byte    gq       54-54  ///
  int     pernum   55-58  ///
  double  perwt    59-68  ///
  byte    sex      69-69  ///
  int     age      70-72  ///
  int     birthyr  73-76  ///
  byte    race     77-77  ///
  int     raced    78-80  ///
  int     bpl      81-83  ///
  long    bpld     84-88  ///
  using `"$PROJ_PATH/analysis/processed/temp/usa_00083.dat"'

replace hhwt    = hhwt    / 100
replace perwt   = perwt   / 100

format serial  %8.0f
format hhwt    %10.2f
format cluster %13.0f
format strata  %12.0f
format perwt   %10.2f

qui do "$PROJ_PATH/analysis/scripts/programs/_ipums_labels.do"

tab bpl, m

rename bpl state
rename birthyr birthyear

keep if birthyear >= `start_year_births' & birthyear <= `end_year_births'
keep if `state_restrictions'

desc, f
compress

save "$PROJ_PATH/analysis/processed/intermediate/ipums/usa_00083_extract.dta", replace


cap rm "$PROJ_PATH/analysis/processed/temp/usa_00083.dat.gz"
cap rm "$PROJ_PATH/analysis/processed/temp/usa_00083.dat"

*************************************************************************
******** NCHS Vital Statistics Multiple Cause-of-Death from NBER ********
*************************************************************************

forvalues y = `start_year_deaths_nchs'(1)`end_year_deaths_nchs' {

	if `y' <= 1995 {
		local statevar "statebth"
	}
	else {
		local statevar "statbth"
	}
	
	cp "$PROJ_PATH/analysis/raw/nber_mortality_mcod/dta/mort`y'.dta.zip" "$PROJ_PATH/analysis/processed/temp/mort`y'.dta.zip"
	cd "$PROJ_PATH/analysis/processed/temp"
	
	unzipfile "mort`y'.dta.zip", replace
	use "mort`y'.dta", clear
	cd "$PROJ_PATH"
	
	capture drop year
	gen year = `y'
	
	* Create consistent state FIPS code and standard age in years variable for all years 
	* For 1980 to 2002, state of birth is reported as a numeric NCHS code
		* See above for crosswalk source
	* From 2003 to 2004, state of birth is reported as a state abbreviation
		* NOTE: Eventually replace user generated state abbreviation crosswalk with code
		* Age coding also changes in 2003 -- fill in details
		* Sex is M/F string in 2003/2004
		
	if `y' <= 2002 {
	
		rename `statevar' nchs_state
		keep if nchs_state <= 51 
		fmerge m:1 nchs_state using "$PROJ_PATH/analysis/processed/intermediate/nber/nchs2fips_xwk.dta", assert(3) nogen
		
		replace age = 0 if age >= 200 & age <= 699
		replace age = . if age == 999
		assert age < 200 | missing(age)
		
	}
	else {
	
		gen stateabb = `statevar'
		fmerge m:1 stateabb using "$PROJ_PATH/analysis/processed/intermediate/bls/st2fips_xwk.dta", assert(1 3) nogen
		drop stateabb
		
		gen temp_age = .
		replace temp_age = age - 1000 if age < 2000
		replace temp_age = 0 if age >= 2000 & age < 9999
		
		assert temp_age <= 135 | missing(temp_age)
		assert age == 9999 if temp_age == .
		drop age
		rename temp_age age
		
		replace sex = "1" if sex == "M"
		replace sex = "2" if sex == "F"
		destring sex, replace
	}
	
	// We keep U.S. states only + drop AK, DC, and HI
	keep if `state_restrictions'
	
	* NOTE: age is age in years on the last birthday as recorded at the time of deaths 
	gen birthyear = year - age
	
	keep if inrange(birthyear,`start_year_births',`end_year_births')
		
	save "$PROJ_PATH/analysis/processed/intermediate/nber_mortality_mcod/mort`y'_extract.dta", replace

	cap rm "$PROJ_PATH/analysis/processed/temp/mort`y'.dta.zip"
	cap rm "$PROJ_PATH/analysis/processed/temp/mort`y'.dta"
}



******************************************************	
******** NHGIS 1930 US Census State-level GIS ********
******************************************************	

cp "$PROJ_PATH/analysis/raw/nhgis/nhgis0032_shape.zip" "$PROJ_PATH/analysis/processed/temp/nhgis0032_shape.zip"

cd "$PROJ_PATH/analysis/processed/temp"
unzipfile "nhgis0032_shape.zip", replace

cd "$PROJ_PATH/analysis/processed/temp/nhgis0032_shape"
unzipfile "nhgis0032_shapefile_tl2000_us_state_1930.zip", replace

******************************************************	
******** NHGIS 1930 US Census County-level GIS *******
******************************************************	

cp "$PROJ_PATH/analysis/raw/nhgis/nhgis0033_shape.zip" "$PROJ_PATH/analysis/processed/temp/nhgis0033_shape.zip"

cd "$PROJ_PATH/analysis/processed/temp"
unzipfile "nhgis0033_shape.zip", replace

cd "$PROJ_PATH/analysis/processed/temp/nhgis0033_shape"
unzipfile "nhgis0033_shapefile_tl2000_us_county_1930.zip", replace

cd "$PROJ_PATH"

********************************************************************
// Load IPUMS data and collapse 
********************************************************************
		
********************************************************************
******** 1940 Full-Count US Census of Population from IPUMS ********
********************************************************************

// Unzip IPUMS extract 
cp "$PROJ_PATH/analysis/raw/ipums/ipums_1940_100_pct/`filename_1940'.dat.gz" "$PROJ_PATH/analysis/processed/temp/`filename_1940'.dat.gz"
shell "$ZIP_PATH" x "$PROJ_PATH/analysis/processed/temp/`filename_1940'.dat.gz" -o"$PROJ_PATH/analysis/processed/temp" -aoa

clear
quietly infix             ///
  int     year         1-4    ///
  long    sample       5-10   ///
  double  serial       11-18  ///
  double  hhwt         19-28    ///
  byte    gq           29-29    ///
  int     pernum       30-33    ///
  double  perwt        34-43    ///
  byte    sex          54-54    ///
  int     age          55-57    ///
  int     birthyr      58-61    ///
  byte    race         62-62    ///
  int     raced        63-65    ///
  int     bpl          66-68    ///
  long    bpld         69-73    ///
  using `"$PROJ_PATH/analysis/processed/temp/`filename_1940'.dat"'

replace hhwt    = hhwt    / 100
replace perwt   = perwt   / 100

format serial  %8.0f
format hhwt    %10.2f
format perwt   %10.2f

qui do "$PROJ_PATH/analysis/scripts/programs/_ipums_labels.do"

tab bpl, m

rename bpl state
rename birthyr birthyear

keep if birthyear >= `start_year_births' & birthyear <= `end_year_births'
keep if `state_restrictions'

gen population = 1

// Use perwt (number of people represented by observation) to generate estimate of A_bst for each census year
gcollapse (sum) population, by(year state birthyear)
	
tempfile by_cohort
save `by_cohort', replace

// Create data sets with unique set of each variable to generate balanced panel 

foreach var in year birthyear state {	

	use `var' using `by_cohort', clear 
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
	
use `by_cohort', clear
fmerge 1:1 year state birthyear using `crosslist', assert(2 3) nogen 
recode population (mis = 0)

gsort year state birthyear
compress
desc, f

save "$PROJ_PATH/analysis/processed/intermediate/ipums/`filename_1940'_extract_1940_100_pct_collapsed.dta", replace
	
cap rm "$PROJ_PATH/analysis/processed/temp/`filename_1940'.dat.gz"
cap rm "$PROJ_PATH/analysis/processed/temp/`filename_1940'.dat"

********************************************************************
******** 1950 Full-Count US Census of Population from IPUMS ********
********************************************************************

// Unzip IPUMS extract 
cp "$PROJ_PATH/analysis/raw/ipums/ipums_1950_100_pct/`filename_1950'.dat.gz" "$PROJ_PATH/analysis/processed/temp/`filename_1950'.dat.gz"
shell "$ZIP_PATH" x "$PROJ_PATH/analysis/processed/temp/`filename_1950'.dat.gz" -o"$PROJ_PATH/analysis/processed/temp" -aoa

clear
quietly infix             ///
  int     year         1-4    ///
  long    sample       5-10   ///
  double  serial       11-18  ///
  double  hhwt         19-28    ///
  byte    gq           29-29    ///
  int     pernum       30-33    ///
  double  perwt        34-43    ///
  byte    sex          54-54    ///
  int     age          55-57    ///
  int     birthyr      58-61    ///
  byte    race         62-62    ///
  int     raced        63-65    ///
  int     bpl          66-68    ///
  long    bpld         69-73    ///
  using `"$PROJ_PATH/analysis/processed/temp/`filename_1950'.dat"'

replace hhwt    = hhwt    / 100
replace perwt   = perwt   / 100

format serial  %8.0f
format hhwt    %10.2f
format perwt   %10.2f

qui do "$PROJ_PATH/analysis/scripts/programs/_ipums_labels.do"

tab bpl, m

rename bpl state
rename birthyr birthyear

keep if birthyear >= `start_year_births' & birthyear <= `end_year_births'
keep if `state_restrictions'

gen population = 1

// Use perwt (number of people represented by observation) to generate estimate of A_bst for each census year
gcollapse (sum) population, by(year state birthyear)
	
tempfile by_cohort
save `by_cohort', replace

// Create data sets with unique set of each variable to generate balanced panel 

foreach var in year birthyear state {	

	use `var' using `by_cohort', clear 
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
	
use `by_cohort', clear
fmerge 1:1 year state birthyear using `crosslist', assert(2 3) nogen 
recode population (mis = 0)

gsort year state birthyear
compress
desc, f

save "$PROJ_PATH/analysis/processed/intermediate/ipums/`filename_1950'_extract_1950_100_pct_collapsed.dta", replace

cap rm "$PROJ_PATH/analysis/processed/temp/`filename_1950'.dat.gz"
cap rm "$PROJ_PATH/analysis/processed/temp/`filename_1950'.dat"

******************************************************

disp "DateTime: $S_DATE $S_TIME"

* EOF