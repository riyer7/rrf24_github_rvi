/*******************************************************************************
							Template Main do-file							   
*******************************************************************************/

clear all
// Until first end of do file - command for making code run on any computer by preinstalling packages

	* Set version
	version 18

	* Set project global(s)	
	// User: you 
	display "`c(username)'" 	//Check username and copy to set project globals by user
	
	* Add file paths to DataWork folder and the Github folder for RRF2024
	if "`c(username)'" == "wb596077" { // CHANGE THIS
		global github 	"C:\WBG\github\rrf24_github_rvi" // CHANGE THIS
		global onedrive "C:\Users\wb596077\OneDrive - WBG\rrf\DataWork\DataWork" // CHANGE THIS
    }
	
	
	* Set globals for sub-folders 
	global data 	"${onedrive}\Data"
	global code 	"${github}\Stata\Code"
	global outputs 	"${github}\Stata\Outputs"
	
	sysdir set PLUS "${code}\ado" // CHANGE THIS (AND CREATE THIS FOLDER BEFORE) 
	* Works only for current stata session, when close and reopen stata, run this again

	* Install packages 
	/*
	local user_commands	ietoolkit iefieldkit winsor sumstats estout keeporder grc1leg2 //Add required user-written commands

	foreach command of local user_commands {
	   capture which `command'
	   if _rc == 111 {
		   ssc install `command'
	   }
	}
	*/

	* Run do files 
	* Switch to 0/1 to not-run/run do-files 
	* If 1 the code will run, if 0 that code will be skipped and rest will be run
	if (1) do "${code}\01-processing-data.do"
	if (1) do "${code}\02-constructing-data.do"
	if (1) do "${code}\03-analyzing-data.do"


* End of do-file!	