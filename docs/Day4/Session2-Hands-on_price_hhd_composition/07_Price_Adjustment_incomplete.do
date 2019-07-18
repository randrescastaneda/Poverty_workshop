/*===================================================================*
* HANDS-ON TRAINING ON POVERTY MEASUREMENT 						    *
* -SPATIAL PRICE ADJUSTMENT									    	*	
*								    								*
*===================================================================*/

cd "C:\Users\wb316966\Projects\Poverty group\Poverty Measurement\Training\do\Spatial price adjustment\data"
use xsectall_nw, clear

* Drop commodities for which quantities are zero and/or missing
describe, short

foreach var of varlist q* {
	qui sum `var', detail
	local mean = r(mean)
	local coic = real(substr("`var'",2,.))
	if `mean' == 0 {
	    drop q`coic'
		drop x`coic'
*        di in ye "Dropping the following variables: " in green "q`coic'   x`coic'"
	}
}
describe, short

* Calculate UNIT VALUES for all commodities 
foreach var of varlist q* {
	local coic = real(substr("`var'",2,.))
	quietly gen double uv`coic' = x`coic'/q`coic'
}


* Deal with OUTLIERS in unit values
foreach var of varlist uv* {
	qui   sum `var' [aw = weight], detail

* When the variance of uv exists and is different from zero we detect and delete outliers
	if r(Var) != 0 & r(Var) < . {
		quietly gen ln`var' = ln(`var')
	    qui levelsof gov, local(gov)
        foreach g of local gov {
            qui   sum `var' [aw = weight] if `var' > 0 & `var' <. & gov == `g'
            local ant`var' = r(N)
			qui sum ln`var' [aw=weight] if gov == `g', detail
			local amean`var' = r(mean)
			local asd`var'   = r(sd)
*			Identify and delete outliers
COMPLETE
		 	qui count if `var' > 0 & ~mi(`var') & gov == `g'
		 	local post`var' = r(N)
		}
	}
}

* If all unit values are missing, drop corresponding variables u, x and q
* (lack of unit values implies that items cannot be included in the price index)
* NOTE: drop x (expenditure) otherwise we'll get the wrong budget shares
foreach var of varlist uv* {
   	 local coic = real(substr("`var'",3,.))
   	 qui sum uv`coic'
	 if r(mean) == . {
	    drop uv`coic'
		drop x`coic'
		drop q`coic'
*		di in ye "Dropping variables: " in green "uv`coic' " "x`coic' " "q`coic' "
	}
}

capture drop N*
capture drop outuv*
capture drop lnuv*
capture drop q*

* --------------------------------------------------------------------
* CALCULATION OF PAASCHE INDEX BY HOUSEHOLD
* -------------------------------------------------------------------
* Calculate weights for individuals
* need to do this b/c later loops use w*
rename wave hwave
rename weight hweight
gen indweight = hweight*hsize
drop xbeea


* Imputing some UNITS VALUES by household
foreach var of varlist uv* {
	
	local coic = real(substr("`var'",3,.))
    
	/* ==============================================================
	 We impute the MEDIAN values at different levels. We start from the lowest or 
	 closest level (cluster) to the highest level (country):
	 1- CLUSTER: maximum number of observations = 9. We ask for 6 or less than 9
	             Weights are not necessary to calculate median. Every household 
				 within the cluster has the same weight.
	 2- STRATUM: Weights are necessary to calculate median.
	 3- GOVERNORATE: Weights are necessary to calculate median.
	 4- AREA: Weights are necessary to calculate median.
	 5- NATION: Weights are necessary to calculate median.
	 ========================================================================= */
		 
*     1- Calculate median by CLUSTER
 	  bysort gov stratum cluster: egen count_cl_`coic'  = count(uv`coic')                           // Count non missing values
	  bysort gov stratum cluster: egen median_cl_`coic' = median(uv`coic') if count_cl_`coic' >= 6  // Median 
	
*     2- Calculate median by STRATUM
	  qui levelsof stratum, local(strat)
 	  qui gen median_st_`coic' = . 
	  foreach s of local strat {
		qui su uv`coic' [aw = hweight] if stratum == `s', detail
		qui replace median_st_`coic' = r(p50) if stratum == `s' &  median_st_`coic' == .
      }

*     3- Calculate median by GOVERNORATE
COMPLETE		

*     4- Calculate median by AREA
COMPLETE
	
*     5- Calculate median by COUNTRY
	  qui su uv`coic' [aw = hweight], detail
      gen median_`coic' = r(p50)   
			

	gen      uvc`coic'    = uv`coic'
	clonevar old_uv`coic' = uv`coic'
	
	di in ye "Replacing by cluster"
	replace uvc`coic' = median_cl_`coic' if uvc`coic' == . 
	
	di in ye "Replacing by stratum"
	replace uvc`coic' = median_st_`coic' if uvc`coic' == . 
	
	di in ye "Replacing by governorate"
	replace uvc`coic' = median_gv_`coic' if uvc`coic' == . 
	
	di in ye "Replacing by urban"
	replace uvc`coic' = median_ur_`coic' if uvc`coic' == . 
	
	di in ye "Replacing by nation"
	replace uvc`coic' = median_`coic'    if uvc`coic' == . 
}	

* Calculate P_0 (national *median* unit values by coicop)
capture drop pz*
foreach var of varlist uvc* {
	local coic = real(substr("`var'",3,.))
	qui su old_uv`coic' [aw = hweight], detail
	gen pz`coic' = r(p50)
}

* Check no missing value are in national median prices
foreach var of varlist pz* {
	local coic = real(substr("`var'",3,.))
	assert ~mi(pz`coic') == 1
}

* Calculate BUDGET SHARES by household
egen sumx = rowtotal(x*)
foreach var of varlist x* {
	local coic = real(substr("`var'",2,.))
	gen w`coic' = x`coic'/sumx
}

* Check no BUDGET SHARE is missing
foreach var of varlist w* {
	local coic = real(substr("`var'",2,.))
	assert ~mi(w`coic') == 1
}

* PAASCHE's index formula (by household) as 
* Deaton and Zaidi eq. (4.5)
capture drop uvz*
foreach var of varlist uvc* {
	local coic = real(substr("`var'",4,.))
	gen double uvz`coic' = w`coic'*(pz`coic'/uvc`coic')
}

capture drop paasche
egen    paasche = rowtotal(uvz*)
replace paasche = 1/paasche
la var  paasche "Paasche Index"

assert ~mi(paasche)

* drop variables no longer needed
cap drop median_*
cap drop count_*
cap drop uvz*

* ------------------------------------------------------------------
* 2)    Estimate LASPEYRES index  
* ------------------------------------------------------------------
* Calculate REFERENCE BUDGET SHARES for LASPEYRES
* calculate W_0 (mean of all budget shares: democratic approach)
capture drop wz*
foreach var of varlist w* {
	local coic = real(substr("`var'",2,.))
	qui sum    w`coic' [aw = hweight] 
	gen double wz`coic' = r(mean)
}

* Check wz* add up to 1
capture drop checkwz
egen double checkwz = rowtotal(wz*)
assert round(checkwz,.0001) == 1
drop checkwz
	

*** ----- Laspeyres index formula(by household) as from
*         DZ eq. (4.10)
capture drop uvz*
foreach var of varlist uvc* {
	local coic = real(substr("`var'",4,.))
	gen double uvz`coic' = wz`coic'*(uvc`coic'/pz`coic')
}

capture drop laspeyres 
egen double laspeyres = rowtotal(uvz*)
label var   laspeyres "Laspeyres Index"
assert ~mi(laspeyres)

* ------------------------------------------------------------------
* 3) Estimate FISHER index  
* ------------------------------------------------------------------

* Fisher indices
capture drop fisher
gen    fisher = sqrt(laspeyres*paasche)
la var fisher "Fisher Index"
assert ~mi(fisher)

rename hwave wave 
keep hhid gov urban hweight hsize indweight paasche laspeyres fisher wave

sort hhid
compress

label data "IHSES-1 - PAASCHE, LASPEYRES & FISHER spatial price indices"
save cpi_spatial_indices.dta, replace      

* ------------------------------------------------------------------
* 4) DEFLATE consumption aggregate  
* ------------------------------------------------------------------
use xconsaggr, clear
 
* Add spatial deflators
merge 1:1 hhid using cpi_spatial_indices
assert _merge == 3
drop _merge

*** ----- ADJUST nominal expenditures for differences in the cost of living
*   1- Use the PAASCHE price index 
foreach var of varlist pce pce_* {
	clonevar a`var' = `var'
	replace a`var' = a`var'/paasche
}

renpfix apce pcep
label var pcep "per capita expenditure (defl. paasche)"

*   2- Use the LASPEYRES price index 
foreach var of varlist pce pce_* {
	clonevar a`var' = `var'
	replace a`var' = a`var'/laspeyres
}

renpfix apce pcel
label var pcel "per capita expenditure (defl. laspeyres)"

*   3- Use the FISHER price index 
foreach var of varlist pce pce_* {
	clonevar a`var' = `var'
	replace a`var' = a`var'/fisher
}

renpfix apce pcef
label var pcef "per capita expenditure (defl. fisher)"

sort hhid
compress
save xconsaggrdefl, replace
