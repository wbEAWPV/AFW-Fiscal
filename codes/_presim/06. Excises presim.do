

/*
Regional Fiscal Microsimulation tool. 
	- Presimulation for excises. 
	Author				: Madi Mangan
	Last Modified: 		: Madi Mangan
	Date last modified	: 26th July, 2025
	
	Objective			: This dofile is to adopt the consumption data (at product levels) for The Gambia, Senegal and Mauritania to run the excise Module
						  of the regional tool. 
						  
						: I will create a list of 10 excise clases. in some countries, some classes will be zero, this is where such group do not exist.   


*/


	*********************************************************
	*01. Assign products to specific excise class
	*********************************************************
	
	* Senegal
if "$country"=="SEN" {
	cap drop alco nalco cafe sugar cig fats dairy cos textiles cement cons broths gasoline diesel kerosene
	noi dis as result " 1. Alcoholic Beverages"
		cap gen alco = inlist(codpr,164,165,197,301,302)
		
	noi dis as result " 2. Non Alcoholic Beverages"
		gen nalco = inlist(codpr,160,162,196)  //Loi 2018-10: Elle s'applique également aux jus obtenus à partir de fruits ou légumes (133)
	
	noi dis as result " 3. Narcotics, tea and Coffee"
		gen cafe = inlist(codpr,155,156, 157,180)
		
	noi dis as result " 4. Tea"
		gen tea = inlist(codpr,157,180)

	noi dis as result " 4. Tabacco and cigerretts"
		gen cig = inlist(codpr,201)	
	
	noi dis as result " 5. Sugar and sugar confestioneries"
		gen sugar = inlist(codpr,82,134,135) 
	
	noi dis as result " 6. Butters and Fats"
		gen fats = inlist(codpr,53,54,55,56,57,59,61,62,36,63,66,67,68,70,175)  // I added other fats here even thou they have a higher rates. 
	
	noi dis as result " 7. Dairy products"	
		gen dairy = inlist(codpr,59,70,88,174,52,53,54,55,56,57,58)

	noi dis as result " 8. Cosmetics Products" //  (Check ordonnance 007-2020)
		gen cos = inlist(codpr,321,417)	
		
	noi dis as result " 9. Textiles" //  (Check Loi 2020-33)
		gen textiles = inlist(codpr,501,502,503,504,505,506,521,804,806,616)
	
	noi dis as result " 10. Cement"	
		gen cement = inlist(codpr,603)
		
	noi dis as result " 11. Other construction products"
		gen cons = inlist(codpr,604,605)	
		
	noi dis as result " 12. Food broths" //  (Check Loi 2021-29)
		gen broths = inlist(codpr,144,145)	
		
*** fuel products
		gen gasoline = inlist(codpr,208,209)
		gen diesel   = inlist(codpr,304)
		gen kerosene = inlist(codpr,202)			
}	
	
				
		
	* The Gambia
if "$country"=="GMB" {
	noi dis as result " 1. Alcoholic Beverages"
		gen alco = inlist(codpr,108,109,689,730,807,905,1009,626,686,907,561)
		
	noi dis as result " 2. Non Alcoholic Beverages"
		gen nalco = inlist(codpr,715,240,241,242,282,895,896,1026)	
	
	noi dis as result " 3. Narcotics, Tea and Coffee"
		gen cafe = inlist(codpr,155,156)
	
	noi dis as result " 4. Tabacco and cigerretts"
		gen cig = inlist(codpr,621,617,14,1,2,4,5,15,70)
	
	noi dis as result " 5. Sugar and sugar confestioneries"
		gen sugar = inlist(codpr,1007,1008,717,718) 
	
	noi dis as result " 6. Butters and Fats"
		gen fats = inlist(codpr,408,711,173,633,154,155,104,105,106,107,541)
	
	noi dis as result " 7. Dairy products"	
		gen dairy = inlist(codpr, 245,330,564,677,703,788,837,853,880,978)
		
	noi dis as result " 8. Cosmetics Products" // at the moment this include only soaps
		gen cos = inlist(codpr,963,544,418,865,262)	
		
	noi dis as result " 9. Textiles" 
		gen textiles = inlist(codpr,537,538,539,639,932,933,934,9,87,547,548,549,550,551,552,553,554,555,556,557,558,559,560,649,654,1015,1016,1017,1018,1019,1020,1021,1022,1023,45,131,132,133,134,135,126,127,128,129,130.392,393,394,395,396,397,398,399400,401)	
		
	noi dis as result " 10. Cement"	
		gen cement = inlist(codpr,155,156)
		
	noi dis as result " 11. Other construction products"
		gen cons = inlist(codpr,583,1006)	
		
	noi dis as result " 12. Food broths" //  (Check Loi 2021-29)
		gen broths = inlist(codpr,523,473)	

*** fuel products
		gen gasoline = inlist(codpr,754)
		gen diesel   = inlist(codpr,276)
		gen kerosene = inlist(codpr,44)			
}	
	
	
	*Mauritania
if "$country"=="MRT" { 
	noi dis as result " 1. Alcoholic Beverages"
		gen alco = inlist(codpr,412)
		
	noi dis as result " 2. Non Alcoholic Beverages"
		gen nalco = inlist(codpr,172)	
	
	noi dis as result " 3. Narcotics and Coffee"
		gen cafe = inlist(codpr,155,156)
	
	noi dis as result " 4. Sugar and sugar confestioneries"
		gen sugar = inlist(codpr,161,162,163,164,165,166) 
	
	noi dis as result " 5. Tabacco and cigerretts"
		gen cig = inlist(codpr,177,179,180)
		
	noi dis as result " 6. Butters and Fats"
		gen fats = inlist(codpr,160) 
	
	noi dis as result " 7. Dairy products"	
		gen dairy = inlist(codpr,134,135,136,137,139,140,145,146,147,148,149,150 )
		
	noi dis as result " 8. Cosmetics Products" 
		gen cos = inlist(codpr,218,219)
	
	noi dis as result " 9. Textiles" 
		gen textiles = inlist(codpr,482,483,484,485,486,487,488,489,490,491,492)
	
	noi dis as result " 10. Cement"	
		gen cement = inlist(codpr,469)	
		
	noi dis as result " 11. Other construction products"
		gen cons = inlist(codpr,457)
		
	noi dis as result " 12. Food broths" //  (Check Loi 2021-29)
		gen broths = inlist(codpr,189)	
		
*** fuel products
		gen gasoline = inlist(codpr,255)
		gen diesel   = inlist(codpr,254)
		gen kerosene = inlist(codpr,234)	
}	
	

/*	
	local goods alco nalco cafe cig sugar dairy cement	
	foreach product in $goods {
		gen exp_`product' = `product'*exp 
	}	
		
		

	
	