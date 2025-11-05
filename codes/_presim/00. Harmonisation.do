

/*
Regional Fiscal Microsimulation tool. 
	- Presimulation for excises and other indirect taxes and subsidies. 
	Author				: Madi Mangan
	Last Modified: 		: Madi Mangan
	Date last modified	: 04th, September 2025
	
	Objective			: This dofile is to adopt the consumption data (at product levels) for The Gambia, Senegal and Mauritania to run the Indirect taxes and subsidies Module
						  of the regional tool. 
						  
						: I will create a list of 10 excise clases. in some countries, some classes will be zero, this is where such group do not exist.   
*/

************************************************************************************ ***************/
noi dis as result " 1. Adjusting presimulation consumption for indirect taxes and subsidies                "
************************************************************************************ ***************

if "`c(username)'"=="gabriellombomoreno" {
	global path     	"/Users/gabriellombomoreno/Documents/WorldBank/Projects/01 AFW Fiscal"	
}

if "`c(username)'"=="manganm" {
	global path     	"/Users/manganm/Documents/World Bank/Regional Tool"	
}

if "`c(username)'"=="andre" {
	global path     	"C:/Users/andre/Dropbox/Senegal/103 AFW_Fiscal"	
}

if "`c(username)'"=="wb419055" {
	global path     	"C:/Users/wb419055/OneDrive - WBG/AWCF1/18 PROJECTS/103 AFW_Fiscal"	
}

if "`c(username)'"=="Andrés Gallegos" {
	global path     	"C:/Users/AndresGallegos/Dropbox/Senegal/103 AFW_Fiscal"	
}	



foreach l in MRT GMB SEN {
	global country "`l'"

	global presim       "${path}/01-Data/2_pre_sim/${country}"
	global tempsim      "${path}/01-Data/3_temp_sim"
	global data_out    	"${path}/01-Data/4_sim_output"
	global con 			"${path}/01-Data/0_country_tool/${country}/01-Data/2_pre_sim"
	


use "$presim/05_netteddown_expenses_SY.dta", clear 

************************************************************************************/
noi dis as result " 1.1. Assign products to specific excise classs                "
************************************************************************************
	
	* Senegal
if "$country"=="SEN" {
		
		cap drop alco nalco cafe sugar cig fats dairy cos textiles cement cons broths gasoline diesel kerosene

		cap gen alco = inlist(codpr,164,165,197,301,302)
		
		gen nalco = inlist(codpr,160,162,196)  //Loi 2018-10: Elle s'applique également aux jus obtenus à partir de fruits ou légumes (133)
	
		gen cafe = inlist(codpr,155,156, 157,180)
		
		gen tea = inlist(codpr,157,180)

		gen cig = inlist(codpr,201)	
	
		gen sugar = inlist(codpr,82,134,135) 
	
		gen fats = inlist(codpr,53,54,55,56,57,59,61,62,36,63,66,67,68,70,175)  // I added other fats here even thou they have a higher rates. 
	
		gen dairy = inlist(codpr,59,70,88,174,52,53,54,55,56,57,58)

		gen cos = inlist(codpr,321,417)	
		
		gen textiles = inlist(codpr,501,502,503,504,505,506,521,804,806,616)
	
		gen cement = inlist(codpr,603)
		
		gen cons = inlist(codpr,604,605)	
		
		gen broths = inlist(codpr,144,145)	
		
		gen other = inlist(codpr,36,63,66,67,68,70,175)
		
*** fuel products
		gen gasoline = inlist(codpr,208,209)
		gen diesel   = inlist(codpr,304)
		gen kerosene = inlist(codpr,202)			
}	
	
					
	* The Gambia
if "$country"=="GMB" {

		gen alco = inlist(codpr,108,109,689,730,807,905,1009,626,686,907,561)
		
		gen nalco = inlist(codpr,715,240,241,242,282,895,896,1026)	
	
		gen cafe = inlist(codpr,155,156)
	
		gen cig = inlist(codpr,621,617,14,1,2,4,5,15,70)
	
		gen sugar = inlist(codpr,1007,1008,717,718) 
	
		gen fats = inlist(codpr,408,711,173,633,154,155,104,105,106,107,541)
	
		gen dairy = inlist(codpr, 245,330,564,677,703,788,837,853,880,978)
		
		gen cos = inlist(codpr,963,544,418,865,262)	
		 
		gen textiles = inlist(codpr,537,538,539,639,932,933,934,9,87,547,548,549,550,551,552,553,554,555,556,557,558,559,560,649,654,1015,1016,1017,1018,1019,1020,1021,1022,1023,45,131,132,133,134,135,126,127,128,129,130.392,393,394,395,396,397,398,399400,401)	
		
		gen cement = inlist(codpr,155,156)
		
		gen cons = inlist(codpr,583,1006)	
		
		gen broths = inlist(codpr,523,473)	
		
		gen other = 0

*** fuel products
		gen gasoline = inlist(codpr,754)
		gen diesel   = inlist(codpr,276)
		gen kerosene = inlist(codpr,44)	
		
	preserve	
		gen q_water = 0
		replace q_water = depan if codpr==996
		collapse (sum) q_water, by(hhid)
		label var q_water "This spending has not been converted to quantities"
		gen water_group = ""
		save "$presim/07_water.dta", replace
	restore	
}	
	
	
	*Mauritania
if "$country"=="MRT" { 
	
		gen alco = inlist(codpr,412)
		
		gen nalco = inlist(codpr,172)	
	
		gen cafe = inlist(codpr,155,156)
	
		gen sugar = inlist(codpr,161,162,163,164,165,166) 
	
		gen cig = inlist(codpr,177,179,180)
		
		gen fats = inlist(codpr,160) 
	
		gen dairy = inlist(codpr,134,135,136,137,139,140,145,146,147,148,149,150)
		 
		gen cos = inlist(codpr,218,219)
	
		gen textiles = inlist(codpr,482,483,484,485,486,487,488,489,490,491,492)
	
		gen cement = inlist(codpr,469)	
		
		gen cons = inlist(codpr,457)
		
		gen broths = inlist(codpr,189)	
		
		gen other = 0
		
*** fuel products
		gen gasoline = inlist(codpr,255)
		gen diesel   = inlist(codpr,254)
		gen kerosene = inlist(codpr,234)	
		
		
	preserve
		gen q_water = 0
		replace q_water = achat_gross if codpr==374
		collapse (sum) q_water, by(hhid)
		label var q_water "This spending has not been converted to quantities"
		gen water_group = ""
		save "$presim/07_water.dta", replace
	restore
		
}	

/*	
if "$country" == "SEN" {
	gen other_exc = inlist(codpr,36,63,66,67,68,70,175)
	gen exp_other_exc = other_exc*achats_sans_subs
	gen ex_other_exc = exp_other_exc*0.12
}

if "$country" != "SEN" {
	foreach v in other_exc exp_other_exc ex_other_exc {
		gen `v' = 0
	}
}
*/	
************************************************************************************/
noi dis as result " 1.2. Assign products to specific energy expenditure                "
************************************************************************************
		
	if "$country"=="GMB"{
		gen codpr_gasoline = (codpr==754)
		gen codpr_pirogue = 0
		gen codpr_kerosene = (codpr==44)
		gen codpr_butane = 0
		gen codpr_diesel = (codpr==276)
		gen codpr_super = 0
		gen codpr_water = (codpr==996)
		gen codpr_elec = (codpr==326)
	}

	if "$country"=="MRT"{
		noi dis as error "MRT lacks pondera_informal variable in 05_netteddown_expenses_SY"
		*merge 1:1 hhid codpr sector informal_purchase using "$presim/05_netteddown_expenses_SY_othervars.dta" , nogen
		gen codpr_gasoline = (codpr==254)
		gen codpr_pirogue = 0
		gen codpr_kerosene = (codpr==234)
		gen codpr_butane = (codpr==233)
		gen codpr_diesel = (codpr==255)
		gen codpr_super = 0
		gen codpr_water = (codpr==374)
		gen codpr_elec = (codpr==376)
		recode pondera_informal depan (.=0) //THIS MISMATCH IS WEIRD, TALK WITH GABRIEL.
	}

	if "$country"=="SEN"{
		cap ren Secteur sector
		gen codpr_gasoline = (codpr==208 | codpr==209 | codpr==304) //*0.184575551
		gen codpr_pirogue = 0
		gen codpr_kerosene = (codpr==202)
		gen codpr_butane = (codpr==303)
		gen codpr_diesel = (codpr==208 | codpr==209 | codpr==304) //*0.815424449
		gen codpr_super = (codpr==208 | codpr==209 | codpr==304)
		gen codpr_water = (codpr==332)
		gen codpr_elec = (codpr==334)
		
		*When collapsing at the household level, I do not want duplicate effects for when I consume 2 of the 3 products in codpr
		replace codpr_gasoline = 0.5 if codpr_gasoline==1 & inlist(hhid,808,1310,3606,6612,9508,10005,10808,21607,21712,24207,25808,27805,28808,32101,32709,32716,36607,40309,43712,44206,44312,47910,51011,52705,54604,56609,57804,58212,59812)
		replace codpr_diesel = 0.5 if codpr_diesel==1 & inlist(hhid,808,1310,3606,6612,9508,10005,10808,21607,21712,24207,25808,27805,28808,32101,32709,32716,36607,40309,43712,44206,44312,47910,51011,52705,54604,56609,57804,58212,59812)
		replace codpr_super = 0.5 if codpr_diesel==1 & inlist(hhid,808,1310,3606,6612,9508,10005,10808,21607,21712,24207,25808,27805,28808,32101,32709,32716,36607,40309,43712,44206,44312,47910,51011,52705,54604,56609,57804,58212,59812)
	}	
	
************************************************************************************/
noi dis as result " 1.3. Adjust income definitions for replication purpose. this should be deleted later.                 "
************************************************************************************


	if "$country"=="MRT" {
		*gen achats_sans_subs = achats_net_excise	
	}
	
	if "$country"=="GMB" {
		*replace achats_net == achats_sans_subs 
	}	
	
	
save "$presim/05_expenses_verylong.dta", replace 	

		if "$country"=="SEN"{
			noi use "$con/07_water.dta", clear 
			gen water_group = "VillesNonAssainies"
			rename eau_quantity q_water
			
			save "$presim/07_water.dta", replace 
		}
		

************************************************************************************/
noi dis as result " 2. Standardize fuels, this imply names and quantities          "
************************************************************************************		
	if "$country"=="GMB"{
		use "$con/06_fuels.dta", clear
		rename q_petrol q_gasoline
		rename q_diesel q_diesel
		rename q_Kerosene q_kerosene
		gen q_pirogue=0
		gen q_super=0
		save "$presim/06_fuels.dta", replace 
	}

	if "$country"=="MRT"{
		use "$con/08_subsidies_fuel.dta", clear
		
		gen q_gasoline = c_gasoline / 43.64
		gen q_diesel = c_gasoil / 38.46
		gen q_butane = c_lpg / 41.376
		gen q_kerosene = 0
		gen q_pirogue=0
		gen q_super=0
		
		keep hhid q_*
		save "$presim/06_fuels.dta", replace 
	}

	if "$country"=="SEN"{
		use "$con/06_fuels.dta", clear
		rename q_pet_lamp q_kerosene
		gen q_gasoline = q_fuel*0.174635172521839		//See weights in SN_Sim_tool_VII_2025_Jun.xlsx    in the SenSim main folder
		gen q_diesel   = q_fuel*0.815424449
		gen q_super    = q_fuel*0.00994037799322985
		gen q_pirogue  = q_fuel*0
		save "$presim/06_fuels.dta", replace 
	}
	
	
************************************************************************************/
noi dis as result " 3. Standardize Electricity, this imply names and quantities          "
************************************************************************************			
	

		if "$country"=="SEN"{
			noi use "$con/05_Electricity_2021.dta", clear 
			gen electricity_group = ""
			replace electricity_group = "PDPP" if type_client==1 & prepaid_woyofal==0
			replace electricity_group = "WDPP" if type_client==1 & prepaid_woyofal==1
			replace electricity_group = "PDMP" if type_client==2 & prepaid_woyofal==0
			replace electricity_group = "WDMP" if type_client==2 & prepaid_woyofal==1
			replace electricity_group = "PDGP" if type_client==3 & prepaid_woyofal==0
			cap gen sector=Secteur
		}

		if "$country"=="GMB"{
			noi use "$con/08_subsidies_elect.dta", clear 
			gen electricity_group = ""
			replace electricity_group = "Domestic" if type_client==1
			replace electricity_group = "Social"   if type_client==2
			replace consumption_electricite = consumption_electricite*2
		}

		if "$country"=="MRT"{
			noi use "$con/08_subsidies_elect.dta", clear 
			gen electricity_group = ""
			replace electricity_group = "Domestic" if type_client==2
			replace electricity_group = "Social"   if type_client==1
		}
save "$presim/08_subsidies_elect.dta", replace 



	if "$country"=="GMB" {
		preserve
			use "$path//01-Data/0_country_tool/${country}/01-Data/3_temp_sim/Subsidies_verylong.dta", clear 
			keep hhid codpr sector achats_sans_subs informal_purchase
			ren achats_sans_subs excise_GMB
			save "$presim/08_subsidies_GMB_tool.dta", replace	
		restore
	}
	
	
	if "$country" == "SEN" {
		use "$path//01-Data/0_country_tool/${country}/01-Data/3_temp_sim/Excises_verylong_SEN.dta", replace
		ren Secteur sector
		ren excise_taxes excise_SEN
		keep hhid codpr sector informal_purchase excise_SEN
		merge 1:1 hhid codpr sector informal_purchase using "$path//01-Data/0_country_tool/${country}/01-Data/3_temp_sim/Excises_verylong_AFW.dta", nogen
		gen ex_other_fats = excise_SEN - excise_taxes
		keep hhid codpr sector informal_purchase ex_other_fats
		save "$presim/match_SEN_excise.dta", replace
	}

}
********************************************************* ********************************************************* ***************************************************
*																			THE END
********************************************************* ********************************************************* ***************************************************	

