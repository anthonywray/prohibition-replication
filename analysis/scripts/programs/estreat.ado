/* Begin estreat program */

cap program drop estreat
program define estreat
	version 17
	
	syntax, treatvar(string) time(string) location(string) cutoff(string)
	
	qui {
		
		// Set inequality depending on cutoff value 
		
		if "`cutoff'" == "1" {
			local vs "=="
		}
		else if "`cutoff'" == "0.5" {
			local vs ">="
		}
		else if "`cutoff'" == "0" {
			local vs ">"
		}
		
		// Make an exposure year variable
		
		tempvar exp_year
		capture drop `exp_year'
				
		gen `exp_year' = `time' if `treatvar' `vs' `cutoff' & !missing(`treatvar')
				
		egen first_exp_year = min(`exp_year'), by(`location')
		drop `exp_year'

		// Generate ever treated
		
		gen ever_treated = 0
		replace ever_treated = 1 if !missing(first_exp_year)

		// Generate post 
		
		gen post = 0
		replace post = 1 if `time' >= first_exp_year & !missing(first_exp_year)

		// Generate treated
		
		gen treated = 0
		replace treated = 1 if post == 1 & ever_treated == 1
		
		// Rename first year of exposure for event study
		
		rename first_exp_year time_treated

	}
end
