*************************************************************************************************************************************
**Data prepared by Ainsley Charles (SP) and Rose Mungai (AFTPM) and Kristen Himelein (AFTP3)
**Part A Data scanned using Teleform
**Part A Data are transferred to ACCESS and then to converted to STATA.
**Part B Data entered in CSPro and transferred to SPSS.
**Part B Data organized as wide or horizontal.
**Part B Data First six months and last six months merged in SPSS.
**Part B Data transposed in SPSS to questionnaire format (see Process manual.doc) and converted to STATA for editting.
*************************************************************************************************************************************

capture log close
clear all
set more off
set mem 1000m

global 	base 			  "c:\Users\WB334843\OneDrive - WBG\Poverty GP\Pov-Measurement-Summer2019\SLIHS2011\"

global slihs2011final     "$base\Data\4-Data final\STATA"
global slihs2011price     "$base\CPI and Prices"
global slihs2011temp      "$base\stdfiles"
global slihs2011fintabs   "$base\tables"
global slihs201logs       "$base\logfiles"

capture mkdir "$slihs2011temp"
capture mkdir "$slihs2011fintabs"

*log using "$slihs201logs\SLE 2011 consumption aggregate.log" , replace

**************************************************************************************************************************
***Table 2: FOOD PURCHASE
**************************************************************************************************************************
*Purpose: To gather the variables from the raw data required for calculating food purchases.
*Data: Part B : Section 13 Part 13A: Food expenses (see page 29-39).


use "$slihs2011final\Section 13 Part A Food purchases", clear	

***Step 1: Filtering out items not consumed.

duplicates report
duplicates drop
summarize


*There are 109 missing food item name.
*3 invalid codes (128, 205, 325) but do not have any data.

tab s13aitem
count if  s13aitem==.
rename s13aitem fooditem
codebook fooditem				
tab fooditem, missing			

sort hid fooditem
drop if fooditem==. | fooditem==128 | fooditem==205 | fooditem==325

gen valid=1
sort slihseacode hhnum 
merge slihseacode hhnum using "$slihs2011final\Part B Date of interview.dta"
tab _merge
drop _merge

sort slihseacode hhnum
merge m:1 slihseacode hhnum using "$slihs2011temp\hhsize.dta"
tab _merge
drop _merge

gen hyphen="-"
egen year_mth=concat(int_year hyphen int_month)
keep if valid==1

**********************************************************

***Step 2: edit outliers.

egen mth_purch=rsum(s13aq3 - s13aq7)			//Computes (item-level) 25-day (over 5 visits) consumption from purchases, in value (Le)
lab var mth_purch "Monthly Total"
recode mth_purch (0=.)
*tabstat mth_purch,by(fooditem) s(N mean q sd max)  f(%12.2f)
gen ann_purch_ori=mth_purch*(365/25)
lab var ann_purch_ori "Annual food purchase with outliers"

compress
outsheet using "$slihs2011temp\slihs2011food13A.csv", replace

preserve
	*Check response rates and average prices by fooditem
	replace s13aq3 =. if s13aq3 ==0
	replace s13aq4 =. if s13aq4 ==0
	replace s13aq5 =. if s13aq5 ==0
	replace s13aq6 =. if s13aq6 ==0
	replace s13aq7 =. if s13aq7 ==0
	  
	collapse (count) s13aq3 s13aq4 s13aq5 s13aq6 s13aq7 (mean) ps13aq3=s13aq3 ps13aq4=s13aq4 p13aq5=s13aq5 ps13aq6=s13aq6 ps13aq7=s13aq7 , by(fooditem)

	gen rate1= s13aq3/6741
	gen rate2= s13aq4/6741
	gen rate3= s13aq5/6741
	gen rate4= s13aq6/6741
	gen rate5= s13aq7/6741
	export excel using "$slihs2011temp\checkresponserates.xlsx", replace firstrow(variables)
restore


*Check 2nd Visit
tab s13aq3
list hid  s13aq3 if  s13aq3>7500000 &  s13aq3~=.
replace s13aq3=7500      if hid=="111102302" & s13aq3==75007500
replace s13aq3=8000      if hid=="224134407" & s13aq3==214118000
replace s13aq3=4000      if hid=="442257504" & s13aq3==206214000
replace s13aq3=1500000   if hid=="221222007" & s13aq3==15000000
replace s13aq3=1400000   if hid=="221222709" & s13aq3==14000000
replace s13aq3=1000      if hid=="331141404" & s13aq3==10001000
replace s13aq3=50000     if hid=="331244401" & s13aq3==24450000
replace s13aq4=25000     if hid=="331244401" & s13aq4==2325000
replace s13aq5=25000     if hid=="331244401" & s13aq5==3525000
replace s13aq6=100000    if hid=="221222005" & s13aq6==1100000 & fooditem==140
replace s13aq6=0 		 if hid=="221222005" & fooditem ==162

*Check 3rd Visit 
tab s13aq4
list hid  s13aq4 if  s13aq4>7500000 &  s13aq4~=.
replace s13aq4=5000    if hid=="112107007" & s13aq4==500034000
replace s13aq5=3400    if hid=="112107007" & s13aq5==. &  fooditem==142
replace s13aq4=900000  if hid=="221121710" & s13aq4==19000000
replace s13aq4=18750   if hid=="331244402" & s13aq4==18750000
replace s13aq5=18750   if hid=="331244402" & s13aq5==1875000
replace s13aq6=14450   if hid=="331244402" & s13aq6==1445000

*Check 4th Visit
tab s13aq5
list hid  s13aq5 if  s13aq5>7500000 &  s13aq5~=.

*Check 5th Visit
tab s13aq6
list hid  s13aq6 if  s13aq6>7500000 &  s13aq6~=.
replace s13aq6=750000  if hid=="112108301" & s13aq6==14750000
replace s13aq6=750000  if hid=="112108301" & s13aq6==1750000  &  fooditem==77

*Check 6th Visit
tab s13aq7
list hid  s13aq7 if  s13aq7>7500000 &  s13aq7~=.
replace s13aq7=800000  if hid=="221222306" & s13aq7==8000000


list hid  s13aq3 if  s13aq4>=3000000  &  s13aq4~=.
replace s13aq6=100000  if hid=="221222005" & s13aq6==1100000 & fooditem==140
replace s13aq3=700000  if hid=="221222008" & s13aq3==7000000 & fooditem==7
replace s13aq3=340000  if hid=="221222305" & s13aq3==3040000 & fooditem==6
replace s13aq3=435000  if hid=="221222707" & s13aq3==4350000 & fooditem==70
replace s13aq3=7500    if hid=="225136510" & s13aq3==7500000 & fooditem==70
list hid  s13aq4 if  s13aq4>=3040000  &  s13aq4~=.
replace s13aq4=750000  if hid=="112108307" & s13aq4==7500000 & fooditem==70
replace s13aq4=600000  if hid=="221120502" & s13aq4==6000000 & fooditem==7
list hid  s13aq5 if  s13aq5>=3040000  &  s13aq5~=.
list hid  s13aq6 if  s13aq6>=3040000  &  s13aq6~=.
replace s13aq3=230000  if hid=="221121701" & fooditem==6 & s13aq3==2300000

replace  s13aq3=.     if  s13aq2==2 &  s13aq3<=100
replace  s13aq4=.     if  s13aq2==2 &  s13aq4<=100
replace  s13aq5=.     if  s13aq2==2 &  s13aq5<=100
replace  s13aq6=.     if  s13aq2==2 &  s13aq6<=100
replace  s13aq7=.     if  s13aq2==2 &  s13aq7<=100

replace  s13aq3=s13aq3/10    if s13aq3>=100000  & s13aq3<1000000 
replace  s13aq3=s13aq3/100   if s13aq3>=1000000 & s13aq3~=.      
replace  s13aq4=s13aq4/10    if s13aq4>=100000  & s13aq4<1000000 
replace  s13aq4=s13aq4/100   if s13aq4>=1000000 & s13aq4~=.      
replace  s13aq5=s13aq5/10    if s13aq5>=100000  & s13aq5<1000000 
replace  s13aq5=s13aq5/100   if s13aq5>=1000000 & s13aq5~=.      
replace  s13aq6=s13aq6/10    if s13aq6>=100000  & s13aq6<1000000 
replace  s13aq6=s13aq6/100   if s13aq6>=1000000 & s13aq6~=.      
replace  s13aq7=s13aq7/10    if s13aq7>=100000  & s13aq7<1000000 
replace  s13aq7=s13aq7/100   if s13aq7>=1000000 & s13aq7~=.      

list hid s13aq2  s13aq3 s13aq4 s13aq5 s13aq6 s13aq7 mth_purch   if   fooditem==1 & mth_purch~=.
replace  s13aq3=7000   if hid=="221121706" & fooditem==1 
replace  s13aq4=4500   if hid=="221121706" & fooditem==1 
replace  s13aq5=2500   if hid=="221121706" & fooditem==1 
replace  s13aq6=2500   if hid=="221121706" & fooditem==1 
list hid s13aq2  s13aq3 s13aq4 s13aq5 s13aq6 s13aq7 mth_purch   if   fooditem==2 & mth_purch~=.
list hid s13aq2  s13aq3 s13aq4 s13aq5 s13aq6 s13aq7 mth_purch   if   fooditem==3 & mth_purch~=.
list hid s13aq2  s13aq3 s13aq4 s13aq5 s13aq6 s13aq7 mth_purch   if   fooditem==4 & mth_purch~=.
list hid s13aq2  s13aq3 s13aq4 s13aq5 s13aq6 s13aq7 mth_purch   if   fooditem==5 & mth_purch~=.
list hid s13aq2  s13aq3 s13aq4 s13aq5 s13aq6 s13aq7 mth_purch   if   fooditem==6 & mth_purch~=.
replace  s13aq3=2000   if hid=="221222707" & fooditem==6 
replace  s13aq4=2000   if hid=="221222707" & fooditem==6 
replace  s13aq6=4000   if hid=="221222707" & fooditem==6 
replace  s13aq3=5600   if hid=="224131305" & fooditem==6 
replace  s13aq3=6400   if hid=="332246607" & fooditem==6 
replace  s13aq3=2750   if hid=="442257403" & fooditem==6 
replace  s13aq6=4000   if hid=="442257403" & fooditem==6 
replace  s13aq6=6000   if hid=="112205701" & fooditem==6 
list hid s13aq2  s13aq3 s13aq4 s13aq5 s13aq6 s13aq7 mth_purch   if   fooditem==7 & mth_purch~=.
replace  s13aq3=26000  if hid=="111103505" & fooditem==7 
replace  s13aq3=5600   if hid=="112105505" & fooditem==8 
replace  s13aq3=3000   if hid=="111203207" & fooditem==61
replace  s13aq5=2000   if hid=="111203207" & fooditem==61
replace  s13aq6=2000   if hid=="112208108" & fooditem==61
replace  s13aq3=1200   if hid=="112211806" & fooditem==61
replace  s13aq3=6000   if hid=="113215110" & fooditem==61
replace  s13aq3=7800   if hid=="113217008" & fooditem==61
replace  s13aq5=6000   if hid=="331139504" & fooditem==61
replace  s13aq7=4000   if hid=="331139504" & fooditem==61
replace  s13aq6=4500   if hid=="332145706" & fooditem==61
replace  s13aq7=2500   if hid=="332146902" & fooditem==61
replace  s13aq3=1200   if hid=="332147501" & fooditem==61
replace  s13aq3=7000   if hid=="333148706" & fooditem==61
replace  s13aq3=2000   if hid=="334152104" & fooditem==61
replace  s13aq3=9000   if hid=="441155301" & fooditem==61
replace  s13aq4=9000   if hid=="441155301" & fooditem==61
replace  s13aq5=9000   if hid=="441155301" & fooditem==61
replace  s13aq6=9000   if hid=="441155301" & fooditem==61
replace  s13aq7=9000   if hid=="441155301" & fooditem==61
replace  s13aq3=4200   if hid=="441255206" & fooditem==61
replace  s13aq4=4200   if hid=="441255206" & fooditem==61
replace  s13aq5=4200   if hid=="441255206" & fooditem==61
replace  s13aq6=4200   if hid=="441255206" & fooditem==61
replace  s13aq7=4200   if hid=="441255206" & fooditem==61
replace  s13aq3=1700   if hid=="442257403" & fooditem==61
replace  s13aq4=2400   if hid=="442257408" & fooditem==61
replace  s13aq3=4500   if hid=="442258701" & fooditem==61

**Compute new monthly expenditure, by food item.

egen mth_purch1=rsum(s13aq3 - s13aq7)			//Computes (item-level) 25-day (over 5 visits) consumption from purchases, in value (Le)
lab var mth_purch1 "Monthly Total"
recode mth_purch1 (0=.)
tabstat mth_purch1,by(fooditem) s(N mean q sd max)  f(%12.2f)

**edit outliers.
bys region year_mth fooditem: egen mth_purch_mn=mean(mth_purch1)
bys region year_mth fooditem: egen mth_purch_md=median(mth_purch1)
bys region year_mth fooditem: egen mth_purch_sd=sd(mth_purch1)
bys region year_mth fooditem: egen mth_purch_mdd=median(mth_purch1)    if mth_purch1>0 & mth_purch1~=.

tabstat  mth_purch_mn mth_purch_md mth_purch_mdd mth_purch_sd,by(fooditem)   f(%12.2f)

gen pcmth_purch=mth_purch1/hhsize
bys region year_mth fooditem: egen pcmth_purch_mn=mean(pcmth_purch)   if pcmth_purch!=0
bys region year_mth fooditem: egen pcmth_purch_md=median(pcmth_purch) if pcmth_purch!=0
bys region year_mth fooditem: egen pcmth_purch_sd=sd(pcmth_purch)     if pcmth_purch!=0

gen zscor=(pcmth_purch - pcmth_purch_mn)/pcmth_purch_sd
lab var zscor "Z scores for a normal distribution"

gen mth_purch2=mth_purch1
count if zscor>3 & zscor~=.
tab fooditem if zscor>3 & zscor~=.
tab region   if zscor>3 & zscor~=.

replace  mth_purch2= pcmth_purch_md*hhsize   if zscor>3 & zscor~=.
assert mth_purch2<500000 if mth_purch2!=.

**computing the annual.

gen ann_purch=mth_purch2*(365/25)		
su mth_purch mth_purch1 mth_purch2 ann_purch_ori ann_purch

sort  slihseacode
merge m:1 slihseacode using "$slihs2011final\Household cluster weights.dta"
tab _merge
drop _merge

sort hid fooditem ann_purch
bys hid fooditem: gen countdup=_n
tab  countdup
keep if countdup==1
drop countdup

tabstat  ann_purch_ori ann_purch [aw=weight],by( year_mth)  s(sum)   f(%18.2f)
tabstat  ann_purch_ori ann_purch [aw=weight],by( year_mth)  s(mean)  f(%18.2f)

sort hid

keep  region district chiefdom section eacode sector lccode slihseacode hhnum hid fooditem ann_purch weight hhsize
order region district chiefdom section eacode sector lccode slihseacode hhnum hid fooditem ann_purch weight hhsize


compress
saveold "$slihs2011temp\Filtered Sec13A_food purchase.dta", replace

compress
saveold "$slihs2011fintabs\Filtered Sec13A_food purchase.dta", replace


**above file will be merged for all consumption for CPI unit.
*this file can also be used to derive what kind of basket the food consume of the say the poorest population (e.g. X% of population).
*see section ALL ITEMS MERGED.
*all files named "*_filtered.dta" are the files to merge for CPI section use.


**********************************************************

***Step 3: Aggregating by broad food groups.
*data already annualized by item.

use "$slihs2011temp\Filtered Sec13A_Food purchase.dta", clear

gen  fdriceby=ann_purch  if inrange(fooditem,6,7)												//local and imported rice
gen  fdmaizby=ann_purch  if fooditem==4 | fooditem==5 | fooditem==20	  								//maize, maize flour, and maize products
gen  fdcereby=ann_purch  if inrange(fooditem,1,3) | fooditem==8 | fooditem==12 | inrange(fooditem,21,23)	//millet, guinea corn, sorghum, other grains, flours, and flour products
gen  fdbrdby=ann_purch   if fooditem==9 | fooditem==10												//bread and buns
gen  fdtubby=ann_purch   if inrange(fooditem,30,40)												//starchy root crops, tubers, plantain, and their products
gen  fdbeanby=ann_purch  if inrange(fooditem,50,69)												//beans and peas
gen  fdfatsby=ann_purch  if inrange(fooditem,70,79)										 		//vegetable oil, animal and vegetable fats, and oil-rich nuts
gen  fdpoulby=ann_purch  if inrange(fooditem,120,124)											//poultry
gen  fdmeatby=ann_purch  if inrange(fooditem,130,136)											//meat and meat products
gen  fdfishby=ann_purch  if inrange(fooditem,140,148)											//fish, snails and frogs
gen  fddairby=ann_purch  if inrange(fooditem,125,127) | inrange(fooditem,150,159)					//eggs, milk, and milk products
gen  fdvegby=ann_purch   if inrange(fooditem,101,117)											//vegetables and vegetable products
gen  fdfrutby=ann_purch  if inrange(fooditem,80,96)												//fruits and fruit products
gen  fdswtby=ann_purch   if fooditem==11 | inrange(fooditem,180,186)								//jams, honey, sugar, and confectionary
gen  fdbevby=ann_purch   if inrange(fooditem,160,164) | fooditem==176 | inrange(fooditem,200,209)		//non-alcoholic beverages
gen  fdalcby=ann_purch   if fooditem==177 | inrange(fooditem,900,910)								//alcoholic beverages
gen  fdrestby=ann_purch  if inrange(fooditem,170,175) | fooditem==178								//meals consumed outside of the home
gen  fdothby=ann_purch   if inrange(fooditem,190,194)											//garlic, salt, pepper, and other miscellaneous foods
gen  tobacco=ann_purch   if inrange(fooditem,951,954)											//tobacco

collapse (sum) fdmaizby fdriceby fdcereby fdbrdby fdtubby fdpoulby fdmeatby fdfishby fddairby fdfatsby ///
	fdfrutby fdvegby fdbeanby fdswtby fdbevby fdalcby fdrestby fdothby tobacco, by(hid)

compress
saveold "$slihs2011temp\table1agg.dta", replace

**********************************************************

***Step 4: Derive total food and other variables.

use "$slihs2011temp\table1agg.dta", clear

recode fd* ( . = 0 )

egen fdtotby = rsum(fdmaizby fdriceby fdcereby fdbrdby fdtubby fdpoulby fdmeatby fdfishby fddairby fdfatsby ///
	fdfrutby fdvegby fdbeanby fdswtby fdbevby fdalcby fdrestby fdothby) 
lab var fdtotby  "Total purchased food expenditure"

lab var fdmaizby "Maize grain and flours purchased"
lab var fdriceby "Rice in all forms purchased"
lab var fdcereby "Other cereals purchased"
lab var fdbrdby  "Bread and the like purchased"
lab var fdtubby  "Bananas & tubers purchased"
lab var fdpoulby "Poultry purchased"
lab var fdmeatby "Meats purchased"
lab var fdfishby "Fish & seafood purchased"
lab var fddairby "Milk, cheese & eggs purchased"
lab var fdfatsby "Oils, fats & oil-rich nuts purchased"
lab var fdfrutby "Fruits purchased"
lab var fdvegby  "Vegetables excludes pulses (beans & peas) purchased"
lab var fdbeanby "Pulses (beans & peas) purchased"
lab var fdswtby  "Sugar, jam, honey, chocolate & confectionary purchased"
lab var fdbevby  "Non-alcoholic purchased"
lab var fdalcby  "Alcoholic beverages purchased"
lab var fdrestby "Food consumed in restaurants & canteens purchased"
lab var fdothby  "Food items not mentioned above purchased"
lab var fdtotby  "Total expenditure of purchased foods"


**survey used 7 day recall periods.

gen fdby_tr = 2 
lab var fdby_tr "Food purchases recall period"
lab val fdby_tr fdby_tr
lab define fdby_tr  1 "Day" 2 "Less than a Week/week"  3 "Two-week"  4 "Month"  5 "Quarterly"  6 "Semi-annual"  7 "Annual"


**count how many households have zero purchases.
*HHs that have zero food (food purchases and own food) will be dropped.

gen fdby0=1  if   (fdtotby==0 | fdtotby==.)
lab var fdby0 "Zero or missing own consumption"
tab fdby0

sum fdmaizby fdriceby fdcereby fdbrdby fdtubby fdpoulby fdmeatby fdfishby fddairby fdfatsby fdfrutby fdvegby fdbeanby ///
	fdswtby fdbevby fdalcby fdrestby fdothby fdtotby 

keep  hid fdby_tr fdmaizby fdriceby fdcereby fdbrdby  fdtubby  fdpoulby fdmeatby fdfishby fddairby fdfatsby fdfrutby ///
	fdvegby  fdbeanby fdswtby  fdbevby  fdalcby  fdrestby fdothby fdtotby

order hid fdby_tr fdmaizby fdriceby fdcereby fdbrdby  fdtubby  fdpoulby fdmeatby fdfishby fddairby fdfatsby fdfrutby ///
	fdvegby  fdbeanby fdswtby  fdbevby  fdalcby  fdrestby fdothby fdtotby

sort hid

describe
compress
saveold "$slihs2011fintabs\Table 2 foodpurchexp.dta", replace


**********************************************************

***Step 5: filter out tobacco.

use "$slihs2011temp\table1agg.dta", clear

keep hid tobacco

sort hid

compress
saveold "$slihs2011temp\Filtered Sec13A_Tobacco.dta", replace




**************************************************************************************************************************
***Table 3: FOOD OWN CONSUMPTION
**************************************************************************************************************************
*Purpose: To gather the variables from the raw data required for calculating food own consumption.
*Data: Section 11: Agriculture Part 12H: Consumption of own produce (page 18-28).
*bear in mind that own-consumption refers, farm food produce, food from enterprise and food stocks.


use "$slihs2011final\Section 12 Part H Own food consumption.dta", clear

***Step 1: Filtering out items not consumed.

describe
duplicates report
duplicates drop
summarize


rename s12hitem fooditem
codebook fooditem				
tab fooditem, m			
drop if fooditem==0 | fooditem==7 | fooditem==21 | fooditem==22 | fooditem==28 | fooditem==39 | fooditem==74 | ///
	fooditem==94 | fooditem==116 | fooditem==149 | fooditem==158 | fooditem==180 | fooditem==205 | fooditem==902

*keep own consumption quantities only and price.

keep region district stratum chiefdom section eacode sector lccode slihseacode hhnum hid fooditem ///
	s12hq2 s12hq5 s12hq6 s12hq7 s12hq8 s12hq9 s12hq10 s12hq11

recode  s12hq5 s12hq6 s12hq7 s12hq8 s12hq9 s12hq10 s12hq11 (0=.)

*if all missing information drop.

gen invalid=1  if  s12hq2==2 &  s12hq5==. &  s12hq6==. &  s12hq7==. &  s12hq8==. &  s12hq9==. &  s12hq10==. &  s12hq11==.
tab invalid
keep if invalid==.

*if all quantities missing drop.

drop invalid
gen invalid=1  if  s12hq2==1 &  s12hq5==. &  s12hq6==. &  s12hq7==. &  s12hq8==. &  s12hq9==.  
tab invalid
keep if invalid==.
drop invalid


gen valid=1
sort slihseacode hhnum
merge slihseacode hhnum using "$slihs2011final\Part B Date of interview.dta"
tab _merge
drop _merge

sort slihseacode hhnum
merge m:1 slihseacode hhnum using "$slihs2011temp\hhsize.dta"
tab _merge
drop _merge


gen hyphen="-"
egen year_mth=concat(int_year hyphen int_month)
keep if valid==1

sort hid fooditem

**********************************************************

***Step 2: edit outliers.
*Compute estimate of cost of food consumed from home production, by food item.

egen tqty=rsum(s12hq5 - s12hq9)			//(item-level) 25-day (over 5 visits) consumption from home production, in units
recode tqty (0=.)
gen uval=tqty*s12hq10					//25-day (over 5 visits) consumption from home production, in value (i.e., times unit sale price)
gen ann_con_ori=uval*(365/25)			//annual consumption from home production, in value


*********************************************

**replace the outliers for quantities.

replace  s12hq7=1     		  if hid=="111101004" & fooditem==900
replace  s12hq5=1     		  if hid=="111101903" & fooditem==900
replace  s12hq9=.     		  if hid=="111104903" & fooditem==35
replace  s12hq8=2     		  if hid=="112106706" & fooditem==70
replace  s12hq9=1     		  if hid=="112106706" & fooditem==70
replace  s12hq6=1     if hid=="112107709" & fooditem==86
replace  s12hq7=1     if hid=="112107709" & fooditem==86
replace  s12hq8=1     if hid=="112107709" & fooditem==86
replace  s12hq9=1     if hid=="112107709" & fooditem==86
replace  s12hq5=s12hq5/100    if (hid=="112107901" | hid=="112107902"  | hid=="112107903"  | hid=="112107904" | ///
	hid=="112107905" | hid=="112107906" | hid=="112107907" | hid=="112107908" | hid=="112107909" | hid=="112107910") & s12hq5>=100 & s12hq5<1000
replace  s12hq5=s12hq5/1000   if (hid=="112107901" | hid=="112107902"  | hid=="112107903"  | hid=="112107904" | ///
	hid=="112107905" | hid=="112107906" | hid=="112107907" | hid=="112107908" | hid=="112107909" | hid=="112107910") & s12hq5>=1000 & s12hq5~=.
replace  s12hq6=s12hq6/100    if (hid=="112107901" | hid=="112107902"  | hid=="112107903"  | hid=="112107904" | ///
	hid=="112107905" | hid=="112107906" | hid=="112107907" | hid=="112107908" | hid=="112107909" | hid=="112107910") & s12hq6>=100 & s12hq6<1000
replace  s12hq6=s12hq6/1000   if (hid=="112107901" | hid=="112107902"  | hid=="112107903"  | hid=="112107904" | ///
	hid=="112107905" | hid=="112107906" | hid=="112107907" | hid=="112107908" | hid=="112107909" | hid=="112107910") & s12hq6>=1000 & s12hq6~=.
replace  s12hq7=s12hq7/100    if (hid=="112107901" | hid=="112107902"  | hid=="112107903"  | hid=="112107904" | ///
	hid=="112107905" | hid=="112107906" | hid=="112107907" | hid=="112107908" | hid=="112107909" | hid=="112107910") & s12hq7>=100 & s12hq7<1000
replace  s12hq7=s12hq7/1000   if (hid=="112107901" | hid=="112107902"  | hid=="112107903"  | hid=="112107904" | ///
	hid=="112107905" | hid=="112107906" | hid=="112107907" | hid=="112107908" | hid=="112107909" | hid=="112107910") & s12hq7>=1000 & s12hq7~=.
replace  s12hq8=s12hq8/100    if (hid=="112107901" | hid=="112107902"  | hid=="112107903"  | hid=="112107904" | ///
	hid=="112107905" | hid=="112107906" | hid=="112107907" | hid=="112107908" | hid=="112107909" | hid=="112107910") & s12hq8>=100 & s12hq8<1000
replace  s12hq8=s12hq8/1000   if (hid=="112107901" | hid=="112107902"  | hid=="112107903"  | hid=="112107904" | ///
	hid=="112107905" | hid=="112107906" | hid=="112107907" | hid=="112107908" | hid=="112107909" | hid=="112107910") & s12hq8>=1000 & s12hq8~=.
replace  s12hq9=s12hq9/100    if (hid=="112107901" | hid=="112107902"  | hid=="112107903"  | hid=="112107904" | ///
	hid=="112107905" | hid=="112107906" | hid=="112107907" | hid=="112107908" | hid=="112107909" | hid=="112107910") & s12hq9>=100 & s12hq9<1000
replace  s12hq9=s12hq9/1000   if (hid=="112107901" | hid=="112107902"  | hid=="112107903"  | hid=="112107904" | ///
	hid=="112107905" | hid=="112107906" | hid=="112107907" | hid=="112107908" | hid=="112107909" | hid=="112107910") & s12hq9>=1000 & s12hq9~=.
replace s12hq5=1      if hid=="112108301" & fooditem==101
replace s12hq6=1      if hid=="112108301" & fooditem==101
replace s12hq7=1      if hid=="112108301" & fooditem==101
replace s12hq8=1      if hid=="112108301" & fooditem==101
replace s12hq5=1      if hid=="112108507" & fooditem==63
replace s12hq6=1      if hid=="112108507" & fooditem==63
replace s12hq7=1      if hid=="112108507" & fooditem==63
replace s12hq8=1      if hid=="112108507" & fooditem==63
replace s12hq9=1      if hid=="112108507" & fooditem==63
replace s12hq6=2      if hid=="112209706" & fooditem==160
replace  s12hq5=s12hq5/1000   if (hid=="113115310") & fooditem==70 
replace  s12hq6=s12hq6/1000   if (hid=="113115310") & fooditem==70 
replace  s12hq7=s12hq7/1000   if (hid=="113115310") & fooditem==70 
replace  s12hq8=s12hq8/1000   if (hid=="113115310") & fooditem==70 
replace  s12hq9=s12hq9/1000   if (hid=="113115310") & fooditem==70 
replace  s12hq5=1     if hid=="221118908" & fooditem==30
replace  s12hq6=1     if hid=="221118908" & fooditem==30
replace  s12hq7=1     if hid=="221118908" & fooditem==30
replace  s12hq8=1     if hid=="221118908" & fooditem==30
replace  s12hq9=1     if hid=="221118908" & fooditem==30
replace  s12hq5=1     if hid=="113115803" & fooditem==63
replace  s12hq6=1     if hid=="113115803" & fooditem==63
replace  s12hq7=1     if hid=="113115803" & fooditem==63
replace  s12hq8=1     if hid=="113115803" & fooditem==63
replace  s12hq9=1     if hid=="113115803" & fooditem==63
replace  s12hq5=4     if hid=="113217104" & fooditem==36
replace  s12hq6=0     if hid=="113217104" & fooditem==36
replace  s12hq7=0     if hid=="113217104" & fooditem==36
replace  s12hq8=0     if hid=="113217104" & fooditem==36
replace  s12hq9=0     if hid=="113217104" & fooditem==36
replace  s12hq5=s12hq5/100    if (hid=="221118101" | hid=="221118102"  | hid=="221118103"  | hid=="221118104" | ///
	hid=="221118105" | hid=="221118106" | hid=="221118107" | hid=="221118108" | hid=="221118109" | hid=="221118110") & s12hq5>=100 & s12hq5<1000
replace  s12hq5=s12hq5/1000   if (hid=="221118101" | hid=="221118102"  | hid=="221118103"  | hid=="221118104" | ///
	hid=="221118105" | hid=="221118106" | hid=="221118107" | hid=="221118108" | hid=="221118109" | hid=="221118110") & s12hq5>=1000 & s12hq5~=.
replace  s12hq6=s12hq6/100    if (hid=="221118101" | hid=="221118102"  | hid=="221118103"  | hid=="221118104" | ///
	hid=="221118105" | hid=="221118106" | hid=="221118107" | hid=="221118108" | hid=="221118109" | hid=="221118110") & s12hq6>=100 & s12hq6<1000
replace  s12hq6=s12hq6/1000   if (hid=="221118101" | hid=="221118102"  | hid=="221118103"  | hid=="221118104" | ///
	hid=="221118105" | hid=="221118106" | hid=="221118107" | hid=="221118108" | hid=="221118109" | hid=="221118110") & s12hq6>=1000 & s12hq6~=.
replace  s12hq7=s12hq7/100    if (hid=="221118101" | hid=="221118102"  | hid=="221118103"  | hid=="221118104" | ///
	hid=="221118105" | hid=="221118106" | hid=="221118107" | hid=="221118108" | hid=="221118109" | hid=="221118110") & s12hq7>=100 & s12hq7<1000
replace  s12hq7=s12hq7/1000   if (hid=="221118101" | hid=="221118102"  | hid=="221118103"  | hid=="221118104" | ///
	hid=="221118105" | hid=="221118106" | hid=="221118107" | hid=="221118108" | hid=="221118109" | hid=="221118110") & s12hq7>=1000 & s12hq7~=.
replace  s12hq8=s12hq8/100    if (hid=="221118101" | hid=="221118102"  | hid=="221118103"  | hid=="221118104" | ///
	hid=="221118105" | hid=="221118106" | hid=="221118107" | hid=="221118108" | hid=="221118109" | hid=="221118110") & s12hq8>=100 & s12hq8<1000
replace  s12hq8=s12hq8/1000   if (hid=="221118101" | hid=="221118102"  | hid=="221118103"  | hid=="221118104" | ///
	hid=="221118105" | hid=="221118106" | hid=="221118107" | hid=="221118108" | hid=="221118109" | hid=="221118110") & s12hq8>=1000 & s12hq8~=.
replace  s12hq9=s12hq9/100    if (hid=="221118101" | hid=="221118102"  | hid=="221118103"  | hid=="221118104" | ///
	hid=="221118105" | hid=="221118106" | hid=="221118107" | hid=="221118108" | hid=="221118109" | hid=="221118110") & s12hq9>=100 & s12hq9<1000
replace  s12hq9=s12hq9/1000   if (hid=="221118101" | hid=="221118102"  | hid=="221118103"  | hid=="221118104" | ///
	hid=="221118105" | hid=="221118106" | hid=="221118107" | hid=="221118108" | hid=="221118109" | hid=="221118110") & s12hq9>=1000 & s12hq9~=.
replace  s12hq5=s12hq5/100    if (hid=="221119001" | hid=="221119002"  | hid=="221119003"  | hid=="221119004" | ///
	hid=="221119005" | hid=="221119006" | hid=="221119007" | hid=="221119008" | hid=="221119009" | hid=="221119010") & s12hq5>=100 & s12hq5<1000
replace  s12hq5=s12hq5/1000   if (hid=="221119001" | hid=="221119002"  | hid=="221119003"  | hid=="221119004" | ///
	hid=="221119005" | hid=="221119006" | hid=="221119007" | hid=="221119008" | hid=="221119009" | hid=="221119010") & s12hq5>=1000 & s12hq5~=.
replace  s12hq6=s12hq6/100    if (hid=="221119001" | hid=="221119002"  | hid=="221119003"  | hid=="221119004" | ///
	hid=="221119005" | hid=="221119006" | hid=="221119007" | hid=="221119008" | hid=="221119009" | hid=="221119010") & s12hq6>=100 & s12hq6<1000
replace  s12hq6=s12hq6/1000   if (hid=="221119001" | hid=="221119002"  | hid=="221119003"  | hid=="221119004" | ///
	hid=="221119005" | hid=="221119006" | hid=="221119007" | hid=="221119008" | hid=="221119009" | hid=="221119010") & s12hq6>=1000 & s12hq6~=.
replace  s12hq7=s12hq7/100    if (hid=="221119001" | hid=="221119002"  | hid=="221119003"  | hid=="221119004" | ///
	hid=="221119005" | hid=="221119006" | hid=="221119007" | hid=="221119008" | hid=="221119009" | hid=="221119010") & s12hq7>=100 & s12hq7<1000
replace  s12hq7=s12hq7/1000   if (hid=="221119001" | hid=="221119002"  | hid=="221119003"  | hid=="221119004" | ///
	hid=="221119005" | hid=="221119006" | hid=="221119007" | hid=="221119008" | hid=="221119009" | hid=="221119010") & s12hq7>=1000 & s12hq7~=.
replace  s12hq8=s12hq8/100    if (hid=="221119001" | hid=="221119002"  | hid=="221119003"  | hid=="221119004" | ///
	hid=="221119005" | hid=="221119006" | hid=="221119007" | hid=="221119008" | hid=="221119009" | hid=="221119010") & s12hq8>=100 & s12hq8<1000
replace  s12hq8=s12hq8/1000   if (hid=="221119001" | hid=="221119002"  | hid=="221119003"  | hid=="221119004" | ///
	hid=="221119005" | hid=="221119006" | hid=="221119007" | hid=="221119008" | hid=="221119009" | hid=="221119010") & s12hq8>=1000 & s12hq8~=.
replace  s12hq9=s12hq9/100    if (hid=="221119001" | hid=="221119002"  | hid=="221119003"  | hid=="221119004" | ///
	hid=="221119005" | hid=="221119006" | hid=="221119007" | hid=="221119008" | hid=="221119009" | hid=="221119010") & s12hq9>=100 & s12hq9<1000
replace  s12hq9=s12hq9/1000   if (hid=="221119001" | hid=="221119002"  | hid=="221119003"  | hid=="221119004" | ///
	hid=="221119005" | hid=="221119006" | hid=="221119007" | hid=="221119008" | hid=="221119009" | hid=="221119010") & s12hq9>=1000 & s12hq9~=.
replace  s12hq5=s12hq5/100    if (hid=="221119601" | hid=="221119602"  | hid=="221119603"  | hid=="221119604" | ///
	hid=="221119605" | hid=="221119606" | hid=="221119607" | hid=="221119608" | hid=="221119609" | hid=="221119610") & s12hq5>=100 & s12hq5<1000
replace  s12hq5=s12hq5/1000   if (hid=="221119601" | hid=="221119602"  | hid=="221119603"  | hid=="221119604" | ///
	hid=="221119605" | hid=="221119606" | hid=="221119607" | hid=="221119608" | hid=="221119609" | hid=="221119610") & s12hq5>=1000 & s12hq5~=.
replace  s12hq6=s12hq6/100    if (hid=="221119601" | hid=="221119602"  | hid=="221119603"  | hid=="221119604" | ///
	hid=="221119605" | hid=="221119606" | hid=="221119607" | hid=="221119608" | hid=="221119609" | hid=="221119610") & s12hq6>=100 & s12hq6<1000
replace  s12hq6=s12hq6/1000   if (hid=="221119601" | hid=="221119602"  | hid=="221119603"  | hid=="221119604" | ///
	hid=="221119605" | hid=="221119606" | hid=="221119607" | hid=="221119608" | hid=="221119609" | hid=="221119610") & s12hq6>=1000 & s12hq6~=.
replace  s12hq7=s12hq7/100    if (hid=="221119601" | hid=="221119602"  | hid=="221119603"  | hid=="221119604" | ///
	hid=="221119605" | hid=="221119606" | hid=="221119607" | hid=="221119608" | hid=="221119609" | hid=="221119610") & s12hq7>=100 & s12hq7<1000
replace  s12hq7=s12hq7/1000   if (hid=="221119601" | hid=="221119602"  | hid=="221119603"  | hid=="221119604" | ///
	hid=="221119605" | hid=="221119606" | hid=="221119607" | hid=="221119608" | hid=="221119609" | hid=="221119610") & s12hq7>=1000 & s12hq7~=.
replace  s12hq8=s12hq8/100    if (hid=="221119601" | hid=="221119602"  | hid=="221119603"  | hid=="221119604" | ///
	hid=="221119605" | hid=="221119606" | hid=="221119607" | hid=="221119608" | hid=="221119609" | hid=="221119610") & s12hq8>=100 & s12hq8<1000
replace  s12hq8=s12hq8/1000   if (hid=="221119601" | hid=="221119602"  | hid=="221119603"  | hid=="221119604" | ///
	hid=="221119605" | hid=="221119606" | hid=="221119607" | hid=="221119608" | hid=="221119609" | hid=="221119610") & s12hq8>=1000 & s12hq8~=.
replace  s12hq9=s12hq9/100    if (hid=="221119601" | hid=="221119602"  | hid=="221119603"  | hid=="221119604" | ///
	hid=="221119605" | hid=="221119606" | hid=="221119607" | hid=="221119608" | hid=="221119609" | hid=="221119610") & s12hq9>=100 & s12hq9<1000
replace  s12hq9=s12hq9/1000   if (hid=="221119601" | hid=="221119602"  | hid=="221119603"  | hid=="221119604" | ///
	hid=="221119605" | hid=="221119606" | hid=="221119607" | hid=="221119608" | hid=="221119609" | hid=="221119610") & s12hq9>=1000 & s12hq9~=.
replace  s12hq5=s12hq5/100    if (hid=="221120701" | hid=="221120702"  | hid=="221120703"  | hid=="221120704" | ///
	hid=="221120705" | hid=="221120706" | hid=="221120707" | hid=="221120708" | hid=="221120709" | hid=="221120710") & s12hq5>=100 & s12hq5<1000
replace  s12hq5=s12hq5/1000   if (hid=="221120701" | hid=="221120702"  | hid=="221120703"  | hid=="221120704" | ///
	hid=="221120705" | hid=="221120706" | hid=="221120707" | hid=="221120708" | hid=="221120709" | hid=="221120710") & s12hq5>=1000 & s12hq5~=.
replace  s12hq6=s12hq6/100    if (hid=="221120701" | hid=="221120702"  | hid=="221120703"  | hid=="221120704" | ///
	hid=="221120705" | hid=="221120706" | hid=="221120707" | hid=="221120708" | hid=="221120709" | hid=="221120710") & s12hq6>=100 & s12hq6<1000
replace  s12hq6=s12hq6/1000   if (hid=="221120701" | hid=="221120702"  | hid=="221120703"  | hid=="221120704" | ///
	hid=="221120705" | hid=="221120706" | hid=="221120707" | hid=="221120708" | hid=="221120709" | hid=="221120710") & s12hq6>=1000 & s12hq6~=.
replace  s12hq7=s12hq7/100    if (hid=="221120701" | hid=="221120702"  | hid=="221120703"  | hid=="221120704" | ///
	hid=="221120705" | hid=="221120706" | hid=="221120707" | hid=="221120708" | hid=="221120709" | hid=="221120710") & s12hq7>=100 & s12hq7<1000
replace  s12hq7=s12hq7/1000   if (hid=="221120701" | hid=="221120702"  | hid=="221120703"  | hid=="221120704" | ///
	hid=="221120705" | hid=="221120706" | hid=="221120707" | hid=="221120708" | hid=="221120709" | hid=="221120710") & s12hq7>=1000 & s12hq7~=.
replace  s12hq8=s12hq8/100    if (hid=="221120701" | hid=="221120702"  | hid=="221120703"  | hid=="221120704" | ///
	hid=="221120705" | hid=="221120706" | hid=="221120707" | hid=="221120708" | hid=="221120709" | hid=="221120710") & s12hq8>=100 & s12hq8<1000
replace  s12hq8=s12hq8/1000   if (hid=="221120701" | hid=="221120702"  | hid=="221120703"  | hid=="221120704" | ///
	hid=="221120705" | hid=="221120706" | hid=="221120707" | hid=="221120708" | hid=="221120709" | hid=="221120710") & s12hq8>=1000 & s12hq8~=.
replace  s12hq9=s12hq9/100    if (hid=="221120701" | hid=="221120702"  | hid=="221120703"  | hid=="221120704" | ///
	hid=="221120705" | hid=="221120706" | hid=="221120707" | hid=="221120708" | hid=="221120709" | hid=="221120710") & s12hq9>=100 & s12hq9<1000
replace  s12hq9=s12hq9/1000   if (hid=="221120701" | hid=="221120702"  | hid=="221120703"  | hid=="221120704" | ///
	hid=="221120705" | hid=="221120706" | hid=="221120707" | hid=="221120708" | hid=="221120709" | hid=="221120710") & s12hq9>=1000 & s12hq9~=.
replace  s12hq5=s12hq5/1000   if (hid=="222125603") & fooditem==900
replace  s12hq6=s12hq6/1000   if (hid=="222125603") & fooditem==900
replace  s12hq7=s12hq7/1000   if (hid=="222125603") & fooditem==900
replace  s12hq8=s12hq8/1000   if (hid=="222125603") & fooditem==900
replace  s12hq9=s12hq9/1000   if (hid=="222125603") & fooditem==900
replace  s12hq9=500           if (hid=="222125604") & fooditem==87
replace  s12hq9=500           if (hid=="222125609") & fooditem==87
replace  s12hq5=1             if (hid=="222125606") & fooditem==3
replace  s12hq6=1             if (hid=="222125606") & fooditem==3
replace  s12hq7=1             if (hid=="222125606") & fooditem==3
replace  s12hq8=1             if (hid=="222125606") & fooditem==3
replace  s12hq9=1             if (hid=="222125606") & fooditem==3
replace  s12hq5=s12hq5/1000   if (hid=="224134008") & fooditem==6
replace  s12hq6=s12hq6/1000   if (hid=="224134008") & fooditem==6
replace  s12hq7=s12hq7/1000   if (hid=="224134008") & fooditem==6
replace  s12hq8=s12hq8/1000   if (hid=="224134008") & fooditem==6
replace  s12hq9=s12hq9/1000   if (hid=="224134008") & fooditem==6
replace  s12hq5=s12hq5/100    if (hid=="225135601" | hid=="225135602") & s12hq5<1000
replace  s12hq5=s12hq5/1000   if (hid=="225135601" | hid=="225135602") & s12hq5>=1000 & s12hq5~=.
replace  s12hq6=s12hq6/100    if (hid=="225135601" | hid=="225135602") & s12hq6<1000
replace  s12hq6=s12hq6/1000   if (hid=="225135601" | hid=="225135602") & s12hq6>=1000 & s12hq6~=.
replace  s12hq7=s12hq7/100    if (hid=="225135601" | hid=="225135602") & s12hq7<1000
replace  s12hq7=s12hq7/1000   if (hid=="225135601" | hid=="225135602") & s12hq7>=1000 & s12hq7~=.
replace  s12hq8=s12hq8/100    if (hid=="225135601" | hid=="225135602") & s12hq8<1000
replace  s12hq8=s12hq8/1000   if (hid=="225135601" | hid=="225135602") & s12hq8>=1000 & s12hq8~=.
replace  s12hq9=s12hq9/100    if (hid=="225135601" | hid=="225135602") & s12hq9<1000
replace  s12hq9=s12hq9/1000   if (hid=="225135601" | hid=="225135602") & s12hq9>=1000 & s12hq9~=.
replace  s12hq5=6      		  if hid=="225136601" & fooditem==192
replace  s12hq9=.        	  if hid=="331140806" & fooditem==70
replace  s12hq10=800   		  if hid=="331140806" & fooditem==70
replace  s12hq6=1      		  if hid=="332146204" & fooditem==6
replace  s12hq7=1      		  if hid=="332146204" & fooditem==6
replace  s12hq8=1      		  if hid=="332146204" & fooditem==6
replace  s12hq9=1      		  if hid=="332146204" & fooditem==6
replace  s12hq9=22     		  if hid=="332146204" & fooditem==87
replace  s12hq9=25     		  if hid=="332145906" & fooditem==37

replace  s12hq5=s12hq5/100    if hid=="112109110" & s12hq5>=100 & s12hq5<1000
replace  s12hq6=s12hq6/100    if hid=="112109110" & s12hq6>=100 & s12hq6<1000
replace  s12hq7=s12hq7/100    if hid=="112109110" & s12hq7>=100 & s12hq7<1000
replace  s12hq8=s12hq8/100    if hid=="112109110" & s12hq8>=100 & s12hq8<1000
replace  s12hq9=s12hq9/100    if hid=="112109110" & s12hq9>=100 & s12hq9<1000
replace  s12hq5=s12hq5/1000   if (hid=="112209707" | hid=="112209708") & fooditem==160
replace  s12hq7=12            if hid=="112209710" & fooditem==124
replace  s12hq5=12            if hid=="112211607" & fooditem==6
replace  s12hq9=5             if hid=="113113208" & fooditem==102
replace  s12hq9=25            if hid=="113216607" & fooditem==6
replace  s12hq10=800          if hid=="113216607" & fooditem==6
replace  s12hq5=5             if hid=="221120403" & fooditem==900
replace  s12hq5=5         	  if hid=="221121508" & fooditem==87
replace  s12hq6=5     		  if hid=="221121508" & fooditem==87
replace  s12hq7=5     		  if hid=="221121508" & fooditem==87
replace  s12hq8=5     		  if hid=="221121508" & fooditem==87
replace  s12hq9=5     		  if hid=="221121508" & fooditem==87
replace  s12hq10=.    		  if hid=="221121508" & fooditem==87
replace  s12hq9=5     		  if hid=="222125604" & fooditem==87
replace  s12hq9=5     		  if hid=="222125609" & fooditem==87
replace  s12hq8=47    		  if hid=="223128808" & fooditem==6 
replace  s12hq9=.     		  if hid=="224130108" & fooditem==107
replace  s12hq6=9     		  if hid=="225236003" & fooditem==6
replace  s12hq7=4     		  if hid=="225236003" & fooditem==6
replace  s12hq9=.     		  if hid=="331139908" & fooditem==30
replace  s12hq5=1     		  if hid=="332146208" & fooditem==5
replace  s12hq6=1     		  if hid=="332146208" & fooditem==5
replace  s12hq7=1     		  if hid=="332146208" & fooditem==5
replace  s12hq8=1     		  if hid=="332146208" & fooditem==5
replace  s12hq9=1     		  if hid=="332146208" & fooditem==5
replace  s12hq7=22    		  if hid=="333148303" & fooditem==6
replace  s12hq8=22    		  if hid=="333148303" & fooditem==6
replace  s12hq5=4     		  if hid=="333148607" & fooditem==6
replace  s12hq6=2     		  if hid=="333148607" & fooditem==6
replace  s12hq6=5     		  if hid=="333149603" & fooditem==140
replace  s12hq9=.     		  if hid=="333149410" & fooditem==66 
replace  s12hq10=7500  		  if hid=="333149410" & fooditem==66 
replace  s12hq5=10     		  if hid=="334152703" & fooditem==61
replace  s12hq6=30     		  if hid=="334152703" & fooditem==61
replace  s12hq7=40     		  if hid=="334152703" & fooditem==61
replace  s12hq8=20     		  if hid=="334152703" & fooditem==61
replace  s12hq9=80     		  if hid=="334152703" & fooditem==61
replace  s12hq9=60     		  if hid=="334152703" & fooditem==63

egen tqty1=rsum(s12hq5 - s12hq9)			//(item-level) 25-day (over 5 visits) consumption from home production, in units
recode tqty1 (0=.)


*********************************************

**Identify outliers for prices
*impute price for missing.
*unit code of consumption missing for most items so will just have to price without unit of consumption.

*do manual edits for obvious outliers and then replace by std and for missing if need be.

tab s12hq10
gen price=s12hq10
count if price==0
recode price (0=.)

count if price==. & tqty1~=.    //about 1,600 observations.
gen invalid=1       if s12hq10==. & tqty1~=.
list slihseacode hhnum fooditem s12hq5 s12hq6 s12hq7 s12hq8 s12hq9 s12hq10 s12hq11 tqty1 if invalid==1,nolab
replace price=800   if hid=="331245605" & fooditem==6
replace price=1000  if hid=="223129201" & fooditem==30


*impute prices for missing items by unit code. 

preserve
bys region year_mth fooditem s12hq11:egen s12hq10_md=median(s12hq10) 
bys region year_mth fooditem s12hq11:egen s12hq10_sd=sd(s12hq10)
bys region year_mth fooditem s12hq11:egen s12hq10_iqr=iqr(s12hq10)
bys region year_mth fooditem s12hq11:egen s12hq10_nu=count(s12hq10)
bys region year_mth fooditem s12hq11:egen s12hq10_mdd=median(s12hq10)     if s12hq10>0 & s12hq10~=.

tabstat s12hq10_md s12hq10_mdd s12hq10_sd s12hq10_iqr s12hq10_nu,by(fooditem)

collapse s12hq10_mdd,by(region fooditem year_mth s12hq11)

sort region fooditem year_mth s12hq11

compress
saveold "$slihs2011temp\imputed prices.dta", replace
restore

sort region fooditem year_mth s12hq11
merge m:1 region fooditem year_mth s12hq11 using "$slihs2011temp\imputed prices.dta"
tab _merge
drop _merge


replace price=s12hq10_mdd   if price==. & tqty1~=.
count if price==. & tqty1~=.
list slihseacode hhnum fooditem s12hq5 s12hq6 s12hq7 s12hq8 s12hq9 s12hq10 s12hq11 tqty if price==. & tqty1~=.,nolab


*809 still missing - impute prices for missing items by unit code. 
*these have unit code missing and so median assigned.

gen impute=(price==. & tqty1~=.)

preserve
bys region fooditem s12hq11:egen s12hq10_md1=median(s12hq10) 
bys region fooditem s12hq11:egen s12hq10_sd1=sd(s12hq10)
bys region fooditem s12hq11:egen s12hq10_iqr1=iqr(s12hq10)
bys region fooditem s12hq11:egen s12hq10_nu1=count(s12hq10)
bys region fooditem s12hq11:egen s12hq10_mdd1=median(s12hq10)      

tabstat s12hq10_md1 s12hq10_mdd1 s12hq10_sd1 s12hq10_iqr1 s12hq10_nu1,by(fooditem)

collapse s12hq10_mdd1,by(region fooditem year_mth s12hq11)

sort region fooditem s12hq11

compress
saveold "$slihs2011temp\imputed prices1.dta", replace
restore

sort region fooditem s12hq11
merge m:1 region fooditem year_mth s12hq11 using "$slihs2011temp\imputed prices1.dta"
tab _merge
drop _merge


replace price=s12hq10_mdd1   if price==. & tqty1~=.
count if price==. & tqty1~=.
list slihseacode hhnum fooditem s12hq5 s12hq6 s12hq7 s12hq8 s12hq9 s12hq10 s12hq11 tqty if price==. & tqty1~=.,nolab


*about 26 items have no unit code and so difficult to impute prices.
*will use only standard units to derive prices (KILOGRAM).

preserve
keep if s12hq11==25 
bys region year_mth fooditem:egen s12hq10_md2=median(s12hq10)
bys region year_mth fooditem:egen s12hq10_sd2=sd(s12hq10)
bys region year_mth fooditem:egen s12hq10_iqr2=iqr(s12hq10)
bys region year_mth fooditem:egen s12hq10_nu2=count(s12hq10)
bys region year_mth fooditem:egen s12hq10_mdd2=median(s12hq10)      if s12hq10>0 & s12hq10~=.

tabstat s12hq10_md2 s12hq10_mdd2 s12hq10_sd2 s12hq10_iqr2 s12hq10_nu2,by(fooditem)

collapse s12hq10_mdd2,by(region year_mth fooditem)

sort region year_mth fooditem 

compress
saveold "$slihs2011temp\imputed prices2.dta", replace
restore


sort region year_mth fooditem 
merge m:1 region year_mth fooditem using "$slihs2011temp\imputed prices2.dta"
tab _merge
drop _merge

replace price=s12hq10_mdd2   if price==. & tqty1~=.
count if price==. & tqty1~=.


**22 missing

preserve
keep if s12hq11==25 
bys region fooditem:egen s12hq10_md3=median(s12hq10)
bys region fooditem:egen s12hq10_sd3=sd(s12hq10)
bys region fooditem:egen s12hq10_iqr3=iqr(s12hq10)
bys region fooditem:egen s12hq10_nu3=count(s12hq10)
bys region fooditem:egen s12hq10_mdd3=median(s12hq10)      if s12hq10>0 & s12hq10~=.

tabstat s12hq10_md3 s12hq10_mdd3 s12hq10_sd3 s12hq10_iqr3 s12hq10_nu3,by(fooditem)

collapse s12hq10_mdd3,by(region fooditem)

sort region fooditem 

compress
saveold "$slihs2011temp\imputed prices3.dta", replace
restore


sort region fooditem 
merge m:1 region fooditem using "$slihs2011temp\imputed prices3.dta"
tab _merge
drop _merge

replace price=s12hq10_mdd3   if price==. & tqty1~=.
count if price==. & tqty1~=.


**21 missing items no prices still.  Will use next available standard unit to assign price.  

preserve
bys region fooditem:egen s12hq10_md4=median(s12hq10)
bys region fooditem:egen s12hq10_sd4=sd(s12hq10)
bys region fooditem:egen s12hq10_iqr4=iqr(s12hq10)
bys region fooditem:egen s12hq10_nu4=count(s12hq10)
bys region fooditem:egen s12hq10_mdd4=median(s12hq10)      if s12hq10>0 & s12hq10~=.

tabstat s12hq10_md4 s12hq10_mdd4 s12hq10_sd4 s12hq10_iqr4 s12hq10_nu4,by(fooditem)

collapse s12hq10_mdd4,by(region fooditem)

sort region fooditem 

compress
saveold "$slihs2011temp\imputed prices4.dta", replace
restore


sort region fooditem 
merge m:1 region fooditem using "$slihs2011temp\imputed prices4.dta"
tab _merge
drop _merge

replace price=s12hq10_mdd4   if price==. & tqty1~=.
count if price==. & tqty1~=.
list slihseacode hhnum fooditem s12hq5 s12hq6 s12hq7 s12hq8 s12hq9 s12hq10 s12hq11 tqty if price==. & tqty1~=.,nolab


**21 missing items no prices still.  Will use next available standard unit to assign price.  

preserve
bys fooditem:egen s12hq10_md5=median(s12hq10)
bys fooditem:egen s12hq10_sd5=sd(s12hq10)
bys fooditem:egen s12hq10_iqr5=iqr(s12hq10)
bys fooditem:egen s12hq10_nu5=count(s12hq10)
bys fooditem:egen s12hq10_mdd5=median(s12hq10)      if s12hq10>0 & s12hq10~=.
	  
tabstat s12hq10_md5 s12hq10_mdd5 s12hq10_mdd5 s12hq10_sd5 s12hq10_iqr5 s12hq10_nu5,by(fooditem)

collapse s12hq10_mdd5,by(fooditem)

sort fooditem 

compress
saveold "$slihs2011temp\imputed prices5.dta", replace
restore


sort fooditem 
merge m:1 fooditem using "$slihs2011temp\imputed prices5.dta"
tab _merge
drop _merge

replace price=s12hq10_mdd5   if price==. & tqty1~=.
count if price==. & tqty1~=.
list slihseacode hhnum fooditem s12hq5 s12hq6 s12hq7 s12hq8 s12hq9 s12hq10 s12hq11 tqty if price==. & tqty1~=.,nolab

replace price=1000          if price==. & tqty1~=. & fooditem==190   //garlic 4 obs and all missing price and in Eastern region.  
                                                                     //Assigned 1/2 price of salt.
		
		
replace price=price/100 if fooditem==72 & hid=="112108302"			/* Kristen edit */
count if price==. & tqty1~=.


count if  s12hq10>=100000 &  s12hq10~=.
list  hid fooditem s12hq11 s12hq10 tqty1 price if  s12hq10>=100000 &  s12hq10~=.
replace price=s12hq10/1000   if price>=100000

count if  s12hq10>=50000 &  s12hq10~=.
list  hid fooditem s12hq11 s12hq10 tqty1 price if  s12hq10>=50000 &  s12hq10~=.
replace price=s12hq10/100    if price>=50000     //one HH bought a 50KG bag (s12hq11==6) of grains @50K and replaced by 500 

count if  s12hq10>=20000 &  s12hq10~=.
list  hid fooditem s12hq11 s12hq10 tqty1 hhsize price if  s12hq10>=20000 &  s12hq10~=.
count if price>=20000 & price~=.
replace price=s12hq10/100  if price>=20000


count if price==. & tqty1~=.
list  hid fooditem s12hq11 s12hq10 tqty1 hhsize price if price==. & tqty1~=.     //2 obs and will replace with national for no purchase unit

bys region year_mth fooditem:egen price_md=median(price)
bys region year_mth fooditem:egen price_mdd=median(price)
bys region year_mth fooditem:egen price_sd=sd(price)
bys region year_mth fooditem:egen price_iqr=iqr(price)
bys region year_mth fooditem:egen price_nu=count(price)

tabstat price_md price_mdd price_sd price_iqr price_nu,by(fooditem)
replace price=price_mdd  if price==. & tqty1~=.

drop price_md price_mdd price_sd price_iqr price_nu
bys region fooditem:egen price_md=median(price)
bys region fooditem:egen price_mdd=median(price)
bys region fooditem:egen price_sd=sd(price)
bys region fooditem:egen price_iqr=iqr(price)
bys region fooditem:egen price_nu=count(price)

tabstat price_md price_mdd price_sd price_iqr price_nu,by(fooditem)
replace price=price_mdd  if price==. & tqty1~=.

count if price==. & tqty1~=.


gen pctmcon=tqty1*price/hhsize
bys region year_mth fooditem s12hq11: egen pctmcon_mn=mean(pctmcon)    if pctmcon!=0
bys region year_mth fooditem s12hq11: egen pctmcon_md=median(pctmcon)  if pctmcon!=0
bys region year_mth fooditem s12hq11: egen pctmcon_sd=sd(pctmcon)      if pctmcon!=0

gen zscor=(pctmcon - pctmcon_mn)/pctmcon_sd
lab var zscor "Z scores for a normal distribution"

gen tmcon=tqty1*price
gen tmcon2=tmcon
count if zscor>3 & zscor~=.
tab fooditem if zscor>3 & zscor~=.
tab region   if zscor>3 & zscor~=.

count if zscor>4 & zscor~=.
tab fooditem if zscor>4 & zscor~=.
tab region   if zscor>4 & zscor~=.

replace tmcon2=pctmcon_md*hhsize   if zscor>4 & zscor~=.   	/* using higher threshhold for replacement since two substitutions were already done */

gen ann_con=tmcon2*(365/30)
lab var tmcon2    "Monthly expenditure (price/quantity editted)"
lab var ann_con   "Annual expenditure (price/quantity editted)"

sort  slihseacode
merge m:1 slihseacode using "$slihs2011final\Household cluster weights.dta"
tab _merge
keep if _merge==3
drop _merge

tabstat ann_con_ori ann_con [aw=weight],by(year_mth)  s(sum)  f(%18.2f)
tabstat ann_con_ori ann_con [aw=weight],by(year_mth)  s(mean)  f(%18.2f)

keep  region district chiefdom section eacode sector lccode slihseacode hhnum hid fooditem ann_con
order region district chiefdom section eacode sector lccode slihseacode hhnum hid fooditem ann_con

compress
saveold "$slihs2011temp\Filtered Sec12H_consumption of own food produced.dta", replace

compress
saveold "$slihs2011fintabs\Filtered Sec12H_consumption of own food produced.dta", replace


**above file will be merged for all consumption for CPI unit.
*this file ca also be used to derive what kind of basket the food consume of the say th epoorest population (e.g. X% of population).
*see section ALL ITEMS MERGED.


**********************************************************

***Step 3: Aggregating by broad food groups.

use "$slihs2011temp\Filtered Sec12H_consumption of own food produced.dta", clear

gen  fdricepr=ann_con if inrange(fooditem,6,7)												//local and imported rice
gen  fdmaizpr=ann_con if fooditem==4| fooditem==5 | fooditem==20									//Maize, maize flour, and maize products
gen  fdcerepr=ann_con if inrange(fooditem,1,3)| fooditem==8 | fooditem==12 | inrange(fooditem,21,23)	//Millet, millet flour, and guinea corn (sorghum)
gen  fdbrdpr=ann_con  if fooditem==9 | fooditem==10												//Purchases of bread and buns
gen  fdtubpr=ann_con  if inrange(fooditem,30,40)											//Starchy root crops, tubers, and plantain
gen  fdbeanpr=ann_con if inrange(fooditem,50,69)											//Beans and peas
gen  fdfatspr=ann_con  if inrange(fooditem,70,79)											//Vegetable oil, animal and vegetable fats, and oil-rich nuts
gen  fdpoulpr=ann_con if inrange(fooditem,120,124)											//Poultry
gen  fdmeatpr=ann_con if inrange(fooditem,130,136)											//Meat and meat products
gen  fdfishpr=ann_con if inrange(fooditem,140,148)											//Fish
gen  fddairpr=ann_con if inrange(fooditem,125,127) | inrange(fooditem,150,159)					//Milk, milk products, and eggs
gen  fdvegpr=ann_con  if inrange(fooditem,101,117)											//Avocados and other vegetables
gen  fdfrutpr=ann_con if inrange(fooditem,80,96)											//Fruits and fruit products
gen  fdswtpr=ann_con  if fooditem==11 | inrange(fooditem,180,186)								//Purchases of biscuits, jams, honey, sugar, and confectionary
gen  fdbevpr=ann_con  if inrange(fooditem,160,164) | fooditem==176 | inrange(fooditem,200,209)		//Non-alcoholic beverages
gen  fdalcpr=ann_con  if fooditem==177 | inrange(fooditem,900,910)								//Alcoholic beverages
gen  fdothpr=ann_con  if inrange(fooditem,190,194)											//Salt, pepper, and other miscellaneous foods
gen  fdrestpr=0

collapse (sum) fdmaizpr fdricepr fdcerepr fdbrdpr fdtubpr fdpoulpr fdmeatpr fdfishpr fddairpr fdfatspr fdfrutpr fdvegpr ///
	fdbeanpr fdswtpr fdbevpr fdalcpr fdrestpr fdothpr, by(hid)

compress
saveold "$slihs2011temp\Sec12H consumption of own food produced_Agg.dta", replace


**********************************************************

***Step 4.  Derive remaining variables.

use "$slihs2011temp\Sec12H consumption of own food produced_Agg.dta", clear

lab var fdbrdpr  "Bread and the like products auto-consumption"
lab var fdtubpr  "Tubers and plantains auto-consumption"
lab var fdpoulpr "Poultry auto-consumption"
lab var fdmeatpr "Meats auto-consumption"
lab var fdfishpr "Fish and seafood auto-consumption"
lab var fddairpr "Milk, cheese and eggs auto-consumption"
lab var fdfatspr "Oils, fats and oil-rich nuts auto-consumption"
lab var fdfrutpr "Fruits auto-consumption"
lab var fdvegpr  "Vegetables excludes pulses auto-consumption"
lab var fdbeanpr "Pulses (beans and peas) auto-consumption"
lab var fdswtpr  "Sugar, jam, honey, chocolate and confectionary auto-consumption"
lab var fdbevpr  "Non-alcoholic auto-consumption"
lab var fdalcpr  "Alcoholic beverages auto-consumption"
lab var fdrestpr "Food consumed in restaurants and canteens auto-consumption"
lab var fdothpr  "Food items not mentioned above auto-consumption"
lab var fdmaizpr "Maize auto-consumption"
lab var fdricepr "Rice auto-consumption"
lab var fdcerepr "Other cereals auto-consumption"

recode fd* ( . = 0 )

egen fdtotpr=rsum(fdbrdpr fdtubpr fdpoulpr fdmeatpr fdfishpr  fddairpr fdfatspr fdfrutpr fdvegpr fdbeanpr fdswtpr ///
	fdbevpr fdalcpr fdrestpr fdothpr fdmaizpr fdricepr fdcerepr)
lab var fdtotpr "Total value of auto-consumption food" 


*count how many households have zero own consumption.

gen fdpr0=1 if (fdtotpr==0 | fdtotpr==.)
lab var fdpr0 "Zero or missing own consumption"

tab fdpr0

sum fdmaizpr fdricepr fdcerepr fdbrdpr fdtubpr fdpoulpr fdmeatpr fdfishpr fddairpr fdfatspr fdfrutpr fdvegpr fdbeanpr ///
	fdswtpr fdbevpr fdalcpr fdrestpr fdothpr fdtotpr 

keep  hid fdmaizpr fdricepr fdcerepr fdbrdpr  fdtubpr  fdpoulpr fdmeatpr fdfishpr fddairpr fdfatspr fdfrutpr fdvegpr fdbeanpr ///
	fdswtpr  fdbevpr  fdalcpr  fdrestpr fdothpr fdtotpr

order hid fdmaizpr fdricepr fdcerepr fdbrdpr  fdtubpr  fdpoulpr fdmeatpr fdfishpr fddairpr fdfatspr fdfrutpr fdvegpr fdbeanpr ///
	fdswtpr  fdbevpr  fdalcpr  fdrestpr fdothpr fdtotpr

sort hid

compress
saveold "$slihs2011fintabs\Table 3 ownconsexp.dta", replace


