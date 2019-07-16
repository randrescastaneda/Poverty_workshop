*===============================================================================
* HANDS_ON TRAINING ON POVERTY MEASUREMENT
* Session 05 - Housing
*===============================================================================

* Change the following line to match your folder's path
global dir "C:\Users\wb436991\Box Sync\WB\Training_Poverty\2016_07\Sessions\04_Consumption_Aggregate_Housing"
cd "$dir"

use 04_Housing_ex.dta, clear

*===============================================================================
* EXERCISE 1 
*===============================================================================

* 1.1 Summary statistics of actual rent and self-reported rent by geographic areas.
local variables rent rent_self
foreach var of local variables {
	di "Summary statistics for `var'"
	table subregion [aw = weight], c(count `var' mean `var' median `var' min `var' max `var')
}

* 1.2 Deal with OUTLIERS in rent and self reported rent values
qui   sum rent [aw = weight], detail
if r(Var) != 0 & r(Var) < . {
	gen lnrent = ln(rent)
    levelsof subregion, local(prov)
    foreach g of local prov {
	    qui sum rent   [aw = weight] if renter == 1 & subregion == `g' & (rent > 0 & rent <.), detail
	    local anterent= r(N)
		qui sum lnrent [aw = weight] if renter == 1 & subregion == `g', detail
		local ameanrent = r(mean)
		local asdrent   = r(sd)
		* identify and delete outliers
		replace  rent = . if (abs((lnrent - `ameanrent') / `asdrent') > 2.5 & ~mi(lnrent)) & subregion == `g' & renter == 1 
		count if rent > 0 & ~mi(rent) & subregion == `g'
		local postrent = r(N)
		loc rout = (`anterent' - `postrent')/`anterent'*100
		if `rout' > 5 & `rout' <. {
			disp in red "the province is: `g'  "  " the variable is: rent    " as res round(`rout',.1) "%" as res " outliers"
		}
  }
drop lnrent
  }

qui   sum rent_self [aw = weight], detail
if r(Var) != 0 & r(Var) < . {
	gen lnrent_self = ln(rent_self)
    levelsof subregion, local(prov)
    foreach g of local prov {
	    qui sum rent_self   [aw = weight] if renter == 0 & subregion == `g' & (rent_self > 0 & rent_self <.), detail
	    local anterent= r(N)
		qui sum lnrent_self [aw = weight] if renter == 0 & subregion == `g', detail
		local ameanrent = r(mean)
		local asdrent   = r(sd)
		* identify and delete outliers
		replace  rent_self = . if (abs((lnrent_self - `ameanrent') / `asdrent') > 2.5 & ~mi(lnrent_self)) & subregion == `g' & renter == 0 
		count if rent_self > 0 & ~mi(rent_self) & subregion == `g'
		local postrent = r(N)
		loc rout = (`anterent' - `postrent')/`anterent'*100
		if `rout' > 5 & `rout' <. {
			disp in red "the province is: `g'  "  " the variable is: rent_self    " as res round(`rout',.1) "%" as res " outliers"
		}
  }
drop lnrent_self
}

* 1.3 Per Capita Housing Rent & Consumption
egen    pce_rent = rsum(rent rent_self) 
replace pce_rent = pce_rent / hsize

egen pce_1 = rsum(pce_food pce_non_food pce_rent)

foreach var of varlist pce_food pce_non_food pce_rent {
 	gen double w_`var' = (`var'/pce_1)*100
	label var w_`var' "budget share for `aggr'"
}

egen double check = rowtotal(w_*)
assert round(check, .0001)  == 100
drop check

* 1.4 Budget shares
xtile decile1 = pce_1 [aw = weight*hsize], nq(10)
table decile1 [aw = weight*hsize], c(mean w_pce_rent)

* 1.5 Headcount rate
povdeco pce_1 [aw = weight*hsize], varpl(z_pl)

drop w_pce_food w_pce_non_food w_pce_rent

*===============================================================================
* EXERCISE 2
*===============================================================================
* Hedonic Model 

*-------------------------------------------------------------------------------
* 2.1 Linear Prediction
*-------------------------------------------------------------------------------
	* Step 1 - Dependent variable
	gen     lnrent2 = ln(rent)      if renter == 1		/*lnrent2 --- log of rent in exercise 2*/
	replace lnrent2 = ln(rent_self) if renter == 0
	local   ln_rent  = "lnrent2"

	* Step 2- Independent variables 
	tab subregion, gen(prov) 
	#d ;
	local var_rent = "hsize garage kitchen bedrooms area_dwl floor1 floor3 roof1 roof2 type_hhd1 elect1 elect2 elect3 
	garbage1 garbage2 garbage3 road_type1 road_type2 road_type3 road_type5 
	cooler1 cooler3 prov1-prov5 prov7-prov9 urban"
	;
	#d cr
					 
	* Step 3- OLS regression
	regress `ln_rent' `var_rent' [aw = weight], robust

	* Step 4- Linear projection for everyone
	capture drop rent_w
	capture drop rrent
	predict rent_nw2

	* Step 5- Residuals
		* Step 5.1- For sample
		predict rrent2 if e(sample), resid 
		* Step 5.2- Out of sample
		set seed 128128
		replace rrent2 = e(rmse) * rnormal() if rrent2 == . 

	* Step 6- Estimated rent
	gen    rent_hat2a = exp(rent_nw2 + rrent2)
	la var rent_hat2a "Retransformation with normal errors"

*-------------------------------------------------------------------------------
*2.2 Per capita rent as the addition of actual data (paid & reported) and estimated rents.
*-------------------------------------------------------------------------------
	gen rent_hat2 = .
	
	count if rent!=.
	replace rent_hat2 = rent if renter==1
	
	count if rent_self!=.
	replace rent_hat2 = rent_self if renter==0
	
	replace rent_hat2 = rent_hat2a if rent_hat2==.
	
	gen pce_rent2 = rent_hat2 / hsize

	egen pce_2 = rsum(pce_food pce_non_food pce_rent2)
	
*-------------------------------------------------------------------------------
*2.3 Predlog command Adding 3 different types of prediction in predlog command
*-------------------------------------------------------------------------------
regress `ln_rent' `var_rent' [aw = weight], robust
predict yhatraw 

gen     rent_hat2b = exp(yhatraw)
replace rent_hat2b = rent      if renter == 1 & rent != .
replace rent_hat2b = rent_self if renter == 0 & rent != .
la var rent_hat2b "Straight Retransformation"
	
gen     rent_hat2c = exp(yhatraw+(e(rmse)^2/2))
replace rent_hat2c = rent      if renter == 1 & rent != .
replace rent_hat2c = rent_self if renter == 0 & rent != .
la var  rent_hat2c "Naive Retransformation"

predict resid, res  
gen resid2 = exp(resid)
su  resid2, meanonly 
scalar meanres = r(mean)
	
gen     rent_hat2d = rent_hat2b * meanres 
replace rent_hat2d = rent      if renter == 1 & rent != .
replace rent_hat2d = rent_self if renter == 0 & rent != .
la var  rent_hat2d "Duan's Smearing Retransformation"

local predlog 2b 2c 2d  
foreach version of local predlog{
	gen rent_`version' = .
	*replace with rent whenever available
	replace rent_`version' = rent      if renter==1
	replace rent_`version' = rent_self if renter==0
	*replace with imputed rent when rent not available
	replace rent_`version' = rent_hat`version' if rent_`version'==.
	*divide by household size
	gen pce_rent`version' = rent_`version'/ hsize
	*construct per capita expenditure
	egen pce_`version' = rsum(pce_food pce_non_food pce_rent`version')
}

*-------------------------------------------------------------------------------
*2.4 Headcount rate
*------------------------------------------------------------------------------- 
local pces pce_1 pce_2 pce_2b pce_2c pce_2d
foreach one of local pces{
	povdeco `one' [aw = weight*hsize], varpl(z_pl)
}

*===============================================================================
* EXERCISE III 
*===============================================================================
* Two-stage estimation method of hedonic housing model

*-------------------------------------------------------------------------------
* 3.1 Summary statistics by owners and renters
*-------------------------------------------------------------------------------
local cont age hsize num_child num_adult pce_food pce_non_food urban married educ_level labor_sts region subregion water elect road_type
		
		foreach var of local cont{
			qui ttest   `var', by(renter)
			local  own_`var'_mu = trim("`: display %10.3f r(mu_1)'")
			local rent_`var'_mu = trim("`: display %10.3f r(mu_2)'")
			local `var'_tscore  = trim("`: display %10.3f r(t)'")
			local `var'_pvalue  = trim("`: display %10.3f r(p)'")
			qui ranksum `var', by(renter)
			local `var'_zscore  = trim("`: display %10.3f r(z)'")
			
			di 	_newline _col(0) in ye "Summary Statistics for `var'"
			di			 _col(5) in ye "Mean for Owners  = `own_`var'_mu'"
			di 			 _col(5) in ye "Mean for Renters = `rent_`var'_mu'"
			di 			 _col(5) in ye "T-score of equal mean = ``var'_tscore' (p-value = ``var'_pvalue')"
			di 			 _col(5) in ye "Z-score of equal median = ``var'_zscore'"
		}

*-------------------------------------------------------------------------------
* 3.2 Sample selection model
*-------------------------------------------------------------------------------
	* Step 1 - Dependent variable
	gen lnrent3 = ln(rent) if renter == 1	/*lnrent3 --- Log of rent in Exercise 3*/	
	local ln_rent  = "lnrent3"
	
	* Step 2- Independent variables 
	local var_rent = "hsize garage kitchen bedrooms area_dwl floor1 floor3 roof1 roof2 type_hhd1 elect1 elect2 elect3 garbage1 garbage2 garbage3 road_type1 road_type2 road_type3 road_type5 cooler1 cooler3 prov1-prov5 prov7-prov9" 	
	local var_sel = "renter"
	local var_ind = "`var_rent' oth_m max_ed married male employed unemployed educ_level num_child num_adult age"
	
	* Step 3 - Heckman's sample selection model
	heckman `ln_rent' `var_rent', select(`var_sel' = `var_ind')
		
	* Heckman prediction when dependent variable is log(Cameron and Trivedi Chap 16 (p548 Table 16.7.2))
	predict probpos, psel 
	predict x1b1, xbsel 
	predict x2b2, xb 
	scalar sig2sq = e(sigma)^2 
	scalar sig12sq = e(rho)*e(sigma)^2 
	display "sigma1sq = 1" " sigma12sq = " sig12sq " sigma2sq = " sig2sq 
	
	* Potential rent that everybody would pay on the market: E(y|X)
	gen herent_hat1b = exp(x2b2 + 0.5*(sig2sq))*(1 - normal(-x1b1-sig12sq)) 
	
	* Rent for tenants corrected by selection: E(y|X, y > 0)
	gen herent_hat1  = herent_hat1b/probpos

*-------------------------------------------------------------------------------
* 3.3 Renters = actual rent 	
*-------------------------------------------------------------------------------
	replace  herent_hat1  = rent if renter == 1 & rent != .

	* Here we are imputing rent for owners: E(y|X)
	replace herent_hat1 = herent_hat1b / hsize
	
*-------------------------------------------------------------------------------
* 3.4 Headcount rate
*-------------------------------------------------------------------------------
egen pce_3 = rsum(pce_food pce_non_food herent_hat1)
sum pce_1 pce_2 pce_3 [aw = weight*hsize]

local pces pce_1 pce_2 pce_3
foreach one of local pces{
	povdeco `one' [aw = weight*hsize], varpl(z_pl)
}
