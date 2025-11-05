/*============================================================================== =====================================================
  AFW Regional Microsimulation Tool; Indirect taxes - Custom Duties - CD
  Author: Madi Mangan
  Date: July, 2025
  Version: 1.0

 Notes: 
	*

	Extra Note: To run this tool, the following datasets are needed. 
		1. 
		2. Our model safely assumes that local produces does not pay custom duties. 
		3. All imported products payes their respective rates.  
*======================================================================================== ============================================ */


********************************************************* ********************************************************* ***************************************************
* 00.		Create the duty rates by product.
********************************************************* ********************************************************* ***************************************************		
********************************************************* ********************************************************* ***************************************************
* 01.		Load data
********************************************************* ********************************************************* ***************************************************		
		
		use "$presim/05_expenses_verylong.dta", clear 

		gen CD=.
		gen imported=.
		levelsof codpr, local(prods)
		foreach prod in `prods'{
		qui: replace CD      = ${cdrate_`prod'} if codpr==`prod'
		qui: replace imported = ${cdimp_`prod'} if codpr==`prod'
			}
		
		replace CD = 0 if imported ==0
		gen CD_direct = achats_net*CD // *imported * (1 - informal_purchase) NOTE!! we can later adjust this for a simulation with reduction in informality. 

********************************************************* ********************************************************* ***************************************************
* 02.		Income definition
********************************************************* ********************************************************* ***************************************************
		gen achats_avec_CD = (achats_net + CD_direct)
		gen dif4 = achats_net - achats_avec_CD
		tab codpr if abs(dif4)>0.0001
		*tabstat achats_net_subs achats_avec_CD, s(sum mean p50)
	
		if $devmode== 1 {
			save "$tempsim/Tariffs_verylong.dta", replace
		}
		tempfile Tariffs_verylong
			save `Tariffs_verylong'
		
********************************************************* ********************************************************* ***************************************************
* 03.		Data by household
********************************************************* ********************************************************* ***************************************************

		collapse (sum) CD_direct achats_net achats_avec_CD /*achats_avec_excises achats_sans_subs achats_sans_subs_dir*/, by(hhid)
		label var achats_avec_CD "Purchases after custom duties"
		destring hhid, replace

		if $devmode== 1 {
			save "${tempsim}/CustomDuties_taxes.dta", replace
		}
		else {
			save `CustomDuties_taxes', replace 
		}
********************************************************* ********************************************************* ***************************************************
*																			THE END
********************************************************* ********************************************************* ***************************************************		
		