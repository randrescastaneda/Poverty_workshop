*! dtapaths: $dir="c:/Users/wb384996/OneDrive - WBG/Various/Poverty_workshop/docs/Day3/Hands-on1"
*! json: stata-autocomplete.json
*! autoupdate: true

/*===================================================================*
* HANDS-ON TRAINING ON POVERTY MEASUREMENT			                 *
* 4 - Consumption Aggregate: DURABLES							     *				
*===================================================================*/
clear
set more off
global dir "c:/Users/wb384996/OneDrive - WBG/Various/Poverty_workshop/docs/Day3/Hands-on1"

cd "${dir}"

*import excel cpi.xlsx, sheet("cpi") cellrange(A1:A13) clear
*mkmat A, matrix(CPI) 

matrix define CPI = 1.0401\1.0771\1.1182\1.1674\1.2091\1.2881\1.3365\1.3906\1.4369\1.5115\1.5717\1.6613\1.7344

mat list CPI


*====================================================================*
* EXCERCISE 1: Estimate of the flow of service 
*====================================================================*
drop _all
use durables_ex.dta, clear

*--------------------------------------------------------------------*
* 1.1 Calculate the houshehold depreciation rate for each durable good
*--------------------------------------------------------------------*

*--------------------------------------------------------------------*
* Data from other source:
* Average inflation rate over several years
* Nominal interest rates over several years
*--------------------------------------------------------------------*

* Set the inflation rate as the average over the last years   

mata {
	C = st_matrix("CPI")
	nC = rows(C)
	C2 = CPI[|2,1\.,.|]
	C1 = CPI[|1,1\nC-1,.|]
	pi = mean((C2 - C1):/C1)

	st_local("pi", strofreal(pi))

}

disp "Average inflation: `pi'"

* Set the nominal interest rate
*   7% for savings, and
*   9% for deposits 
*   We take the average of the two values

local r = (0.07+0.09)/2

*--------------------------------------------------------------------*
* Data from the survey:
*  Current value for each durable good
*  Age for each durable good
*  Value when purchased of each durable good
*--------------------------------------------------------------------*

* Age of each durable item
generate puryear = .										
replace  puryear = yr_visit - yr_aq 
label var puryear "purchasing year"

sum puryear

* Depreciation rate by item for each household
loc rows = rowsof(CPI)

gen presval = val_aq if puryear ==  0
label var presval "value of durables at time of purchase in constant price"

forvalues r= 1(1)`rows' {
	if `r' != `rows' replace presval = val_aq * CPI[`r',1] if puryear == `r'
	if `r' == `rows' replace presval = val_aq * CPI[`r',1] if puryear >= `r'
}

gen double drate = 1 - (val_td/presval)^(1/puryear)	/*drate = depreciation rate*/
label var drate "depreciation rate"

* Inspect depreciation rates by item
table durable_code [aw=weight], c(mean drate median drate min drate max drate count drate) format(%9.4f)

* Inspect depreciation rates by item and subregion
levelsof durable_code, local(durables)
foreach durable of local durables {
	disp as res _n "depreciation rates of `: label durable_code `durable'' and subregion"
	table subregion    [aw=weight] if durable_code == `durable', /*
	 */ c(mean drate median drate min drate max drate count drate) /*
	 */ format(%9.4f)
}

*--------------------------------------------------------------------*
* 1.2 Calculate median depreciation rates across households:
*     by item 
*--------------------------------------------------------------------*
gen dratem1 = .
levelsof durable_code, local(durables)
label var dratem1 "median depreciation rate for each item"

foreach durable of local durables {
	disp as res "`: label durable_code `durable''"
	qui sum drate [aw = weight]  if durable_code == `durable' , detail
	qui replace dratem1 = r(p50) if durable_code == `durable'  &  dratem1 == .			  
}	

*--------------------------------------------------------------------*
* A1.1.2 Calculate median depreciation rates across households:
*    	 by subregion
*     	 by item 
*--------------------------------------------------------------------*
gen dratem2 = .
levelsof durable_code, local(durables)
levelsof subregion, local(regions)
label var dratem2 "median depreciation rate for each item, by province"

qui foreach durable of local durables {
	disp as res "`: label durable_code `durable''" 
	table subregion  [aw = weight] if durable_code == `durable', /*
	*/ c(median drate) row format(%9.4f)
    
	foreach region of local regions {	 	  
		sum drate [aw = weight]  if subregion == `region' & /*
		*/ durable_code == `durable' , detail
		
		replace dratem2 = r(p50) if subregion == `region' & /*
		*/ durable_code == `durable'  &  dratem2 == .			  
	}
}	


*check median depreciate by subregion and durable goods
table subregion durable [aw = weight], c(med dratem2) format(%9.4f)

*--------------------------------------------------------------------*
* A2.1.2 Calculate median depreciation rates across households:
*     	by subregion
*     	by item 
*     	by group of years of purchase
*--------------------------------------------------------------------*
gen     age_dur = 1 if puryear >= 0 & puryear <= 1 
replace age_dur = 2 if puryear >= 2 & puryear <= 3 
replace age_dur = 3 if puryear >= 4                

gen dratem3 = .
label var dratem3 "median depreciation rate for each item, by province and vintage"

*******************************************************************************
* An alternative way to loops
preserve
	collapse (median)  drate [aw = weight], /*
	*/ by(durable_code age_dur subregion) fast
	rename drate dratem3_2

	tempfile drate
	save `drate'
restore

merge m:1 durable_code age_dur subregion using `drate'



********************************************************************************

*--------------------------------------------------------------------*
* 1.3 Estimate the consumption flow for each durable good
*--------------------------------------------------------------------*

* 1.3 
gen double xcf1_  = val_td * (`r'- `pi' + dratem1)
* A1.1.3
gen double xcf2_  = val_td * (`r'- `pi' + dratem2)
* A2.1.3
gen double xcf3_ = val_td * (`r'- `pi' + dratem3)

* Adding multiple units for each durable item by household 
collapse weight subregion hsize pce_food pce_non_food z_pl (sum) xcf1_ xcf2_ xcf3_, by(hhid durable_code)
foreach var of varlist xcf* {
	replace `var' = 0 if missing(`var')
}

reshape wide xcf1_ xcf2_ xcf3_, i(hhid) j(durable_code)
	
* Transform into 1,000 $/month/capita
foreach var of varlist xcf* {
	replace `var' = ((`var'/12)/hsize)/1000
	qui mvencode `var', mv(0) override
}

*--------------------------------------------------------------------*
* 1.4 Estimate the total per capita consumption 
*--------------------------------------------------------------------*

* 1.4 National median depreciation rate by item
egen      pce_durables1 = rowtotal(xcf1_1 xcf1_2 xcf1_3 xcf1_4 xcf1_5 xcf1_6 xcf1_7)
label var pce_durables1 "Consumption flow from all durables (1,000 $/person/month)"
egen pce1 = rsum(pce_food pce_non_food pce_durables1)

* A1.1.4 Provincial median depreciation rate by item
egen      pce_durables2 = rowtotal(xcf2_1 xcf2_2 xcf2_3 xcf2_4 xcf2_5 xcf2_6 xcf2_7)
label var pce_durables2 "Consumption flow from all durables (1,000 $/person/month)"
egen pce2 = rsum(pce_food pce_non_food pce_durables2)

* A2.1.4 Vintage, provincial median depreciation rate by item
egen      pce_durables3 = rowtotal(xcf3_1 xcf3_2 xcf3_3 xcf3_4 xcf3_5 xcf3_6 xcf3_7)
label var pce_durables3 "Consumption flow from all durables (1,000 $/person/month)"
egen pce3 = rsum(pce_food pce_non_food pce_durables3)

*--------------------------------------------------------------------*
* 1.5 Calculate Headcount ratio using the national poverty line 
*--------------------------------------------------------------------*
// I recommend apoverty

* 1.5	
povdeco pce1 [aw = weight*hsize], varpl(z_pl)
* A1.1.5
povdeco pce2 [aw = weight*hsize], varpl(z_pl)
* A2.1.5
povdeco pce3 [aw = weight*hsize], varpl(z_pl)

*--------------------------------------------------------------------*
* 1.6 poverty rate by subregions	
*--------------------------------------------------------------------*

*without using povdeco
forvalue i = 1(1)3 {
	cap gen poor`i' = (pce`i'<=z_pl) 
}

table subregion [aw = weight*hsize], c(mean poor1 mean poor2 mean poor3) format(%9.2f)


exit 

><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>

levelsof durable_code, local(durables)
levelsof age_dur, local(ages)
levelsof subregion, local(regions)
foreach durable of local durables {  // loop over goods
    
	foreach age of local ages {  // loop over good age

	  foreach region of local regions {	// loop over region
	disp as res "`: label durable_code `durable'' - age: `age' - subregion: `region'" 
		  qui sum drate [aw = weight] if subregion == `region' /*
		  */ & durable_code == `durable' & age_dur == `age'  , detail

		  qui replace dratem3 = r(p50) if subregion == `region' /*
		  */ & durable_code == `durable' & age_dur == `age'  &  dratem3 == .
	  }
   	}
}	


