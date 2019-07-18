clear
set more off
*=====================================================================
* HANDS-ON TRAINING ON POVERTY MEASUREMENT                   	 	 * 
* 8 - Poverty Lines: Exercise 1                  					 *   
*=====================================================================
global dir "c:\Users\WB334843\GitHub\Poverty_workshop_2019\docs\Day4\Session4-Hands-on_poverty_lines\"
cd $dir

*=====================================================================
* 2.1 Direct Caloric Intake
*=====================================================================
* Open household dataset
use 08_ex_1_consume.dta, clear

* Nutritional Basket matrix
matrix calories = 1386\139\153\39\180\14\51\62\6\82
matrix list calories

matrix quantity = 397\40\40\58\20\12\48\177\20\20
matrix list quantity

matrix prices  = 15.19,12.81,30.84,15.9,58.24,66.39,46.02,33.71,30.49,28.86
matrix list prices


* RESCALING: The unit in the data set is kilograms per week and this 
* needs to be converted into grams per day in per capita terms

local quanty "qrice qwheat qpulse qmilk qoil qmeat qfish qveg qfruit qsuger"
local i = 1

foreach var of local quanty {
 COMPLETE
}

* Total amount of calories consumed 
egen      pc_cal = rsum(qrice_cal-qsuger_cal)
label var pc_cal "per capita direct calories intake"

* Generate Calories poverty line
generate  cal_line = 2122
label var cal_line "direct calories - poverty line"

* Poor Direct calorie 
generate  direct_p = pc_cal <= cal_line
label var direct_p "direct calories - poor"

* Merge with household dataset
merge hhcode using 08_ex_1_hh.dta
ta   _merge
drop _merge

* Individual Weights
generate  weighti = weight * famsize
label var weighti "individual weights"

* Structure of the survey weights
svyset [pweight = weighti], strata(region) psu(thana)

tabulate direct_p [aw = weighti]

*=====================================================================
* 2.2. Food Energy Intake - Simple approach
*=====================================================================
* 2.2.1. Calculate the average per capita expenditure for the households 
* whose per capita caloric intake is within the 10 percent of 
* 2112 Calories intake per day

sum pcexp [aw = weighti] if (pc_cal > (cal_line * 0.9)) & (pc_cal < (cal_line * 1.1))
return list

generate  feipline = r(mean)
label var feipline "food-energy intake-poverty line"

* 2.2.1. Generate  
generate  fei_mean = pcexp <= feipline
label var fei_mean "food energy - poor" 

* 2.2.2. Total poor and by region 
sum fei_mean [aw = weighti] 
local tot = r(mean)* 100
sum fei_mean [aw = weighti] if region == 1
local dhaka = r(mean)* 100
sum fei_mean [aw = weighti] if region >= 2
local other = r(mean)* 100


#d ;
display as text "{hline}" _newline 
        as text in smcl _col(5) in gr "% of poor in Bangladesh    =   " in yellow  %9.2f `tot'   _newline
        as text in smcl _col(5) in gr "% of poor in Dhaka         =   " in yellow  %9.2f `dhaka' _newline
        as text in smcl _col(5) in gr "% of poor in Other regions =   " in yellow  %9.2f `other' _newline
        as text "{hline}" _newline
;
#d cr


*=====================================================================
* 2.2. Food Energy Intake - Regression approach
*=====================================================================
* 2.3.1. Regression
regress pcexp pc_cal [aw = weighti]

* Food-Energy intake poverty line
generate feipline_reg = _b[_cons] + _b[pc_cal] * 2112

* 2.3.2. Poor Food-Energy intake
generate  fei_reg = pcexp <= feipline_reg
label var fei_reg "food energy - poor" 

* 2.3.3. Total poor and by region 
sum fei_reg [aw = weighti] 
local tot = r(mean)* 100
sum fei_reg [aw = weighti] if region == 1
local dhaka = r(mean)* 100
sum fei_reg [aw = weighti] if region >= 2
local other = r(mean)* 100


#d ;
display as text "{hline}" _newline 
        as text in smcl _col(5) in gr "% of poor in Bangladesh    =   " in yellow  %9.2f `tot'   _newline
        as text in smcl _col(5) in gr "% of poor in Dhaka         =   " in yellow  %9.2f `dhaka' _newline
        as text in smcl _col(5) in gr "% of poor in Other regions =   " in yellow  %9.2f `other' _newline
        as text "{hline}" _newline
;
#d cr

*=====================================================================
* 2.4. Cost of Basic Needs - General
*=====================================================================
* 2.4.1. Cost of Caloric Requirement per person 
matrix      costofcals = prices * (quantity/1000) 
matrix list costofcals 
local total_food = costofcals[1,1] * 4

* 2.4.2. Minimum expenditure for a household of 4 persons
*      Total expenditure: Food (total_food) + Non-food (total_non_food)
*      Period: year basis = about 365.25 days

local total_non_food = `total_food' * 0.3
local total_exp      = (`total_food' + `total_non_food') * 365.25 

#d ;
display as text "{hline}" _newline 
        as text in smcl _col(5) in gr "Daily Cost of Caloric Requirement for a household of 4 persons =   " in yellow %9.2f `total_food' _newline
        as text in smcl _col(5) in gr "Annual Minimum Expenditure for a household of 4 persons        =   " in yellow %9.2f `total_exp' _newline
        as text "{hline}" _newline
;
#d cr

* Save the results
sort thana vill, stable
save pce.dta, replace


*=====================================================================
* 2.5. Cost of Basic Needs - Food allowances
*=====================================================================
* 2.5.1.
* Unit values
drop _all
use 08_ex_1_vprice.dta, clear

* a. Inspect the existence of missing data by village
forvalues i = 1(1)4 {
	sum if vill == `i'
}

* b. Inspect the existence of outliers data by village
* Source: Deaton & Tarozzi (99) 2.5 std from the mean of logarithm

* Fruit prices
generate pfruit_ln = ln(pfruit)
forvalues i = 1(1)4 {
	
	sum pfruit_ln if vill == `i'

	if r(N) > 5 {
COMPLETE	
	}

}

* Fish prices
generate pfish_ln  = ln(pfish)
forvalues i = 1(1)4 {
	
	sum pfish_ln if vill == `i'

	if r(N) > 5 {
COMPLETE	
	}

}

drop pfish_ln pfruit_ln

* c. Imputation of prices by village
* Source: Deaton & Zaidi (01) and Deaton & Tarozzi (99): MEDIAN price paid by similar households

* Fruit prices
generate medfruit = .
forvalues i = 1(1)4 {

	sum pfruit if vill == `i', detail

COMPLETE
}
replace pfruit = medfruit if pfruit == .

* Fish prices
generate medfish = .
forvalues i = 1(1)4 {

	sum pfish if vill == `i', detail

COMPLETE
}
replace pfish  = medfish if pfish == .
drop medfruit medfish

* 2.5.2. Prices to estimate the cost of the nutritional bundle:
* Assumption: the villages are representative of poor households (first quantiles of the distribution)
*             all prices are spatial adjusted

local prices "price pwheat ppulse pmilk poil pmeat pfish pveg pfruit psugar"
loc i 1
foreach px of local prices {
        qui sum `px' 
	    generate `px'_aux = (r(mean) * quantity[`i',1]/1000) * 365.25
        loc i = `i'+ 1
}

egen      food_line = rsum(price_aux-psugar_aux)
label var food_line "food poverty line"

drop price_aux-psugar_aux

sort  thana vill, stable
merge thana vill using 08_ex_1_pce.dta
drop _merge

*=====================================================================
* 2.6. Cost of Basic Needs - Non Food allowances
*=====================================================================
* 2.6.1. 
generate  pcexpfd  = expfd /famsize
label var pcexpfd "food per capita expenditure"

generate  pcexpnfd = expnfd/famsize
label var pcexpnfd "non-food per capita expenditure"

generate sh_nonfood = pcexpnfd / pcexp

* Lower-bound: 
* - Total expenditure approximately equals the food poverty line
* Graphically
twoway (scatter sh_nonfood pcexp        if (pcexp > (food_line * 0.9)) & (pcexp < (food_line * 1.1)))
qui summarize sh_nonfood [aw = weighti] if (pcexp > (food_line * 0.9)) & (pcexp < (food_line * 1.1)), d
local p50_lower = r(p50)
gen z_lower = food_line/(1-`p50_lower')

* Upper-bound: 
* - Total FOOD expenditure approximately equals the food poverty line
* Graphically
twoway (scatter sh_nonfood pcexpfd      if (pcexpfd > (food_line * 0.9)) & (pcexpfd < (food_line * 1.1)))
qui summarize sh_nonfood [aw = weighti] if (pcexpfd > (food_line * 0.9)) & (pcexpfd < (food_line * 1.1)), d
local p50_upper = r(p50)
gen z_upper = food_line/(1-`p50_upper') 

gen poverty_line = (z_lower + z_upper)/2

qui sum poverty_line
loc zl = r(mean)

* 
qui sum food_line
matrix non_food = `zl' - r(mean) 

sum food_line 
#d ;
display as text "{hline}" _newline 
        as text in smcl _col(5) in gr "% of Non-Food over Food    =   " in yellow  %9.2f non_food[1,1]/r(mean)*100   _newline
        as text in smcl _col(5) in gr "Non-Food allowance         =   " in yellow  %9.0f non_food[1,1]               _newline
        as text "{hline}" _newline
;
#d cr

* Calculating extreme poor: less than the food poverty line
generate ext_poor = pcexp < food_line
sum ext_poor [aw = weighti] 
local tot = r(mean)* 100
sum ext_poor  [aw = weighti] if region == 1
local dhaka = r(mean)* 100
sum ext_poor  [aw = weighti] if region >= 2
local other = r(mean)* 100

#d ;
display as text "{hline}" _newline 
        as text in smcl _col(5) in gr "% of poor in Bangladesh    =   " in yellow  %9.2f `tot'   _newline
        as text in smcl _col(5) in gr "% of poor in Dhaka         =   " in yellow  %9.2f `dhaka' _newline
        as text in smcl _col(5) in gr "% of poor in Other regions =   " in yellow  %9.2f `other' _newline
        as text "{hline}" _newline
;
#d cr


* 2.6.3. Calculating poor: less than the total poverty line
generate cbn_poor = pcexp < poverty_line
sum cbn_poor [aw = weighti] 
local tot = r(mean)* 100
sum cbn_poor  [aw = weighti] if region == 1
local dhaka = r(mean)* 100
sum cbn_poor  [aw = weighti] if region >= 2
local other = r(mean)* 100

#d ;
display as text "{hline}" _newline 
        as text in smcl _col(5) in gr "% of poor in Bangladesh    =   " in yellow  %9.2f `tot'   _newline
        as text in smcl _col(5) in gr "% of poor in Dhaka         =   " in yellow  %9.2f `dhaka' _newline
        as text in smcl _col(5) in gr "% of poor in Other regions =   " in yellow  %9.2f `other' _newline
        as text "{hline}" _newline
;
#d cr
