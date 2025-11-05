/*============================================================================*\
 Project: Tool - Regional Tool
 To do: Validation of results
 Authors: Gabriel Lombo
 Start Date: March 2025
 Update Date: April 2025
\*============================================================================*/

** SAME AS MASTER
/*
if "`c(username)'"=="gabriellombomoreno" {
	global path     	"/Users/gabriellombomoreno/Documents/WorldBank/Projects/01 AFW Fiscal"	
}
else if "`c(username)'"=="manganm" {
	global path     	"/Users/manganm/Documents/World Bank/Regional Tool"	
}
else if "`c(username)'"=="andre" {
	global path     	"C:/Users/andre/Dropbox/Senegal/103 AFW_Fiscal"	
}
else if "`c(username)'"=="wb419055" {
	global path     	"C:\Users\wb419055\OneDrive - WBG\AWCF1\18 PROJECTS\103 AFW_Fiscal"	
}


global tool         "${path}/03-Outputs/`c(username)'"	
global xls_out		"${tool}/AFW_Sim_tool_Output.xlsx"

global presim		"${path}/01-Data/2_pre_sim" 
global tempsim		"${path}/01-Data/3_temp_sim"
global data_out    	"${path}/01-Data/4_sim_output"

global countries 	"GMB MRT SEN"
*/
*============================================================================*
//	1. Parameters
*============================================================================*


* Policies
local dirtax		"PIT BIT PropertyTax FinancialTax"
local ssc			"sscontribs_total"
local dirtra		"am_prog_1 am_prog_2 am_prog_3 am_prog_other"
local subs			"subsidy_elec_direct subsidy_elec_indirect subsidy_fuel_direct subsidy_fuel_indirect subsidy_water_direct subsidy_water_indirect subsidy_agric"
local indtax 		"CD_direct excise_taxes VAT_direct VAT_indirect"
local inktra 		"education_inKind am_health" 
*local misscellaneuos "hhweight deciles_pc hhsize"
 
global var_dtr 	 "`dirtax' `ssc' `dirtra' `subs' `indtax' `inktra'" // `misscellaneuos'"  // Choose policies


*============================================================================*
//	2. Validation indicators
*============================================================================*

*----- Merge datasets: Master dataset is AFW tool and usng dataset is country specific tool created in the _presim/Validation 
use "${data_out}/output_${scenario_name_save}.dta", clear

keep hhid $var_dtr	
	
merge 1:1 hhid using "${presim}/val_output_Ref_Scenario.dta", nogen keep(3) keepusing($var_dtr)

local npolicies = length("${var_dtr}") - length(subinstr("${var_dtr}", " ", "", .)) + 1
	
* By observations
forvalues i = 1/`npolicies' {
	local w1 : word `i' of ${var_dtr}
		
	*gen c_`w1' = `w1' > 0 & `w1' != .	// Possitive values
	gen c_`w1' = `w1'_cst > 0 & `w1'_cst != .	// Possitive values
		
	gen d_`w1' = 1 if `w1' / `w1'_cst > -0.001 & `w1' / `w1'_cst < 0.001	// Dummy ok values
		
	gen dif_1_`w1' = abs(1 - `w1' / `w1'_cst)
	gen dif_2_`w1' = abs(1 - `w1'_cst / `w1')
 
	gen dif_`w1' = 0
	replace dif_`w1' = max(dif_2_`w1', dif_1_`w1') //dif_2_`w1' if dif_1_`w1' == .
		
	drop dif_1_`w1' dif_2_`w1'
}
	
sum d_am* dif_am*
	
merge 1:1 hhid using "${presim}/01_menages.dta", nogen keep(3) keepusing(hhweight hhsize)

save "$data_out/val_id_${scenario_name_save}.dta", replace

*----- Save Results

gen uno = 1
collapse (sum) c_* d_* (max) dif_*, by(uno)
sum c_am_prog_2* d_am_prog_2* dif_am_prog_2*	
	
if ("$country" == "SEN") {
	gen _mi_miss = 0
	mi extract 0, clear
}
	
local npolicies = length("${var_dtr}") - length(subinstr("${var_dtr}", " ", "", .)) + 1
forvalues i = 1/`npolicies' {
	local w1 : word `i' of ${var_dtr}
		
	gen k_`w1' = d_`w1' / c_`w1'
}	
	
reshape long k_ c_ d_ dif_, i(uno) j(category, string)
	
ren * v_*
ren v_category category
drop v_uno
	
reshape long v_ , i(category) j(indicator, string)

ren v_ value 
	
replace indicator = "wrong_obs" if indicator == "k_"
replace indicator = "dif_amount_obs" if indicator == "dif_"
replace value = 0 if value == .
		
gen concat = category + "_" + indicator
	
order concat, first

export excel "$xls_out", sheet("val_${scenario_name_save}") sheetreplace





