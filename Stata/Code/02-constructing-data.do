* RRF 2024 - Construction Data Template	
*-------------------------------------------------------------------------------	
* Data construction: HH 
*------------------------------------------------------------------------------- 
	// Load household-level data (HH)
	use "${data}/Intermediate/TZA_CCT_HH.dta", clear
	
	
	// Exercise 1: Plan construction outputs ----
		// Plan the following outputs:
			// 1. Area in acres.
			// 2. Household consumption (food and nonfood) in USD.
			// 3. Any HH member sick.
			// 4. Any HH member can read or write.
			// 5. Average sick days.
			// 6. Total treatment cost in USD.
			// 7. Total medical facilities.
	
	// Exercise 2: Standardize conversion values ----
		// Define standardized conversion values:
			// 1. Conversion factor for acres.
				// Equal to area farm if unit is acres, 
				// otherwise multiplied by value of hectare in acres
			// 2. USD conversion factor.
	
		global acre_conv 2.47
	
	di $acre_conv
	
	generate 	area_acre = ar_farm 				if ar_farm == 1 , after(ar_farm)
	replace 	area_acre = ar_farm * $acre_conv 	if ar_farm == 2
	
	lab var		area_acre "Area farmed in acres"
	
	* Consumption in usd
	global usd 0.00037
	
	foreach cons_var in food_cons nonfood_cons {
		
		* Save labels 
		local `cons_var'_lab: variable label `cons_var'
		
		* generate vars
		gen `cons_var'_usd = `cons_var' * $usd , after(`cons_var')
		
		* apply labels to new variables
		lab var `cons_var'_usd "``cons_var'_lab' (USD)"
		
	}
	
	// Exercise 3: Handle outliers ----
		// you can use custom Winsorization function to handle outliers.

	local winvars area_acre food_cons_usd nonfood_cons_usd
	
	foreach win_var of local winvars {
		
		local `win_var'_lab: variable label `win_var'
		
		winsor 	`win_var', p(0.05) high gen(`win_var'_w)
		order 	`win_var'_w, after(`win_var')
		lab var `win_var'_w "``win_var'_lab' (Winsorized 0.05)"
		
	}
	
	//Save tempfile	
	
	tempfile hh
	save `hh'
	
*-------------------------------------------------------------------------------	
* Data construction: HH - mem
*------------------------------------------------------------------------------- 	
	// Exercise 4.1: Create indicators at household level ----
		// Instructions:
			// Collapse HH-member level data to HH level.
			// Plan to create the following indicators:
				// 1. Any member was sick.
				// 2. Any member can read/write.
				// 3. Average sick days.
				// 4. Total treatment cost in USD.
	use "${data}/Intermediate/TZA_CCT_HH_mem.dta", clear
	collapse 	(sum) treat_cost ///
				(max) read sick ///
				(mean) m_cost = treat_cost days_sick, by(hhid)
				
	// collapsing on "sum" can make missing values 0, correct it because no one falling sick (.m) and falling sick but not spending (0) are different
				
	replace treat_cost = m_cost if mi(m_cost)	
	
				//Cost in USD
	gen treat_cost_usd = treat_cost * $usd

				// Add labels	
				
	lab var read 		"Any member can read/write"
	lab var sick 		"Any member was sick in the last 4 weeks"
	lab var days_sick 	"Average sick days"
	lab var treat_cost_usd 		"Treatment cost in USD"
	
	drop treat_cost m_cost 

				// Save tempfile  
	
	tempfile mem
	save `mem'
	
*-------------------------------------------------------------------------------	
* Data construction: merge all hh datasets
*------------------------------------------------------------------------------- 	
		use `hh', clear 

	// Exercise 5: Merge HH and HH-member data ----
		// Instructions:
			// Merge the household-level data with the HH-member level indicators.
	merge 1:1 hhid using `mem', assert(3) nogen 
			
			// Merge hh and member data with the treatment data, ensure the treatment status is included in the final dataset.
 	merge m:1 vid using "${data}\Raw\treat_status.dta", assert(3) nogen 

	
			//Save data
	save "${data}\Final\TZA_CCT_analysis.dta", replace

*-------------------------------------------------------------------------------	
* Data construction: Secondary data
*------------------------------------------------------------------------------- 	
	use "${data}/Intermediate/TZA_amenity_tidy.dta", clear
	
	// Exercise 4.2: Data construction: Secondary data ----
		// Instructions:
			// Calculate the total number of medical facilities by summing relevant columns.
			// Apply appropriate labels to the new variables created.
			
	egen n_medical = rowtotal(n_clinic n_hospital)
	lab var n_medical "No. of medical facilities"
	
	// Exercise 6: Save final dataset ----
		// Instructions:
			// Only keep the variables you will use for analysis.
			// Save the final dataset for further analysis.
			// Save both the HH dataset and the secondary data.

			//Save data
	save "${data}\Final\TZA_amenity_analysis.dta", replace

	
*************************************************************************** end!
	
