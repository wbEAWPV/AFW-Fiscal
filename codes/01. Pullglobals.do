/*==============================================================================
	To do:			Read Parameters

	Editted by:		Madi Mangan
	Laste Updated:	June, 2025
===============================================================================*/


*===============================================================================
// Set globals in this do-file
*===============================================================================

*----- Sheet names
global sheet1 "AFW_Policy" 
global sheet2 "AFW_Parameters"
global sheet3 "AFW_Targeting"
global sheet4 "Products_${country}"

*===============================================================================
// Read Parameters
*===============================================================================

/*-------------------------------------------------------/
	1. Policy Names
/-------------------------------------------------------*/

*------ Policy
import excel "$xls_sn", sheet("$sheet1") firstrow clear

keep category varname varlabel
keep if varname != "."

* Policy names
levelsof varname, local(params)
foreach z of local params {
	levelsof varlabel if varname=="`z'", local(val)
	global `z'_lab `val'
}
	
* Policy categories
gen order = _n
bysort category (order): gen count = _n

keep category varname count
ren varname v_	
	
reshape wide v_, i(category) j(count)		
		
egen v = concat(v_*), punct(" ")	
gen globalvalue = strltrim(v)
		
levelsof category, local(params)
foreach z of local params {
	levelsof globalvalue if category=="`z'", local(val)
	global `z'_A `val'
}
	
drop v_1 v globalvalue
	
egen v = concat(v_*), punct(" ")	
gen globalvalue = strltrim(v)
		
levelsof category, local(params)
foreach z of local params {
	levelsof globalvalue if category=="`z'", local(val)
	global `z' `val'
}


/*-------------------------------------------------------/
	2. Parameters
/-------------------------------------------------------*/

*------ Settings
import excel "$xls_sn", sheet("$sheet2") first clear

keep  globalname globalvalue_${country}

isid globalname

levelsof globalname, local(params)
foreach z of local params {
	levelsof globalvalue if globalname == "`z'", local(val)
	global `z' `val'
}

/*-------------------------------------------------------/
	3. Targeting
/-------------------------------------------------------*/

*------ Settings
import excel "$xls_sn", sheet("$sheet3") first clear

keep  policy *_${country}
drop lab_${country}

ren * (policy var_dep var_loc var_mon)

drop if var_dep == . 

reshape long var_, i(policy var_dep) j(name, string)

drop if name == "dep"
tostring var_dep, replace

gen globalname = policy + "_" + name + "_" + var_dep
ren var_ globalvalue 

keep globalname globalvalue
isid globalname

levelsof globalname, local(params)
foreach z of local params {
	levelsof globalvalue if globalname == "`z'", local(val)
	global `z' `val'
}

*---- All params
forvalues i = 1/$n_progs {


	import excel "$xls_sn", sheet("$sheet3") first clear

	keep  policy *_${country}
	drop lab_${country}

	ren * (policy var_dep var_loc var_mon)

	drop if var_dep == . 

	reshape long var_, i(policy var_dep) j(name, string)

	drop if name == "dep"
	tostring var_dep, replace

	gen globalname = policy + "_" + name + "_" + var_dep
	ren var_ globalvalue 

		keep if policy == "am_prog_`i'"
		keep var_dep
		duplicates drop
		
		levelsof var_dep, local(var)
		global pr_div_loc_`i' "`var'"
	
}

/*-------------------------------------------------------/
	4. Parameters by product
/-------------------------------------------------------*/

import excel "$xls_sn", sheet("${sheet4}") first clear
keep codpr vatrate_ vatexem_ cdimp_ vatelas_ sector vatform_ cdrate_ percent_
 
* 	if ("$country" == "SEN") collapse (mean) vatrate_ vatexem_ cdimp_ vatelas_ sector vatform_ cdrate_ percent_ , by(codpr)

if ("$country" == "SEN") duplicates drop codpr, force 
 
levelsof codpr, local(products)
global products "`products'"

* Organise a table of parameters
ren * value_*
ren value_codpr codpr
reshape long value_, i(codpr) j(var_, string)

tostring codpr, replace
gen globalname = var_ + codpr
ren value_ globalvalue

* Store as parameters
keep globalname globalvalue

levelsof globalname, local(params)
foreach z of local params {
	levelsof globalvalue if globalname == "`z'", local(val)
	global `z' `val'
}			


