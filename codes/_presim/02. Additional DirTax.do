/*
Regional Fiscal Microsimulation tool. 
	- Presimulation for direct taxes and SSC. 
	Author				: Andres Gallegos
	Last Modified: 		: Andres Gallegos
	Date last modified	: 5th September, 2025
	
	Objective			: This dofile creates dummy databases for GMB and MRT, and brings TRIMF to SEN (given that we are not modeling this tax). 
						  
*/

*********************************************************
* Senegal
*********************************************************

global country SEN
global con 			"${path}/01-Data/0_country_tool/${country}/01-Data/2_pre_sim"
global presim       "${path}/01-Data/2_pre_sim/${country}"
	
use  "${path}/01-Data/0_country_tool/${country}/01-Data/4_sim_output/output_Ref_2021_SEN.dta", clear

keep hhid trimf
rename trimf nm_dirtax

save  "$presim/02_dummy_trimf.dta", replace

*********************************************************
* Mauritania
*********************************************************

global country MRT
global con 			"${path}/01-Data/0_country_tool/${country}/01-Data/2_pre_sim"
global presim       "${path}/01-Data/2_pre_sim/${country}"
	
use  "${path}/01-Data/0_country_tool/${country}/01-Data/4_sim_output/output_Ref_2019_MRT.dta", clear

keep hhid
gen nm_dirtax = 0

save  "$presim/02_dummy_trimf.dta", replace


*********************************************************
* The Gambia
*********************************************************

global country GMB
global con 			"${path}/01-Data/0_country_tool/${country}/01-Data/2_pre_sim"
global presim       "${path}/01-Data/2_pre_sim/${country}"
	
use  "${path}/01-Data/0_country_tool/${country}/01-Data/4_sim_output/output_Ref_2020_GMB.dta", clear

destring hhid, replace
keep hhid
gen nm_dirtax = 0

save  "$presim/02_dummy_trimf.dta", replace
