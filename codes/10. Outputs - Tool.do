/*--------------------------------------------------------------------------------
*--------------------------------------------------------------------------------
* Program: Program for the Impact of Fiscal Reforms - CEQ Senegal
* Author: 	JuanP. Baquero
* Date: 		11 Nov 2020
* Title: 	Generate Output for Simulation
*--------------------------------------------------------------------------------
*--------------------------------------------------------------------------------
*Note: Each output goes in long format  to a hidden sheet call all_`sheetnm'

Version 2. 
	- Change the refrence income for marginal contributions for all categories
	- Minor: commenting do-file and Making comments and Pendent
	- Added a new category for subsidies (before were together with transfers, not correct because their marginal contributions are measured differently

	
Pendent : 
_---------------------------------------------------------------------------------*/

if $save_scenario == 1 {	
	global sheetname "${scenario_name_save}"
}
if $save_scenario == 0 & $load_scenario == 1 {	
	global sheetname "${scenario_name_load}"
}
if $load_scenario == 0 & $save_scenario == 0 {	
	global sheetname "User_def_sce"
}

*---- Macros for household values 

		
	local Directaxes 		"${Directaxes}"
	local Contributions 	"${Contributions}" 
	local DirectTransfers   "${DirectTransfers}"
	local Subsidies         "${Subsidies}"
	local Indtaxes 			"${Indtaxes}"
	local InKindTransfers	"${InKindTransfers}" 

	local tax dirtax_total sscontribs_total `Directaxes' `Contributions' 
	local indtax indtax_total `Indtaxes' Tax_VAT
	local inkind inktransf_total `InKindTransfers' education_inKind
	local transfer dirtransf_total `DirectTransfers' 
	local Subsidies subsidy_total `Subsidies' subsidy_elec subsidy_fuel subsidy_water
	local income ymp yn yd yc yf 
	local concs `tax' `indtax' `transfer' `inkind' `income' `Subsidies'

	
*Macros at per-capita values 
	foreach x in tax indtax inkind transfer income concs Subsidies {
		local `x'_pc
		foreach y of local `x' {
			local `x'_pc ``x'_pc' `y'_pc 	
		}
	}
*Other macros 
	*local rank ymp_pc
	local pline zref line_1 line_2 line_3
	
*===============================================================================
		* Save Scenario
*===============================================================================

if $save_scenario == 1 {
	global c:all globals
	macro list c

	clear
	gen globalname = ""
	gen globalcontent = ""
	local n = 1
	foreach glob of global c{
		dis `"`glob' = ${`glob'}"'
		set obs `n'
		replace globalname = "`glob'" in `n'
		replace globalcontent = `"${`glob'}"' in `n'
		local ++n
	}

	foreach gloname in c thedo_pre theado thedo xls_sn data_out tempsim presim data_dev data_sn path S_4 S_3 S_level S_ADO S_StataSE S_FLAVOR S_OS S_OSDTL S_MACH save_scenario load_scenario devmode asserts_ref2018 {
		cap drop if globalname == "`gloname'"
	}

	export excel "$xls_out", sheet("p_${scenario_name_save}") sheetreplace first(variable)
	noi dis "{opt All the parameters of scenario ${scenario_name_save} have been saved to Excel.}"
	
	*Add saved scenario to list of saved scenarios
	import excel "$xls_out", sheet("legend") first clear cellrange(AH1)
	drop if Scenario_list == ""
	expand 2 in -1
	replace Scenario_list = "${scenario_name_save}" in -1
	duplicates drop
	gen ord = 2
	replace ord = 1 if Scenario_list == "Ref_2018"
	replace ord = 3 if Scenario_list == "User_def_sce"
	sort ord, stable
	drop ord
	
	export excel "$xls_out", sheet("legend", modify) cell(AH2)
}

	
	
*===============================================================================
		*Produce Concentration by centile_pc
*===============================================================================

/*
foreach rank in ymp  {
	
	use "$data_out/output", clear

	keep hhid `concs_pc' pondih *_centile_pc
	
	foreach x of local concs_pc {
		covconc `x' [aw=pondih] , rank(`rank'_pc)	//gini and concentration coefficients
		local _`x' = r(conc)
	}
	
	groupfunction [aw=pondih], sum(`concs_pc') by(`rank'_centile_pc) norestore
	qui count
	local _1 =r(N)
	local nnn=`_1'+ 1  //add one more obs, the total obs goes from 100 to 101
	set obs `nnn'
	replace `rank'_centile_pc = 0 in `nnn'
	
	sort `rank'_centile_pc
	putmata x = (`concs_pc') if `rank'_centile_pc!=0, replace 
	mata: x = J(1,cols(x),0) \ x  //generate a constant row, add to the top
	mata: x = x:/quadcolsum(x)  //divide each element by the column total
	mata: for(i=1; i<=cols(x);i++) x[.,i] = quadrunningsum(x[.,i])  //replace exisiting matrix by new elements
	
	getmata (`concs_pc') = x, replace
	
	qui count
	local _1 =r(N)
	local nnn=`_1'+ 1 //add one more obs, the total obs goes to 102
	set obs `nnn'
	
	replace `rank'_centile_pc = 999 in `nnn'
	foreach x of local concs_pc {
		replace `x' = `_`x'' in `nnn'  //replace the last observation with gini/concentration coefficient
	}	
	order `rank'_centile_pc, first
	
	export excel using "$xls_out", sheet("conc`rank'_${sheetname}") sheetreplace first(variable) // locale(C)  nolabel
}
*/

*===============================================================================
		*Netcash Position
*===============================================================================


{
* net cash ymp

	use "$data_out/output", clear
	
	keep hhid `concs_pc' pondih *_centile_pc deciles_pc 
	
	foreach x in `tax' `indtax'  {
		gen share_`x'_pc= -`x'_pc/ymp_pc
	}		
	
	foreach x in `transfer' `inkind' `Subsidies' {
		gen share_`x'_pc= `x'_pc/ymp_pc
	}
		
	*replace share_snit_hh_ae = - share_snit_hh_ae
	keep deciles_pc share* pondih	
		
	groupfunction [aw=pondih], mean (share*) by(deciles_pc) norestore
	
	reshape long share_, i(deciles_pc) j(variable) string
		gen measure = "netcash" 
		rename share_ value
	
	tempfile netcash_ymp
	save `netcash_ymp'

* net cash yd 	
	
	use "$data_out/output", clear
	
	foreach x in `tax' `indtax'  {
		gen share_`x'_pc= -`x'_pc/yd_pc
	}		
	
	foreach x in `transfer' `inkind' `Subsidies' {
		gen share_`x'_pc= `x'_pc/yd_pc
	}
	
	*replace share_snit_hh_ae = - share_snit_hh_ae
	keep yd_deciles_pc share* pondih	
		
	groupfunction [aw=pondih], mean (share*) by(yd_deciles_pc) norestore
	
	reshape long share_, i(yd_deciles_pc) j(variable) string
		gen measure = "netcash" 
		rename share_ value
	
	tempfile netcash_yd
	save `netcash_yd'
}		

*===============================================================================
		*Distributional indicators Gini, Theil, and FGT measures
		*Generate Income Concepts for Marginal Contribution
*===============================================================================

*run "$theado\sp_groupfunction.ado"

use "$data_out/output",  clear
		
		*Gabriela's 2022 suggestions for marginal contribution calculations:
		// (DV) For taxes ymp_pc is the counterfactual withouth the policy
		// (DV) For indirect taxes yd_pc is the counterfactual withouth the policy
		// (DV) For direct transfers ymp_pc is the counterfactual withouth the policy 
		// (DV) For subsidies yd_pc is the counterfactual withouth the policy 
		// (DV) For in-kind yc_pc is the counterfactual withouth the policy 
		
		//(AGV) I will generate all possible combinations, and fix these suggestions in Excel (allowing us to change them easily there)

*List of all new marginal contributinos store in income
local income2 ""

local aux1 `tax' `indtax'
foreach var of local aux1{
	replace `var' = -`var'
	replace `var'_pc = -`var'_pc
}

local aux2 `tax' `indtax' `transfer' `Subsidies' `inkind'
foreach inc in ymp yn yd yc {   //(AGV) I'm excluding final income because it does not make sense contributing to that
	foreach var of local aux2 {
		gen `inc'_inc_`var'=`inc'_pc+`var'_pc
		local income2 `income2' `inc'_inc_`var'   // Store incomes to marignal contribution calculation
	}
}

foreach var of local aux1{
	replace `var' = -`var'
	replace `var'_pc = -`var'_pc
}

sp_groupfunction [aw=pondih], gini(`income_pc' `income2') theil(`income_pc' `income2') poverty(`income_pc' `income2') povertyline(`pline')  by(all) 
tempfile poverty
save `poverty'

*===============================================================================
		*SP Indicators 
*===============================================================================

	
	* All 
* benefits, coverage beneficiaries by all	
	use "$data_out/output",  clear	

	sp_groupfunction [aw=pondih], benefits(`concs_pc') mean(`concs_pc') coverage(`concs_pc') beneficiaries(`concs_pc')  by(all)
	gen deciles_pc=0
	tempfile theall
	save `theall'

* benefits, coverage beneficiaries by deciles (ymp)	
	use "$data_out/output",  clear
	
	sp_groupfunction [aw=pondih], benefits(`concs_pc') mean(`concs_pc') coverage(`concs_pc') beneficiaries(`concs_pc')  by(deciles_pc)
*adding previous ones 	
	append using `poverty'
	append using `netcash_ymp'
	append using `theall'	
		
	gen concat = variable +"_"+ measure+"_" +reference+"_ymp_"+string(deciles_pc)
	order concat, first
	
	tempfile aux1
	save `aux1'
	
* benefits, coverage beneficiaries by yd
	use "$data_out/output",  clear	
	
	
	sp_groupfunction [aw=pondih], benefits(`concs_pc') mean(`concs_pc') coverage(`concs_pc') beneficiaries(`concs_pc')  by(yd_deciles_pc)
	
	
	append using `netcash_yd'
	
	gen concat = variable +"_"+ measure+"_"+"_yd_"+string(yd_deciles_pc)
	order concat, first
	
	append using `aux1'
	*append using `trans'
	
	
	export excel "$xls_out", sheet("all${sheetname}") sheetreplace first(variable)


