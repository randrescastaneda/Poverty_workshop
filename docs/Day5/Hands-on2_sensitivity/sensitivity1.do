*-------------------------------------------------------------------*
* Elasticity of Poverty with respect to Consumption
*-------------------------------------------------------------------*
*Open the dataset 
datalibweb, type(GMD) country(PRY) year(2016) clear


* Convert to 2011 PPP values
gen double welfare_ppp = welfare/cpi2011/icp2011/365


* 2.1 Calculate the elasticity of poverty with respect to the per capita expenditure for an increase of 10%

generate poor = welfare_ppp < 3.2
*Average consumption using original welfare_ppp
sum    welfare_ppp [aw = weight]
scalar mean_orig = r(mean)
*Headcount original welfare_ppp
sum    poor [aw = weight]
scalar hc_orig = r(mean)
*Increase welfare_ppp by 10% for all households
generate   welfare_ppp_10p = welfare_ppp * 1.1
generate 	 poor_10p  = welfare_ppp_10p < 3.2

*Average consumption using welfare_ppp_10p
sum    welfare_ppp_10p [aw = weight]
scalar mean_10p = r(mean)

*Headcount using welfare_ppp_10p
sum    poor_10p [aw = weight]
scalar hc_10p = r(mean)

*Calculate elasticity of headcount wrt to welfare_ppp	
scalar elasticity = [[(hc_10p - hc_orig)/hc_orig]/[(mean_10p-mean_orig)/mean_orig]]

display as text "{hline}" _n/*
 */ as text in smcl _col(5) in gr /*
 */ "Elasticity of Poverty with respect to Consumption =   " in yellow  /*
 */  elasticity  /*
 */ _newline   as text "{hline}" _newline

 *-------------------------------------------------------------------*
 * EXERCISE 2.3 and 2.4		 					    						
 * How much does the number of poor change if the total poverty line is 
 * increased/decreased by 5, 10 and 20 percent? 
 *-------------------------------------------------------------------*
 * EXERCISE 2.5		 					    						
 * Repeat Exercise 2.3 and 2.4 using the food poverty line
 *-------------------------------------------------------------------*
 *Open the dataset 
 datalibweb, type(GMD) country(PRY) year(2016) clear


 * Convert to 2011 PPP values
 gen double welfare_ppp = welfare/cpi2011/icp2011/365


 *Matrix of changes in poverty line(positive and negative)
 local changes "0 0.05 0.1 0.2 -0.05 -0.1 -0.2"
 *Save the number of columns(changes) as a local
 local cols = colsof(change)

 *Save two poverty lines in a local
 local pl 5.5 3.2

 *Estimating the number of poor by changes in poverty line
 foreach p of local pl {
 	local pl1 = 100*`p'
 	tempname P_`pl1'
 	foreach change of local changes {
 		tempvar	 poor
 		gen		`poor' = welfare_ppp < (`p' * (1 + `change'))
 		qui sum `poor' [aw = weight], meanonly
 		*Saving results in matrix
 		matrix `P_`pl1'' = nullmat(`P_`pl1'') \ r(mean)

 	}
 	local Ms = "`P_`pl1'',`Ms'" // matrcies
 }
 if regexm("`Ms'", "(.*)(,$)") local Ms = regexs(1)
 disp "`Ms'"
 *Showing results
 matrix poor_all = `Ms'
 mat colnames poor_all = `pl'
 mat rownames poor_all = `changes'
 matrix list poor_all

 *-------------------------------------------------------------------*
 * EXERCISE 2.7
 * How much do the Poverty Gap and Severity (Squared Poverty Gap)
 * change while increasing/decreasing
 * the poverty line by 5, 10 and 20 percent?		 					    						
 *-------------------------------------------------------------------*
 * EXERCISE 2.8		 					    						
 * Repeat Exercise 2.7 using the food poverty line
 *-------------------------------------------------------------------*


 *Matrix of changes in poverty line(positive and negative)
 local changes "0 0.05 0.1 0.2 -0.05 -0.1 -0.2"
 *Save the number of columns(changes) as a local
 local cols = colsof(change)

 *Save two poverty lines in a local
 local pl 5.5 3.2

 *Estimating the number of poor by changes in poverty line
 foreach p of local pl {
 	local pl1 = 100*`p'
 	forval a=0/2	{
 		tempname P_`pl1'_`a'
 		foreach change of local changes {

 			tempvar	 poor
				gen		`poor' = (welfare_ppp<`p' * (1 + `change'))*   /*
				*/ (1-(welfare_ppp/(`p'* (1 + `change'))))^`a'
				
				qui sum `poor' [aw = weight], meanonly

				*Saving results in matrix
				matrix `P_`pl1'_`a'' = nullmat(`P_`pl1'_`a'') \ r(mean)
			}
			local Ms = "`P_`pl1'_`a'',`Ms'" // matrcies
			local colnames "`colnames' `p'-`a'"
		}
	}
	if regexm("`Ms'", "(.*)(,$)") local Ms = regexs(1)
	disp "`Ms'"
	*Showing results
	matrix poor_all = `Ms'
	mat colnames poor_all = `colnames'
	mat rownames poor_all = `changes'
	matrix list poor_all


