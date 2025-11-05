

/*============================================================================== =====================================================
  AFW Regional Microsimulation Tool; Indirect taxes - Presimulation
  Author		: Madi Mangan
  Date			: August, 2025
  Version		: 1.0
  last update	: , 2025

 Notes: 
	*

	Extra Note: To run this tool, the following datasets are needed. 
		1. 
		2. This file is run on topof the presimulation run in the country specific tools. 
*======================================================================================== ============================================ */


// Mauritania
	if "$country"=="MRT" {
		replace achats_sans_subs = achats_net_excise
		
	}
	
// Senegal
	if "$country"=="SEN" {
		*replace achats_sans_subs achats_net_excise
	}
	
// The Gambia
	if "$country"=="GMB" {
		*replace achats_net == achats_sans_subs 
	}	
