/*============================================================================*\
 AFW Fiscal - Regional Tool Fiscal Simulation
 Authors: Gabriel Lombo, Madi Mangan, Andrés Gallegos, Daniel Valderrama
 Start Date: March 2025
 Update Date: August 2025
\*============================================================================*/

clear all
macro drop _all
scalar t1 = c(current_time)

*===============================================================================
// Set Up - Parameters
*===============================================================================

if "`c(username)'"=="gabriellombomoreno" {
	global path     	"/Users/gabriellombomoreno/Documents/WorldBank/Projects/01 AFW Fiscal"	
	global country		"SEN"
}

if "`c(username)'"=="manganm" {
	global path     	"/Users/manganm/Documents/World Bank/Regional Tool"	
	global country		"GMB"
}

if "`c(username)'"=="andre" {
	global path     	"C:/Users/andre/Dropbox/Senegal/103 AFW_Fiscal"	
	global country		"SEN"
}

if "`c(username)'"=="Andrés Gallegos" {
	global path     	"C:/Users/AndresGallegos/Dropbox/Senegal/103 AFW_Fiscal"	
	global country		"GMB"
}

if "`c(username)'"=="wb419055" {
	global path     	"C:/Users/wb419055/OneDrive - WBG/AWCF1/18 PROJECTS/103 AFW_Fiscal"	
	global country		"MRT"
}

	*version 18

	* Data
	global presim       "${path}/01-Data/2_pre_sim/${country}"
	global tempsim      "${path}/01-Data/3_temp_sim"
	global data_out    	"${path}/01-Data/4_sim_output"
	global con 			"${path}/01-Data/0_country_tool/${country}/01-Data/2_pre_sim"
	
	* Tool
	global tool         "${path}/03-Outputs/`c(username)'"	// 	 
	global xls_sn 		"${tool}/AFW_Sim_tool.xlsx"
	global xls_out    	"${tool}/AFW_Sim_tool_Output.xlsx"	
	
	* Scripts	
	*global thedo     	"${path}/02-Scripts/`c(username)'" // 	this only temporal. 
	global thedo     	"${path}/02-Scripts" //
	global theado       "$thedo/ado"
	
	* Global about the type of simulation.
	global devmode = 1  		// Indicates if we run a developers mode of the tool.
								// In the developers mode all the data is being saved 
								// in .dta files in the subfolders in 3_temp_sim 
	global asserts_ref2018 = 0	
	
*===============================================================================
// Isolate Environment
*===============================================================================

sysdir set PLUS "${thedo}/ado"

local user_commands //Add required commands

foreach command of local user_commands {
	capture which `command'
	if _rc == 111 {
		ssc install `command'
	}
}
	
*===============================================================================
// Run ado files
*===============================================================================

local files : dir "$theado" files "*.ado"
foreach f of local files{
	 qui: cap run "$theado//`f'"
}

*===============================================================================
// Run simulation files
*===============================================================================

*-------------------------------------
// 00. Set up
*-------------------------------------
set rmsg on
qui: do "${thedo}/01. Pullglobals.do"

*-------------------------------------
// 01. P1 - Direct Taxes
*-------------------------------------

if (1) qui: do "${thedo}/02. Income Tax.do" 
else {
	use hhid using "${presim}/01_menages.dta", clear
	save "${tempsim}/income_tax_collapse.dta", replace
}

*-------------------------------------
// 02. P2 - Social Security Contributions
*-------------------------------------

if (1) qui: do "${thedo}/03. Social Security Contributions.do" 
else {
	use hhid using "${presim}/01_menages.dta", clear
	save "${tempsim}/social_security_contribs.dta", replace
}

*-------------------------------------
// 03. P3 - Direct Transfers
*-------------------------------------

if (1) do "${thedo}/04. Direct Transfers.do" 
else {
	use hhid using "${presim}/01_menages.dta", clear
	save "${tempsim}/Direct_transfers.dta", replace
}

*-------------------------------------
// 04. P4 - Indirect Taxes - Custom Duties
*-------------------------------------

if (1) qui: do "${thedo}/04. Indirect Taxes - Custom Duties.do" 
else {
	use hhid using "${presim}/01_menages.dta", clear
	save "${tempsim}/CustomDuties_taxes.dta", replace
}

*-------------------------------------
// 05. P5 - Indirect Subsidies
*-------------------------------------

if (1) {
	qui: do "${thedo}/05a. Subsidies_Electricity.do"
	qui: do "${thedo}/05b. Subsidies_Fuels.do"
	qui: do "${thedo}/05c. Subsidies_Water.do"
	qui: do "${thedo}/05d. Subsidies_Agric.do"
	qui: do "${thedo}/05e. Subsidies_Merge.do"
}
else {
	use hhid using "${presim}/01_menages.dta", clear
	save "${tempsim}/Subsidies.dta", replace
}

*-------------------------------------
// 06. P4 - Indirect Taxes - Excises 
*-------------------------------------

if (1) qui: do "${thedo}/06. Indirect Taxes - Excises.do"
else {
	use hhid using "${presim}/01_menages.dta", clear
	save "${tempsim}/Excise_taxes.dta", replace
}

*-------------------------------------
// 07. P4 - Indirect Taxes - VAT 
*-------------------------------------
 
if (1) qui: do "${thedo}/07. Indirect Taxes - VAT.do" 
else {
	use hhid using "${presim}/01_menages.dta", clear
	save "${tempsim}/VAT_taxes.dta", replace
}
*-------------------------------------
// 08. P6 - In-Kind Transfers
*-------------------------------------

if (1) qui: do "${thedo}/08. In-Kind Transfers.do" 
else {
	use hhid using "${presim}/01_menages.dta", clear
	save "${tempsim}/Transfers_InKind.dta", replace
}

*-------------------------------------
// 06. Income Aggregates
*-------------------------------------

qui: do "${thedo}/09. Income Aggregates.do" 

*-------------------------------------
// 07. Process outputs
*-------------------------------------

qui: do "${thedo}/10. Outputs - Tool.do" 
set rmsg off

*===============================================================================
// Launch Excel
*===============================================================================


scalar t2 = c(current_time)

display as error "Running the complete tool took " ///
	(clock(t2, "hms") - clock(t1, "hms")) / 1000 " seconds. " ///
	"The scenario was saved with the name ${scenario_name_save}"

qui: do "${thedo}/11. Validation.do"

shell ! "$xls_out"

* End of do-file