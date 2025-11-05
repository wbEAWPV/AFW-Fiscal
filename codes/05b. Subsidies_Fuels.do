/********************************************************************************
* Program: Subsidies Fuels
* Date: July 2025
* Version: 1.0
* Revision: 21/07/25 		By: Andres Gallegos
Modified: We should create the following files from presim:
			- 06_fuels: hhid(id) q_gasoline(annual) q_diesel(annual) q_kerosene(annual) q_butane(annual)
			- IO_Matrix: sector(id) sect_1-sect_n fixed(0/1) gasoline_sec(0/1 or 0/share) kerosene_sec(0/1 or 0/share) butane_sec(0/1 or 0/share) diesel_sec(0/1 or 0/share)
		Outputs:
			- `fuel_dir_sub_hhid'
			- `io_ind_fuels'
*********************************************************************************/

**********************************************************************************
noi dis as result " 3. Direct effect of fuel subsidies                          "
**********************************************************************************
use "$presim/06_fuels.dta", clear


*Compute subsidy receive for each tranche of consumption 

foreach fuelprod in butane kerosene gasoline diesel pirogue super {	
	gen subf_`fuelprod'	= 0
	if "${P4_2_`fuelprod'_mp}" != "" {
		replace subf_`fuelprod'= (${P4_2_`fuelprod'_mp}-${P4_2_`fuelprod'_sp})*q_`fuelprod' 
	}
}

egen subsidy_fuel_direct=rowtotal(subf_*)

*gen rarosSEN = (inlist(hhid,808,1310,3606,6612,9508,10005,10808,21607,21712,24207,25808,27805,28808,32101,32709,32716,36607,40309,43712,44206,44312,47910,51011,52705,54604,56609,57804,58212,59812)) //The problem happens when there are two or more products of fuel (208, 208, 304) but this has to be solved in 06e for Senegal only.

keep hhid subsidy_fuel_direct subf_butane subf_kerosene subf_gasoline subf_diesel subf_pirogue subf_super

if $devmode == 1 {
    save "$tempsim/fuel_dir_sub_hhid.dta", replace
}
tempfile fuel_dir_sub_hhid
save `fuel_dir_sub_hhid'



************************************************************************************
noi dis as result " 4. Indirect effects of Fuel subsidies                         "
************************************************************************************

// load IO
use "$presim/IO_Matrix.dta", clear			//What matrix should we use???? _elec is 2021, _new is 2023

*Shock
foreach fuelprod in butane kerosene gasoline diesel pirogue super {	
	gen shock_`fuelprod'	= 0
	if "${P4_2_`fuelprod'_mp}" != "" {
		replace shock_`fuelprod'= (${P4_2_`fuelprod'_mp}-${P4_2_`fuelprod'_sp})/${P4_2_`fuelprod'_mp}
	}
	replace shock_`fuelprod' = 0 if shock_`fuelprod'==.
	replace shock_`fuelprod' = shock_`fuelprod' * `fuelprod'_sec
}
egen shock=rowtotal(shock_*)

des sect_*, varlist 
local list "`r(varlist)'"

// Cost push 
costpush `list', fixed(fixed) price(shock) genptot(fuel_tot_shock) genpind(fuel_ind_shock) fix
	
keep sector fuel_ind_shock fuel_tot_shock

if $devmode == 1 {
    save "$tempsim/io_ind_fuels.dta", replace
}
tempfile io_ind_fuels
save `io_ind_fuels', replace
