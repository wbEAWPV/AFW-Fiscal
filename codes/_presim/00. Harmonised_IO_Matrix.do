
/*
Regional Fiscal Microsimulation tool. 
	- Presimulation for excises. 
	Author				: Madi Mangan, Andres
	Last Modified: 		: Madi Mangan
	Date last modified	: 18th August, 2025
	
	Objective			: This dofile is to adopt the IO Matric=x of each of the countries to uniform format to avoid too many if country conditions in the simulation.
						  This is pretty important to running the indirect taxes and subsidies modules. 
*/



************************************************************************************
noi dis as result " 4. Indirect effects of Fuel subsidies                         "
************************************************************************************

use "$con/IO_Matrix.dta", clear 	
cap drop
if "$country"=="SEN"{
	ren Secteur sector
	gen fixed=0
	foreach var in 7 8 9 10 14 15 25 26 27 { // Gasoline, Kerosene, Natural gas, Diesel and others, ÉLECTRICITÉ, EAU, ADMINISTRATION PUBLIQUE, ENSEIGNEMENT, SANTÉ HUMAINE
		replace fixed=1  if  sector==`var'
	}

	gen elec_sec = (sector==14)
	gen gasoline_sec = (sector==7)*0.01
	gen pirogue_sec  = (sector==7)*0.99
	gen kerosene_sec = (sector==8)
	gen butane_sec = (sector==9)
	gen diesel_sec = (sector==10)*0.72978917182462
	gen super_sec = (sector==10)*0.27021082817538
	
	gen water_sec = (sector==15)
	
	forval sector = 1/30 {
		rename C`sector' sect_`sector'
	}
}


if "$country"=="GMB"{
preserve
	use "$tempsim/Tariffs_verylong.dta", clear
	keep if inlist(codpr,754,276,44)
	
	local p 754 276 44
	foreach v of local p {
		gen r`v' = achat_gross if codpr == `v'
		replace r`v' = 0 if codpr != `v'
	}
	egen tot = rowtotal(r754 r276 r44)
	gen w11 = r754/tot
	gen w12 = r44/tot
	gen w13 = r276/tot
	collapse (mean) w11 w12 w13
	
	local w1 = w11
	local w2 = w12
	local w3 = w13
restore

	cap drop fixed
	gen fixed=0
	foreach var in 13 22 32 33 34 { // Gasoline, Kerosene, Natural gas, Diesel and others, ÉLECTRICITÉ, EAU, ADMINISTRATION PUBLIQUE, ENSEIGNEMENT, SANTÉ HUMAINE
		replace fixed=1  if  sector==`var'
	}
*	noi dis as error "The IO matrix is not correctly used for GMB, please correct here and in the Country Tool."
	gen gasoline_sec = (sector==13)*`w1'
	gen pirogue_sec  = 0
	gen kerosene_sec = (sector==13)*`w2'
	gen butane_sec = 0
	gen diesel_sec = (sector==13)*`w3'
	gen super_sec = 0
	
	gen water_sec = (sector==22)*0.3742
}

if "$country"=="MRT"{
	*use "$presim/IO_Matrix.dta", clear 
	gen gasoline_sec = (sector==9 | sector==12)*0.122589344/4                  //I need that the average fuel shock in Mauritania amounts to 0.0033858 = 3.3/100 * (0.0779 + 0.1273)/2
	gen kerosene_sec = (sector==9 | sector==12)*0.122589344/4                  //These variables should be 0 for all sectors,
	gen butane_sec = (sector==9 | sector==12)*0.122589344/4                    //and should be equal to the weight that each fuel has on each sector if it corresponds.
	gen diesel_sec = (sector==9 | sector==12)*0.122589344/4                    //Therefore, they are 1 for Senegal(new) but 0.031 for Mauritania
	gen pirogue_sec  = 0
	gen super_sec = 0
	
	gen water_sec = (sector==9)
}


************************************************************************************/
noi dis as result " 7. Temporal fix just to replicate, delete later               "
************************************************************************************
/*
	gen fixed2 = fixed
	if "$country"=="GMB" {
		replace fixed2 = 0
	}
*/	
save "$presim/IO_Matrix.dta", replace 
********************************************************* ********************************************************* ***************************************************
*																			THE END
********************************************************* ********************************************************* ***************************************************	
