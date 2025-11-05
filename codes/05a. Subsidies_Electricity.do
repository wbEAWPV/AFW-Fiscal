/********************************************************************************
* Program: Subsidies Electricity
* Date: July 2025
* Version: 1.0
* Revision: 21/07/25 		By: Andres Gallegos
Modified: We should create the following files from presim:
			- 08_subsidies_elect: hhid(id) consumption_electricite(bimonthly) electricity_group(text)
			- IO_Matrix: sector(id) sect_1-sect_n fixed(0/1) elec_sec(0/1 or 0/share)
		Outputs:
			- `Elec_subsidies_direct_hhid'
			- `io_ind_elec'
*********************************************************************************/

************************************************************************************
noi dis as result " 1. Direct Effects of Electricity subsidies                     "
************************************************************************************

noi use "$presim/08_subsidies_elect.dta", clear 


keep hhid consumption_electricite electricity_group

*Define tranches for subsidies consumption_electricite is bimonthly so intervals should also be bimonthly 

forval i=1/5{
	gen tranche`i'_tool=. //(AGV) The user can use up to 5 tranches in the tool, but certainly most of them will not be used
}

local groups $P4_1_g1_name $P4_1_g2_name $P4_1_g3_name $P4_1_g4_name $P4_1_g5_name

scalar ngroups_elec = `:word count `groups''

if ngroups_elec == 0{
	gen subsidy_elec_direct = 0
	gen exempted_cons_elec = 0
}
else {
	local groupid = 0
	foreach group in `groups' {  
		local ++groupid	

		*Step 1: How many tranches has the group?
		local ntranches = 0
		forval ntra = 1/5 {
			if "${P4_1_g`groupid'_t`ntra'}" != ""{
				local ++ntranches
			}
			if "${P4_1_g`groupid'_m`ntra'}" == ""{
				global P4_1_g`groupid'_m`ntra' .
			}
		}
		
		*Step 2: Separate quantities by tranche
		global P4_1_g`groupid'_m0 0 //This "tranche 0" is helpful for the next loops
		forval tranch = 1/`ntranches' {
			local before = `tranch'-1
			replace tranche`tranch'_tool=${P4_1_g`groupid'_m`tranch'}-${P4_1_g`groupid'_m`before'} if consumption_electricite>=${P4_1_g`groupid'_m`tranch'} & electricity_group=="`group'"
			replace tranche`tranch'_tool=consumption_electricite-${P4_1_g`groupid'_m`before'} if consumption_electricite<${P4_1_g`groupid'_m`tranch'} & consumption_electricite>${P4_1_g`groupid'_m`before'} & electricity_group=="`group'"
			dis "`group' households, tranche `tranch'"
		}
	}

	forval i=1/5{
		replace tranche`i'_tool=0 if tranche`i'_tool==.
	}

	gen tranche_elec_max = .
	forval i=1/5{
		local l = 6-`i'
		replace tranche_elec_max = `l' if tranche`l'_tool!=0 & tranche`l'_tool !=. & tranche_elec_max==.
		gen subsidy`i'=.
		gen spending`i'=.
	}

	if $P4_1_block_tariffs == 0 { 													// Marginal tariffs: each kWh has its own rate
		
		local groupid = 0
		foreach group in `groups' {  
			local ++groupid	
			
			*Step 1: How many tranches has the group?
			local ntranches = 0
			forval ntra = 1/5 {
				if "${P4_1_g`groupid'_t`ntra'}" != ""{
					local ++ntranches
				}
			}
			*Step 2: Calculate subsidy by tranche
			forval tranch = 1/`ntranches' {
				replace subsidy`tranch'=(${P4_1_cost_dom} - ${P4_1_g`groupid'_t`tranch'})*tranche`tranch'_tool if electricity_group=="`group'"
				replace spending`tranch'=(${P4_1_g`groupid'_t`tranch'})*tranche`tranch'_tool if electricity_group=="`group'"
			}
		}
	}

	if $P4_1_block_tariffs == 1 { 													// Block tariffs: you pay the same max rate for the whole consumption
		
		local groupid = 0
		foreach group in `groups' {  
			local ++groupid	
			
			*Step 1: How many tranches has the group?
			local ntranches = 0
			forval ntra = 1/5 {
				if "${P4_1_g`groupid'_t`ntra'}" != ""{
					local ++ntranches
				}
			}
			*Step 2: Calculate subsidy by tranche
			forval tranch = 1/`ntranches' {
				replace subsidy`tranch'=(${P4_1_cost_dom} - ${P4_1_g`groupid'_t`tranch'})*consumption_electricite  if electricity_group=="`group'" & tranche_elec_max==`tranch'
				replace spending`tranch'=(${P4_1_g`groupid'_t`tranch'})*consumption_electricite  if electricity_group=="`group'" & tranche_elec_max==`tranch'
			}
		}
	}

	egen subsidy_elec_direct=rowtotal(subsidy*)
	egen spending_elec=rowtotal(spending*)

	*Generate how much spending is exempt from VAT

	gen exempted_cons_elec = 0
	if "$P4_3_t_noVAT" == "" {
		global P4_3_t_noVAT 0
	}
	if $P4_1_t_noVAT <= 0 {
		dis "No electricity VAT exemptions."
	}
	if $P4_1_t_noVAT > 0 {
		forval tranche = 1/$P4_1_t_noVAT{
			replace exempted_cons_elec = exempted_cons_elec+spending`tranche' if spending`tranche'!=.
		}
		if $P4_1_allcons_VAT == 1 {
			replace exempted_cons_elec = 0 if tranche_elec_max > $P4_1_t_noVAT
		}
	}


	*Tranches are bimonthly therefore subsidy is bimonthly. Here we convert to annual values everything 
	foreach v of varlist subsidy* spending* exempted_cons_elec {
		replace `v'=6*`v'
	}

	
}


keep hhid consumption_electricite electricity_group subsidy_elec_direct exempted_cons_elec

if $devmode == 1 {
    save "$tempsim/Elec_subsidies_direct_hhid.dta", replace
}
tempfile Elec_subsidies_direct_hhid
save `Elec_subsidies_direct_hhid'


************************************************************************************/
noi dis as result " 2. Indirect Effects of Electricity subsidies                "
************************************************************************************
use "$presim/IO_Matrix.dta", clear 
*Shock
gen shock=(${P4_1_cost_prof}-${P4_1_tprof})*${P4_1_elec_weight_IO}/${P4_1_cost_prof} if elec_sec==1
replace shock=0  if shock==.

*Indirect effects 
des sect_*, varlist 
local list "`r(varlist)'"
	
costpush `list', fixed(fixed) priceshock(shock) genptot(elec_tot_shock) genpind(elec_ind_shock) fix
	
keep sector elec_ind_shock elec_tot_shock

if $devmode == 1 {
    save "$tempsim/io_ind_elec.dta", replace
}
tempfile io_ind_elec
save `io_ind_elec', replace
