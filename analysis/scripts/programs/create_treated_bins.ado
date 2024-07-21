// state is treated units
// time is time variable
// time_treated is date of treatment 
// treated is ever_treated x post_treatment


capture program drop create_treated_bins
program create_treated_bins, 
syntax, ///
	low_event_cap(real) ///
	high_event_cap(real) ///
	output_file_name(string) ///
	time_variable(string) ///
	id_variable(string) 

	////////////////////////////////////////////////////////////////////////////
// Set up variables
	 


	capture confirm variable time_treated
	if !_rc {
		di "time_treated exists"
	}
	else {
		*Make an adoption time variable.
		capture drop temp_time
		gen temp_time = `time_variable' if ever_treated == 1
		egen time_treated = min(temp_time), by(`id_variable')
		drop temp_time
	}
	
	
	* gen event-time (adoption_date = treatment adoption date )
	capture drop event_time_bacon
	gen event_time_bacon = `time_variable' - time_treated

	* make sure untreated units are included, but also don't get dummies (by giving them "-1")
	recode event_time_bacon (-1000/`low_event_cap'=`low_event_cap') (`high_event_cap'/1000=`high_event_cap')

	// Determine number of unique "event times"

	local version = floor(`c(stata_version)')
	if `version' < 15 {
		
		levelsof(event_time_bacon), local(event_time_names)

		capture mat drop event_time_names
		foreach i of local event_time_names {
			matrix event_time_names = (nullmat(event_time_names) \ `i')
		}
	}
	else {	
		levelsof(event_time_bacon), matrow(event_time_names)
	}
	
	mat list event_time_names
				
	local unique_event_times = r(r)
	di `unique_event_times'
	
	// Find out which event time in the pre-period is closest to -1
	capture drop event_time_names1
	svmat event_time_names
	preserve 
		drop if event_time_names1 >= 0
		egen ref_event_time = max(event_time_names1)
		sum ref_event_time
		local ref_event_time = r(mean)
	restore
	di `ref_event_time'
	capture drop event_time_names1
	
	recode event_time_bacon (.=`ref_event_time')
	char event_time_bacon[omit] `ref_event_time'
	
	
		xi i.event_time_bacon, pref(_T)
		
		
	// Determine number of unique "event times"		
	capture drop x_value 
	capture drop y_value 
	
	gen x_value = .
	gen y_value = . 
	
	local order_index = 1
	forvalues i = `low_event_cap'(1)`high_event_cap' {
		di "`i'"
		
		
			replace x_value = `i' in `order_index'
			gunique `id_variable' if event_time_bacon == `i'
			replace y_value = `r(unique)' in  `order_index'
		
			local order_index = `order_index' + 1

		
	}
	
	// Now for actual treated 
	drop if ever_treated == 0 
	
	capture drop x_value 
	capture drop y_value 
	
	gen x_value = .
	gen y_value = . 
	
	local order_index = 1
	forvalues i = `low_event_cap'(1)`high_event_cap' {
		di "`i'"
		replace x_value = `i' in `order_index'
		gunique `id_variable' if event_time_bacon == `i'
		replace y_value = `r(unique)' in  `order_index'
		
		local order_index = `order_index' + 1
	}
	
	twoway bar y_value x_value, barw(0.5) col("230 65 115") ///
		xlab(`low_event_cap'(1)`high_event_cap', nogrid labsize(6) angle(0)) ///
		ylab(0(10)50, nogrid labs(6) angle(0) format(%3.0f)) ///
		legend(off) ///
		xtitle("Event time", size(6) height(7)) ///
		ytitle("Number of units", size(6)) ///
		subtitle("Number of treated units by event-time period", size(6) pos(11)) ///
		xsize(8) ///
		graphregion(fcolor(white) ifcolor(white) ilcolor(white) color(white)) plotregion(margin(zero) style(none) fcolor(white) ilcolor(white) ifcolor(white) color(white)) bgcolor(white)
		

	// Save graph
	graph export "`output_file_name'.png", as(png) height(2400) replace

end
