*! assignprogram
* Andres Gallegos - World Bank Group
*assignprogram PNBSF, by(region) sortseed(pmt_seed) target(benefsreg_PNBSF) weight(hhweight) replace
/*(varname numeric min=1)*/ 
		/*[by(varlist)]*/ 

cap prog drop assignprogram
program define assignprogram, rclass sortpreserve
	version 11.2, missing
	#delimit;
	syntax name 
		[if] [in], 
		SORTseed(varlist numeric min=1) 
		TARget(real) 
		[POPweight(varname numeric min=1)] 
		[REPlace] 
		[UPDate] 
		[NOIsyresults] 
		;
#delimit cr

qui{
	if ("`popweight'"==""){
		tempvar myweight
		gen `myweight' = 1
		local popweight `myweight'
	}
	if ("`replace'"!="" & "`update'"!="") {
		dis as error "You cannot replace and update the assignment variable simultaneously"
		exit
	}

	marksample touse
	
	sum `popweight'
	if `r(min)'<=0 {
		dis as error "Population weights must be strictly positive."
		exit
	}
	
	sort `touse' `sortseed', stable

	tempvar pop_acum dist orden asig
	gen `pop_acum' = sum(`popweight') if `touse'
	gen `dist' = abs(`pop_acum'-`target' ) if `touse'
	gen `asig' = (`dist'[_n]<`dist'[_n-1]) if `touse'
	gen `orden' = _n if `touse'
	sum `orden'
	replace `orden' = `orden'+1-`r(min)'
	replace `asig' = 0 if `touse' & `dist'[_n]<=`dist'[_n+1] & `orden'==1
	replace `asig' = 0 if `touse' & `dist'[_n]>`pop_acum'[_n]/2 & `orden'==1 & `asig'[_n+1]==0
	
	return scalar target = `target'
	sum `popweight' if `touse'
    return scalar potential = `r(sum)'
	sum `popweight' if `touse' & `asig'==1
    return scalar assigned = `r(sum)'
	
	if ("`noisyresults'"!="") {
		cap gen _pop_acum = .
		cap gen _dist = .
		cap gen _orden = .
		replace _pop_acum = `pop_acum'
		replace _dist = `dist'
		replace _orden = `orden'
	}
	
	if ("`replace'"!="") {
		cap drop `namelist'
		gen `namelist' = `asig'
		exit
	}
	if ("`update'"!="") {
		cap gen `namelist' = .
		replace `namelist' = `asig' if `touse'
		exit
	}
	
	gen `namelist' = `asig'
	
}

end

