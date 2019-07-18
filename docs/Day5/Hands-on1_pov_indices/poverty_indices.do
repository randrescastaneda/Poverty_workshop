*===============================================================================
* HANDS-ON POVERTY TRAINING
* 09 Poverty Indices
*===============================================================================
clear
set more off

/*==================================================
download commands from SSC
==================================================*/

local cmds apoverty ainequal fastgini quantiles prosperity hoi /* 
*/   iop drdecomp skdecomp adecomp povdeco

foreach cmd of local cmds {
	capture which `cmd'
	if (_rc != 0) ssc install `cmd'
}

// ------------------------------------------------------------------------
// Load data
// ------------------------------------------------------------------------

datalibweb, type(GMD) country(PRY) year(2016) clear

*-------------------------------------------------------------------------------
*Density function and main statistics
*-------------------------------------------------------------------------------

kdensity welfare [aw=weight]

gen ln_welfare = ln(welfare) 
kdensity ln_welfare [aw=weight]

twoway (kdensity ln_welfare [aw=weight] if urban==1) /*
*/		(kdensity ln_welfare [aw=weight] if urban==0), /*
*/     legend(label(1 "urban") label(2 "rural")) 


* Urban/Rural
table urban   [aw=weight], c(mean welfare)

* subnatids
table subnatid [aw=weight], c(mean welfare)

* Quintiles
xtile quintile=welfare [aw=weight], nq(5)
table quintile [aw=weight], c(mean welfare)

* Whole Country
sum welfare 	 [aw=weight]

*-------------------------------------------------------------------------------
* Convert to 2011 PPP values
*-------------------------------------------------------------------------------

gen double welfare_ppp = welfare/cpi2011/icp2011/365


*-------------------------------------------------------------------------------
* Calculate poverty indices (FGT0, FGT1, FGT2) for the country as a whole. 
* Discuss results.	
*-------------------------------------------------------------------------------


local plines "1.9 3.2 5.5"
local wvar "welfare_ppp"
foreach pl of local plines	{
	gen pl_`=100*`pl'' = `pl'
	forval a=0/2	{
		gen fgt`a'_`=100*`pl'' = (`wvar'<`pl')*(1-(`wvar'/`pl'))^`a'
	}
}

tabstat fgt0* [w = weight]

* tabstatmat 
table year [w = weight], c(mean fgt0_190 mean fgt0_320 mean fgt0_550 )

apoverty welfare_ppp [w = weight] , line(1.9)


* 3.2.2	
*-------------------------------------------------------------------------------
* Calculate poverty measures by area and by subnatid.
*-------------------------------------------------------------------------------
tabstat fgt0* [w = weight]
tabstat fgt0* [w = weight], by(subnatid)

* tabstatmat 
table subnatid2 [w = weight], c(mean fgt0_190 mean fgt0_320 mean fgt0_550 )


*-------------------------------------------------------------------------------
*  MONOTONICITY
*-------------------------------------------------------------------------------

*-------------------------------------------------------------------------------
/*Reduce 25% the per capita expenditure of fgt0 individuals located 
in the third quintile among the fgt0. How much does the incidence in 
poverty change compared  to that of the initial distribution? What about 
the poverty gap and severity?*/
*-------------------------------------------------------------------------------

/*xtile fgt_qt = welfare [aw=weight] if fgt0_320==1, nq(5)
gen welfare_75 = welfare
replace welfare_75= welfare*0.75 if fgt_qt==3


assert welfare_75<welfare if fgt_qt==3
*/
local plines "1.9 3.2 5.5"
foreach pl of local plines	{
	local pl100 = 100*`pl'

	xtile fgt_qt_`pl100' = welfare_ppp [aw=weight] if fgt0_`pl100'==1, nq(5)
	gen     welfare_75_`pl100' = welfare_ppp
	replace welfare_75_`pl100' = welfare_ppp*0.75 if fgt_qt_`pl100'==3

	local wvar "welfare_75_`pl100'"
	forval a=0/2	{
		gen fgt`a'_`pl100'_75 = (`wvar'<`pl')*(1-(`wvar'/`pl'))^`a' 
	}
}

// headcount
tabstat fgt0_320 fgt0_320_75 [aw=weight], by(subnatid)

// Gap
tabstat fgt1_320 fgt1_320_75 [aw=weight], by(subnatid)

*-------------------------------------------------------------------------------
* Increase the welfare aggregate by transferring the gap to 20% of fgt0 
* individuals closest to the poverty line. Does the incidence in poverty change 
* compared to that of the initial distribution? What about the poverty gap and 
* severity? 
* How much is the direct total fiscal cost of this policy if there is perfect 
* target?
*-------------------------------------------------------------------------------

* HOMEWORK !!!

*-------------------------------------------------------------------------------
* 4.2 TRANSFER
*-------------------------------------------------------------------------------

*-------------------------------------------------------------------------------
* Reduce 20% the per capita expenditure of individuals in the second quintile 
* and distribute equally the total amount within the first quintile. 
* Calculate incidence, gap and severity and discuss.
*-------------------------------------------------------------------------------


gen transfer= welfare_ppp*0.20 if quintile==2
sum transfer [w=weight]
local transfer_tot=r(sum)

// Use $5.5 poor as examples
sum fgt0_550 if quintile==1 [w=weight]
local n_fgt_qt_1=r(sum_w)

local transfer_pc   = `transfer_tot'/`n_fgt_qt_1'

gen welfare_transfer= welfare_ppp + `transfer_pc' if quintile == 1
replace welfare_transfer= welfare_ppp *(1-0.2) if quintile == 2
replace welfare_transfer= welfare_ppp if quintile > 2 

povdeco welfare_transfer  [w=weight], pline(3.2) 
povdeco welfare_ppp [w=weight], pline(3.2) 


* 4.2.2	
*-------------------------------------------------------------------------------
* Reduce 10% the per capita expenditure of individuals in the fourth quintile 
* among the fgt0 and distribute equally the total amount within the fgt0 of the 
* fifth quintile. Calculate incidence, gap and severity and discuss.
*-------------------------------------------------------------------------------
* HOMEWORK !!!

*-------------------------------------------------------------------------------
* 4.3 DECOMPOSABILITY
*-------------------------------------------------------------------------------

* 4.3.1	
*-------------------------------------------------------------------------------
* Calculate the contribution of each area to the total poverty headcount.
*-------------------------------------------------------------------------------
* Compute n_j/n where n_j is the number of individuals livind in subnatid j
*-------------------------------------------------------------------------------

encode subnatid, gen(region)


sum weight
local n=r(sum)

levelsof region, local(regions)
local plines "1.9 3.2 5.5"


foreach pl of local plines	{
	local pl100 = 100*`pl'

	gen FGT0_share_`pl100' = .

	sum fgt0_`pl100' [w=weight]
	local fgt=r(mean)

	foreach region of local regions {
		sum weight if (region==`region')
		local n_r=r(sum)
		local sh_r = `n_r'/`n' // share of region
		
		sum fgt0_`pl100' if (region == `region') [w=weight]
		local fgt_r   = r(mean)  // fgt in region
		local fgt_r_s = `sh_r'* `fgt_r'/`fgt' // share of fgt in region
		
		replace FGT0_share_`pl100' = `fgt_r_s' if region==`region'
	}
}

tabstat FGT0_share_* [w=weight], by(region)

* Let's re-do everything by using the command povdeco, and saving the results in
* an Excell file
*-------------------------------------------------------------------------------

levelsof region, local(regions)
povdeco welfare_ppp [w=weight], pline(1.9) by(region)	

tempname A
foreach region of local regions {
	matrix `A' = nullmat(`A')  \ r(fgt0_`region') , r(share0_`region')
}

matrix A = `A'

