/*===================================================================*
* HANDS-ON TRAINING ON POVERTY MEASUREMENT			                 *
* 4 - Consumption Aggregate: DURABLES							     *				
*===================================================================*/
clear
set more off
set matsize 10000
global dir C:\Users\wb415019\Documents\Work\Training on Poverty Measurement\June 2014\My Sessions\4_Consumption_Aggregate_Durables
cd "$dir"

*import excel cpi.xlsx, sheet("cpi") cellrange(A1:A13) clear
*mkmat A, matrix(CPI) 

matrix define CPI = 1.0401\1.0771\1.1182\1.1674\1.2091\1.2881\1.3365\1.3906\1.4369\1.5115\1.5717\1.6613\1.7344

mat list CPI

*====================================================================*
* EXCERCISE 1: Estimate of the flow of service 
*====================================================================*
drop _all
use 05_durables_ex.dta, clear
mat list CPI

*--------------------------------------------------------------------*
* 1.1 Calculate the houshehold depreciation rate for each durable good
*--------------------------------------------------------------------*

*--------------------------------------------------------------------*
* Data from other source:
* Average inflation rate over several years
* Nominal interest rates over several years
*--------------------------------------------------------------------*

* Set the inflation rate as the average over the last years   
	local pi = 0.04

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
	sum puryear

* Depreciation rate by item for each household
	loc rows = rowsof(CPI)
	
	gen     presval = val_aq          if puryear ==  0
	forvalues r= 1(1)`rows' {
		if `r' != 13 replace presval = val_aq * CPI[`r',1] if puryear == `r'
		if `r' == 13 replace presval = val_aq * CPI[`r',1] if puryear >= `r'
	}
	label var presval "value of durables at time of purchase in constant price"

	gen double drate = 1 - (val_td/presval)^(1/puryear)	/*drate = depreciation rate*/
	label var drate "depreciation rate"

* Inspect depreciation rates by item
	table durable_code [aw=weight], c(mean drate median drate min drate max drate count drate) format(%9.4f)

* Inspect depreciation rates by item and subregion	
	table subregion    [aw=weight] if durable_code == 1, c(mean drate median drate min drate max drate count drate) format(%9.4f)

*--------------------------------------------------------------------*
* 1.2 Calculate median depreciation rates across households:
*     by item 
*--------------------------------------------------------------------*
gen dratem1 = .
levelsof durable_code, local(durables)

foreach dur of local durables {
	di in ye "the good is " `d'  
		  qui sum drate [aw = weight]  if durable_code == `d' , detail
		  qui replace dratem1 = r(p50) if durable_code == `d'  &  dratem1 == .			  
}	
la var dratem1 "median depreciation rate for each item"

*--------------------------------------------------------------------*
* A1.1.2 Calculate median depreciation rates across households:
*    	 by subregion
*     	 by item 
*--------------------------------------------------------------------*
gen dratem2 = .
levelsof durable_code, local(durable)
foreach dur of local durable {
	di in ye "the good is " `dur'  
	table subregion  [aw = weight] if durable_code == `dur', c(median drate) row format(%9.4f)
    
	qui levelsof subregion, local(prov)
	foreach g of local prov {	 	  
		qui sum drate [aw = weight]  if subregion == `g' & durable_code == `dur' , detail
		qui replace dratem2 = r(p50) if subregion == `g' & durable_code == `dur'  &  dratem2 == .			  
	}
}	

la var dratem2 "median depreciation rate for each item, by province"

*check median depreciate by subregion and durable goods
table subregion durable [aw = weight], c(med dratem2) format(%9.4f)
table subregion durable [aw = weight], c(sd  dratem2) format(%9.4f)

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
la var dratem3 "median depreciation rate for each item, by province and vintage"

/*below is the command used to create dratem2
add another loop over each unique value of age_dur to create dratem3
*/
********************************************************************************
	levelsof durable_code, local(durable)
	foreach dur of local durable {
		di in ye "the good is " `dur'  
		table subregion  [aw = weight] if durable_code == `dur', c(median drate) row format(%9.4f)
		
		qui levelsof subregion, local(prov)
		foreach g of local prov {	 	  
			qui sum drate [aw = weight]  if subregion == `g' & durable_code == `dur', detail
			qui replace dratem2 = r(p50) if subregion == `g' & durable_code == `dur'  &  dratem2 == .			  
		}
	}	
********************************************************************************

*--------------------------------------------------------------------*
* 1.3 Estimate the consumption flow for each durable good
*--------------------------------------------------------------------*

* 1.3 
	gen double xcf   = val_td * (`r'- `pi' + dratem1)
* A1.1.3
	gen double xcff  = val_td * (`r'- `pi' + dratem2)
* A2.1.3
	gen double xcfff = val_td * (`r'- `pi' + dratem3)

* Adding multiple units for each durable item by household 
	collapse weight subregion hsize pce_food pce_non_food z_pl (sum) xcf xcff xcfff, by(hhid durable_code)
	foreach var of varlist xcf* {
	replace `var' = 0 if mi(`var')
	}

	reshape wide xcf xcff xcfff, i(hhid) j(durable_code)
	
* Transform into 1,000 $/month/capita
	foreach var of varlist xcf* {
		replace `var' = ((`var'/12)/hsize)/1000
		qui mvencode `var', mv(0) override
	}

*--------------------------------------------------------------------*
* 1.4 Estimate the total per capita consumption 
*--------------------------------------------------------------------*

* 1.4 National median depreciation rate by item
	egen      pce_durables1 = rowtotal(xcf1 xcf2 xcf3 xcf4 xcf5 xcf6 xcf7)
	label var pce_durables1 "Consumption flow from all durables (1,000 $/person/month)"
	egen pce1 = rsum(pce_food pce_non_food pce_durables1)

* A1.1.4 Provincial median depreciation rate by item
	egen      pce_durables2 = rowtotal(xcff1 xcff2 xcff3 xcff4 xcff5 xcff6 xcff7)
	label var pce_durables2 "Consumption flow from all durables (1,000 $/person/month)"
	egen pce2 = rsum(pce_food pce_non_food pce_durables2)

* A2.1.4 Vintage, provincial median depreciation rate by item
	egen      pce_durables3 = rowtotal(xcfff1 xcfff2 xcfff3 xcfff4 xcfff5 xcfff6 xcfff7)
	label var pce_durables3 "Consumption flow from all durables (1,000 $/person/month)"
	egen pce3 = rsum(pce_food pce_non_food pce_durables3)

*--------------------------------------------------------------------*
* 1.5 Calculate Headcount ratio using the national poverty line 
*--------------------------------------------------------------------*
* 1.5	
	povdeco pce1 [aw = weight*hsize], varpl(z_pl)
* A1.1.5
	povdeco pce2 [aw = weight*hsize], varpl(z_pl)
* A2.1.5
	povdeco pce3 [aw = weight*hsize], varpl(z_pl)

*--------------------------------------------------------------------*
* 1.6 poverty rate by subregions	
*--------------------------------------------------------------------*

levelsof subregion, local(prov)
foreach p of local prov{
	di ""
	di "********poverty estimate in subregion `p'************"
	di ""
	povdeco pce1 [aw = weight*hsize] if subregion==`p', varpl(z_pl) 
	povdeco pce2 [aw = weight*hsize] if subregion==`p', varpl(z_pl) 
	povdeco pce3 [aw = weight*hsize] if subregion==`p', varpl(z_pl) 
}	

*without using povdeco
	forvalue i = 1(1)3{
		tempvar  poor`i'
		cap gen `poor`i'' = (pce`i'<=z_pl) 
	}

	table subregion [aw = weight*hsize], c(mean `poor1' mean `poor2' mean `poor3') format(%9.2f)
