/*=============================================================================
	Project:		Direct Taxes - Figures Scenarios
	Author:			Gabriel 
	Creation Date:	Sep 3, 2024
	Modified:		
	
	Section: 		1. Names
					2. Relative Incidence
					3. Absolute Incidence
					4. Marginal Contributions
					5. Poverty and Inequality
	Note:
==============================================================================*/

clear all
macro drop _all

* Policies
local A1 "dirtax_total PIT BIT PropertyTax FinancialTax"
local A2 "sscontribs_total ssc_health_1 ssc_health_2 ssc_risk ssc_family"
local A3 "dirtransf_total am_prog_1 am_prog_2 am_prog_3"
local A4 "subsidy_total subsidy_elec subsidy_fuel subsidy_water subsidy_agric"
local A5 "indtax_total CD_direct excise_taxes Tax_VAT VAT_direct VAT_indirect"
local A6 "inktransf_total education_inKind am_educ_1 am_educ_2 am_educ_3 am_educ_4 am_educ_7 am_health"

global all_bypolicy "`A1' `A2' `A3' `A4' `A5' `A6'"

* Gabriel - Personal Computer
if "`c(username)'"=="gabriellombomoreno" {			
	global path     	"/Users/gabriellombomoreno/Documents/WorldBank/Projects/01 AFW Fiscal"
	
	global tool        "${path}/03-Outputs/`c(username)'" 
	global path_out     "/Users/gabriellombomoreno/Documents/WorldBank/Projects/03 R-Shiny/AFWCEQstats/data" 	

	global thedo     	"${path}/02-Scripts/`c(username)'/0-Fiscal-Model"
}
	
	*----- Figures parameters
	global numscenarios	3
	global proj_1		"Ref_AFW_GMB" 
	global proj_2		"Ref_AFW_SEN"
	global proj_3		"Ref_AFW_MRT"
	
	global policy		"$all_bypolicy"
	
	global income		"ymp" // ymp, yn, yd, yc, yf
	global income2		"yd"
	global reference 	"zref" // Only one
	
	*----- Data
	global data    		"${path}/01-Data/4_sim_output"

	*----- Tool
	global xls_sn 		"${tool}/AFW_Sim_tool_Output.xlsx"
	global xls_out    	"${path_out}/Indicators2.xlsx"	
	
	*----- Ado	
	global theado       "$thedo/ado"

	scalar t1 = c(current_time)
	

	
*==============================================================================
// Run necessary ado files
*==============================================================================

cap run "$theado//_ebin.ado"	


/*-------------------------------------------------------/
	2. Netcashflow
/-------------------------------------------------------*/

global allpolicy	"dirtax_total sscontribs_total dirtransf_total subsidy_total indtax_total inktransf_total"
forvalues scenario = 1/$numscenarios {

	*local scenario = 1

	import excel "$xls_sn", sheet("all${proj_`scenario'}") firstrow clear 
	
	keep if measure=="netcash" 
	gen keep = 0

	global policy2 	""
	foreach var in $allpolicy {
		replace keep = 1 if variable == "`var'_pc"
		global policy2	"$policy2 v_`var'_pc_${income}" 
	}	
	keep if keep ==1 

	replace variable=variable+"_ymp" if deciles_pc!=.
	replace variable=variable+"_yd" if deciles_pc==.

	egen decile=rowtotal(yd_deciles_pc deciles_pc)

	keep decile variable value
	*gen val2 = . 
	*replace val2 = value * (-100) if value < 0
	*replace val2 = value * (100) //if value >= 0
	rename value v_

	reshape wide v_, i(decile) j(variable) string
	drop if decile ==0
	
	keep decile *_${income}
	gen scenario = `scenario'
	order scenario decile $policy2
	ren (*) (scenario decile $allpolicy)
	
	tempfile inc_`scenario'
	save `inc_`scenario'', replace

}

clear
forvalues scenario = 1/$numscenarios {
	append using `inc_`scenario''
}

export excel "$xls_out", sheet(Netcash) first(variable) sheetreplace cell(A1)




/*-------------------------------------------------------/
	2. Relative Incidence
/-------------------------------------------------------*/

forvalues scenario = 1/$numscenarios {

	import excel "$xls_sn", sheet("all${proj_`scenario'}") firstrow clear 

	keep if measure=="netcash" 
	gen keep = 0

	global policy2 	""
	foreach var in $policy {
		replace keep = 1 if variable == "`var'_pc"
		global policy2	"$policy2 v_`var'_pc_${income}" 
		di "`var'"
	}	
	keep if keep ==1 

	replace variable=variable+"_ymp" if deciles_pc!=.
	replace variable=variable+"_yd" if deciles_pc==.

	egen decile=rowtotal(yd_deciles_pc deciles_pc)

	keep decile variable value
	gen val2 = . 
	*replace val2 = -1 * value * 100 if value < 0
	*replace val2 = value * 100 //if value >= 0 ***
	drop value
	rename val2 v_

	reshape wide v_, i(decile) j(variable) string
	drop if decile ==0
	
	keep decile *_${income}
	gen scenario = `scenario'
	order scenario decile $policy2
	ren (*) (scenario decile $policy)
	
	tempfile inc_`scenario'
	save `inc_`scenario'', replace

}

clear
forvalues scenario = 1/$numscenarios {
	append using `inc_`scenario''
}

export excel "$xls_out", sheet(Rel_Incidence) first(variable) sheetreplace cell(A1)

/*-------------------------------------------------------/
	3. Absolute Incidence
/-------------------------------------------------------*/

forvalues scenario = 1/$numscenarios {

	import excel "$xls_sn", sheet("all${proj_`scenario'}") firstrow clear 

	keep if measure=="benefits" 
	gen keep = 0

	global policy2 	""
	global policy3 	""	
	foreach var in $policy {
		replace keep = 1 if variable == "`var'_pc"
		global policy2	"$policy2 v_`var'_pc_${income}" 
		global policy3	"$policy3 in_v_`var'_pc_${income}" 
	}	
	keep if keep ==1 

	replace variable=variable+"_ymp" if deciles_pc!=.
	replace variable=variable+"_yd" if deciles_pc==.

	egen decile=rowtotal(yd_deciles_pc deciles_pc)

	keep decile variable value
	rename value v_
	
	reshape wide v_, i(decile) j(variable) string
	drop if decile ==0
	keep decile *_${income}

	foreach var in $policy2 {
		egen ab_`var' = sum(`var')
		gen in_`var' = `var' /ab_`var' //100/ab_`var'
	}
	
	preserve 
	
		keep decile v_*
		gen scenario = `scenario'
		order scenario decile $policy2
		ren (*) (scenario decile $policy)
		
		tempfile v_`scenario'
		save `v_`scenario'', replace	
	
	restore

	keep decile in_*
	gen scenario = `scenario'
	order scenario decile $policy3
	ren (*) (scenario decile $policy)
	
	tempfile inc_`scenario'
	save `inc_`scenario'', replace
	
}


clear
forvalues scenario = 1/$numscenarios {
	append using `inc_`scenario''
}

export excel "$xls_out", sheet(Ab_Incidence) first(variable) sheetreplace cell(A1)


clear
forvalues scenario = 1/$numscenarios {
	append using `v_`scenario''
}

export excel "$xls_out", sheet(Total) first(variable) sheetreplace cell(A1)
	
/*-------------------------------------------------------/
	4. Coverage
/-------------------------------------------------------*/
	
forvalues scenario = 1/$numscenarios {
	
	*local scenario = 1
	import excel "$xls_sn", sheet("all${proj_`scenario'}") firstrow clear 
	
	keep if measure=="coverage" 
	gen keep = 0

	global policy2 	""
	foreach var in $policy {
		replace keep = 1 if variable == "`var'_pc"
		global policy2	"$policy2 v_`var'_pc_${income}" 
	}	
	keep if keep ==1 
	
	replace variable=variable+"_ymp" if deciles_pc!=.
	replace variable=variable+"_yd" if deciles_pc==.
	*replace value = value * 100

	egen decile=rowtotal(yd_deciles_pc deciles_pc)

	keep decile variable value
	
	rename value v_

	reshape wide v_, i(decile) j(variable) string
	drop if decile ==0
	
	keep decile *_${income}
	gen scenario = `scenario'
	order scenario decile $policy2
	ren (*) (scenario decile $policy)
	
	tempfile cov_`scenario'
	save `cov_`scenario'', replace
	
}	

clear
forvalues scenario = 1/$numscenarios {
	append using `cov_`scenario''
}

export excel "$xls_out", sheet(Coverage) first(variable) sheetreplace 


	
/*-------------------------------------------------------/
	5. Marginal Contributions
/-------------------------------------------------------*/

forvalues scenario = 1/$numscenarios {

*local scenario = 1
	import excel "$xls_sn", sheet("all${proj_`scenario'}") firstrow clear 
	
	* Total values
	local len : word count $policy
	
	sum value if measure == "fgt0" & variable == "${income}_pc" & reference == "$reference"
	global pov0 = r(mean)
	 
	sum value if measure == "fgt1" & variable == "${income}_pc" & reference == "$reference"
	global pov1 = r(mean) 
	 
	sum value if measure == "gini" & variable == "${income}_pc"
	global gini1 = r(mean)
	
	* Variables of interest
	gen keep = 0
	global policy2 	"" 
	global policy3 	"" 	
	local counter = 1
	foreach var in $policy {
		replace keep = 1 if variable == "${income}_inc_`var'"
		global policy2	"$policy2 v_`var'_pc_${income}" 
		global policy3	"$policy3 cat_`counter'_`var'" 
		local counter = `counter' + 1
	}	
	
	keep if keep == 1
	
	keep if inlist(measure, "fgt0", "fgt1", "gini") 
	keep if inlist(reference, "$reference", "") 
	
	* Order the results
	gen o_variable = ""
	local len : word count $policy
	forvalues i = 1/`len' {
		local v : word `i' of $policy
		replace o_variable = "`i'_`v'"  if variable == "${income}_inc_`v'"
	}
	
	ren value val_
	keep o_variable measure val_
	gsort o_variable
	
	reshape wide val_, i(o_variable) j(measure, string)
	
	gen gl_fgt0 = $pov0
	gen gl_fgt1 = $pov1
	gen gl_gini = $gini1
	
	tempfile mc
	save `mc', replace

*-----  Kakwani	
	import excel "$xls_sn", sheet("conc${income}_${proj_`scenario'}") firstrow clear 
	
	global policy2: subinstr global policy " " "_pc ", all
	
	keep ${income}_centile_pc ${income}_pc $policy2
	keep if ${income}_centile_pc == 999
	
	ren * var_*
	ren var_${income}_centile_pc income_centile_pc
	ren var_${income}_pc income_pc
	
	reshape long var_, i(income_centile_pc) j(variable, string)
	ren var_ value_
	
	* Order the results
	gen o_variable = ""
	local len : word count $policy
	forvalues i = 1/`len' {
		local v : word `i' of $policy
		replace o_variable = "`i'_`v'"  if variable == "`v'_pc"
	}

	keep o_variable income_pc value_
	ren value value_k

	merge 1:1 o_variable using `mc', nogen
	
	gen scenario = `scenario'
	
	gen mc_fgt0 = gl_fgt0 - val_fgt0
	gen mc_fgt1 = gl_fgt1 - val_fgt1
	gen mc_gini = gl_gini - val_gini 
	gen mc_kakw = income_pc - value_k
	
	drop val_* gl_* income_pc value_k
	
	ren * cat_*
	ren (cat_scenario cat_o_variable) (scenario variable)
	
	reshape long cat_ , i(scenario variable) j(cat, string)
	
	*gen var = substr(variable, 3, length(variable))
	*drop variable
	
	ren variable var
	reshape wide cat_ , i(scenario cat) j(var, string)

	order scenario cat $policy3
	ren * (scenario indic $policy)
	
	tempfile pov_`scenario'
	save `pov_`scenario'', replace
}	

clear
forvalues scenario = 1/$numscenarios {
	append using `pov_`scenario''
}

export excel "$xls_out", sheet(Marginal) first(variable) sheetreplace 



/*-------------------------------------------------------/
	6. Poverty and Inequality
/-------------------------------------------------------*/

*------	Compare Scenarios
forvalues scenario = 1/$numscenarios {
	
*local scenario = 1	
	import excel "$xls_sn", sheet("all${proj_`scenario'}") firstrow clear 
	
	keep if inlist(measure, "fgt0", "fgt1", "fgt2", "gini", "theil")

	keep if inlist(reference, "zref", "line_1", "line_2", "line_3")

	keep if inlist(variable, "ymp_pc", "yn_pc", "yd_pc", "yc_pc", "yf_pc")
	
	gen scenario = `scenario'
	order scenario, first
	
	tempfile pov_`scenario'
	save `pov_`scenario'', replace
	
}	

clear
forvalues scenario = 1/$numscenarios {
	append using `pov_`scenario''
}

keep scenario measure value variable reference

export excel "$xls_out", sheet(Poverty) first(variable) sheetreplace 



/*-------------------------------------------------------/
	7. Organize indicators in one long table
/-------------------------------------------------------*/

*----- Indicators 1
global indicators "Netcash Rel_Incidence Ab_Incidence Total Coverage"
foreach var of global indicators {

	*local var "Rel_Incidence"
	import excel "$xls_out", sheet(`var') firstrow clear 

	ren * p_*
	ren p_scenario n_scenario
	ren p_decile measure

	reshape long p_, i(n_scenario measure) j(policy, string)
	
	ren p_ value
	gen indicator = "`var'"
	gen income = "$income"
	tempfile ind_`var'
	save `ind_`var'', replace

}

clear
foreach var of global indicators {
	append using `ind_`var''
}

gen simulation = ""
replace simulation = "$proj_1" if n_scenario == 1
replace simulation = "$proj_2" if n_scenario == 2
replace simulation = "$proj_3" if n_scenario == 3

drop n_scenario

gen reference = ""

tostring measure, replace

order indicator simulation policy measure income reference value
sort indicator simulation policy measure

tempfile all_1
save `all_1', replace

*export excel "$path_out/indicators.xlsx", sheet("Indicators1") first(variable) sheetreplace 



*----- Indicators 2
* Marginal contributions
import excel "$xls_out", sheet("Marginal") firstrow clear 

ren * p_*
ren p_scenario n_scenario
ren p_indic measure

reshape long p_, i(n_scenario measure) j(policy, string)
	
ren p_ value
gen indicator = "Marginal"
gen income = "$income"
gen reference = "zref"

tempfile ind_`var'
save `ind_`var'', replace

* Poverty by all incomes
import excel "$xls_out", sheet("Poverty") firstrow clear 

ren scenario n_scenario

gen income = ""
replace income = "ymp" if variable == "ymp_pc"
replace income = "yn" if variable == "yn_pc"
replace income = "yd" if variable == "yd_pc"
replace income = "yc" if variable == "yc_pc"
replace income = "yf" if variable == "yf_pc"

drop variable

gen policy = "All"

gen indicator = "Poverty"

tempfile ind2_`var'
save `ind2_`var'', replace

use `ind_`var'', clear
append using `ind2_`var''


gen simulation = ""
replace simulation = "$proj_1" if n_scenario == 1
replace simulation = "$proj_2" if n_scenario == 2
replace simulation = "$proj_3" if n_scenario == 3

drop n_scenario

order indicator simulation policy measure income reference value
sort indicator simulation policy measure

tempfile all_2
save `all_2', replace

*export excel "$path_out/indicators.xlsx", sheet("Indicators2") first(variable) sheetreplace 

use `all_1', clear
append using `all_2'

export excel "$path_out/indicators.xlsx", sheet("Indicators") first(variable) sheetreplace 











