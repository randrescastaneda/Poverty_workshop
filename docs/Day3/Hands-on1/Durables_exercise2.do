/*===================================================================*
* HANDS-ON TRAINING ON POVERTY MEASUREMENT			                 *
* 4 - Consumption Aggregate: DURABLES							     *				
*===================================================================*/
*====================================================================*
* EXCERCISE 2: Rough estimate of the flow of service 
*====================================================================*
use 05_durables_ex.dta, clear

*--------------------------------------------------------------------*
* Data from the survey:
*  Current value for each durable good
*  Age for each durable good
*--------------------------------------------------------------------*

* Age of each durable item
	generate puryear = .
	replace  puryear = yr_visit - yr_aq 
	sum puryear
 
*--------------------------------------------------------------------*
* 2.1 Remaining life of each good
*--------------------------------------------------------------------* 
	gen rem_life = .
	levelsof durable_code, local(durable)
	foreach dur of local durable {
		di in ye "the good is " `dur'  
		  qui sum puryear [aw = weight] if durable_code == `dur' , detail
		  qui replace rem_life = 2*r(mean) - puryear if durable_code == `dur'  &  rem_life == .			  
	}	
	la var rem_life "remaining life for each item"
	table durable_code, c(mean rem_life min rem_life max rem_life)
	

*--------------------------------------------------------------------*
* 2.2 Arbitrary decision: rounded up to 2 years when the estimate is less 
*--------------------------------------------------------------------*
	replace rem_life = 2 if rem_life < 2

*--------------------------------------------------------------------*
* 2.3 Flow of services
*--------------------------------------------------------------------*
	gen double xcf   = val_td / rem_life

* Adding multiple units for each durable item by household (e.g. 2 tvs in one household)
	collapse weight subregion hsize pce_food pce_non_food z_pl (sum) , by()

	foreach var of varlist xcf* {
		replace `var' = 0 if mi(`var')
	}
	
	reshape wide xcf, i() j()
	
* Transform into 1,000 $/month/capita
	foreach var of varlist xcf* {
		replace `var' = 
		qui mvencode `var', mv(0) override
	}
	label data "Consumption flows from durable goods"
	qui compress
	sort hhid
*--------------------------------------------------------------------*
* 2.4 Estimate the total Per Capita Consumption
*--------------------------------------------------------------------*
	egen      pce_durables1 = rowtotal(xcf1 xcf2 xcf3 xcf4 xcf5 xcf6 xcf7)
	label var pce_durables1 "Consumption flow from all durables (1,000 $/person/month)"

	egen pce = rsum(pce_food pce_non_food pce_durables1)

*--------------------------------------------------------------------*
* 2.5 Budget Shares
*--------------------------------------------------------------------*

* Generate the budget shares
	foreach var of varlist pce_food pce_non_food pce_durables1 {
		gen double w_`var' = (`var'/pce)*100
		label var  w_`var' "budget share for `aggr'"
	}

	egen double check = rowtotal(w_*)
	assert round(check, .0001)  == 100
	drop check

* Mean share for each decile of total consumption
	xtile decile1 = pce [aw = weight*hsize], nq(10)
	table decile1 [aw = weight*hsize], c(mean w_pce_durables1)
	table decile1 [aw = weight*hsize], c(mean w_pce_food mean w_pce_non_food mean w_pce_durables1)

*--------------------------------------------------------------------*
* 2.6 Headcount Ratio using the national poverty line
*--------------------------------------------------------------------*
	povdeco pce [aw = weight*hsize], varpl(z_pl)

*poverty rate by subregions	
	levelsof subregion, local(prov)
	foreach p of local prov{
		di ""
		di "********poverty estimate in subregion `p'************"
		di ""
		povdeco pce  [aw = weight*hsize] if subregion==`p', varpl(z_pl) 
	}	

	
