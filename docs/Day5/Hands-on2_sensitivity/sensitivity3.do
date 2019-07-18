*-------------------------------------------------------------------*
* EXERCISE 4 Equivalence Scale			    						*
*-------------------------------------------------------------------*
* I. EQUIVALENCE SCALES
*-------------------------------------------------------------------*
*Open the dataset 

datalibweb, type(GMD) country(PRY) year(2016) clear

* Convert to 2011 PPP values
gen double welfare_ppp = welfare/cpi2011/icp2011/365


*Total Expenditure
gen tot_exp = welfare_ppp * hsize

*Identifying number of adults and number of children in the household
gen adults = 1 if age >= 15
egen nro_ad = sum(adults), by(hhid)

gen child = 1 if age < 15
egen nro_ch = sum(child), by(hhid)

* 3. Defining parameters of Equivalence scales: 
*      alpha = Adult equivalent; 
*      theta= Economies of scales

local alpha = "25 75 100"
local theta = "50 75 100"

local p_a = 2 // pivot adults
local p_c = 2 // pivot children

foreach a of local alpha {

	foreach te of local theta {

		*Calculate Eq 6.10 in Deaton and Zaidi

		*household pivot: 4 household members = 2 adults + 2 children 
		*numerator on the second term

		gen pivot_`a'_`te'   = (`p_a' + (`a'/100)*`p_c')^(`te'/100)

		*equivalence scales
		*denomenator on the first term

		gen ae_`a'_`te'      = (nro_ad + (`a'/100)* nro_ch)^(`te'/100)

		*x star (Eq 6.10 in Deaton and Zaidi)
		gen ae_exp_`a'_`te'  = (tot_exp / ae_`a'_`te') * /*
		*/ (pivot_`a'_`te'/(`p_a'+`p_c'))

		* II. POVERTY INCIDENCE CURVES
		*-------------------------------------------------------------------*
		* Children
		*-------------------------------------------------------------------*
		*Order per capita expenditure (horizontal axis)
		sort child ae_exp_`a'_`te', stable

		*Cumulative Density Function children (CDF)
		*Total population
		sum weight if child == 1
		local child_tot = r(sum)
		
		*Cumulative sum of population
		gen 	cum_ch_`a'_`te' = sum(weight) if child == 1
		
		*Cumulative sum of population normalized by total population 
		*(varies between 0 and 1)
		replace cum_ch_`a'_`te' = cum_ch_`a'_`te'/ `child_tot'

		*-------------------------------------------------------------------*
		* Adults
		*-------------------------------------------------------------------*
		*Order per capita expenditure (horizontal axis)
		sort adult ae_exp_`a'_`te', stable

		*Cumulative Density Function adults (CDF)
		*Total population
		sum weight if adult == 1
		local adult_tot = r(sum)

		*Cumulative sum of population
		gen 	cum_ad_`a'_`te' = sum(weight) if adult == 1

		*Cumulative sum of population normalized by total population 
		*(it varies between 0 and 1)
		replace cum_ad_`a'_`te' = cum_ad_`a'_`te'/ `adult_tot'

		*Checking results:
		sum cum_ch_`a'_`te' cum_ad_`a'_`te'

		*Graphs
	twoway (line cum_ch_`a'_`te' cum_ad_`a'_`te' ae_exp_`a'_`te' /*
		*/ if ae_exp_`a'_`te' <80, sort saving(al_`a'_`te',  replace))

	}					/*loop over theta ends*/
}						/*loop over alpha ends*/

	gr combine al_25_50.gph al_75_50.gph al_100_50.gph al_25_75.gph al_75_75.gph al_100_75.gph al_25_100.gph al_75_100.gph al_100_100.gph


	*a quick check on dominance
	*alpha = Adult equivalent; 
	*theta= Economies of scales

local alpha = "25 75 100"
local theta = "50 75 100"
tempname M

foreach a of local alpha{
	foreach t of local theta{
		foreach p of numlist 1 5 10 25 50 75 90 95 99 {
			
			qui sum ae_exp_`a'_`t', d
			local  check: di %9.4f r(p`p')
			
			qui sum cum_ch_`a'_`t' if ae_exp_`a'_`t' >=`check'*0.99 & /*
			*/ ae_exp_`a'_`t' <= `check'*1.01
			
			local ch_p: di %9.4f r(mean)
			
			qui sum cum_ad_`a'_`t' if ae_exp_`a'_`t' >=`check'*0.99 & /*
			*/ ae_exp_`a'_`t' <=`check'*1.01
			local ad_p: di %9.4f r(mean)

			*saving results in matrix
			
			matrix `M' = nullmat(`M') \ `a', `t', `p', `check', `ch_p', `ad_p', `ch_p' - `ad_p'

		}						/*loop over numlist ends*/			
	}							/*loop over theta ends*/
}								/*loop over alpha ends*/

matrix all = `M'

matrix colnames  all = alpha theta percentile pov_line child adult difference 
matrix list all

drop _all
svmat all, n(col)

* PLease, create a graph plotting the results. 

exit 


