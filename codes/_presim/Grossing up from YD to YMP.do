
**********************************************
* GROSSING OUT FROM YD TO YMP
**********************************************

noi dis as error "In this file, Mauritania and The Gambia must calculate their market income plus pensions per capita (ymp_pc)"
noi dis as error "given that they are currently using disposable income (equated to per capita spending) as ymp_pc, and this is"
noi dis as error "a mistake. Please import your policies of direct taxes, SSC, and transfers, and gross up that disposable"
noi dis as error "income per capita. If you have any questions, please check the presim/Income_Aggregate_GU.do of Senegal."

foreach country in GMB MRT {
	use "${path}/01-Data/2_pre_sim/`country'/01_menages.dta", clear

	gen double yd_pre = dtot / hhsize
	rename yd_pre ymp_pc
	keep hhid ymp_pc

	save "${path}/01-Data/2_pre_sim/`country'/gross_ymp_pc.dta", replace
}

























