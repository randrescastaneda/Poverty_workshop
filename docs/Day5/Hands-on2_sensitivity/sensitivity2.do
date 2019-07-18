*-------------------------------------------------------------------*
*Dominance Analysis	 					    						*
*-------------------------------------------------------------------*
*Open the dataset 
datalibweb, type(GMD) country(PRY) year(2016) clear


* Convert to 2011 PPP values
gen double welfare_ppp = welfare/cpi2011/icp2011/365


*-------------------------------------------------------------------*
* Urban Areas
*-------------------------------------------------------------------*
*Create a dummy variable for urban residents
	gen urb_aux = 1 if urban == 1

/**********Question***************************************************
	Suppose that we create urb_auz2 with the following line of command
	
	gen urb_auz2 = (urban==1)
	
	How is urb_aux different from urb_auz2?
*********************************************************************/

*Order per capita expenditure for urban residents (horizontal axis)
	sort urb_aux welfare_ppp, stable
*Cumulative Density Function urban areas (CDF)

*Cumulative sum of population
	gen cumul_urb = sum(weight) if urb_aux == 1

*Save total population as a local
	sum weight if urb_aux == 1
	local urban_tot = r(sum)
*Cumulative sum of population normalized by total population 

*(it varies between 0 and 1)
	replace   cumul_urb = cumul_urb/`urban_tot' if urb_aux == 1
	label var cumul_urb "CDF's urban population"

*-------------------------------------------------------------------*
* Rural Areas
*-------------------------------------------------------------------*
	*Create a dummy variable for rural residents
		gen rur_aux = 1 if urban == 0

	*Order per capita expenditure (horizontal axis)
		sort rur_aux welfare_ppp, stable

	*Cumulative Density Function rural areas (CDF)
	*Total rural population
		sum weight if rur_aux == 1
		local rural_tot = r(sum)

	*Cumulative sum of population
		gen cumul_rur = sum(weight) if rur_aux == 1

	*Cumulative sum of population normalized by total population 
	*it varies between 0 and 1
		replace   cumul_rur = cumul_rur/`rural_tot' if rur_aux == 1
		label var cumul_rur "CDF's rural areas"

	* Checking results:
		sum cumul_urb cumul_rur

*-------------------------------------------------------------------*
* Graphs
*-------------------------------------------------------------------*
	twoway(line cumul_urb cumul_rur welfare_ppp) if welfare_ppp < 100
	
