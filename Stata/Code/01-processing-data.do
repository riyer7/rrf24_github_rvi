* RRF 2024 - Processing Data Template	
*-------------------------------------------------------------------------------	
* Loading data
*------------------------------------------------------------------------------- 	
	
	* Load TZA_CCT_baseline.dta
	use "${data}\raw\TZA_CCT_baseline.dta", clear
	
*-------------------------------------------------------------------------------	
* Checking for unique ID and fixing duplicates
*------------------------------------------------------------------------------- 		

	* Identify duplicates 
	ieduplicates	hhid /// enter ID name here (need not be unique)
					using "${outputs}\duplicates.xlsx", ///
					uniquevars(key) /// (needs to be unique)
					keepvars(vid enid submissionday) ///
					nodaily /// helps export a daily report if required
	// say correct=yes to keep and drop=yes to drop				
	
*-------------------------------------------------------------------------------	
* Define locals to store variables for each level
*------------------------------------------------------------------------------- 							
	
	* IDs
	local ids vid hhid enid
	
	* Unit: household
	local hh_vars floor-n_elder ///
				  food_cons - submissionday
	
	* Unit: Household-memebr
	local hh_mem gender age read clinic_visit sick days_sick ///
				 treat_fin treat_cost ill_impact days_impact
	
	* define locals with suffix and for reshape
	foreach mem in `hh_mem' {
		
		local mem_vars "`mem_vars' `mem'_*"
		local reshape_mem "`reshape_mem' `mem'_"
	}
		
	
*-------------------------------------------------------------------------------	
* Tidy Data: HH
*-------------------------------------------------------------------------------	

	preserve 
		
		* Keep HH vars
		keep `ids' `hh_vars'
		
		* Check if data type is string
		ds, has (type string)	// describe variable that has string	
		
		* Fix data types 
		* numeric should be numeric
		* dates should be in the date format
		* Categorical should have value labels 
		
		* Fix submission date		
		gen submissiondate = date(submissionday, "YMD hms")
		format submissiondate %td
		
		* Encode area farm unit
		encode ar_farm_unit, gen(ar_unit) // retains labels, divides into categories without having to do gen replace
		labelbook ar_unit
		
		* Destring duration
		destring duration, replace
		
		* Clean crop_other
		replace crop_other = proper(crop_other)
		
		* labelbook crop // to know what number to assign to coconut and sesame
		replace crop = 40 if regex(crop_other, "Coconut") == 1
		replace crop = 41 if regex(crop_other, "Sesame") == 1
		
		label define df_CROP 40 "Coconut" 41 "Sesame", add
		
		* Turn numeric variables with negative values into missings
		ds, has(type numeric)
		global numVar `r(varlist)' // ask where r(varlist) came from

		foreach numVar of global numVars {
			
			recode `numVar' (-88 = .d) //.d is don't know
		}	
		****************** DIY below *********************
		
		* Explore variables for outliers
		sum food_cons nonfood_cons ar_farm, det
		
		* dropping, ordering, labeling before saving
		drop 	ar_farm_unit submissionday crop_other
				
		order 	ar_unit, after(ar_farm)
		
		lab var submissiondate "Date of interview"
		
		isid hhid, sort
		
		* Save data		
		iesave 	"${data}\Intermediate\TZA_CCT_HH.dta", /// saves dataset but also exports a report
				idvars(hhid)  version(18.0) replace ///
				report(path("${outputs}\TZA_CCT_HH_report.csv") replace)  
		
	restore
	
*-------------------------------------------------------------------------------	
* Tidy Data: HH-member 
*-------------------------------------------------------------------------------*

	preserve 

		keep `mem_vars' `ids'

		* tidy: reshape tp hh-mem level 
		reshape long `reshape_mem', i(`ids') j(member) 
		
		* clean variable names 
		rename *_ *
		
		* drop missings 
		drop if mi(gender)
		
		* Cleaning using iecodebook
		// recode the non-responses to extended missing
		// add variable/value labels
		// create a template first, then edit the template and change the syntax to 
		// iecodebook apply
		iecodebook template 	using ///
								"${outputs}\hh_mem_codebook.xlsx", replace
								
		isid hhid member					
		
		* Save data: Use iesave to save the clean data and create a report 
		iesave "${data}\Intermediate\TZA_CCT_HH_mem.dta", ///
				idvars(hhid member)  version(18.0) replace ///
				report(path("${outputs}\TZA_CCT_HH_mem_report.csv") replace)     
				
	restore			
	
*-------------------------------------------------------------------------------	
* Tidy Data: Secondary data
*------------------------------------------------------------------------------- 	
	
	* Import secondary data 
	import delimited "${data}\Raw\TZA_amenity.csv", clear
	
	* reshape  
	reshape wide n , i(adm2_en) j(amenity) str
	
	* rename for clarity
	rename n* n_*
	
	* Fix data types
	encode adm2_en , gen(district) 
	
	* Label all vars 
	lab var district "District"
	lab var n_school "No. of schools"
	lab var n_clinic "No. of clinics"
	lab var n_hospital "No. of hospitals"
	
	* Save
	keeporder district n_*
	
	save "${data}\Intermediate\TZA_amenity_tidy.dta", replace

	
****************************************************************************end!
	
