/*============================================================================*\
 Project: Tool - Regional Tool
 To do: Validation of results
 Authors: Gabriel Lombo
 Start Date: March 2025
 Update Date: April 2025
\*============================================================================*/

clear all
macro drop _all

*===============================================================================
// Set Up - Parameters
*===============================================================================

if "`c(username)'"=="gabriellombomoreno" {
	global path     	"/Users/gabriellombomoreno/Documents/WorldBank/Projects/01 AFW Fiscal"	
}

if "`c(username)'"=="manganm" {
	global path     	"/Users/manganm/Documents/World Bank/Regional Tool"	
}

if "`c(username)'"=="andre" {
	global path     	"C:/Users/andre/Dropbox/Senegal/103 AFW_Fiscal"	
}

else if "`c(username)'"=="Andrés Gallegos" {
	global path     	"C:/Users/AndresGallegos/Dropbox/Senegal/103 AFW_Fiscal"	
}

if "`c(username)'"=="wb419055" {
	global path     	"C:/Users/wb419055/OneDrive - WBG/AWCF1/18 PROJECTS/103 AFW_Fiscal"	
}

*===============================================================================
// Common globals
*===============================================================================
global countries 	"SEN GMB MRT" //
* Reference Scenarios: Ref_2020_GMB, Ref_2021_SEN, Ref_2019_MRT

* AFW Fiscal folders

global presim			"${path}/01-Data/2_pre_sim" 
global tempsim			"${path}/01-Data/3_temp_sim"
global data_out    		"${path}/01-Data/4_sim_output"


*============================================================================*
//	1. Direct taxes and SSC  (Andres)
*============================================================================*

*  Policies names as in the regional tool
global var_dtr 		 "PIT BIT PropertyTax FinancialTax other_DT sscontribs_total ssc_health_1 ssc_health_2 ssc_risk ssc_family"  // Add your policies

forvalues i = 1/3 {
	
	global country : word `i' of ${countries}
	di "$country"
	global cst_output 		"${path}/01-Data/0_country_tool/${country}/01-Data/4_sim_output"

	*Policy names as in the country specific tools (CST)
	if "$country" == "GMB" {
		global var_dtr_cst 	 "income_tax BIT property_tax retenu_cap trimf sscontribs_total csh_ipm ssc_health_2 csh_css ssc_family"  // Add your policies
		global scenario_cst  "Ref_2020_GMB"	 // Add scenario name
	}
	if "$country" == "SEN" {
		global var_dtr_cst 	 "PIT BIT property_tax retenu_cap trimf sscontribs_total csh_ipm ssc_health_2 csh_css ssc_family"  // Add your policies
		global scenario_cst  "Ref_2021_SEN"	// Add scenario name
	}
	if "$country" == "MRT" {
		global var_dtr_cst 	 "income_tax_1 income_tax_2 income_tax_3 FinancialTax other_DT sscontribs_total ss_contrib_pub ss_contrib_pri ssc_risk ssc_family" // Add your policies
		global scenario_cst  "Ref_2019_MRT"	// Add scenario name
	}

	use "${cst_output}/output_${scenario_cst}.dta", clear
    *dsadsadsa
    *Grouping direct transfer policies that are not modeled in the regional tool 
    if "$country" == "MRT" {
        gen FinancialTax = 0
        gen other_DT = 0
        gen ssc_risk = 0
        gen ssc_family = 0
    }
    if "$country" == "SEN" {
        gen PIT = reel + irev - income_tax_reduc
        gen BIT = CGU + cgf
		gen ssc_health_2 = 0
		gen ssc_family = 0
    }
    if "$country" == "GMB" {
        gen BIT = 0
        gen property_tax = 0
        gen retenu_cap = 0
		gen ssc_health_2 = 0
		gen ssc_family = 0
    }

	keep hhid $var_dtr_cst
	ren ($var_dtr_cst) ($var_dtr)
	ren * *_cst
	ren hhid_cst hhid

	if "$country" == "GMB" {
		destring hhid, replace 
	}
	
	tempfile data_1_$country
	save `data_1_$country', replace

	
}

*============================================================================*
//	2. Direct transfers  (Gabriel)
*============================================================================*

*  Policies names as in the regional tool
global var_dtr 		 "am_prog_1 am_prog_2 am_prog_3 am_prog_other"  // Add your policies

forvalues i = 1/3 {
	
	global country : word `i' of ${countries}
	di "$country"
	
	*global country	"MRT"
	
	global cst_output 		"${path}/01-Data/0_country_tool/${country}/01-Data/4_sim_output"

	if "$country" == "GMB" {
		global var_dtr_cst 	 "am_BNSF am_Cantine am_bourse am_prog_other_0"  // Add your policies
		global scenario_cst  "Ref_2020_GMB"	 // Add scenario name
	}
	if "$country" == "SEN" {
		global var_dtr_cst 	 "am_BNSF am_Cantine am_bourse am_prog_other_0"  // Add your policies
		global scenario_cst  "Ref_2021_SEN"	// Add scenario name
	}
	if "$country" == "MRT" {
		global var_dtr_cst 	 "am_prog_1 am_prog_2 am_prog_3 am_prog_other_0" // Add your policies
		global scenario_cst  "Ref_2019_MRT"	// Add scenario name
	}

	use "${cst_output}/output_${scenario_cst}.dta", clear
    
    *Grouping direct transfer policies that are not modeled in the regional tool 
    if "$country" == "MRT" {
        egen am_prog_other_0 = rowtotal(am_prog_2 am_prog_3 ss_ben_sa)
		
		drop am_prog_2 am_prog_3
		gen am_prog_3 = 0
		gen am_prog_2 = am_prog_4
		
		order hhid $var_dtr
		
    }
    if "$country" == "SEN" {
        gen am_prog_other_0 = am_subCMU
    }
    if "$country" == "GMB" {
        gen am_prog_other_0 = 0 
    }

	keep hhid $var_dtr_cst
	ren ($var_dtr_cst) ($var_dtr)
	ren * *_cst
	ren hhid_cst hhid

	if "$country" == "GMB" {
		destring hhid, replace 
	}

	tempfile data_2_$country
	save `data_2_$country', replace	
	
}

*============================================================================*
//	3. Subsidies   (Andres)
*============================================================================*

*  Policies names as in the regional tool
global var_dtr 		 "subsidy_elec subsidy_elec_direct subsidy_elec_indirect subsidy_fuel subsidy_fuel_direct subsidy_fuel_indirect subsidy_water subsidy_water_direct subsidy_water_indirect subsidy_agric subsidy_emel_direct"  // Add your policies

forvalues i = 1/3 {
	
	
	
	global country : word `i' of ${countries}
	di "$country"
	global cst_output 		"${path}/01-Data/0_country_tool/${country}/01-Data/4_sim_output"

	if "$country" == "GMB" {
		global var_dtr_cst 	 "subsidy_elec subsidy_elec_direct subsidy_elec_indirect subsidy_fuel subsidy_fuel_direct subsidy_fuel_indirect subsidy_eau subsidy_eau_direct subsidy_eau_indirect subsidy_agric subsidy_emel_direct"  // Add your policies
		global scenario_cst  "Ref_2020_GMB"	 // Add scenario name
	}
	if "$country" == "SEN" {
		global var_dtr_cst 	 "subsidy_elec subsidy_elec_direct subsidy_elec_indirect subsidy_fuel subsidy_fuel_direct subsidy_fuel_indirect subsidy_eau subsidy_eau_direct subsidy_eau_indirect subsidy_agric subsidy_emel_direct"  // Add your policies
		global scenario_cst  "Ref_2021_SEN"	// Add scenario name
	}
	if "$country" == "MRT" {
		global var_dtr_cst 	 "subsidy_elec subsidy_elec_direct subsidy_elec_indirect subsidy_fuel subsidy_fuel_direct subsidy_fuel_indirect subsidy_eau subsidy_eau_direct subsidy_eau_indirect subsidy_agric subsidy_emel_direct" // Add your policies
		global scenario_cst  "Ref_2019_MRT"	// Add scenario name
	}

	use "${cst_output}/output_${scenario_cst}.dta", clear
    
    *Grouping direct transfer policies that are not modeled in the regional tool 
    if "$country" == "MRT" {
        egen subsidy_eau = rowtotal(subsidy_eau_direct subsidy_eau_indirect)
        egen subsidy_agric = rowtotal(subsidy_inag_direct subsidy_inag_indirect)  //(AGV) MRT has 0 agricultural subsidy, but there is a weird "indirect" effect that I want to understand.
    }
    if "$country" == "SEN" {
        gen subsidy_emel_direct = 0
    }
    if "$country" == "GMB" {
        gen subsidy_emel_direct = 0 
    }

	keep hhid $var_dtr_cst
	ren ($var_dtr_cst) ($var_dtr)
	ren * *_cst
	ren hhid_cst hhid

	if "$country" == "GMB" {
		destring hhid, replace 
	}

	tempfile data_3_$country
	save `data_3_$country', replace
	
	
}

*============================================================================*
//	4. Indirect taxes  (Madi)
*============================================================================*
*  Policies names as in the regional tool
global var_dtr 		 "VAT_indirect VAT_direct excise_taxes CD_direct "  // Add your policies

forvalues i = 1/3 {
	
	global country : word `i' of ${countries}
	di "$country"
	global cst_output 		"${path}/01-Data/0_country_tool/${country}/01-Data/4_sim_output"

	if "$country" == "GMB" {
		global var_dtr_cst 	 "TVA_indirect TVA_direct excise_taxes Custom"  // Add your policies
		global scenario_cst  "Ref_2020_GMB"	 // Add scenario name
	}
	if "$country" == "SEN" {
		global var_dtr_cst 	 "TVA_indirect TVA_direct excise_taxes tariff_duties"  // Add your policies
		global scenario_cst  "Ref_2021_SEN"	// Add scenario name
	}
	if "$country" == "MRT" {
		global var_dtr_cst 	 "TVA_indirect TVA_direct excise_taxes CD_direct" // Add your policies
		global scenario_cst  "Ref_2019_MRT"	// Add scenario name
	}

	use "${cst_output}/output_${scenario_cst}.dta", clear
    
	if "$country" == "GMB" {
		destring hhid, replace
		gen Custom=0 
	}

	keep hhid $var_dtr_cst
	ren ($var_dtr_cst) ($var_dtr)
	ren * *_cst
	ren hhid_cst hhid
	
	tempfile data_4_$country
	save `data_4_$country', replace	
}

*============================================================================*
//	5. In-kind transfers  (Gabriel)
*============================================================================*

* Policies names as in the regional tool
global var_dtr 		 "education_inKind am_health"  // Add your policies


forvalues i = 1/3 {
	
	
	global country : word `i' of ${countries}
	di "$country"
	global cst_output 		"${path}/01-Data/0_country_tool/${country}/01-Data/4_sim_output"

	if "$country" == "GMB" {
		global var_dtr_cst 	 "education_inKind am_sante"  // Add your policies
		global scenario_cst  "Ref_2020_GMB"	 // Add scenario name
	}
	if "$country" == "SEN" {
		global var_dtr_cst 	 "education_inKind am_sante"  // Add your policies
		global scenario_cst  "Ref_2021_SEN"	// Add scenario name
	}
	if "$country" == "MRT" {
		global var_dtr_cst 	 "education_inKind am_health" // Add your policies
		global scenario_cst  "Ref_2019_MRT"	// Add scenario name
	}

	use "${cst_output}/output_${scenario_cst}.dta", clear

	keep hhid $var_dtr_cst
	ren ($var_dtr_cst) ($var_dtr)
	ren * *_cst
	ren hhid_cst hhid

	if "$country" == "GMB" {
		destring hhid, replace 
	}

	tempfile data_5_$country
	save `data_5_$country', replace	
	
	
}


*============================================================================*
//	6. Weights and misscellaneuos 
*============================================================================*


forvalues i = 1/3 {
	
	global country : word `i' of ${countries}
	di "$country"
	global cst_output 		"${path}/01-Data/0_country_tool/${country}/01-Data/4_sim_output"
	
	if "$country" == "GMB" {
		global scenario_cst  "Ref_2020_GMB"	 // Add scenario name
	}
	if "$country" == "SEN" {
		global scenario_cst  "Ref_2021_SEN"	// Add scenario name
	}
	if "$country" == "MRT" {
		global scenario_cst  "Ref_2019_MRT"	// Add scenario name
	}
	use "${cst_output}/output_${scenario_cst}.dta", clear

	keep hhid hhweight deciles_pc hhsize
	ren * *_cst
	ren hhid_cst hhid


	if "$country" == "GMB" {
		destring hhid, replace 
	}
	
	tempfile data_6_$country
	save `data_6_$country', replace	
	
}

*============================================================================*
//	6. Compilation 
*============================================================================*

forvalues i = 1/3 {
	
	global country : word `i' of ${countries}
	di "$country, `i'"
	
	use `data_1_${country}', clear
	
	di "$country, `i'"

	forvalues j = 2/6 {
		merge 1:1 hhid using `data_`j'_${country}', nogen assert(matched)
	}

	di "$country"

	sum *
	
	order hhid PIT_cst BIT_cst PropertyTax_cst FinancialTax_cst other_DT_cst ///
			sscontribs_total_cst ssc_health_1_cst ssc_health_2_cst ssc_risk_cst ssc_family_cst /// 
			am_prog_1_cst am_prog_2_cst am_prog_3_cst am_prog_other_cst ///
			subsidy_elec_cst subsidy_elec_direct_cst subsidy_elec_indirect_cst ///
			subsidy_fuel_cst subsidy_fuel_direct_cst subsidy_fuel_indirect_cst ///
			subsidy_water_cst subsidy_water_direct_cst subsidy_water_indirect_cst /// 
			subsidy_agric_cst subsidy_emel_direct_cst ///
			CD_direct_cst excise_taxes_cst VAT_direct_cst VAT_indirect_cst ///
			education_inKind_cst am_health_cst 
	
	save  "$presim/$country/val_output_Ref_Scenario.dta", replace

}




exit

*-#-*-#-*-#-*-#-*-#-*-#-*-#-*-#-*-#-*-#-*-#-*-#-*-#-*-#-*-#-*-#-*-#-*-#-*-#-*-#-*-#-*-#-*-#-*-#-*-#-*-#-*-#-*-#-*-#-*-#-*-#-*-#-*-#-*-#-
* Please ignore everything after here
*-#-*-#-*-#-*-#-*-#-*-#-*-#-*-#-*-#-*-#-*-#-*-#-*-#-*-#-*-#-*-#-*-#-*-#-*-#-*-#-*-#-*-#-*-#-*-#-*-#-*-#-*-#-*-#-*-#-*-#-*-#-*-#-*-#-*-#-
/*

