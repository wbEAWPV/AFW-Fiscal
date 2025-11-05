/********************************************************************************
* Program: Agricultural Subsidies
* Date: July 2025
* Version: 1.0
* Revision: 21/07/25 		By: Andres Gallegos
Modified: We should create the following files from presim:
			- 01_menages: hhid(id) q_`input'(annual) seed_`input'(from presim)
		Outputs:
			- `agricole'
*********************************************************************************/

************************************************************************************
noi dis as result " 7. Agricultural Subsidies                                      "
************************************************************************************

if "$country"=="SEN"{
	set seed 1234
	use  "$presim/09_agric_subsidies.dta", clear // hh level dataset
	
	local aginputs $P4_4_g1_name $P4_4_g2_name $P4_4_g3_name $P4_4_g4_name $P4_4_g5_name $P4_4_g6_name $P4_4_g7_name $P4_4_g8_name $P4_4_g9_name $P4_4_g10_name $P4_4_g11_name $P4_4_g12_name $P4_4_g13_name
	
	local inputid = 0
	foreach input in `aginputs' {
		local ++inputid	
		cap gen qw_`input'= q_`input'*hhweight
		cap replace qw_`input'= 0.000001 if qw_`input'==0
		assignprogram ben_`input' if seed_`input'!=., sortseed(seed_`input') target(${P4_4_g`inputid'_target}) popweight(qw_`input') update
		gen montant_`input' = ${P4_4_g`inputid'_subsidy}*q_`input' if ben_`input'==1
		* THIS HELPS US REACH 100% SPENDING AND QUANTITIES, BY PARTIALLY GIVING SUBSIDY TO THE TURNING POINT HOUSEHOLD
		sort seed_`input' q_`input', stable
		gen qsum_`input' = sum(qw_`input')
		replace qsum_`input' = qsum_`input'-${P4_4_g`inputid'_target}
		gen qsum1_`input' = qsum_`input'[_n-1]
		replace qsum1_`input' = -${P4_4_g`inputid'_target} if qsum1_`input'==.
		replace montant_`input' = ${P4_4_g`inputid'_subsidy}*(-qsum1_`input')/hhweight if qsum_`input'>0 & qsum1_`input'<0 & seed_`input'!=.
		replace ben_`input'=1 if qsum_`input'>0 & qsum1_`input'<0 & seed_`input'!=. & ben_`input'!=.
		*
	}

	egen subsidy_agric = rowtotal(montant_*)

	keep hhid subsidy_agric
	tempfile agricole
	save `agricole', replace
	if $devmode == 1 {
		save "$tempsim/agricole.dta", replace
	}

}
else {
	dis as error "We are not calculating agricultural subsidies for $country due to lack of inputs and data. Please check if this can be solved in presim."
	use  "$presim/01_menages.dta", clear
	gen subsidy_agric = 0
	keep hhid subsidy_agric
	tempfile agricole
	save `agricole', replace
	if $devmode == 1 {
		save "$tempsim/agricole.dta", replace
	}
}