/*============================================================================== =====================================================
  AFW Regional Microsimulation Tool; Indirect taxes - Excises
  Author		: Madi Mangan
  Date			: July, 2025
  Version		: 1.0
  last update	: 29 July, 2025

 Notes: 
	*

	Extra Note: To run this tool, the following datasets are needed. 
		1. 
*======================================================================================== ============================================ */


********************************************************* ********************************************************* ***************************************************
*** 00. load datasets
********************************************************* ********************************************************* ***************************************************

		if $devmode== 1 {
			use "$tempsim/Subsidies_verylong.dta", clear
		}
		else{
			use `Subsidies_verylong', clear
		}
	if (0) qui: do "${thedo}/_presim/06. Excises presim.do"
		
	if (0) qui: do "${thedo}/_presim/00. Income def.do"		

		if "$country"=="MRT" {
			*replace achats_sans_subs = achats_net_excise	// temporal fixed, this should be deleted later 
		}		
 
		if "$country"=="GMB" {
			merge m:m hhid codpr using "$presim/08_subsidies_GMB_tool.dta", nogen	// temporal fixed, this should be deleted later 
			replace achats_sans_subs = excise_GMB
		}	
 

********************************************************* ********************************************************* ***************************************************
*** 01. Set necessary globals
		global goods alco nalco cafe sugar cig fats dairy cos textiles cement cons broths gasoline diesel kerosene 
		global sin_list alco cig sugar fats 
		global exp achats_sans_subs
			
*** 02. generate expenditure by product for each excisable good. 		
			foreach product in $goods {
			gen exp_`product' = `product'*$exp 
		}	
	
*** 03. Create sin taxes by doubling excise duties for sin goods. 		
			if $sin_tax== 1 {
				foreach product in $sin_list {
					replace $sin_ex_`product' = $sin_ex_`product'
				}
			}

********************************************************* ********************************************************* ***************************************************		
*** 04. Compute excise taxes
********************************************************* ********************************************************* ***************************************************
	
	foreach p in $goods {
		cap drop ex_`p'
		 gen double ex_`p' = exp_`p' * ${sin_ex_`p'} + exp_`p' * (${sin_ex_`p'} - ${ref_ex_`p'})*${elas_ex_`p'}
		
	}
		
	if "$country" == "SEN" {
		merge 1:1 hhid codpr sector informal_purchase using "$presim/match_SEN_excise.dta", nogen
	}
	
	egen excise_taxes = rowtotal(ex_*)	
	gen achats_avec_excises = $exp + excise_taxes
	
*We are interested in the detailed long version, to continue the confirmation process with VAT
	compress
	if $devmode== 1 {
		save "$tempsim/Excises_verylong.dta", replace
	}
	tempfile Excises_verylong
	save `Excises_verylong'
		
********************************************************* ********************************************************* ***************************************************	
*** 05. Finally, we are only interested in the per-household amounts, so we will collapse the database:
********************************************************* ********************************************************* ***************************************************
			collapse (sum) exp_* ex_* excise_taxes, by(hhid)
			label var excise_taxes "Excise Taxes all"
			destring hhid, replace
			if $devmode== 1 {
				sum ex_*
				save "${tempsim}/Excise_taxes.dta", replace
			}

			tempfile Excise_taxes
			save `Excise_taxes'
			
********************************************************* ********************************************************* *******************************************************
*																			THE END
********************************************************* ********************************************************* *******************************************************
			
			