


**********************************************************

***Rent.

use "$slihs2011final\Section 6 Part A-H2 and I Housing and amenities.dta" , clear

**Step 1: annualize rent for uniforminity.

gen rent=(s6cq01a*12)    if (s6cq01b==1)
replace rent=(s6cq01a*4) if (s6cq01b==2)
replace rent=(s6cq01a*1) if (s6cq01b==3)

recode s6cq01a (0=.)
count if s6cq01a~=. & s6cq01b==.
list refno hid s6bq01 s6cq01a s6cq01b if s6cq01a~=. & s6cq01b==.
replace s6cq01a=900000     if refno=="579-05-1"
replace s6cq01b=3          if refno=="579-05-1"
replace s6cq01a=750000     if refno=="574-08-1"
replace s6cq01b=1          if refno=="574-08-1"
replace s6cq01a=60000      if refno=="597-09-1"
replace s6cq01a=48000      if refno=="633-01-1"
replace s6cq01a=26000      if refno=="118-05-1"
replace s6cq01b=1          if s6cq01a<100000 & s6cq01b==.
replace s6cq01b=3          if (s6cq01a>=100000 & s6cq01a~=.)& s6cq01b==.
replace s6cq01b=3          if refno=="113-08-1"
replace s6cq01a=10000      if refno=="171-10-1"
replace s6cq01a=15000      if refno=="170-06-1"
replace s6cq01a=12000      if  s6cq01a==12
replace s6cq01a=20000      if  s6cq01a==20
replace s6cq01a=10000      if  s6cq01a==10
replace s6cq01a=24000      if  s6cq01a==240
replace s6cq01a=45000      if  s6cq01a==450
replace s6cq01a=25000      if  s6cq01a==250
replace s6cq01a=13000      if  s6cq01a==13000000
replace s6cq01b=1          if  refno=="551-10-1"
replace s6cq01b=3          if  refno=="665-04-1"
replace s6cq01a=400000     if  s6cq01a==40000000
replace s6cq01b=3          if  refno=="674-08-1"
replace s6cq01a=1500000    if  s6cq01a==15000000
replace s6cq01b=3          if  refno=="681-02-1"
replace s6cq01b=3          if  refno=="681-06-1"
replace s6cq01a=.          if  refno=="001-07-1"

replace rent=(s6cq01a*12)  if (s6cq01b==1)
replace rent=(s6cq01a*4)   if (s6cq01b==2)
replace rent=(s6cq01a*1)   if (s6cq01b==3)
list slihseacode hhnum section rent  if rent<100     //only 4 cases
replace rent=rent*1000     if rent<100


tabstat rent, stat (n mean median sd min max) by(region)
tabstat rent, stat (n mean median sd min max) by(district)
tabstat rent, stat (n mean median sd min max) by(sector)

gen lnrent=ln(rent) 

*if missing rooms (which is impossible) assign mean by district.

tab s6aq02
bysort district: egen room_mn=mean(s6aq02)
lab var room_mn "Mean number of rooms by zone"

gen rooms=s6aq02
replace rooms=room_mn if s6aq02==.

gen lnroom=ln(rooms) 
gen lnroom2=lnroom*lnroom 


**create dummies.

*region: dummy=western urban.

tab region sector
gen southurb=3  if region==3 & sector==2
gen southrur=3  if region==3 & sector==1
gen easturb=1   if region==1 & sector==2
gen eastrur=1   if region==1 & sector==1
gen northurb=2  if region==2 & sector==2
gen northrur=2  if region==2 & sector==1
gen westurb=4   if region==4 & sector==2
gen westrur=4   if region==4 & sector==1

*water: dummy=private pipe.

tab s6fq04a
gen privpipe=s6fq04a<=2
gen pubpipe=inrange(s6fq04a,3,5) | s6fq04a==7 | s6fq04a>=9 & s6fq04a<=11 | s6fq04a==13 | s6fq04a==14
gen lake=s6fq04a==6 | s6fq04a==8 | s6fq04a== 12 | s6fq04a==15  | s6fq04a==16

*electricity: dummy=other lighting.

tab s6eq02a
gen eleclight=s6eq02a==3 | s6eq02a==4
gen othlight=s6eq02a<=2 | s6eq02a>=4 & s6eq02a<=9

*cooking fuel: dummy=other.

tab s6eq01a
gen woodcuk=s6eq01a==1
gen charcuk=s6eq01a==2
gen eleccuk=s6eq01a>=3 & s6eq01a<=5
gen othcuk=inrange(s6eq01a,6,8) | s6eq01a==.

*toilet: dummy=none.

tab s6fq17
gen flustoil=s6fq17<=4
gen othetoil=inrange(s6fq17,5,10) | s6fq17==12 | s6fq17==.
gen nonetoil=s6fq17==11

*wall: dummy=mud wall.

tab s6dq01
gen mudwall=s6dq01==1
gen cemwall=s6dq01==5 | s6dq01==6
gen othwall=inrange(s6dq01,2,4) | s6dq01==7| s6dq01==8 | s6dq01==.

*floor: dummy=mud floor

tab s6dq02
gen mudflor=s6dq02==1
gen stonflor=inrange(s6dq02,2,5)
gen othflor=s6dq02==6 | s6dq02==.

*roof: dummy=permanent roof.     ///kindly cechk this

tab s6dq03
gen ththroof=s6dq03==2
gen semiroof=1           if s6dq03==3 | s6dq03==4 | s6dq03==1
gen permroof=1           if s6dq03==5 | s6dq03==6
gen othroof=1            if (s6dq03>=7 & s6dq03<=9) | s6dq03==.

recode southurb southrur eastrur easturb northurb northrur westurb westrur privpipe pubpipe lake  ///
  eleclight othlight woodcuk charcuk othcuk flustoil othetoil nonetoil ///
  mudwall cemwall othwall mudflor stonflor ththroof semiroof permroof othroof  (.=0) 

su lnrent-othroof

compress
saveold "$slihs2011temp\House_Utilities_Rent1.dta",replace



**run regression model.
*The predlog command works if one can assume homoskedastic errors.
*Also note that one should use the predlog command with the raw dependent variable (not logged).
*predlog is self-contained and carries out a regression and then does the necessary extra calculations
*predlog - gives 3 types of predicted values and that is all it does.
*(a) "Straight Retransformation" which is just the exponentiated predicted yhat [exp(yhat)]
*(b) "Naive transformation": adjust the predicted plus half of squared root mean squared error.
*(c) "Duan's Smearing Retransformation": mutiply the exponentiated predicted yhat by the mean value of residuals from the regression (otherwise known as smearing).
*(a) YHAT=exp(yhat)
*(b) YHAT1=exp(yhat+(rmse^2/2))
*(c) YHAT2=YHAT*mean residual
*Duan, Naihua (1983). "Smearing Estimate: A Nonparametric Retransformation Method." {it:Journal of the American Statistical Association}. 78 (383): 605-610.  
*Manning, Willard G. (1998). "The logged dependent variable, heteroscedasticity, and the retransformation problem." {it:Journal of Health Economics}. 17 (3): 283-295.
*Manning, Willard G., and John Mullahy (2001). "Estimating log models: to transform or not to transform?" {it:Journal of Health Economics}. 20 (4): 461-494.  
*fpredict constrains predlog to calculate in-sample predictions only.  The default is to calculate predictions for all possible cases.
*generalied linear model (GLM) is better way of estimating model.
*GLM is a flexible generalization of ordinary linear regression that allows for response variables that have other than a normal distribution. 
*GLM generalizes linear regression by allowing the linear model to be related to the response variable via a link function and
*by allowing the magnitude of the variance of each measurement to be a function of its predicted value.

use "$slihs2011temp\House_Utilities_Rent1.dta",clear

predlog lnrent southurb southrur easturb eastrur northurb northrur westrur ///
	pubpipe lake eleclight woodcuk charcuk flustoil othetoil  ///
	cemwall othwall stonflor permroof othroof  
estimates store model1
fpredict rent1
gen rent11=exp(YHATRAW)
gen rent12=exp(YHTNAIVE)
gen rent13=exp(YHTSMEAR)
ren YHATRAW   yhatraw1
ren YHTNAIVE  yhtnaive1
ren YHTSMEAR  yhtsmear1


reg lnrent southurb southrur easturb eastrur northurb northrur westrur ///
	pubpipe lake eleclight woodcuk charcuk flustoil othetoil  ///
	cemwall othwall stonflor permroof othroof  
estimates store model4
predict rent4
gen rntexp=exp(rent4)


predlog lnrent southurb southrur easturb eastrur northurb northrur westrur ///
	pubpipe lake eleclight woodcuk charcuk flustoil othetoil  ///
	cemwall othwall stonflor
estimates store model2
fpredict rent2  
gen rent21=exp(YHATRAW)
gen rent22=exp(YHTNAIVE)
gen rent23=exp(YHTSMEAR)
ren YHATRAW   yhatraw2
ren YHTNAIVE  yhtnaive2
ren YHTSMEAR  yhtsmear2


tab region, gen(regiondum)
predlog lnrent regiondum1-regiondum3  ///
	pubpipe lake eleclight woodcuk charcuk flustoil othetoil  ///
	cemwall othwall stonflor permroof othroof
estimates store model3
fpredict rent3  
gen rent31=exp(YHATRAW)
gen rent32=exp(YHTNAIVE)
gen rent33=exp(YHTSMEAR)
ren YHATRAW   yhatraw3
ren YHTNAIVE  yhtnaive3
ren YHTSMEAR  yhtsmear3


estimates table model1 model2 model3 model4, stats(N  f r2 r2_a rmse)
sum rent11 rent12 rent13 rent21 rent22 rent23 rent31 rent32 rent33 rntexp
sum rent13 rent23 rent33 rntexp

tabstat rent11 rent12 rent13 rent21 rent22 rent23 rent31 rent32 rent33 rntexp,by(region)

sort hid
merge m:1 slihseacode using "$slihs2011final\Household cluster weights.dta"
tab _m
drop _m

tabstat rent11 rent12 rent13 rent21 rent22 rent23 rent31 rent32 rent33 rntexp [aw=weight],by(region)


glm lnrent lnroom lnroom2 southurb southrur easturb eastrur northurb northrur westrur ///
	pubpipe lake eleclight woodcuk charcuk flustoil othetoil  ///
	cemwall othwall stonflor, link(log)
estimates store model_glm
predict rent_glm
gen rntim=exp(rent_glm)

tabstat rent11 rent12 rent13 rent21 rent22 rent23 rent31 rent32 rent33 rntexp rntim [aw=weight],by(region)


**glm model selected.
*predict actual rent by applying model to data.

gen rntac=rent 
gen rntif=s6bq03
gen rnthh=rent 
replace rnthh=rntim if rnthh==.
lab var rntac  "Actual rent paid" 
lab var rntif  "Owner imputed rent" 
lab var rntim  "Statistical imputed rent for all households"
lab var rnthh  "Actual and imputed rent for missing households" 

sum rnthh

tabstat rntac rntif rntim rnthh,by(region)
tabstat rntac rntif rntim rnthh,by(sector)

keep region district sector slihseacode hhnum hid rntac rntim rnthh rntif

order region district sector slihseacode hhnum hid rntac rntim rnthh rntif

sort hid

compress
saveold "$slihs2011temp\Sec6_nfdrent.dta",replace


*reshape.

use "$slihs2011temp\Sec6_nfdrent.dta",clear

ren rntac    s711
ren rntim    s712
ren rnthh    s713
ren rntif    s714

reshape long s, i(region district slihseacode hhnum hid) j(nonfooditem)
drop if inlist(s,0,.)

lab define nonfooditem  711 "Actual rent" 712 "Imputed rent - regression" 713 "Actual and imputed rent" 714 "Owner-imputed rent" 
lab val nonfooditem nonfooditem
ren s ann_rent

compress
saveold "$slihs2011temp\Filtered Sec6_nfdrent.dta",replace


**above file will be merged for all consumption for CPI unit.
*this file ca also be used to derive what kind of basket the food consume of the say th epoorest population (e.g. X% of population).
*see section ALL ITEMS MERGED.
