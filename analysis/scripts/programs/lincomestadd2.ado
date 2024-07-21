capture program drop lincomestadd2
program define lincomestadd2
syntax anything, statname(name) comtype(string) [format(string) omitstars column(string)]

capture which estadd
if _rc {
	di "You need to install estadd/estout first: ssc install estout."
	exit 199
}

if "`comtype'" == "lincom" {
	lincom `anything'
	*local pvalue = 2*ttail(r(df), abs(r(estimate)/r(se)))
	local pvalue = r(p)
	assert `pvalue' ~= .

	if "`format'" == "" {
		local format %04.2f
	}

	local b_est : di `format' `r(estimate)'
	local se : di `format' `r(se)'
	local t : di `format' `r(estimate)'/`r(se)'
	local bnum = `r(estimate)'
	local senum = `r(se)'
	local tnum = `r(estimate)'/`r(se)'
}

if "`comtype'" == "nlcom" {
	nlcom `anything'
	mat b_est = r(b)
	mat V_est = r(V)

	scalar b_est = b_est[1,1]
	local b_est = b_est
	scalar se_v2 = sqrt(V_est[1,1])
	local se_v2 = se_v2
	local  pvalue = 2*ttail(`e(df_r)',abs(b_est/se_v2))
	
	assert `pvalue' ~= .

	if "`format'" == "" {
		local format %04.2f
	}
	
	local b_est : di `format' `b_est'
	local se : di `format' `se_v2'
	local t : di `format' `b_est'/`se_v2'
	local bnum = `b_est'
	local senum = `se_v2'
	local tnum = `b_est'/`se_v2'
}


if "`comtype'" == "nlcom_pois" {
	nlcom `anything'
	mat b_est = r(b)
	mat V_est = r(V)

	scalar b_est = b_est[1,1]
	local b_est = b_est
	scalar se_v2 = sqrt(V_est[1,1])
	local se_v2 = se_v2
	local  pvalue = 2*ttail(`e(df)',abs(b_est/se_v2))
	
	assert `pvalue' ~= .

	if "`format'" == "" {
		local format %04.2f
	}
	
	local b_est : di `format' `b_est'
	local se : di `format' `se_v2'
	local t : di `format' `b_est'/`se_v2'
	local bnum = `b_est'
	local senum = `se_v2'
	local tnum = `b_est'/`se_v2'
}


	local stars ""
	if "`omitstars'" == "" {
		if `pvalue' < 0.10 local stars *
		if `pvalue' < 0.05 local stars **
		if `pvalue' < 0.01 local stars ***
	}

	local bstring `b_est'`stars'
	local sestring (`se')
	local tstring [`t']

	estadd local `statname'b "`bstring'" : p1_c`column'
	estadd local `statname'se "`sestring'" : p1_c`column'
	estadd local `statname't "`tstring'" : p1_c`column'

	estadd scalar `statname'b_num = `bnum' : p1_c`column'
	estadd scalar `statname'se_num = `senum' : p1_c`column'
	estadd scalar `statname't_num = `tnum' : p1_c`column'



	/*
		// Round Estimates to Whatever place we need
		scalar rm_rounded_estimate = round(b,.01)
		local rm_rounded_estimate : di %3.2f rm_rounded_estimate
		scalar rm_string_estimate = "`rm_rounded_estimate'"

		// Round Standard Errors
		scalar rm_rounded_se = round(se_v2,.01)
		local rm_rounded_se : di %3.2f rm_rounded_se
		scalar rm_string_se = "("+"`rm_rounded_se'"+")"

		//Add Stars for Significance 
		if p_val <= .01	{
			scalar rm_string_estimate = rm_string_estimate + "\nlsym{3}"
		}	

		if p_val>.01 & p_val<=.05 {
			scalar rm_string_estimate = rm_string_estimate + "\nlsym{2}"

		}

		if  p_val>.05 & p_val<=.1 {
			scalar rm_string_estimate = rm_string_estimate + "\nlsym{1}"

		}
		else {
			scalar rm_string_estimate = rm_string_estimate 
		}			
			
		// Add the results
		estadd local rm_b_str =rm_string_estimate
		estadd local rm_se_str =rm_string_se	
	}
	*/
end
