/*===========================================================================
Project:            Regional Tool
Authors:            Andrés Gallegos, Gabriel Lombo, Madi Mangan, w/ Moritz Meyer & Daniel Valderrama 
Program Name:       02. Income Tax.do
---------------------------------------------------------------------------
Comments:       	We should create the following file from presim:
						- 02_incomes_harmonized: [hhid s01q00a](id) income_variables abatement_dummies BIT1 BIT2 BIT3 BIT4
						- IO_Matrix: sector(id) sect_1-sect_n fixed(0/1) elec_sec(0/1 or 0/share)
					Outputs:
						- `Elec_subsidies_direct_hhid'
						- `io_ind_elec'
===========================================================================*/


use  "$presim/02_incomes_harmonized.dta", replace


/**********************************************************************************/
noi dis as result " 1. TAX ON INDEPENDENT BUSINESSES (CGU - IBAPP)    "
/**********************************************************************************/


*CÁLCULO DE LOS IMPUESTOS A SMALL BUSINESSES À LA CGU

forval BIT = 1/4 {
	forval thre = 1/4{
		foreach indic in rate max ceiling{
			dis as text "`BIT'-`indic'-`thre': ${P1_4_I`BIT'_`indic'`thre'}"
			if "${P1_4_I`BIT'_`indic'`thre'}"==""{
				global P1_4_I`BIT'_`indic'`thre' "."
				*dis as error "changed"
			}
			if "${P1_4_I`BIT'_floor_p}"==""{
				global P1_4_I`BIT'_floor_p "0"
			}
		}
	}
}

gen double tax_bit1=0
gen double tax_bit2=0
gen double tax_bit3=0
gen double tax_bit4=0

forval BIT = 1/4 {
	if "${P1_4_I`BIT'_income}"!="" {
		local min =0
		local max =${P1_4_I`BIT'_max1}
		local rate=${P1_4_I`BIT'_rate1}
		local plus=0
		dis "If income is between `min' and `max', I start from `plus' and add the `rate'% of the remaining money."
		replace tax_bit`BIT'=((${P1_4_I`BIT'_income}-`min')*`rate')+`plus' if ${P1_4_I`BIT'_income}>=`min' & ${P1_4_I`BIT'_income}<=`max' & BIT`BIT'==1
		
		forval thre = 2/4{
			local last =`thre'-1
			local plus=`plus'+((`max'-`min')*`rate')
			local min =${P1_4_I`BIT'_max`last'}
			local max =${P1_4_I`BIT'_max`thre'}
			local rate=${P1_4_I`BIT'_rate`thre'}
			dis "If income is between `min' and `max', I start from `plus' and add the `rate'% of the remaining money."
			dis ((${P1_4_I`BIT'_income}-`min')*`rate')+`plus'
			replace tax_bit`BIT'=((${P1_4_I`BIT'_income}-`min')*`rate')+`plus' if ${P1_4_I`BIT'_income}>=`min' & ${P1_4_I`BIT'_income}<=`max' & BIT`BIT'==1
		}
		
		replace tax_bit`BIT' = ${P1_4_I`BIT'_floor_p} if BIT`BIT'==1 & tax_bit`BIT'< ${P1_4_I`BIT'_floor_p} & ${P1_4_I`BIT'_income}!=0      //Minimum tax that has to be paid
		replace tax_bit`BIT' = 0 if tax_bit`BIT'<0.001
		replace tax_bit`BIT' = 0 if tax_bit`BIT' > ${P1_4_I`BIT'_ceiling} & ${P1_4_I`BIT'_income}!=.
		recode  tax_bit`BIT' (.=0)
	}
}

gen BIT = tax_bit1 + tax_bit2 + tax_bit3 + tax_bit4

/*********************************************************************************************/
noi dis as result " 2. PERSONAL INCOME TAXES 1 AND 2 "
/*********************************************************************************************/

forval PIT = 1/2 {
	forval abat = 1/3{
		foreach indic in rate max min{
			dis as text "`PIT'-`indic'-`abat': ${P1_`PIT'_abat`abat'_`indic'}"
			if "${P1_`PIT'_abat`abat'_`indic'}"==""{
				global P1_`PIT'_abat`abat'_`indic' .
				*dis as error "changed"
			}
		}
	}
	forval level = 1/10{
		foreach indic in rate max{
			dis as text "`PIT'-`level'-`abat': ${P1_`PIT'_`indic'`level'}"
			if "${P1_`PIT'_`indic'`level'}"==""{
				global P1_`PIT'_`indic'`level' .
				*dis as error "changed"
			}
		}
	}
	if "${P1_`PIT'_Y_min}"==""{
		global P1_`PIT'_Y_min 0  
	}
	if "${P1_`PIT'_Y_max}"==""{
		global P1_`PIT'_Y_max .
	}
}


foreach PIT in 1 2 {
	
	*Step 0: Fixing globals and creating variables
	if "$P1_`PIT'_incomes" == ""{
		continue
	}
	
	foreach income in ${P1_`PIT'_incomes} {
		cap drop `income'_c
		gen `income'_c = `income'												//Gen start of taxable base of income definition j
		recode `income'_c (.=0)
	}
	
	*Step 1: Apply abatements
	forval abat = 1/3{
		if "${P1_`PIT'_abat`abat'_incs}" == "" {
			continue
		}
		foreach income in ${P1_`PIT'_abat`abat'_incs} {
			cap drop `income'_r												//Gen start of abatement i applied to income definition j
			gen `income'_r = 0
			dis "`income'_r"
			replace `income'_r = `income' * ${P1_`PIT'_abat`abat'_rate}
			replace `income'_r = ${P1_`PIT'_abat`abat'_max} if `income'_r >= ${P1_`PIT'_abat`abat'_max} & ${P1_`PIT'_abat`abat'_max} !=.
			replace `income'_r = ${P1_`PIT'_abat`abat'_min} if `income'_r <= ${P1_`PIT'_abat`abat'_min} & ${P1_`PIT'_abat`abat'_min} !=.
			if "${P1_`PIT'_abat`abat'_cond}"!=""{
				replace `income'_r = 0 if ${P1_`PIT'_abat`abat'_cond} !=1
			}
			recode  `income'_r (.=0)
			*Apply reduction
			replace `income'_c = `income'_c - `income'_r
			replace `income'_c = 0 if `income'_c < 0
		}
	}
	
	*Step 2: Calculating individual taxes
	if "${P1_`PIT'_marginal}" == "1" {											// Marginal rates for PIT
		
		local min  = 0
		local max  = ${P1_`PIT'_max1}
		local rate = ${P1_`PIT'_rate1}
		local plus = 0
		*dis "If income is between `min' and `max', I start from `plus' and add the `rate'% of the remaining money."
		foreach income in ${P1_`PIT'_incomes} {
			sum `income'_c `income'
			gen pit_`income'`PIT' = 0
			replace pit_`income'`PIT' = ((`income'_c-`min')*`rate')+`plus' if `income'_c>=`min' & `income'_c<=`max'
		}
		forval thre = 2/10{
			local last = `thre'-1
			local plus = `plus'+((`max'-`min')*`rate')
			local min  = ${P1_`PIT'_max`last'}
			local max  = ${P1_`PIT'_max`thre'}
			local rate = ${P1_`PIT'_rate`thre'}
			*dis "If income is between `min' and `max', I start from `plus' and add the `rate'% of the remaining money."
			foreach income in ${P1_`PIT'_incomes} {
				replace pit_`income'`PIT' = ((`income'_c-`min')*`rate')+`plus' if `income'_c>=`min' & `income'_c<=`max'
			}
		}
		
		foreach income in ${P1_`PIT'_incomes} {
			replace pit_`income'`PIT' = 0 if `income' > ${P1_`PIT'_Y_max} | `income' < ${P1_`PIT'_Y_min}
		}
	}
	
	if "${P1_`PIT'_marginal}"=="0" {											// Block rates for PIT (for Mauritania!!!)
		
		local min  = 0
		local max  = ${P1_`PIT'_max1}
		local rate = ${P1_`PIT'_rate1}
		
		foreach income in ${P1_`PIT'_incomes} {
			sum `income'_c `income'
			gen pit_`income'`PIT' = 0				//Initialize tax variables
			replace pit_`income'`PIT' = (`income'_c*`rate') if `income'_c>=`min' & `income'_c<=`max'
		}
		forval thre = 2/10{
			local last = `thre'-1
			local min  = ${P1_`PIT'_max`last'}
			local max  = ${P1_`PIT'_max`thre'}
			local rate = ${P1_`PIT'_rate`thre'}
			*dis "If income is between `min' and `max', I start from `plus' and add the `rate'% of the remaining money."
			foreach income in ${P1_`PIT'_incomes} {
				replace pit_`income'`PIT' = (`income'_c*`rate') if `income'_c>=`min' & `income'_c<=`max'
			}
		}
	}
	
	*Step 3: Calculating tax credits
	if "${P1_`PIT'_parts}"=="1" { // each individual income receives credits: labor income1, labor income2, pensions 
		foreach income in ${P1_`PIT'_incomes} {
			*gen pit_`income'`PIT'_net = pit_`income'`PIT'-
			
			gen `income'_cred = 0
			forval t =1/12 {  // up to 12 parts of family credits 
				if "${P1_3_number`t'}"=="" {
					continue
				}
				local min =${P1_3_min`t'}
				local max =${P1_3_max`t'}
				local rate=${P1_3_rate`t'}
				local part=${P1_3_number`t'}
				replace `income'_cred=pit_`income'`PIT'*`rate' if nom_part_total==`part'
				replace `income'_cred=`min' if `income'_cred< `min' & nom_part_total==`part' & (pit_`income'`PIT'!=0 & pit_`income'`PIT'!=.)
				replace `income'_cred=`max' if `income'_cred> `max' & nom_part_total==`part' & (pit_`income'`PIT'!=0 & pit_`income'`PIT'!=.)
			}
			
			// Applying ratio and limiting deductions (in the regional tool, we will not have the ratio we had for Senegal)
			replace `income'_cred = pit_`income'`PIT' if `income'_cred>pit_`income'`PIT'

			// computing income tax net of discounts
			assert pit_`income'`PIT'!=. & `income'_cred!=.   //It's safe to do - and not rowtotal
			gen pit_`income'`PIT'_net = pit_`income'`PIT' - `income'_cred
			
		}
	}
	
	if "${P1_`PIT'_parts}"=="0" {
		foreach income in ${P1_`PIT'_incomes} {
			gen pit_`income'`PIT'_net = pit_`income'`PIT'
		}
	}
	
	*Step 4: Aggregating taxes
	gen PIT_`PIT'=0
	foreach income in ${P1_`PIT'_incomes} {
		replace PIT_`PIT' = PIT_`PIT' + pit_`income'`PIT'_net //Poner neto al final
	}
}

gen PIT = PIT_1+PIT_2


/**********************************************************************************/
noi dis as result " 3. Dividends Tax "
/**********************************************************************************/

if "$P1_6_rate"==""{
	global P1_6_rate 0
}
gen FinancialTax = income_financial* $P1_6_rate




/**********************************************************************************/
noi dis as result " 4. Property Tax "
/**********************************************************************************/

if "$P1_5_rate"==""{
	global P1_5_rate 0
}
if "$P1_5_abatement"==""{
	global P1_5_abatement 0
}

*Step 1. Apply abatement
replace property_value_base = property_value_base - $P1_5_abatement if proptax_abat_dummy==1
replace property_value_base = 0 if property_value_base < 0

*Step 2: Calculate tax
gen PropertyTax = property_value_base* $P1_5_rate




if $devmode== 1 {
    save "$tempsim/income_tax_not_collapsed.dta", replace
}

*Tax data collapsed 
collapse (sum) PIT BIT FinancialTax PropertyTax /*hhweight (mean) hhsize*/ , by(hhid)
*label var income_tax "Household Income Tax payment"
*label var trimf "Tax Rep. de l'Impot Min. Fiscal"
*label var cgf "Contribution Globale Foncière"

foreach var in PIT BIT FinancialTax PropertyTax {  //income_tax income_tax_reduc trimf cgf retenu_cap property_tax CGU reel irev
	replace `var'=0 if abs(`var')<0.001
}


merge 1:1 hhid using "$presim/02_dummy_trimf.dta", nogen 

foreach var in PIT BIT FinancialTax PropertyTax nm_dirtax{
	recode `var' (.=0)
}

if $devmode== 1 {
    save "$tempsim/income_tax_collapse.dta", replace
}

tempfile income_tax_collapse
save `income_tax_collapse'
