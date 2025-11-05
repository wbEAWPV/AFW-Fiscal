/*===========================================================================
Project:            Regional Tool
Authors:            Andrés Gallegos, Gabriel Lombo, Madi Mangan, w/ Moritz Meyer & Daniel Valderrama 
Program Name:       02. Income Tax.do
---------------------------------------------------------------------------
Comments:           WE MOVED PRESIM TO ANOTHER DOFILE, IN _presim.
===========================================================================*/


use  "$presim/02_incomes_harmonized.dta", replace


/**********************************************************************************/
noi dis as result " 0. Transition des personnes à hauts revenus vers la formalité"
/**********************************************************************************/

foreach var of varlist inclab_ssc*{
	replace `var'=0 if `var'>=.
}


foreach group in P2_1 P2_2 P2_3 P2_4_l1 P2_4_l2 P2_4_l3 {
		if "${`group'_rate}"==""{
			global `group'_rate "0"
		}
		if "${`group'_max_base}"==""{
			global `group'_max_base "."
		}
}

gen ssc_risk = 0

forval risks=1/3{
	replace ssc_risk = inclab_ssc_risk*${P2_4_l`risks'_rate} if risk_level==`risks' & inclab_ssc_risk<${P2_4_l`risks'_max_base}
	replace ssc_risk = ${P2_4_l`risks'_max_base}*${P2_4_l`risks'_rate} if risk_level==`risks' & inclab_ssc_risk>=${P2_4_l`risks'_max_base}
}



gen ssc_family = 0

replace ssc_family = inclab_ssc_family*${P2_3_rate} if inclab_ssc_family<${P2_3_max_base}
replace ssc_family = ${P2_3_max_base}*${P2_3_rate} if inclab_ssc_family>=${P2_3_max_base}



gen ssc_health_1 = 0
gen ssc_health_2 = 0

forval regime=1/2{
	replace ssc_health_`regime' = inclab_ssc_health*${P2_`regime'_rate} if public_private==`regime' & inclab_ssc_health<${P2_`regime'_max_base}
	replace ssc_health_`regime' = ${P2_`regime'_max_base}*${P2_`regime'_rate} if public_private==`regime' & inclab_ssc_health>=${P2_`regime'_max_base}
}



collapse (sum) ssc_risk ssc_family ssc_health_1 ssc_health_2, by(hhid)

if $devmode== 1 {
    save "$tempsim/social_security_contribs.dta", replace
}

tempfile social_security_contribs
save `social_security_contribs'





