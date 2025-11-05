/*
Regional Fiscal Microsimulation tool. 
	- Presimulation for direct taxes and SSC. 
	Author				: Andres Gallegos
	Last Modified: 		: Andres Gallegos
	Date last modified	: 13th August, 2025
	
	Objective			: This dofile is to adopt the income data at the individual level for The Gambia, Senegal and Mauritania. 
						  
*/

foreach country in GMB MRT SEN {

	global country `country'

	global con 			"${path}/01-Data/0_country_tool/${country}/01-Data/2_pre_sim"
	global presim       "${path}/01-Data/2_pre_sim/${country}"


	*********************************************************
	* Senegal
	*********************************************************


	if "$country"=="SEN"{
		
		use  "$con/03_Incomes_2021.dta", clear
		
		gen risk_level=1
		replace risk_level=2 if s04q30c==5 | s04q30c==15 | (s04q30c>=17 & s04q30c<=22) | s04q30c==25 | s04q30c==26 | s04q30c==33 | s04q30c==35 | s04q30c==36 | s04q30c==40  ///
						| s04q30c==41 | s04q30c==50 | s04q30c==51 | s04q30c==52 | s04q30c==60 | s04q30c==63  
		replace risk_level=3 if (s04q30c>=10 & s04q30c<=14) | s04q30c==16 | s04q30c==23 | s04q30c==24 | (s04q30c>=27 & s04q30c<=32) | s04q30c==34 | s04q30c==45  ///
						| s04q30c==61 | s04q30c==62 
		gen public_private = 2 //2=Private sector workers
		replace public_private = 1 if inlist(s04q31, 1, 2) //1=Public sector workers
		gen inclab_ssc_risk = inc1_formal + inc2_formal + inc3_formal
		gen inclab_ssc_family = inc1_formal + inc2_formal + inc3_formal
		gen inclab_ssc_health = inc1_formal + inc2_formal + inc3_formal
		replace inclab_ssc_health = 0 if !inlist(s04q31,1,2,3,4,6) //Housekeepers do not pay
		
		gen regime_g1=0
		*1. Self employed Prestataires de services
		replace regime_g1=1 if type_emploi1==2 & s04q30c>=49
		*2. Self employed Revendeurs de ciment et de denrées alimentaires
		replace regime_g1=2 if type_emploi1==2 & inlist(s04q30d,2330,2340,4711,4712,4721,4722,4723,4724,4725) & regime_g1==0
		*3. Self employed Autres catégories de producteurs et revendeurs
		replace regime_g1=3 if type_emploi1==2 & s04q30c<49 & regime_g1==0
		*CGU ne s'applique pas aux personnes physiques réalisant des operations de vente, lotissement, location d'immeubles et gestion immobilière
		replace regime_g1=0 if inlist(s04q30d,6810,6820)

		gen regime_g2=0
		*1. Self employed Prestataires de services
		replace regime_g2=1 if type_emploi2==2 & s04q52c>=55
		*2. Self employed Revendeurs de ciment et de denrées alimentaires
		replace regime_g2=2 if type_emploi2==2 & inlist(s04q52d,521,522,523,553,263,264) & regime_g2==0
		*3. Self employed Autres catégories de producteurs et revendeurs
		replace regime_g2=3 if type_emploi2==2 & s04q52c<55 & regime_g2==0 
		*CGU ne s'applique pas aux personnes physiques réalisant des operations de vente, lotissement, location d'immeubles et gestion immobilière
		replace regime_g2=0 if s04q52d==701 | s04q52d==702

		*I want to put both together, so I will use g1 when available, otherwise use g2, otherwise 0.
		gen regime_g = regime_g1
		replace regime_g = regime_g2 if regime_g==0

		gen BIT1 = (regime_g==1)
		gen BIT2 = (regime_g==2)
		gen BIT3 = (regime_g==3)
		gen BIT4 = 1
		
		foreach job in  1 2  {
			gen double incsal_y`job' = inc`job'_formal
			replace incsal_y`job'=int(incsal_y`job'/1000)*1000 //it was rounded, because law said: "For the calculation of the tax, the taxable income, rounded to thousands of lower franc" || This also helps with TRIMF because between 999,999 and 1,000,000, for instance, there is a gap that, if we don't round incsal, we could fall into
		}
		egen pension_inc = rowtotal(inc4_pension_retraite  inc5_pension_veuvage)
		gen inc8_loyers_forPIT=0
		
		
		
		** WE WILL CREATE THE NUMBER OF PARTS AS A HARCODED VARIABLE IN PRESIM FOR EACH COUNTRY
		** THAT IS, THE USER WILL NOT BE ABLE TO MANIPULATE IT

		global P1_3_part1 1
		global P1_3_part2 1.5
		global P1_3_part3 1.5
		global P1_3_part4 0.5
		global P1_3_part5 0.5
		global P1_3_part6 0.5
		global P1_3_Max_parts 5

		
		*--> Parts due to civil status
		gen nom_part1=$P1_3_part1 if inlist(s01q07,1,5,6,7)  // Célibataire, divorcé ou veuf 
		replace nom_part1=$P1_3_part3 if inlist(s01q07,2,3,4) // Mariée ou Union Libre
		replace nom_part1=$P1_3_part2 if inlist(s01q07,1,5,6,7) & pension_invalidite_widow==1 //Célibataire, divorcé ou veuf avec pension d'invalidité

		*--> Parts due to infants in charge (infants in the household)
		gen nom_part2=${P1_3_part6}*chi25_h

		*--> Parts due to having one income apportant 
		gen nom_part3=$P1_3_part5 if total_income_apportant==1 // Le contribuable est le seul conjoint a disposer de revenus imposables, ajoutez un demi-part 

		*--> Parts due to being Veuf avec des enfants à charge
		gen nom_part4=$P1_3_part4 if s01q07==5 & chi25_h>0 

		*--> Total number of parts 
		egen nom_part_total=rowtotal(nom_part1 nom_part2 nom_part3 nom_part4)	
		replace nom_part_total=$P1_3_Max_parts if nom_part_total>$P1_3_Max_parts
		
		
		*RENTAL INCOME FOR CGF
		replace inc8_loyers = int(inc8_loyers) //I want ONLY integers
		gen inc8_loyers_formal=inc8_loyers if inc3_formal!=0 // Tax filing assumption for rental income
		recode inc8_loyers_formal (.=0)
		*gen liable_CFPB = (inc8_loyers_formal > $CGF_threshold ) //Above 30 million, you don't pay CGF but CFPB
		*gen inc8_loyers_forPIT = inc8_loyers_formal if inc8_loyers_formal > $CGF_threshold
		*gen inc8_loyers_forCGF = inc8_loyers_formal if inc8_loyers_formal <= $CGF_threshold
		*recode inc8_loyers_forCGF inc8_loyers_forPIT (.=0)
		rename inc8_loyers_formal cgf_income
		rename inc9_financiers income_financial
		
		*SELF-EMPLOYED INCOME FOR CGU, CAPPED AT 50M FCFA
		forval i=1/3{
			gen inclab_bit`i' = inc3_formal
			replace inclab_bit`i' = 0 if inclab_bit`i'>50000000 
		}
		
		*SELF-EMPLOYED INCOME FOR REEL, STARTING AT 50M FCFA IF OUTSIDE CGU REGIMES
		gen inc_PIT2 = inc3_formal
		replace inc_PIT2 = 0 if inc_PIT2 <= 50000000 & regime_g!=0
		gen reel_simplif_dummy = (inc_PIT2<100000000)
		
		*PROPERTY TAX: TAXABLE VALUE OF THE PROPERTY, AND ABATEMENT DUMMY (IF ANY)
		recode loyerpred loyerpred_othermaison (.=0)  //In case there are missings
		egen is_pensioned = rowtotal(inc4_pension_retraite inc5_pension_veuvage)
		egen all_incomes = rowtotal(inc1_formal inc2_formal inc3_formal inc4_pension_retraite inc5_pension_veuvage cgf_income income_financial)
		replace loyerpred = 0 if is_pensioned>0 & all_incomes<1800000   //Pensioners are exempted to pay proptax on their OWN home IF their total income from last year do NOT surpass 1'8 million FCFA
		replace loyerpred_othermaison = 0 if cgf_income <= 30000000 //Above 30 million of rental income, you don't pay CGF but CFPB
		gen property_value_base = (loyerpred + loyerpred_othermaison)*12  //UNIFY BOTH OWN AND OTHER HOMES. Transform monthly to annual data
		replace property_value_base = 0 if s01q02!=1   //only one person (head) by households should pay
		replace property_value_base = 0 if inc3_formal==0 //INFORMALITY ASSUMPTION: Households pay property tax if they own a formal business.
		gen proptax_abat_dummy = (loyerpred*12 > 0)  //Abatement only applies to those paying for their own home
		
	}


	*********************************************************
	* Mauritania
	*********************************************************

	if "$country"=="MRT"{
		
		use  "$con/02_Income_tax_input.dta", clear
		merge 1:1 idind hhid using "$con/01_social_security.dta", nogen
		
		gen BIT1 = (regime_1==1)
		gen BIT2 = (regime_2==1)
		gen BIT3 = 0
		gen BIT4 = 0
		
		*MAURITANIA DOES NOT HAVE A FAMILY CREDITS SYSTEM (PARTS)
		gen nom_part_total = 0
		gen inclab_ssc_risk = 0
		gen inclab_ssc_family = 0
		gen inclab_ssc_health = an_income
		recode inclab_ssc_health (.=0)
		gen risk_level = 0
		gen public_private = 1 //1=Public sector workers
		replace public_private = 2 if public==0 //2=Private sector workers
		gen income_financial = 0
		
		*Identify household head, and make him pay the property tax (to not double count for each hh member)
		bys hhid : egen min_idind = min(idind)
		gen property_value_base = an_income_3
		bys hhid: egen regime_1_hh = max(regime_1)			//regime_1 varies across the same household, but when collapsing property tax, MRT takes max, i.e., the hh pays always
		replace property_value_base = 0 if idind!=min_idind
		replace property_value_base = 0 if tax_ind_3==0 | regime_1_hh==0 //I believe this was a typo in the country tool and must be regime_3, but this is how it works.
		drop min_idind regime_1_hh
		gen proptax_abat_dummy = 0
	}


	*********************************************************
	* The Gambia
	*********************************************************


	if "$country"=="GMB"{
		
		use  "$con/02_Income_tax_input.dta", clear
		
		destring hhid, replace
		noi dis as error "To reproduce current amount, I have to quantize the individual labor income as follows. In the future, check this and solve if needed"
		gen income_base_tomatch = tax_base_1
		replace income_base_tomatch = 24000 if tax_base_1>0 & tax_base_1<=24000
		replace income_base_tomatch = 34000 if tax_base_1>24000 & tax_base_1<=33500
		replace income_base_tomatch = 44000 if tax_base_1>33500 & tax_base_1<=42000
		replace income_base_tomatch = 54000 if tax_base_1>42000 & tax_base_1<=51000
		replace income_base_tomatch = 64000 if tax_base_1>51000 & tax_base_1<=59000
		replace income_base_tomatch = 74000 if tax_base_1>59000 & tax_base_1<.
		recode income_base_tomatch (.=0)
		gen inclab_ssc_risk = tax_base_1
		gen inclab_ssc_family = tax_base_1
		gen inclab_ssc_health = tax_base_1
		replace inclab_ssc_health = tax_base_1
		gen risk_level = 0
		gen public_private = 2 //1=Public sector workers, 2=Private sector workers
		gen income_financial = 0
		gen property_value_base = 0
		gen proptax_abat_dummy = 0
	}

	save  "$presim/02_incomes_harmonized.dta", replace



}