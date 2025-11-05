/*============================================================================== =====================================================
  AFW Regional Microsimulation Tool; Indirect taxes - Value Added Taxes - VAT
  Author: Madi Mangan
  Date: July, 2025
  Version: 1.0

 Notes: 
	*

	Extra Note: To run this tool, the following datasets are needed. 
		1. 
*======================================================================================== ============================================ */


/* --------------------------------------------------------------- -------------------------------------------------------------------
1.1  Creating the database for vatmat, with %exempted by Sector
 ----------------------------------------------------------------- ------------------------------------------------------------------- */
	*use "$presim/05_purchases_hhid_codpr.dta", clear
	use "$presim/05_netteddown_expenses_SY.dta", clear
	destring hhid, replace 
		merge m:1 hhid using "$presim/01_menages.dta" , nogen keepusing(hhweight)
		cap gen depan = achat_gross
		collapse (sum) depan [iw=hhweight], by(codpr) 
	tempfile prod_weights
	save `prod_weights'

		use `prod_weights', clear
		gen VAT=.
		gen exempted=.
		levelsof codpr, local(produits)
		foreach prod of local produits {
			replace VAT      = ${vatrate_`prod'} if codpr==`prod'
			replace exempted = ${vatexem_`prod'} if codpr==`prod'
		}
		
		preserve
			import excel "$xls_sn", sheet("${sheet4}") first clear
			keep codpr sector percent_
			ren sector_ sector
			drop if codpr==.
			tempfile VAT_original
			save `VAT_original'
		restore
		
		merge 1:m codpr using `VAT_original', keepusing(sector percent_) nogen
		replace depan      = 0 if depan==.
		replace depan      = depan*percent_

********************************************************* ********************************************************* ***************************************************
*** 1.2. Product data --> Sector data

		gen all=1
		collapse (mean) VAT (sum) all [iw=depan], by(sector exempted)
		ren all depan // this was to make VAT a weighted average but not depan
	tempfile VAT_sectors_exempted
	save `VAT_sectors_exempted', replace

		collapse (mean) VAT exempted [iw=depan], by(sector)
	tempfile sectors
	save `sectors', replace

*1.3. Sector data --> IO matrix y vatmat

	use "$presim/IO_Matrix.dta", clear	
	drop if sector==.
	merge 1:1 sector using `sectors', nogen
	
	rename exempted VAT_exempt_share
	gen VAT_exempt=0 if VAT_exempt_share==0
	replace VAT_exempt=1 if VAT_exempt_share>0 & VAT_exempt_share<.
	assert  VAT_exempt_share>0   if VAT_exempt==1 // all exempted sector should have a exemption share 
	assert  VAT_exempt_share==0  if VAT_exempt==0 // all non exempted sector should have either zero or missing  

*What to do with sectors with no VAT information? Assume they are no exempted & avg. rate
	count if VAT_exempt_share==.
	if `r(N)'>0{
		local numsect `r(N)'
		sum VAT
		local avgrate = round(`r(mean)'*100,0.01)
		dis as error "`numsect' sectors have no VAT information, we just assumed they are no exempted and assume the average VAT rate of `avgrate'%"
		dis as error "should we include this assumed VAT rate for missing sectors as a parameter in the tool?"
	}

	replace VAT_exempt_share=0 if VAT_exempt_share==.
	replace VAT_exempt      =0 if VAT_exempt      ==.
	sum VAT
	replace VAT=`r(mean)' if VAT==.
	
	tempfile io_original_SY 
	save `io_original_SY', replace 

	des sect_*, varlist  
	local list "`r(varlist)'"
	vatmat `list' , exempt(VAT_exempt) pexempt(VAT_exempt_share) sector(sector) 
	
********************************************************* ********************************************************* ***************************************************
*** 02.  Estimating indirect effects of VAT
********************************************************* ********************************************************* ***************************************************
	noi dis as result " 1. ndirect effect of Value Added Taxes - VAT"
	
	merge m:1 sector using "$presim/IO_Matrix.dta", assert(master matched) keepusing(fixed) nogen 

	merge m:1 sector using `io_original_SY', assert(master matched) keepusing(VAT) nogen

	*No price control sectors 
	gen cp=1-fixed

	*vatable sectors 
	gen vatable=1-fixed-exempted
	replace vatable = 0 if vatable==-1 //Sectors that are fixed and exempted are not VATable

	*Indirect effects 
	des sector_*, varlist 
	local list "`r(varlist)'"
	vatpush `list' , exempt(exempted) costpush(cp) shock(VAT) vatable(vatable) gen(VAT_indirect)

	keep sector VAT VAT_indirect fixed exempted
	rename VAT VAT_mean_sector

	tempfile ind_effect_VAT
	save `ind_effect_VAT'

********************************************************* ********************************************************* ***************************************************
***  03. Computing direct price effects of VAT
********************************************************* ********************************************************* ***************************************************
noi dis as result " 2. Direct effect of VAT policy"

		clear
		gen codpr=.
		gen VAT=.
		gen exempted=.
		local i=1
		foreach prod of global products {
			set obs `i'
			qui replace codpr	 = `prod' in `i'
			qui replace VAT      = ${vatrate_`prod'} if codpr==`prod' in `i'
			qui replace exempted = ${vatexem_`prod'} if codpr==`prod' in `i'
			local i=`i'+1
		}
		tempfile VATrates
		save `VATrates'

		if $devmode== 1 {
			use "$tempsim/Excises_verylong.dta", clear	
		}
		else{
			use `Excises_verylong', clear
		}
		
		merge m:1 codpr using `VATrates', nogen keep(1 3)
		
		if "$country"=="MRT" {
			replace achats_avec_excises = achats_net_VAT	// temporal fixed, this should be deleted later 
		}		

* Informality simulation assumption
		noi dis as result "Simulation with the assumption that informality decrease in ${informal_reduc_rate} %"

		egen aux = max(informal_purchase * achats_avec_excises * $informal_reduc_rate), by(hhid codpr)
		gen aux_f = (1 - informal_purchase) * (achats_avec_excises + aux) 
		gen aux_i = informal_purchase * (achats_avec_excises - aux)

		bysort hhid codpr: egen x_bef = total(achats_avec_excises)

		replace aux_f = 0 if aux_f == .
		replace aux_i = 0 if aux_i == .
		replace achats_avec_excises = aux_f + aux_i

		bysort hhid codpr: egen x_aft = total(achats_avec_excises)

		* Check
		*assert inrange(x_bef,x_aft*0.9999, x_aft*1.0001)
		drop aux aux_f aux_i x_bef x_aft 
		gen VAT_direct = achats_avec_excises * VAT * (1 - informal_purchase)
		
		if "$country"=="GMB" {
			replace VAT_direct = achats_avec_excises*VAT if import ==1
		}

* Include VAT exemptions to water and electricity
		noi dis as result "Now, we will take into account the VAT exemptions of water and electricity -- ''Tranche Sociale'' "
		
		gen VAT_exemption_elec = exempted_cons_elec * codpr_elec * VAT * (1 - informal_purchase)
		gen VAT_exemption_water = exempted_cons_water * codpr_water * VAT * (1 - informal_purchase) 
		replace VAT_direct = VAT_direct-VAT_exemption_elec-VAT_exemption_water
		
		drop exempted_cons_elec exempted_cons_water VAT_exemption_elec VAT_exemption_water //To make the database a little bit softer
		
*-------------------------------------------------------------------*
*		Merging direct and indirect VAT, and confirmation
*-------------------------------------------------------------------*

		merge m:1 sector exempted using `ind_effect_VAT', nogen  /*assert(match using)*/ keep(match)

		rename VAT_indirect VAT_indirect_shock
		gen VAT_indirect = VAT_indirect_shock * achats_avec_excise

		*Confirmation that the calculation is correct for the survey year policies:
		gen achats_avec_VAT = (achats_avec_excise + VAT_direct) * (1 + VAT_indirect_shock)
		gen dif5 = achat_gross - achats_avec_VAT
		tab codpr if abs(dif5)>0.0001


		gen achats_avec_VAT2 = achats_avec_excise + VAT_direct + VAT_indirect

		gen interaction_VATs = achats_avec_VAT-achats_avec_VAT2
		sum interaction_VATs, deta

		if $devmode== 1 {
			save "$tempsim/FinalConsumption_verylong.dta", replace
		}
		else{
			save `FinalConsumption_verylong', replace
		}

		*Finally, we are only interested in the per-household amounts, so we will collapse the database:

		collapse (sum) VAT_indirect VAT_direct interaction_VATs achats_avec_VAT achats_net, by(hhid)

		label var achats_net "Purchases before any policy"
		label var achats_avec_VAT "Purchases - All Subs. + Excises + VAT"

		*Correction: We will count the interaction as further indirect effects
		replace VAT_indirect = VAT_indirect + interaction_VATs
		drop interaction_VATs
		egen Tax_VAT = rowtotal(VAT_direct VAT_indirect)
		destring hhid, replace
		if $devmode== 1 {
			save "${tempsim}/VAT_taxes.dta", replace
		}

		tempfile VAT_taxes
		save `VAT_taxes'				
********************************************************* ********************************************************* ***************************************************
*																			THE END
********************************************************* ********************************************************* ***************************************************	
