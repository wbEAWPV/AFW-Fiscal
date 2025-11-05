/*============================================================================*\
 Presim Data - Mauritania
 Authors: Gabriel Lombo
 Start Date: March 2025
 Update Date: 
\*============================================================================*/

*===============================================================================
// Education
*===============================================================================

use "$presim/inkind_education.dta", clear 

merge m:1 hhid using "$presim/01_menages.dta", keep(3) keepusing(hhweight hhsize) nogen

*-------------------------------------
// Allocation
*-------------------------------------

gen uno = 1

local policy 1 2 3 4 7
foreach i of local policy {
	gen am_educ_`i' = .
	replace am_educ_`i' = ${am_educ_tot_`i'} if level_`i' == 1
}
	
*-------------------------------------
// Low quality reduction
*-------------------------------------

if $run_qeduc == 1 {

	ren am_educ_2 am_educ_2_prev
	gen am_educ_2 = am_educ_2_prev * index

	drop index
}

*-------------------------------------
// Data by household
*-------------------------------------

if "$data_educ" == "hh" {
	collapse (sum) am_educ*, by(hhid)
}
else {
	collapse (sum) am_educ*, by(hhid)
}

egen education_inKind = rowtotal(am*)

*egen education_general = rowtotal(am_educ_1 am_educ_2 am_educ_3 am_educ_4)

tempfile Transfers_InKind_Education
save `Transfers_InKind_Education'


global educ_var am_educ_1 am_educ_2 am_educ_3 am_educ_4 am_educ_7 //am_educ_8

*===============================================================================
// Health
*===============================================================================

use "$presim/inkind_health.dta", clear
 
merge m:1 hhid using "$presim/01_menages.dta", keep(1 3) keepusing(hhweight hhsize) nogen

tab ht_use [iw = hhweight]

*-------------------------------------
// Allocation
*-------------------------------------
 
gen am_health = 0
replace am_health = $mont_health_pc if ht_use == 1
 
/*
sum ht_use [iw = hhweight]

qui sum ht_use [iw=hhweight]
local ht_use `r(sum)' 

if "$type_health_pc" == "tot" {
	gen am_health = ${mont_health_pc} / `ht_use' if ht_use == 1	
}
else {
	gen am_health = $mont_health_pc if ht_use > 0
}

sum am_health
*/

di $mont_health_pc
/*sum am_health, d
 
gen benhe = am_health > 0 & am_health != .
 
tabstat am_health [aw = hhweight] , s(sum)
 */
*-------------------------------------
// Low quality reduction
*-------------------------------------

if $run_qhealth == 1 {

	ren am_health am_health_prev
	gen am_health = am_health_prev * index
	
	drop index		
}

format hhid %16.0f
sort hhid



*-------------------------------------
// Data by household
*-------------------------------------

if "$data_health" == "hh" {
	collapse (sum) am_health*, by(hhid)
} 
else {
	collapse (sum) am_health*, by(hhid)

}

egen health_inKind = rowtotal(am_health)

merge 1:1 hhid using `Transfers_InKind_Education', keep(3) nogen

if $devmode== 1 {
    save "$tempsim/Transfers_InKind.dta", replace
}

tempfile Transfers_InKind
save `Transfers_InKind'


