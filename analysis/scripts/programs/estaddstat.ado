/**** Script: estaddstat.ado 
	* Purpose: 
	*	- Adds statistics to eststo stored estimates
*/

cap program drop estaddstat
program define estaddstat

	syntax anything, [by(string) using(string) y(string) comtype(string) column(string) coef(string)]
	
	if "`anything'" == "gunique" | "`anything'" == "unique" {
			
		estadd scalar unique_hh = e(N_clust) : p1_c`column'
	}
	else if "`anything'" == "pcteffect" {
		
		if "`comtype'" == "lincom" {
			
			// Extract regression coefficient
			local b_est = `using'
			di "`b_est'"
			
		}
		else {
						
			// Extract regression coefficient
			local b_est = `coef'["b","`using'"]	
		}
		
		// Format mean of Y
		local ybar_rnd : di %9.2f `y'
		
		// Compute and format percent effect
		local pct_eff = `b_est'*100/`y'
		local pct_eff_rnd : di %9.1f `pct_eff'
		di "`pct_eff_rnd'"
		
		estadd local ymean "`ybar_rnd'" : p1_c`column'
		estadd local pct_effect "`pct_eff_rnd'" : p1_c`column'
	}
	
end
