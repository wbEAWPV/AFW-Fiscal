/*============================================================================*\
 Project: Simulation Tool - Regional Tool
 To do: Standardize data
 Authors: Gabriel Lombo
 Start Date: March 2025
 Update Date: April 2025
\*============================================================================*/
  
  
clear all
macro drop _all



if "`c(username)'"=="gabriellombomoreno" {
	global path     	"/Users/gabriellombomoreno/Documents/WorldBank/Projects/01 AFW Fiscal"
	global user			"gabriellombomoreno"
}
if "`c(username)'"=="manganm" {
	global path     	"/Users/manganm/Documents/World Bank/Regional Tool"	
	global user			"manganm"
}
if "`c(username)'"=="andre" {
	global path     	"C:/Users/andre/Dropbox/Senegal/103 AFW_Fiscal"	
	global user			"andre"
}
if "`c(username)'"=="wb419055" {
	global path     	"C:\Users\wb419055\OneDrive - WBG\AWCF1\18 PROJECTS\103 AFW_Fiscal"
	global user			"wb419055"

}

	 
global presim		"${path}/01-Data/2_pre_sim" 
global tempsim		"${path}/01-Data/3_temp_sim" 


*============================================================================*
//	Presimualtion data of other countries into Regional Tool requeriments
*============================================================================*
  
*-------------------------------------
// Mauritania
*-------------------------------------

global country 		"MRT"
global cst_data		"${path}/01-Data/0_country_tool/${country}/01-Data/2_pre_sim" 



* Quality index
global qeduc_index1_u	1.2162
global qeduc_index1_r	0.8476
global ink_qh_1			0.8867
global ink_qh_2			0.8187
global ink_qh_3			0.9646
global ink_qh_4			0.6926
global ink_qh_5			0.7443
global ink_qh_6			0.9141
global ink_qh_7			1.0639
global ink_qh_8			0.5091
global ink_qh_9			0.9829
global ink_qh_10		0.8126
global ink_qh_11		0.8146
global ink_qh_12		0.8069
global ink_qh_13		1.5552


*----- Households

use "${cst_data}/01_menages.dta", clear 
save "${presim}/${country}/01_menages.dta", replace 


*----- Main Cash Transfer	

use "${cst_data}/07_dir_trans_PMT.dta", clear 
keep hhid departement eleg_1 PMT_1 pmt_seed_1
ren departement departement_1

save "${presim}/${country}/07_dir_trans_PMT_1.dta", replace // hhid departement eleg PMT pmt_seed


*----- School feeding program
use "${cst_data}/07_educ.dta", clear 
keep hhid region eleg_4 pmt_seed_4 

ren region departement_2
ren eleg_4 eleg_2
ren pmt_seed_4 pmt_seed_2

merge m:1 hhid using "${cst_data}/07_dir_trans_PMT.dta", keepusing(PMT_4) nogen

save "${presim}/${country}/07_dir_trans_PMT_2.dta", replace 


*----- Scolarship tertiary education

use "${cst_data}/07_educ.dta", clear 

gen eleg_3 = 0
gen departement_3 = 0
gen pmt_seed_3 = 0
gen PMT_3 = 0

keep hhid eleg_3 departement_3 pmt_seed_3 PMT_3

save "${presim}/${country}/07_dir_trans_PMT_3.dta", replace 


*----- In-kind transfers education
use "${cst_data}/inkind_transfers2.dta", clear 

keep hhid milieu level_1 level_2 level_3 level_4 level_7 

gen index = .
replace index = ${qeduc_index1_u} if milieu == 1
replace index = ${qeduc_index1_r} if milieu == 2

drop milieu

save "${presim}/${country}/inkind_education.dta", replace 

*----- In-kind transfers health
use "${cst_data}/inkind_transfers.dta", clear 

keep hhid ht_use location

ren ht_use ht_use_times

gen ht_use = 0
replace ht_use = 1 if ht_use_times > 0

gen index=.

* Assign Params
levelsof location, local(category)
foreach z of local category {
	replace index      = ${ink_qh_`z'} if location == `z'
}

keep hhid ht_use index

save "${presim}/${country}/inkind_health.dta", replace 


*-------------------------------------
// The Gambia
*-------------------------------------

global country 		"GMB"
global cst_data		"${path}/01-Data/0_country_tool/${country}/01-Data/2_pre_sim" 


*----- Households
use "${cst_data}/01_menages.dta", clear

destring hhid, replace

save "${presim}/${country}/01_menages.dta", replace


*----- Individuals
use "${cst_data}/07_educ.dta", clear

destring hhid, replace
ren idnum memb_no

keep hhid memb_no

*isid hhid memb_no

save "${presim}/${country}/01_individuals.dta", replace



*----- Main cash transfer
use "${cst_data}/07_dir_trans_PMT.dta", clear 

keep hhid PMT* pmt_seed* departement hhweight hhsize

destring hhid, replace
sum

gen eleg_1 = 1
ren PMT PMT_1
ren pmt_seed pmt_seed_1

save "${presim}/${country}/07_dir_trans_PMT_1.dta", replace 

*----- School feeding program
use "${cst_data}/07_educ.dta", clear 

ren idnum memb_no

gen eleg_2 = (ben_pre_school== 1 | ben_primary==1)

keep hhid memb_no eleg_2

merge m:1 hhid using "${cst_data}/07_dir_trans_PMT.dta", nogen keepusing(hhid PMT pmt_seed region)

ren PMT PMT_2 
ren region departement_2 // Check
ren pmt_seed pmt_seed_2 
destring hhid, replace

save "${presim}/${country}/07_dir_trans_PMT_2.dta", replace 


*----- Scolarship tertiary education
use "${cst_data}/07_educ.dta", clear 

ren idnum memb_no

gen eleg_3 = ben_tertiary == 1
gen departement_3 = ed_level == 4

ren ter_seed pmt_seed_3

keep hhid memb_no eleg_3 departement pmt_seed_3

merge m:1 hhid using "${cst_data}/07_dir_trans_PMT.dta", nogen keepusing(hhid PMT)

ren PMT PMT_3 
destring hhid, replace

format hhid %16.0f
gsort hhid

save "${presim}/${country}/07_dir_trans_PMT_3.dta", replace 


*----- In-kind transfers education
use "${cst_data}/07_educ.dta", clear 

destring hhid, replace

gen level_1 = ben_pre_school == 1 & pub_school == 1
gen level_2 = ben_primary == 1 & pub_school == 1
gen level_3 = ben_secondary == 1 & pub_school == 1
gen level_4 = 0
gen level_7 = ben_tertiary == 1 & pub_school == 1

gen index = 1

keep hhid index level_1 level_2 level_3 level_4 level_7

save "${presim}/${country}/inkind_education.dta", replace 


*----- In-kind transfers health
use "${cst_data}/07_health.dta", clear 

destring hhid, replace
keep hhid consult_prim consult_sec publichealth
gen ht_use = 0
replace ht_use = 1 if publichealth == 1
gen index = 1

keep hhid ht_use index

save "${presim}/${country}/inkind_health.dta", replace

*-------------------------------------
// Senegal
*-------------------------------------

global country 		"SEN"
global cst_data		"${path}/01-Data/0_country_tool/${country}/01-Data/2_pre_sim" 

*----- Households	
use "${cst_data}/02_Menages_2021.dta", clear
		
keep hhid hhsize hhweight dtot zref 

save "${presim}/${country}/01_menages.dta", replace


*----- Individuals
use "${cst_data}/01_Individuelle_2021.dta", clear

tostring grappe menage, replace
gen len = length(menage)
replace menage = "0" + menage if len == 1
gen hhid = grappe + menage
rename s01q00a memb_no
destring hhid, replace   

keep hhid memb_no

save "${presim}/${country}/01_individuals.dta", replace


*----- Direct transfers
use "${cst_data}/02_Menages_2021.dta", clear

keep hhid PMT RNU_PMT region random_hh_seed hhweight hhsize
	
sum	

gen eleg_1 = 1
ren RNU_PMT PMT_1
ren random_hh_seed pmt_seed_1
ren region departement_1
keep hhid PMT_1 eleg_1 departement_1 pmt_seed_1
order hhid, first

save "${presim}/${country}/07_dir_trans_PMT_1.dta", replace


*----- School feeding program
use "${cst_data}/01_Individuelle_2021.dta", clear

tostring grappe menage, replace
gen len = length(menage)
replace menage = "0" + menage if len == 1
gen hhid = grappe + menage
rename s01q00a memb_no
destring hhid, replace 
order hhid memb_no, first


gen eleg_2 = (ben_preschool_pub==1 | ben_primary_pub==1)

keep hhid memb_no eleg_2 school_seed

merge m:1 hhid using "${cst_data}/02_Menages_2021.dta", nogen keepusing(PMT region)

ren PMT PMT_2 
ren region departement_2 
ren school_seed pmt_seed_2

save "${presim}/${country}/07_dir_trans_PMT_2.dta", replace



*----- Scolarship tertiary education
use "${cst_data}/01_Individuelle_2021.dta", clear

tostring grappe menage, replace
gen len = length(menage)
replace menage = "0" + menage if len == 1
gen hhid = grappe + menage
rename s01q00a memb_no
destring hhid, replace 
order hhid memb_no, first

gen eleg_3 = .
replace eleg_3 = 1 if ben_tertiary_pri == 1
replace eleg_3 = 1 if ben_tertiary_pub == 1

gen departement_3 = .
replace departement_3 = 1 if ben_tertiary_pub == 1
replace departement_3 = 2 if ben_tertiary_pri == 1

ren ter_seed pmt_seed_3
replace pmt_seed_3 = ter2_seed - 1 if ben_tertiary_pri == 1

*br ter_seed ter2_seed if ben_tertiary_pri == 1


keep hhid memb_no eleg_3 pmt_seed_3 departement_3

merge m:1 hhid using "${cst_data}/02_Menages_2021.dta", nogen keepusing(PMT /*random_hh_seed region*/)

ren PMT PMT_3

save "${presim}/${country}/07_dir_trans_PMT_3.dta", replace


*----- In-kind transfers education
use "${cst_data}/01_Individuelle_2021.dta", clear 

tostring grappe menage, replace
gen len = length(menage)
replace menage = "0" + menage if len == 1
gen hhid = grappe + menage
destring hhid, replace  

gen level_1 = ben_preschool_pub == 1 & pub_school == 1
gen level_2 = ben_primary_pub == 1 & pub_school == 1
gen level_3 = ben_secondary_pub == 1 & pub_school == 1
gen level_4 = 0
gen level_7 = ben_tertiary_pub == 1 & pub_school == 1

gen index = 1

keep hhid level_1 level_2 level_3 level_4 level_7

save "${presim}/${country}/inkind_education.dta", replace 


*----- In-kind transfers health
use "${cst_data}/01_Individuelle_2021.dta", clear 

tostring grappe menage, replace
gen len = length(menage)
replace menage = "0" + menage if len == 1
gen hhid = grappe + menage
destring hhid, replace  

keep hhid consult_prim consult_sec publichealth
order hhid, first

gen index = 1
gen ht_use = . 
replace ht_use = 1 if publichealth == 1

keep hhid index ht_use

save "${presim}/${country}/inkind_health.dta", replace



*============================================================================*
//	Direct Transfers other group
*============================================================================*

*-------------------------------------
// Mauritania
*-------------------------------------

global country 		"MRT"
global cst_data		"${path}/01-Data/0_country_tool/${country}/01-Data/4_sim_output" 


use "${cst_data}/output_Ref_2019_MRT.dta", clear 

keep hhid am_prog_2 am_prog_3 ss_ben_sa

egen am_prog_other = rowtotal(am_prog_2 am_prog_3 ss_ben_sa)

keep hhid am_prog_other

save "${presim}/${country}/07_dir_trans_PMT_other.dta", replace


*-------------------------------------
// Senegal
*-------------------------------------

global country 		"SEN"
global cst_data		"${path}/01-Data/0_country_tool/${country}/01-Data/4_sim_output" 


use "${cst_data}/output_Ref_2021_SEN.dta", clear 

keep hhid am_subCMU

ren am_subCMU am_prog_other

keep hhid am_prog_other

save "${presim}/${country}/07_dir_trans_PMT_other.dta", replace

*-------------------------------------
// Gambia
*-------------------------------------

global country 		"GMB"
global cst_data		"${path}/01-Data/0_country_tool/${country}/01-Data/4_sim_output" 


use "${presim}/${country}/01_menages.dta", clear

gen am_prog_other = 0

keep hhid am_prog_other

save "${presim}/${country}/07_dir_trans_PMT_other.dta", replace


