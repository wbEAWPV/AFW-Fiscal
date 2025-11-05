/*============================================================================*\
 Direct Transfers simulation
 Authors: Gabriel Lombo
 Start Date: January 2024
 Update Date: April 2025
\*============================================================================*/
  

*-------------------------------------
// Beneficiary Allocation: Tekavoul, Food Distribution, Shock Responsive
*-------------------------------------

set seed 123456789
global prog_hh 		""
global prog_ind 	""

forvalues i = 1/$n_progs {
	
	*local i = 2

	noi di "Program number `i', ${pr_label_`i'}, assigning by ${pr_div_`i'}"

	use  "$presim/07_dir_trans_PMT_`i'.dta", clear 
	
	//Depending on how the benefits of the progam are assigned we add information from menages at the household or individual level(Grabriel this step is unnecesary if you left in presim matched the databases of each program with the weights and hhsize, is not it?)
	if "${pr_type_`i'}" == "hh" {
		merge 1:1 hhid using "${presim}/01_menages.dta", keepusing(hhweight hhsize) // assert (matched)  We are waiting that Gabriel Check why is not working
		global prog_hh $prog_hh am_prog_`i'  // we define list of all the programs at household level 
	} 
	else {
		merge m:1 hhid using "${presim}/01_menages.dta", keepusing(hhweight hhsize) // assert (matched) We are waiting that Gabriel Check why is not working
		global prog_ind $prog_ind am_prog_`i' // we define list of all the programs at household level  Why? 
	}
			
	gen benefsdep = .
	gen montantdep = . 

	// Defining amount and number of beneficiaries by departement	
	foreach j of global pr_div_loc_`i' {
		
		replace benefsdep = ${am_prog_`i'_loc_`j'} if departement == `j'
		replace montantdep = ${am_prog_`i'_mon_`j'} if departement == `j'		
	}
	
	*----- Why if all the lines of code are the same we have two separate codes here? 
	*----- Random
	if (${tar_PMT_`i'} == 0) {  
			
		bysort departement (pmt_seed_`i'): gen potential_ben= sum(hhweight) if eleg_`i'==1
			gen _e1=abs(potential_ben-benefsdep)
		
		bysort departement: egen _e=min(_e1)
		gen _icum=potential_ben if _e==_e1
			gen numicum = (_icum!=.)
			bysort departement numicum (_icum): gen rep = _n
			replace _icum = . if rep>1
		
		bysort departement: egen Beneficiaires_i=total(_icum)
		bysort departement: egen _icum2_sd=sd(_icum)
		
		assert _icum2_sd==.
			sum benefsdep if _icum!=.
			local realbenefs = r(sum)
		
		drop _icum2_sd _icum _e _e1 rep
		
		gen am = montantdep*(potential_ben<=Beneficiaires_i)
		gen beneficiaire = (potential_ben<=Beneficiaires_i)
			replace beneficiaire = 0 if benefsdep == 0 // This is a temporal fix that we should look at later. 
			replace am = 0 if benefsdep ==0
		drop Beneficiaires_i potential_ben numicum
				sum hhweight if eleg_`i'==1
				local potential = r(sum)
				sum beneficiaire [iw=hhweight]
				nois dis as text "Excel requested `realbenefs' beneficiary hh, and we assigned `r(sum)' of the potential `potential'"
				if `potential'<=`r(sum)'{
				nois dis as error "Potential beneficiaries are less than total beneficiaries. Check if assigning every potential beneficiary makes sense."
			}
	}
		
	*----- PMT
	if (${tar_PMT_`i'} == 1) {  
			
		bysort departement (PMT_`i' pmt_seed_`i'): gen potential_ben= sum(hhweight) if eleg_`i'==1
		gen _e1=abs(potential_ben-benefsdep)
		bysort departement: egen _e=min(_e1)
		gen _icum=potential_ben if _e==_e1
			gen numicum = (_icum!=.)
			bysort departement numicum (_icum): gen rep = _n
			replace _icum = . if rep>1
		bysort departement: egen Beneficiaires_i=total(_icum)
		bysort departement: egen _icum2_sd=sd(_icum)
		assert _icum2_sd==.
			sum benefsdep if _icum!=.
			local realbenefs = r(sum)
		drop _icum2_sd _icum _e _e1 rep
		gen am = montantdep*(potential_ben<=Beneficiaires_i)
		gen beneficiaire = (potential_ben<=Beneficiaires_i)
		replace beneficiaire = 0 if benefsdep == 0 // This is a temporal fix that we should look at later. 
		*replace am = 0 if benefsdep ==0
		drop Beneficiaires_i potential_ben numicum
			sum hhweight if eleg_`i'==1
			local potential = r(sum)
			sum beneficiaire [iw=hhweight]
			nois dis as text "Excel requested `realbenefs' beneficiary hh, and we assigned `r(sum)' of the potential `potential'"
			if `potential'<=`r(sum)'{
				nois dis as error "Check if assigning every potential beneficiary makes sense."
			}
	}
				
	gen am_prog_`i' = am
	ren beneficiaire beneficiaire_prog_`i'
	drop benefsdep montantdep
	drop am
		
	keep hhid am_prog_`i'
		
	if "${pr_type_`i'}" == "ind" {
		collapse (sum) am_prog_`i', by(hhid)
	} 		
		
	tempfile name_`i'
	save `name_`i'', replace
}

global prog_total $prog_hh $prog_ind // Gabriel,  why this global with all programs matter or is needed in this order? 

*-------------------------------------
// Join Data
*-------------------------------------

use `name_1'

local num : word count $prog_total
forvalues j = 2/`num' {
	merge 1:1 hhid using `name_`j'', nogen
}

merge 1:1 hhid using "${presim}/07_dir_trans_PMT_other.dta", nogen
format hhid %16.0f
gsort hhid


if $devmode== 1 {
    save "$tempsim/Direct_transfers.dta", replace
}
tempfile Direct_transfers
save `Direct_transfers'


