/********************************************************************************
* Program: Merge All Subsidies
* Date: July 2025
* Version: 1.0
* Revision: 21/07/25 		By: Andres Gallegos
Modified: This file merges all subsidies data in a "verylong" setting (PRODUCT x SECTOR x HOUSEHOLDS x INFORMALITY x POURCENTAGE)
		  and then collapses amounts at the household level.
		  From presim (or 05. Spending Adjustment or 05. Tariff Duties):
			- 05_netteddown_expenses_SY: [hhid codpr pourcentage sector informal_purchase](id) [codpr_gasoline codpr_kerosene codpr_butane codpr_diesel codpr_water codpr_elec](0/1 or 0/share)
*********************************************************************************/


/***********************************************************************************
* MERGE DATA BY PRODUCT x SECTOR x HOUSEHOLDS
***********************************************************************************/

if $devmode== 1 {
	use "$tempsim/Tariffs_verylong.dta", clear
}
else{
	use `Tariffs_verylong', clear
}


if $devmode == 1 {
	merge m:1 sector using "$tempsim/io_ind_elec.dta",  assert(using matched) keep(matched) nogen 
	merge m:1 sector using "$tempsim/io_ind_fuels.dta", /*assert(matched using)*/ keep(1 3) nogen             //\\ <- This is a need to correct the IO_percentage file to the new IO
	merge m:1 sector using "$tempsim/io_ind_water.dta", assert(using matched) keep(matched) nogen             //\\    matrix, this requires some more time.
	merge m:1 hhid using "$tempsim/Elec_subsidies_direct_hhid.dta",  assert(using matched) keep(match) nogen
	merge m:1 hhid using "$tempsim/Water_subsidies_direct_hhid.dta", assert(using matched) keep(master match) nogen
	merge m:1 hhid using "$tempsim/fuel_dir_sub_hhid.dta",           assert(using matched) keep(match) nogen 
}
else {
	merge m:1 sector using `io_ind_elec',  assert(using matched) keep(matched) nogen 
	merge m:1 sector using `io_ind_fuels', /*assert(matched using)*/ keep(1 3) nogen               //\\ <- This is a need to correct the IO_percentage file to the new IO
	merge m:1 sector using `io_ind_water', assert(using matched) keep(matched) nogen               //\\    matrix, this requires some more time.
	merge m:1 hhid using `Elec_subsidies_direct_hhid',  assert(using matched) keep(match) nogen
	merge m:1 hhid using `Water_subsidies_direct_hhid', assert(using matched) keep(match) nogen
	merge m:1 hhid using `fuel_dir_sub_hhid',           assert(using matched) keep(match) nogen 
}


*Indirect effects
gen subsidy_fuel_indirect  = achats_avec_CD*fuel_ind_shock
gen subsidy_elec_indirect  = achats_avec_CD*elec_ind_shock
gen subsidy_water_indirect = achats_avec_CD*water_ind_shock

*Direct effects (correct duplicates because of informality*pourcentage*other_codpr)
rename subsidy_fuel_direct subsidy_fuel_direct_hhidlevel
gen subsidy_gasoline_dir = codpr_gasoline*subf_gasoline*pourcentage*pondera_informal
gen subsidy_pirogue_dir  = codpr_pirogue*subf_pirogue*pourcentage*pondera_informal
gen subsidy_kerosene_dir = codpr_kerosene*subf_kerosene*pourcentage*pondera_informal
gen subsidy_butane_dir   = codpr_butane*subf_butane*pourcentage*pondera_informal
gen subsidy_diesel_dir   = codpr_diesel*subf_diesel*pourcentage*pondera_informal
gen subsidy_super_dir    = codpr_super*subf_super*pourcentage*pondera_informal
recode subsidy_gasoline_dir subsidy_pirogue_dir subsidy_kerosene_dir subsidy_butane_dir subsidy_diesel_dir subsidy_super_dir (.=0)
gen subsidy_fuel_direct = subsidy_gasoline_dir+subsidy_pirogue_dir+subsidy_kerosene_dir+subsidy_butane_dir+subsidy_diesel_dir+subsidy_super_dir

replace subsidy_elec_direct  = codpr_elec*subsidy_elec_direct*pourcentage*pondera_informal
replace subsidy_water_direct = codpr_water*subsidy_water_direct*pourcentage*pondera_informal


*Subtracting direct effects first
gen achats_sans_subs_dir = achats_avec_CD - subsidy_elec_direct - subsidy_fuel_direct - subsidy_water_direct

if $asserts_ref2018 == 1{
	gen dif1 = achats_net_subind - achats_sans_subs_dir
	tab codpr if abs(dif1)>0.00001
	assert abs(dif1)<0.00001
	noi dis "{opt Assert of purchases - direct subsidies worked!}"
	drop dif1
}


*Subtracting indirect effects

gen achats_sans_subs = achats_sans_subs_dir - subsidy_fuel_indirect - subsidy_elec_indirect - subsidy_water_indirect


if $asserts_ref2018 == 1{
	gen dif2 = achats_net_excise-achats_sans_subs
	tab codpr if abs(dif2)>0.00001
	assert abs(dif2)<0.00001
	noi dis "{opt Assert of purchases - indirect subsidies worked!}"
	drop dif2
}

*We are interested in the detailed long version, to continue the confirmation process with excises and VAT

compress

preserve
	foreach var in pourcentage pondera_informal adjustment_factor subsidy_fuel_direct_hhidlevel subsidy_fuel_indirect subsidy_fuel_direct prix_electricite periodicite consumption_electricite subsidy1 subsidy2 subsidy3 eau_depbim eau_quantity3 eau_quantity2 eau_quantity1 eau_quantity value subsidy_eau_direct elec_ind_shock elec_tot_shock eau_ind_shock eau_tot_shock subsidy_elec_indirect subsidy_eau_indirect{
		cap drop `var'
	}

	if $devmode == 1 {
		save "$tempsim/Subsidies_verylong.dta", replace
	}
	tempfile Subsidies_verylong
	save `Subsidies_verylong'
restore

*Finally, we are only interested in the per-household amounts, so we will collapse the database:

collapse (sum) subsidy_fuel_direct subsidy_elec_direct subsidy_water_direct subsidy_elec_indirect subsidy_water_indirect subsidy_fuel_indirect, by(hhid)

egen subsidy_elec = rowtotal(subsidy_elec_direct subsidy_elec_indirect)
egen subsidy_fuel = rowtotal(subsidy_fuel_direct subsidy_fuel_indirect)
egen subsidy_water = rowtotal(subsidy_water_direct subsidy_water_indirect)


if "$country"=="GMB"{
	destring hhid, replace
}

if "$country"=="MRT"{
	replace subsidy_fuel_indirect=0
	drop subsidy_fuel
	egen subsidy_fuel = rowtotal(subsidy_fuel_direct subsidy_fuel_indirect)
	noi dis as error "IN THIS FIRST VERSION OF THE TOOL, MRT FUEL INDIRECT EFFECTS WILL BE 0. ONCE WE HAVE THE CORRECT WEIGHTS"
}


* Agricultural subsidy

if $devmode == 1 {
	merge 1:1 hhid using "$tempsim/agricole.dta", nogen
}
else {
	merge 1:1 hhid using `agricole', nogen
}


* Extra food subsidy (Temwine for Mauritania, empty for SEN and GMB)

merge 1:1 hhid using "$presim/05_dummy_subsidy_emel.dta", nogen

if $devmode == 1 {
    save "$tempsim/Subsidies.dta", replace
}
tempfile Subsidies
save `Subsidies'
