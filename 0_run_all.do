*****************************************************
* OVERVIEW
*	FILE: 0_run_all.do
*   This script generates tables and figures for the paper:
*		"Later-life Mortality and the Repeal of Federal Prohibition"
*	AUTHORS: David S. Jacks, Krishna Pendakur, Hitoshi Shigeoka, and Anthony Wray
* 	VERSION: July 2024
*
* DESCRIPTION
* 	This script replicates the analysis in our paper and online appendix
*   All raw data are stored in /raw/
*   All code is stored in /scripts/
*   All tables and figures are outputted to /output/
*
* SOFTWARE REQUIREMENTS
*   Analyses run on Windows using Stata version 17 and R-4.4.1
*
* TO PERFORM A CLEAN RUN, 
*	1. Be sure to have downloaded the publicly available IPUMS data that we are not allowed to redistribute
* 	2. Delete the following two directories:
*   	/processed
*   	/output
*	3. Open the stata project `prohibition-replication.stpr` or 
*		make the working directory of Stata is the same directory `prohibition-replication.stpr`
*		 is located in
* 	4. Run this file, `0_run_all.do`

*****************************************************
// Clear stored objects and set preferences
clear all
matrix drop _all // Drop everything in mata
set more off
set varabbrev off

*****************************************************
// Local switches

* Install packages
local install_packages 1

* Force removal of the gtools package that was installed
local remove_existing_gtools 0

* Install gtools, The stata package gtools installs differently depending on your machine.
* The version in our libraries may not work for your machine. 
local install_gtools 0

* Switch log on/off
local log 1

* Switches for running individual do files
local unzip_files		1 // Note this will not include some IPUMS data
local run_build			1 // You will need to download IPUMS data before this will run. Please see README.
local run_paper 		1
local run_appendix		1

*****************************************************

// Set root directory
	local root_directory `c(pwd)'
	di "`root_directory'"
	global PROJ_PATH 	"`root_directory'"										// Project folder
	
// Set shell command paths
	global RSCRIPT_PATH "C:/Program Files/R/R-4.4.1/bin/x64/Rscript.exe"		// Location of the program R
	global ZIP_PATH 	"C:/Program Files/7-Zip/7zG.exe"						// Location of 7-Zip (used to unzip files)

*****************************************************

* Confirm that the globals for the project root directory and the R executable have been defined
assert !missing("$PROJ_PATH")

* Initialize log and record system parameters
cap mkdir "$PROJ_PATH/analysis/scripts/logs"
cap log close
set linesize 255 // Specify screen width for log files
local datetime : di %tcCCYY.NN.DD!_HH.MM.SS `=clock("$S_DATE $S_TIME", "DMYhms")'
local logfile "$PROJ_PATH/analysis/scripts/logs/log_`datetime'.txt"
if `log' {
	log using "`logfile'", text
}

di "Begin date and time: $S_DATE $S_TIME"
di "Stata version: `c(stata_version)'"
di "Updated as of: `c(born_date)'"
di "Variant:       `=cond( c(MP),"MP",cond(c(SE),"SE",c(flavor)) )'"
di "Processors:    `c(processors)'"
di "OS:            `c(os)' `c(osdtl)'"
di "Machine type:  `c(machine_type)'"

*****************************************************
* Make sure libraries are set up correctly
*****************************************************

local t0 = clock(c(current_time), "hms")
di "Starting extraction of libraries: `t0'"

// Takes ~1 minute to run
if `unzip_files' {
	
	// Unzip Stata libraries
	shell "$ZIP_PATH" x "$PROJ_PATH/analysis/scripts/libraries.zip" -o"$PROJ_PATH/analysis/scripts" -aoa

	// Only Stata packages included in libraries.zip so R packages need to be installed via renv
	local install_packages 		1
			
}

* Disable locally installed Stata programs
cap adopath - PERSONAL
cap adopath - PLUS
cap adopath - SITE
cap adopath - OLDPLACE
cap adopath - "$PROJ_PATH/analysis/scripts/libraries/stata"

* Create and define a local installation directory for the packages
net set ado "$PROJ_PATH/analysis/scripts/libraries/stata"

adopath ++ "$PROJ_PATH/analysis/scripts/libraries/stata"
adopath ++ "$PROJ_PATH/analysis/scripts/programs" // Stata programs and R scripts are stored in /scripts/programs

if `install_gtools' {
	if `remove_existing_gtools' {
		shell rm -r "$PROJ_PATH/analysis/scripts/libraries/stata/g"
	}
	ssc install gtools
	gtools, upgrade
}

// Stata version control
version 17

// Build new list of libraries to be searched
mata: mata mlib index

// Set up R packages 

if `install_packages' {
	
	* Activate renv manually
	rscript using "$PROJ_PATH/renv/activate.R", rpath($RSCRIPT_PATH)
	
	* Install R packages 
	rscript using "$PROJ_PATH/analysis/scripts/programs/_install_R_packages.R", rpath($RSCRIPT_PATH)
}

* R version control
rscript, rversion(4.4.1) 

cd "$PROJ_PATH"

*****************************************************
// Create project directories 
cap mkdir "$PROJ_PATH/analysis/output"
cap mkdir "$PROJ_PATH/analysis/output/main"
cap mkdir "$PROJ_PATH/analysis/output/appendix"
cap mkdir "$PROJ_PATH/analysis/processed"
cap mkdir "$PROJ_PATH/analysis/processed/data"
cap mkdir "$PROJ_PATH/analysis/processed/intermediate"
cap mkdir "$PROJ_PATH/analysis/processed/intermediate/bls"
cap mkdir "$PROJ_PATH/analysis/processed/intermediate/great_depression"
cap mkdir "$PROJ_PATH/analysis/processed/intermediate/ipums"
cap mkdir "$PROJ_PATH/analysis/processed/intermediate/nber_mortality_mcod"
cap mkdir "$PROJ_PATH/analysis/processed/intermediate/nber"
cap mkdir "$PROJ_PATH/analysis/processed/intermediate/nchs"
cap mkdir "$PROJ_PATH/analysis/processed/intermediate/new_deal"
cap mkdir "$PROJ_PATH/analysis/processed/intermediate/prohibition"
cap mkdir "$PROJ_PATH/analysis/processed/temp"

**********************************************************************************************************
* Run project analysis ***********************************************************************************
**********************************************************************************************************

local t1 = clock(c(current_time), "hms")
di "Starting build: `t1'"

// Takes ~21 min to run
if `run_build' {

	do "$PROJ_PATH/analysis/scripts/code/1_import_data.do"
	do "$PROJ_PATH/analysis/scripts/code/2_clean_data.do"
	do "$PROJ_PATH/analysis/scripts/code/3_combine_data.do"
	
}

local t2 = clock(c(current_time), "hms")
di "Ending build and starting analysis: `t2'"

////////////////////////////////////////////////////////////////////////////
// Main tables and figures (~ 1.2 minutes to run)
////////////////////////////////////////////////////////////////////////////

if `run_paper' {

	// Run analysis for main paper
	do "$PROJ_PATH/analysis/scripts/code/4_tables_figures.do"
	
}

local t3 = clock(c(current_time), "hms")
di "Ending main analysis and starting appendix: `t3'"

////////////////////////////////////////////////////////////////////////////
// Appendix tables and figures (~3.75 minutes to run)
////////////////////////////////////////////////////////////////////////////

if `run_appendix' {
	
	// Run analysis for appendix
	do "$PROJ_PATH/analysis/scripts/code/5_online_appendix.do"
	
}

local t4 = clock(c(current_time), "hms")
di "Ending appendix: `t4'"

*****************************************************
// Log of times per section

// Extract Stata libraries and install R packages
local time = clockdiff_frac(`t0', `t1', "minute")
di "Time to extract libraries: `time' minutes"

// Build
local time = clockdiff_frac(`t1', `t2', "minute")
di "Time to build raw data: `time' minutes"

// Main analysis
local time = clockdiff_frac(`t2', `t3', "minute")
di "Time to do main analysis: `time' minutes"

// Appendix 
local time = clockdiff_frac(`t3', `t4', "minute")
di "Total time to run appendix: `time' minutes"

*****************************************************
// End log
di "End date and time: $S_DATE $S_TIME"

if `log' {
	log close
}

*****************************************************

** EOF
