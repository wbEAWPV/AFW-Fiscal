*Run 00. master.do first to set up environment
*Be sure that the global country is well set as it defines $tempsim and $country

global country "GMB"

*Load itemized AFW tool for direct taxes 
use "$tempsim/income_tax_not_collapsed.dta", clear

if "$country" == "SEN" {
*pit_`income'`PIT'_net = pit_`income'`PIT' - `income'_cred
	keep hhid tax_bit1 tax_bit2 tax_bit3 tax_bit4 ///
			  pit_incsal_y11     pit_incsal_y21     pit_pension_inc1     pit_inc8_loyers_forPIT1     pit_inc_PIT22     ///
			  pit_incsal_y11_net pit_incsal_y21_net pit_pension_inc1_net pit_inc8_loyers_forPIT1_net pit_inc_PIT22_net

	gen CGU_afw = tax_bit1 + tax_bit2 + tax_bit3
	gen cgf_afw = tax_bit4
	gen irev_afw = pit_incsal_y11+pit_incsal_y21+pit_pension_inc1+pit_inc8_loyers_forPIT1
	gen reel_afw = pit_inc_PIT22
	gen income_tax_reduc_afw = pit_incsal_y11+pit_incsal_y21+pit_pension_inc1+pit_inc8_loyers_forPIT1+pit_inc_PIT22 - (pit_incsal_y11_net+pit_incsal_y21_net+pit_pension_inc1_net+pit_inc8_loyers_forPIT1_net+pit_inc_PIT22_net)
	collapse (sum) tax_bit1 - income_tax_reduc_afw, by(hhid)
}

if "$country" == "MRT" {
*pit_`income'`PIT'_net = pit_`income'`PIT' - `income'_cred
	keep hhid tax_bit1 tax_bit2 tax_bit3 tax_bit4 ///
			  pit_an_income_11  pit_an_income_11_net PropertyTax
	gen income_tax_1_afw = pit_an_income_11_net
	gen income_tax_2_afw = tax_bit1 + tax_bit2 + tax_bit3 + tax_bit4
	gen income_tax_3_afw = PropertyTax
	collapse (sum) tax_bit1 - income_tax_3_afw, by(hhid)
}
if "$country" == "GMB" {
	keep hhid tax_ind_1 tax_base_1 PIT_schedule_ind income_tax PIT
	gen income_tax_afw = income_tax
	gen tax_base_1_afw = tax_base_1
	gen PIT_schedule_ind_afw = PIT_schedule_ind
	gen PIT_afw = PIT
	gen tax_ind_1_afw = tax_ind_1
	collapse (sum) tax_base_1_afw income_tax_afw PIT_afw (mean) tax_ind_1_afw PIT_schedule_ind_afw, by(hhid)
	tostring hhid, replace format(%15.0f)
}

if "$country" == "SEN" {
    local baseline "Ref_2021_SEN"
	global dirtaxvars CGU reel irev cgf income_tax_reduc
}
if "$country" == "MRT" {
    local baseline "Ref_2019_MRT"
	global dirtaxvars income_tax_1 income_tax_2 income_tax_3
}
if "$country" == "GMB" {
    local baseline "Ref_2020_GMB"
    local baseline "Final_2020_ref_upd"
	global dirtaxvars hhweight income_tax dirtax_total
}

*Merging with individual level dataset on taxes from country-specific tool 
merge 1:1 hhid using "${path}/01-Data/0_country_tool/${country}/01-Data/4_sim_output/output_`baseline'.dta", keepusing(${dirtaxvars}) nogen //assert(matched)

foreach v in $dirtaxvars {
    cap gen ratio_`v' = `v'_afw / `v'
    cap gen flag_`v' = 1 if `v'==0 & `v'_afw!=0
}

sum ratio*
sum flag*



*Just to check the correct names of the country specific policies:
/*
if "$country" == "SEN" {
    local baseline "Ref_2021_SEN"
}
if "$country" == "MRT" {
    local baseline "Ref_2019_MRT"
}
if "$country" == "GMB" {
    local baseline "Ref_2020_GMB"
    local baseline "Final_2020_ref_upd"
}
use "${path}/01-Data/0_country_tool/${country}/01-Data/4_sim_output/output_`baseline'.dta", clear