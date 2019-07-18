clear
set more off
*=====================================================================
* HANDS-ON TRAINING ON POVERTY MEASUREMENT                   	 	 * 
* 8 - Poverty Lines: Exercise 2                  					 *   
*=====================================================================

global dir "c:\Users\WB334843\GitHub\Poverty_workshop_2019\docs\Day4\Session4-Hands-on_poverty_lines\"
cd "$dir"


* AVERAGE KILOCALORIC REQUIREMENT 
local akr = 2112

*----------------------------------------------------------------------
* Open the dataset with household expenditures
*----------------------------------------------------------------------
use 08_ex2_hh.dta, clear

*======================================================================
* Let us define the reference groups for the different parts of the 
* exercise
*======================================================================

* Generate deciles of population starting from the total household per
* capita consumption
*----------------------------------------------------------------------
	xtile decile = pcep [aw = weight*hsize], nq(10)
	generate gref_23 = (decile == 2 | decile == 3)
	generate gref_12 = (decile == 1 | decile == 2)
	generate gref_13 = (decile >= 1 & decile <= 3)
	
	label var gref_23 "reference group for calculation of average unit cost of calories (deciles 2-3)"
	label var gref_12 "reference group for calculation of average unit cost of calories (deciles 1-2)"
	label var gref_13 "reference group for calculation of average unit cost of calories (deciles 1-3)"

	local gref "23 12 13"
*======================================================================
* 1.1 Check Food Baskets within each reference group
*======================================================================
* Generate shares of food subgroups
	local fagg "cereals meat fish milk oils fruit veget sugar unclasfood coffee minwat restaurant"
	foreach f of local fagg{
	gen sh_`f' = pcepf_`f'/pcep_food*100
	}
	
	foreach g of local gref{
	
* Generate quintiles of total consumption within each group of reference
	xtile quintile_`g' = pcep [aw = weight*hsize] if gref_`g'==1, nq(5)

* Tabulate foods subgroup with largest shares
di in red "Reference group is made by quintiles `g'"
	table quintile_`g' [w=round(weight*hsize)], c(mean sh_cereals	mean sh_meat mean sh_milk mean sh_veget	mean sh_sugar) row
	}	

*======================================================================
* 1.2 FOOD POVERTY LINE 
*======================================================================
*  Compute the cost of 1 Kcal
*----------------------------------------------------------------------
	noi disp "Average Kilocalorie Requirement per day: " `akr'
	generate  costcal = ((pcep_food * 12 / 365)/(kcal))
	label var costcal "cost of 1 kcalories"

* The food poverty line is computed as the average expenditure for 
* the average caloric requirement for people in group of reference
*----------------------------------------------------------------------
foreach d of local gref {
	summarize costcal [aw = weight*hsize] if gref_`d' == 1, d
	generate  zfood_`d' = ( (r(mean)) * `akr')*(365/12)
	local akrr = round(`akr',1)
	label var zfood_`d' "food poverty line (person/month) - AKR = `akrr' kcal/day/person"	
	}

*======================================================================
* 1.3 NON-FOOD POVERTY LINE 
*----------------------------------------------------------------------
* It involves three steps:
* 1- LOWER BOUND
* 2- UPPER BOUND
* 3- Take mean of the two
*======================================================================
* Generate the share of food and non-food expenditure as a share of tot
* expenditure	
	gen sh_food = pcep_food/pcep
	label var sh_food "Share of food expenditure"
	gen sh_nonfood = ( 1 - sh_food)
	
* 1- LOWER BOUND
*----------------------------------------------------------------------
* Select a group of households whose TOTAL expenditure is equal (close)
* to the Food poverty line and estimate the median share of non-food 
* consumption SL in their total consumption expenditure
*----------------------------------------------------------------------
	loc range = 0.10

	foreach d of local gref {
COMPLETE
	}

* 2- UPPER BOUND
*----------------------------------------------------------------------
* Select a group of households whose FOOD expenditure is equal (close 10%)
* to the Food poverty line and estimate the median share of non-food 
* consumption SU in their total consumption expenditure
*----------------------------------------------------------------------
	foreach d of local gref{
COMPLETE
	}
	

* 3- Average NON-FOOD POVERTY LINE, as average between UPPER and LOWER 
*----------------------------------------------------------------------

	foreach d of local gref{
	gen z_nonfood_`d' = (`znonfood_upper_`d'' + `znonfood_lower_`d'')/2
	
	}
*======================================================================
* TOTAL POVERTY LINE
*======================================================================	
	foreach d of local gref{
	gen ztot_`d'= zfood_`d' + z_nonfood_`d'
	}

*======================================================================
* 1.4 SHARE OF INDIVIDUALS BELOW THE POVERTY LINE
*======================================================================
	foreach d of local gref{
	gen poor_`d'=pcep < ztot_`d'
	sum poor_`d' [aw = hsize*weight]
	local poor_`d'=round(r(mean), 0.0001)*100
	di in red "Reference group is `d' and % of poor individuals is `poor_`d''"
	}



