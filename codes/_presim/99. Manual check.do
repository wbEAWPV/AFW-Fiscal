/*============================================================================*\
 Project: Tool - Regional Tool
 To do: Validation of results
 Authors: Gabriel Lombo
 Start Date: March 2025
 Update Date: April 2025
\*============================================================================*/

clear all
macro drop _all

global path     	"/Users/gabriellombomoreno/Documents/WorldBank/Projects/01 AFW Fiscal"

global tool         "${path}/03-Outputs/`c(username)'"	
global xls_out		"${tool}/AFW_Sim_tool_Output.xlsx"

global presim		"${path}/01-Data/2_pre_sim" 
global tempsim		"${path}/01-Data/3_temp_sim"
global data_out    	"${path}/01-Data/4_sim_output"


*global countries 	"MRT SEN GMB"

*============================================================================*
//	1. Parameters
*============================================================================*

local dirtax	"PIT BIT PropertyTax FinancialTax"
local ssc		"sscontribs_total"
local dirtra	"am_prog_1 am_prog_2 am_prog_3 am_prog_other"
local subs		"subsidy_elec_direct subsidy_elec_indirect subsidy_fuel_direct subsidy_fuel_indirect subsidy_water_direct subsidy_water_indirect subsidy_agric"
local indtax 	"CD_direct excise_taxes VAT_direct VAT_indirect"
local inktra 	"education_inKind am_health" 
 
*global var_dtr 	"$inktra"	// "`dirtax' `ssc' `dirtra' `subs' `indtax' `inktra'"


*============================================================================*
//	2. Manual check - comments
*============================================================================*

global scenario_name	"Ref_AFW_GMB"
global var_dtr			am_prog_3	

use "$data_out/val_id_${scenario_name}.dta", clear

sum *${var_dtr}*
tab1 d_${var_dtr} c_${var_dtr}

br hhid *${var_dtr}* if d_${var_dtr} == 1



*============================================================================*
//	2. Manual check - comments
*============================================================================*

global country			"GMB"
global cst_data    		"${path}/01-Data/0_country_tool/${country}/01-Data/2_pre_sim"

global scenario_name	"Ref_AFW_GMB"
global var_dtr			am_prog_3	


* Auxiliar Data
use  "$cst_data/07_educ.dta", clear

ren idnum memb_no
destring hhid, replace

egen max = sum(ben_tertiary), by(hhid)

keep hhid max

duplicates drop

* Check
merge m:1 hhid using "$data_out/val_id_${scenario_name}.dta", nogen keep(3) keepusing(*${var_dtr}*) 

sum *

merge 1:m hhid using "$presim/${country}/07_dir_trans_PMT_3.dta", nogen keep(3)

egen tag = tag(hhid)

tab d_${var_dtr} if tag == 1

br if d_${var_dtr} == 1 & tag == 1

gsort pmt_seed_3

tab eleg_3





*******
* Education
gen comp = ${var_dtr} == ${var_dtr}_cst

sum ${var_dtr}* if comp == 0 // No ceros

gen dif = abs(1 - ${var_dtr} / ${var_dtr}_cst)

sum dif // Max is almost cero

keep hhid ${var_dtr}* comp dif

br if comp == 0

br if ${var_dtr} > 0

tab dif





