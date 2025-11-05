/********************************************************************************
* Program: Subsidies Water
* Date: July 2025
* Version: 1.0
* Revision: 21/07/25 		By: Andres Gallegos
Modified: We should create the following files from presim:
			- 06_fuels: hhid(id) q_water(bimonthly) water_group(text)
			- IO_Matrix: sector(id) sect_1-sect_n fixed(0/1) water_sec(0/1 or 0/share)
		Outputs:
			- `Water_subsidies_direct_hhid'
			- `io_ind_water'
*********************************************************************************/

************************************************************************************
noi dis as result " 5. Direct Effects of Water subsidies                     "
************************************************************************************

noi use "$presim/07_water.dta", clear

keep hhid q_water water_group

*Define tranches for subsidies consumption_electricite is bimonthly so intervals should also be bimonthly 

forval i=1/5{
	gen tranche`i'_tool=. //(AGV) The user can use up to 5 tranches in the tool, but certainly most of them will not be used
}

local groups $P4_3_g1_name $P4_3_g2_name

scalar ngroups_water = `:word count `groups''
*dis ngroups_water

if ngroups_water == 0{
	gen subsidy_water_direct = 0
	gen exempted_cons_water = 0
}
else {
	local groupid = 0
	foreach group in `groups' {  
		local ++groupid	

		*Step 1: How many tranches has the group?
		local ntranches = 0
		forval ntra = 1/5 {
			if "${P4_3_g`groupid'_t`ntra'}" != ""{
				local ++ntranches
			}
			if "${P4_3_g`groupid'_m`ntra'}" == ""{
				global P4_3_g`groupid'_m`ntra' .
			}
		}
		
		*Step 2: Separate quantities by tranche
		global P4_3_g`groupid'_m0 0 //This "tranche 0" is helpful for the next loops
		forval tranch = 1/`ntranches' {
			local before = `tranch'-1
			replace tranche`tranch'_tool=${P4_3_g`groupid'_m`tranch'}-${P4_3_g`groupid'_m`before'} if q_water>=${P4_3_g`groupid'_m`tranch'} & water_group=="`group'"
			replace tranche`tranch'_tool=q_water-${P4_3_g`groupid'_m`before'} if q_water<${P4_3_g`groupid'_m`tranch'} & q_water>${P4_3_g`groupid'_m`before'} & water_group=="`group'"
			dis "`group' households, tranche `tranch'"
		}
	}

	forval i=1/5{
		replace tranche`i'_tool=0 if tranche`i'_tool==.
	}

	gen tranche_water_max = .
	forval i=1/5{
		local l = 6-`i'
		replace tranche_water_max = `l' if tranche`l'_tool!=0 & tranche`l'_tool !=. & tranche_water_max==.
		gen subsidy`i'=.
		gen spending`i'=.
	}

	if $P4_3_block_tariffs == 0 { 													// Marginal tariffs: each kWh has its own rate
		
		local groupid = 0
		foreach group in `groups' {  
			local ++groupid	
			
			*Step 1: How many tranches has the group?
			local ntranches = 0
			forval ntra = 1/5 {
				if "${P4_3_g`groupid'_t`ntra'}" != ""{
					local ++ntranches
				}
			}
			*Step 2: Calculate subsidy by tranche
			forval tranch = 1/`ntranches' {
				replace subsidy`tranch'=(${P4_3_cost_dom} - ${P4_3_g`groupid'_t`tranch'})*tranche`tranch'_tool if water_group=="`group'"
				replace spending`tranch'=(${P4_3_g`groupid'_t`tranch'})*tranche`tranch'_tool if water_group=="`group'"
			}
		}
	}

	if $P4_3_block_tariffs == 1 { 													// Block tariffs: you pay the same max rate for the whole consumption
		
		local groupid = 0
		foreach group in `groups' {  
			local ++groupid	
			
			*Step 1: How many tranches has the group?
			local ntranches = 0
			forval ntra = 1/5 {
				if "${P4_3_g`groupid'_t`ntra'}" != ""{
					local ++ntranches
				}
			}
			*Step 2: Calculate subsidy by tranche
			forval tranch = 1/`ntranches' {
				replace subsidy`tranch'=(${P4_3_cost_dom} - ${P4_3_g`groupid'_t`tranch'})*q_water if water_group=="`group'" & tranche_water_max==`tranch'
				replace spending`tranch'=(${P4_3_g`groupid'_t`tranch'})*q_water  if water_group=="`group'" & tranche_water_max==`tranch'
			}
		}
	}

	egen subsidy_water_direct=rowtotal(subsidy*)
	egen spending_water=rowtotal(spending*)

	*Generate how much spending is exempt from VAT
	
	gen exempted_cons_water = 0
	if "$P4_3_t_noVAT" == "" {
		global P4_3_t_noVAT 0
	}
	if $P4_3_t_noVAT <= 0 {
		dis "No water VAT exemptions."
	}
	if $P4_3_t_noVAT > 0 {
		forval tranche = 1/$P4_3_t_noVAT{
			replace exempted_cons_water = exempted_cons_water+spending`tranche' if spending`tranche'!=.
		}
		if $P4_3_allcons_VAT == 1 {
			replace exempted_cons_water = 0 if tranche_water_max > $P4_3_t_noVAT
		}
	}


	*Tranches are bimonthly therefore subsidy is bimonthly. Here we convert to annual values everything 
	foreach v of varlist subsidy* spending* exempted_cons_water {
		replace `v'=6*`v'
	}
	
	
}


keep hhid q_water water_group subsidy_water_direct exempted_cons_water

if $devmode == 1 {
    save "$tempsim/Water_subsidies_direct_hhid.dta", replace
}
tempfile Water_subsidies_direct_hhid
save `Water_subsidies_direct_hhid'


************************************************************************************/
noi dis as result " 6. Indirect Effects of Water subsidies                "
************************************************************************************
use "$presim/IO_Matrix.dta", clear 	

if "${P4_3_cost_prof}${P4_3_tprof}" == "" {
	gen water_ind_shock=0
	gen water_tot_shock=0
}
else {
	
	*Shock
	gen shock=(${P4_3_cost_prof}-${P4_3_tprof})*water_sec/${P4_3_cost_prof}
	replace shock=0  if shock==.

	*Indirect effects 
	des sect_*, varlist 
	local list "`r(varlist)'"

	costpush `list', fixed(fixed) priceshock(shock) genptot(water_tot_shock) genpind(water_ind_shock) fix
	
}
	
keep sector water_ind_shock water_tot_shock

if $devmode == 1 {
    save "$tempsim/io_ind_water.dta", replace
}
tempfile io_ind_water
save `io_ind_water', replace
