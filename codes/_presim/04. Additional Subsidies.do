/*
Regional Fiscal Microsimulation tool. 
	- Presimulation for subsidies. 
	Author				: Andres Gallegos
	Last Modified: 		: Andres Gallegos
	Date last modified	: 7th September, 2025
	
	Objective			: This dofile creates dummy databases for GMB and SEN, and brings Temwine to MRT (given that we are not modeling this subsidy). 
						  
*/

*********************************************************
* Senegal
*********************************************************

global country SEN
global con 			"${path}/01-Data/0_country_tool/${country}/01-Data/2_pre_sim"
global presim       "${path}/01-Data/2_pre_sim/${country}"
	
use  "${path}/01-Data/0_country_tool/${country}/01-Data/4_sim_output/output_Ref_2021_SEN.dta", clear

keep hhid
gen nm_subsidy=0

save  "$presim/05_dummy_subsidy_emel.dta", replace

*********************************************************
* Mauritania
*********************************************************

global country MRT
global con 			"${path}/01-Data/0_country_tool/${country}/01-Data/2_pre_sim"
global presim       "${path}/01-Data/2_pre_sim/${country}"
	
use  "${path}/01-Data/0_country_tool/${country}/01-Data/4_sim_output/output_Ref_2019_MRT.dta", clear

keep hhid subsidy_emel_direct
rename subsidy_emel_direct nm_subsidy

save  "$presim/05_dummy_subsidy_emel.dta", replace


*********************************************************
* The Gambia
*********************************************************

global country GMB
global con 			"${path}/01-Data/0_country_tool/${country}/01-Data/2_pre_sim"
global presim       "${path}/01-Data/2_pre_sim/${country}"
	
use  "${path}/01-Data/0_country_tool/${country}/01-Data/4_sim_output/output_Ref_2020_GMB.dta", clear

destring hhid, replace
keep hhid
gen nm_subsidy = 0

save  "$presim/05_dummy_subsidy_emel.dta", replace
