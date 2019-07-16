**************************************************************************************************************************
***Table 7: INFREQUENT NON-FOOD CONSUMPTION
**************************************************************************************************************************

****Step 1: stack file for easy to work for later.

use "$slihs2011final\Section 7 Ownership of durable assets.dta", clear

keep if s7q01==1
gen item=1

keep region district chiefdom section eacode sector lccode slihseacode hhnum ///
	hid itemno s7q03a s7q04a s7q05a item

compress
saveold "$slihs2011temp\durable good first.dta", replace


**********************************************************

use "$slihs2011final\Section 7 Ownership of durable assets.dta", clear

drop s7q03a s7q04a s7q05a

keep if s7q01==1
gen item=2
rename s7q03b s7q03a
rename s7q04b s7q04a
rename s7q05b s7q05a

keep region district chiefdom section eacode sector lccode slihseacode hhnum ///
	hid itemno s7q03a s7q04a s7q05a item

compress
saveold "$slihs2011temp\durable good second.dta", replace


**********************************************************

*Step 2: merge durable files.

use "$slihs2011temp\durable good first.dta",clear

append using "$slihs2011temp\durable good second.dta"

sort hid itemno

tab itemno

compress
saveold "$slihs2011temp\durable stacked.dta", replace


**********************************************************

***Step 3: edit durables

use "$slihs2011temp\durable stacked.dta",clear

sort hid  itemno item 

gen valid=0 if s7q03a==. & s7q04a==. & s7q05a==.
tab valid
drop if valid==0
drop valid

*assets in 2003/04 survey different.  
*More added in 2011.
*will use just similar items collected as in 2003/04.
*2003 items: 301 Furniture; 302 Sewing Machine; 303 Stove; 304 Refrigerator; 305 Air Conditioner; 306 Fan;
*2003 items: 307 Radio; 308 Radio Cassette; 309 Record Player; 310 3-in-One Radio; 311 Video Equipment;
*2003 items: 312 Washing Machine; 313 T.V.; 314 Camera; 315 Iron (Electric); 316 Bicycle; 317 Motor Cycle;
*2003 items: 318 Car; 319 House; 320 Land/Plot; 321 Shares; 322 Boat; 323 Canoes; 324 Out Board
*2003 excluded furniture, home, land shares, boat, canoes and outboard from computation for production items.

keep if itemno==8 | inrange(itemno, 10,12) | inrange(itemno,14,15) | inrange(itemno,16,22) | ///
	itemno==24 | itemno==25 | itemno==27 | inrange(itemno,32,34)
count

*prices collected '000.

format  s7q04a %10.2f
format  s7q05a %10.2f

list   s7q03a s7q04a  s7q05a if  itemno==8
replace  s7q04a=200  if  itemno==8 &  s7q04a==200000
replace  s7q04a=150  if  itemno==8 &  s7q04a==150000
replace  s7q05a=150  if  itemno==8 &  s7q05a==150000
replace  s7q05a=100  if  itemno==8 &  s7q05a==100000
replace  s7q04a=500  if  itemno==8 &   s7q04a==50
replace  s7q04a=.    if  itemno==8 & s7q04a==1 & s7q03a==.
replace  s7q04a=.    if  itemno==8 & s7q04a==11 & s7q03a==.
replace  s7q04a=.    if  itemno==8 & s7q04a==1111 & s7q03a==.

list   s7q03a s7q04a  s7q05a if  itemno==10
replace  s7q04a=.    if  itemno==10 & s7q04a==1 & s7q03a==.
replace  s7q05a=.    if  itemno==10 & s7q05a==1 & s7q03a==.
replace  s7q04a=.    if  itemno==10 & s7q04a==11 & s7q03a==.
replace  s7q04a=90   if  itemno==10 & s7q04a==9000
replace  s7q05a=70   if  itemno==10 & s7q05a==7000

list   s7q03a s7q04a  s7q05a if  itemno==11
replace  s7q04a=.    if  itemno==11 & s7q04a==1 & s7q03a==.
replace  s7q05a=.    if  itemno==11 & s7q05a==1 & s7q03a==.
replace  s7q04a=.    if  itemno==11 & s7q04a==111 & s7q03a==.

list   s7q03a s7q04a  s7q05a if  itemno==12
replace  s7q04a=.    if  itemno==12 & s7q04a==1 & s7q03a==.
replace  s7q05a=.    if  itemno==12 & s7q05a==1 & s7q03a==.

list   s7q03a s7q04a  s7q05a if  itemno==14
replace  s7q04a=.    if  itemno==14 & s7q04a==1 & s7q03a==.
replace  s7q05a=.    if  itemno==14 & s7q05a==1 & s7q03a==.
replace  s7q04a=.    if  itemno==14 & s7q04a==11 & s7q03a==.
replace  s7q04a=800  if  itemno==14 & s7q04a==800000

list   s7q03a s7q04a  s7q05a if  itemno==15
replace  s7q04a=.       if  itemno==15 & s7q04a==1 & s7q03a==.
replace  s7q05a=.       if  itemno==15 & s7q05a==1 & s7q03a==.
replace  s7q04a=3000    if  itemno==15 & s7q04a==300000
replace  s7q04a=6500    if  itemno==15 & s7q04a==650000
replace  s7q05a=4000    if  itemno==15 & s7q05a==400000
replace  s7q04a=1500    if  itemno==15 & s7q04a==15000
replace  s7q04a=1200    if  itemno==15 & s7q04a==12000
replace  s7q04a=1120    if  itemno==15 & s7q04a==11200
replace  s7q04a=1300    if  itemno==15 & s7q04a==13000
replace  s7q04a=1005    if  itemno==15 & s7q04a==100500
replace  s7q04a=1008    if  itemno==15 & s7q04a==100800
replace  s7q04a=1000    if  itemno==15 & s7q04a==100000
replace  s7q05a=1000    if  itemno==15 & s7q05a==100000
replace  s7q05a=1004    if  itemno==15 & s7q05a==100400
replace  s7q05a=1000    if  itemno==15 & s7q05a==10000
replace  s7q05a=1200    if  itemno==15 & s7q05a==12000
replace  s7q04a=1200    if  itemno==15 & s7q04a==120000
replace  s7q04a=2000    if  itemno==15 & s7q04a==20000
replace  s7q04a=2500    if  itemno==15 & s7q04a==25000
replace  s7q05a=2000    if  itemno==15 & s7q05a==20000
replace  s7q05a=1200    if  itemno==15 & s7q05a==12000
replace  s7q05a=800     if  itemno==15 & s7q05a==8000
replace  s7q05a=700     if  itemno==15 & s7q05a==7000
replace  s7q05a=8000    if  itemno==15 & s7q05a==800000
replace  s7q04a=1300    if  itemno==15 & s7q04a==30
replace  s7q04a=500     if  itemno==15 & s7q04a==5
replace  s7q05a=1000    if  itemno==15 & s7q04a==2000 & s7q05a==100
replace  s7q05a=1200    if  itemno==15 & s7q04a==1230 & s7q05a==200

list   s7q03a s7q04a  s7q05a if  itemno==16
replace  s7q04a=.       if  itemno==16 & s7q04a==1 & s7q03a==.
replace  s7q05a=.       if  itemno==16 & s7q05a==1 & s7q03a==.
replace  s7q04a=.       if  itemno==16 & s7q04a==2 & s7q03a==.

list   s7q03a s7q04a  s7q05a if  itemno==17
replace  s7q04a=.       if  itemno==17 & s7q04a==1 & s7q03a==.
replace  s7q05a=.       if  itemno==17 & s7q05a==1 & s7q03a==.
replace  s7q04a=300     if  itemno==17 & s7q04a==30000
replace  s7q04a=60      if  itemno==17 & s7q04a==60000
replace  s7q04a=80      if  itemno==17 & s7q04a==80000
replace  s7q04a=100     if  itemno==17 & s7q04a==1000
replace  s7q04a=150     if  itemno==17 & s7q04a==15 & s7q05a==60
replace  s7q05a=200     if  itemno==17 & s7q05a==20000
replace  s7q05a=90      if  itemno==17 & s7q05a==90000
replace  s7q05a=110     if  itemno==17 & s7q05a==110000
replace  s7q05a=110     if  itemno==17 & s7q05a==1100 
replace  s7q05a=100     if  itemno==17 & s7q05a==2000
replace  s7q05a=.       if  itemno==17 & s7q05a==2
replace  s7q05a=90      if  itemno==17 & s7q05a==1990
replace  s7q03a=.       if  itemno==17 & s7q03a==99
replace  s7q03a=.       if  itemno==17 & s7q03a==79
replace  s7q03a=.       if  itemno==17 & s7q03a==29

list   s7q03a s7q04a  s7q05a if  itemno==18
replace  s7q04a=.       if  itemno==18 & s7q04a==1 & s7q03a==.
replace  s7q05a=.       if  itemno==18 & s7q05a==1 & s7q03a==.
replace  s7q04a=50      if  itemno==18 & s7q04a==50000
replace  s7q04a=80      if  itemno==18 & s7q04a==80000
replace  s7q04a=100     if  itemno==18 & s7q04a==100000
replace  s7q04a=25      if  itemno==18 & s7q04a==25000
replace  s7q04a=20      if  itemno==18 & s7q04a==20000
replace  s7q04a=35      if  itemno==18 & s7q04a==35000
replace  s7q04a=15      if  itemno==18 & s7q04a==50 & s7q05a==150
replace  s7q04a=30      if  itemno==18 & s7q04a==3000
replace  s7q04a=120     if  itemno==18 & s7q04a==120000
replace  s7q04a=30      if  itemno==18 & s7q04a==30000
replace  s7q04a=40      if  itemno==18 & s7q04a==40000
replace  s7q04a=50      if  itemno==18 & s7q04a==50000
replace  s7q04a=45      if  itemno==18 & s7q04a==45000
replace  s7q04a=31      if  itemno==18 & s7q04a==31000
replace  s7q05a=30      if  itemno==18 & s7q05a==30000
replace  s7q05a=25      if  itemno==18 & s7q05a==25000
replace  s7q05a=20      if  itemno==18 & s7q05a==20000
replace  s7q05a=20      if  itemno==18 & s7q05a==2000
replace  s7q05a=250     if  itemno==18 & s7q05a==250000
replace  s7q05a=40      if  itemno==18 & s7q05a==40000
replace  s7q05a=10      if  itemno==18 & s7q05a==10000
replace  s7q04a=15      if  itemno==18 & s7q04a==1500
replace  s7q04a=60      if  itemno==18 & s7q04a==600
replace  s7q04a=80      if  itemno==18 & s7q04a==800
replace  s7q04a=45      if  itemno==18 & s7q04a==450
replace  s7q05a=15      if  itemno==18 & s7q04a==15 & s7q05a==150
replace  s7q05a=30      if  itemno==18 & s7q04a==300 & s7q05a==25
replace  s7q05a=18      if  itemno==18 & s7q04a==180 & s7q05a==10

list   s7q03a s7q04a  s7q05a if  itemno==19
replace  s7q04a=.       if  itemno==19 & s7q04a==1 & s7q03a==.
replace  s7q05a=.       if  itemno==19 & s7q05a==1 & s7q03a==.
replace  s7q04a=600     if  itemno==19 & s7q04a==1600 & s7q05a==400
replace  s7q04a=30      if  itemno==19 & s7q04a==30000
replace  s7q05a=15      if  itemno==19 & s7q05a==15000
replace  s7q04a=150     if  itemno==19 & s7q04a==150000
replace  s7q05a=120     if  itemno==19 & s7q05a==120000
replace  s7q04a=80      if  itemno==19 & s7q04a==80000
replace  s7q05a=70      if  itemno==19 & s7q05a==70000
replace  s7q04a=500     if  itemno==19 & s7q04a==500000
replace  s7q05a=300     if  itemno==19 & s7q05a==300000
replace  s7q04a=12      if  itemno==19 & s7q04a==12000
replace  s7q05a=6       if  itemno==19 & s7q05a==6000
replace  s7q04a=170     if  itemno==19 & s7q04a==170000
replace  s7q04a=250     if  itemno==19 & s7q04a==250000
replace  s7q05a=219     if  itemno==19 & s7q05a==219000
replace  s7q04a=45      if  itemno==19 & s7q04a==45000
replace  s7q05a=30      if  itemno==19 & s7q05a==30000
replace  s7q04a=69      if  itemno==19 & s7q04a==69000
replace  s7q05a=75      if  itemno==19 & s7q05a==75000
replace  s7q04a=75.6    if  itemno==19 & s7q04a==7560
replace  s7q05a=50      if  itemno==19 & s7q05a==5000
replace  s7q04a=125     if  itemno==19 & s7q04a==12500 & s7q05a==1000
replace  s7q05a=100     if  itemno==19 & s7q05a==1000 & s7q04a==125

list   s7q03a s7q04a  s7q05a if  itemno==20
replace  s7q04a=.       if  itemno==20 & s7q04a==1 & s7q03a==.
replace  s7q05a=.       if  itemno==20 & s7q05a==1 & s7q03a==.

list   s7q03a s7q04a  s7q05a if  itemno==21
replace  s7q04a=.       if  itemno==21 & s7q04a==1 & s7q03a==.
replace  s7q05a=.       if  itemno==21 & s7q05a==1 & s7q03a==.
replace  s7q04a=100     if  itemno==21 & s7q04a==100000
replace  s7q04a=150     if  itemno==21 & s7q04a==150000
replace  s7q04a=300     if  itemno==21 & s7q04a==300000
replace  s7q04a=500     if  itemno==21 & s7q04a==5000
replace  s7q05a=100     if  itemno==21 & s7q05a==100000
replace  s7q05a=110     if  itemno==21 & s7q05a==110000
replace  s7q05a=150     if  itemno==21 & s7q05a==150000
replace  s7q04a=150     if  itemno==21 & s7q04a==1500
replace  s7q05a=100     if  itemno==21 & s7q05a==1000
replace  s7q05a=100     if  itemno==21 & s7q05a==7100
replace  s7q05a=70      if  itemno==21 & s7q05a==7     
replace  s7q05a=30      if  itemno==21 & s7q05a==3     

list   s7q03a s7q04a  s7q05a if  itemno==22
replace  s7q04a=.       if  itemno==22 & s7q04a==1 & s7q03a==.
replace  s7q05a=.       if  itemno==22 & s7q05a==1 & s7q03a==.
replace  s7q04a=1500    if  itemno==22 & s7q04a==15000
replace  s7q04a=400     if  itemno==22 & s7q04a==400000
replace  s7q04a=250     if  itemno==22 & s7q04a==250000
replace  s7q04a=450     if  itemno==22 & s7q04a==450000
replace  s7q04a=1150    if  itemno==22 & s7q04a==115000
replace  s7q04a=150     if  itemno==22 & s7q04a==160000
replace  s7q05a=.       if  itemno==22 & s7q05a==1111  
replace  s7q05a=290     if  itemno==22 & s7q05a==290000
replace  s7q05a=350     if  itemno==22 & s7q05a==350000
replace  s7q05a=500     if  itemno==22 & s7q05a==500000
replace  s7q05a=150     if  itemno==22 & s7q05a==150000
replace  s7q05a=300     if  itemno==22 & s7q05a==300000
replace  s7q04a=500     if  itemno==22 & s7q04a==5000 & s7q05a==300

list   s7q03a s7q04a  s7q05a if  itemno==24
replace  s7q04a=. if  itemno==24 & s7q04a==1

list   s7q03a s7q04a  s7q05a if  itemno==25
replace  s7q04a=.       if  itemno==25 & s7q04a==1 & s7q03a==.
replace  s7q05a=.       if  itemno==25 & s7q05a==1 & s7q03a==.

list   s7q03a s7q04a  s7q05a if  itemno==27
replace  s7q04a=.       if  itemno==27 & s7q04a==1 & s7q03a==.
replace  s7q05a=.       if  itemno==27 & s7q05a==1 & s7q03a==.
replace  s7q04a=50      if  itemno==27 & s7q04a==50000
replace  s7q05a=40      if  itemno==27 & s7q05a==40000
replace  s7q04a=.       if  itemno==27 & s7q04a==2 & s7q03a==.

list   s7q03a s7q04a  s7q05a if  itemno==32
replace  s7q04a=.       if  itemno==32 & s7q04a==1 & s7q03a==.
replace  s7q05a=.       if  itemno==32 & s7q05a==1 & s7q03a==.
replace  s7q04a=110     if  itemno==32 & s7q04a==11000
replace  s7q04a=25      if  itemno==32 & s7q04a==2500 & s7q05a==50
replace  s7q05a=100     if  itemno==32 & s7q05a==100000
replace  s7q04a=200     if  itemno==32 & s7q04a==2000
replace  s7q04a=300     if  itemno==32 & s7q04a==3000
replace  s7q04a=100     if  itemno==32 & s7q04a==100000
replace  s7q04a=120     if  itemno==32 & s7q04a==1200
replace  s7q04a=430     if  itemno==32 & s7q04a==4300
replace  s7q05a=300     if  itemno==32 & s7q05a==3000
replace  s7q05a=200     if  itemno==32 & s7q05a==2000
replace  s7q05a=290     if  itemno==32 & s7q05a==2790
replace  s7q04a=.       if  itemno==32 & s7q04a<10 & s7q03a==.
replace  s7q04a=.       if  itemno==32 & s7q04a<10 & s7q03a==1

list   s7q03a s7q04a  s7q05a if  itemno==33
replace  s7q04a=.       if  itemno==33 & s7q04a==1 & s7q03a==.
replace  s7q05a=.       if  itemno==33 & s7q05a==1 & s7q03a==.
replace  s7q04a=3800    if  itemno==33 & s7q04a==380000
replace  s7q04a=4000    if  itemno==33 & s7q04a==400000
replace  s7q04a=3000    if  itemno==33 & s7q04a==300000
replace  s7q04a=4500    if  itemno==33 & s7q04a==45900
replace  s7q04a=1500    if  itemno==33 & s7q04a==150000
replace  s7q04a=1500    if  itemno==33 & s7q04a==15000
replace  s7q04a=700     if  itemno==33 & s7q04a==700000
replace  s7q04a=5000    if  itemno==33 & s7q04a==50000
replace  s7q04a=1350    if  itemno==33 & s7q04a==13500
replace  s7q05a=3000    if  itemno==33 & s7q05a==300000
replace  s7q05a=2000    if  itemno==33 & s7q05a==200000
replace  s7q05a=1400    if  itemno==33 & s7q05a==14000
replace  s7q05a=1300    if  itemno==33 & s7q05a==130000
replace  s7q05a=550     if  itemno==33 & s7q05a==550000
replace  s7q05a=4000    if  itemno==33 & s7q05a==40000
replace  s7q05a=2500    if  itemno==33 & s7q05a==250000
replace  s7q04a=.       if  itemno==33 & s7q04a<=20 & s7q03a==.
replace  s7q04a=1800    if  itemno==33 & s7q04a==180
replace  s7q05a=1300    if  itemno==33 & s7q05a==130
replace  s7q04a=.       if  itemno==33 & s7q04a<=20 & s7q03a==1

list   s7q03a s7q04a  s7q05a if  itemno==34
replace  s7q04a=.       if  itemno==34 & s7q04a==1 & s7q03a==.
replace  s7q05a=.       if  itemno==34 & s7q05a==1 & s7q03a==.

compress
saveold "$slihs2011temp\durable stacked1.dta", replace


use "$slihs2011temp\durable stacked1.dta", clear

gen age=s7q03a
gen purchase=s7q04a*1000
gen sale=s7q05a*1000

replace purchase=100000   if hid=="225135209" & itemno==10
replace purchase=100000   if hid=="111203808" & itemno==11
replace purchase=100000   if hid=="113114203" & itemno==18
replace purchase=1500000  if hid=="442266110" & itemno==15
replace sale=210000       if hid=="442264108" & itemno==17
replace purchase=100000   if hid=="113114203" & itemno==18
replace purchase=100000   if hid=="223228503" & itemno==20
format purchase sale %10.5g

count if age==.
count if purchase==.
count if sale==.

**drop households with missing age, purchase and sale price.

count if age==. & purchase==. & sale==.
drop  if age==. & purchase==. & sale==.

**drop households with missing purchase and sale price.
*Records with zero amount in both sale and purchase (sale=0 and purchase=0) deleted.

count if age~=. & purchase==. & sale==.

gen valid=0      if purchase==. & sale==.
replace valid=1  if valid==. & purchase==0 & sale==0
tab valid
count
keep if valid==.
drop valid

*if either purchase/sale is zero and vice versa==. drop.

gen valid=0      if purchase==0 & sale==.
replace valid=1  if purchase==. & sale==0
tab valid
keep if valid==.
drop valid

**if purchase or sale prices missing impute by median by item type.

bys itemno: egen agemed=median(age)
bys itemno: egen purmed=median(purchase)
bys itemno: egen salemed=median(sale)

gen age1=age
replace age1=agemed 		if age==.					    //Replace, for age of item, missings with median value

gen purchase1=purchase
replace purchase1=purmed 	if s7q04a==0 | s7q04a==.	    //Replace, for purchase price of item, missings and zeros with median value

gen purchase2=purchase
replace purchase2=purmed 	if purchase==0 | purchase==.	//Replace, for purchase price of item, missings and zeros with median value

gen sale1=sale
replace sale1=salemed 		if s7q05a==0 | s7q05a==.  	    //Replace, for sale price of item, missings and zeros with median value
format purchase1 purchase2 sale1 %10.5g

replace purchase1=1500000   if hid=="442262707" & itemno==25
replace purchase1=1500000   if hid=="442261605" & itemno==25
replace purchase1=1800000   if hid=="442264403" & itemno==25  
replace purchase1=1800000   if hid=="442262205" & itemno==25
replace purchase1=1800000   if hid=="442262205" & itemno==25
replace purchase1=10000000  if hid=="113217107" & itemno==34
replace purchase1=1500000   if hid=="442263604" & itemno==34
replace sale1=65000         if hid=="225138104" & itemno==18


**if items aged less than one year, survey asked an entry of zero.
*presence of items with age zero, will assume correct age.
*however, code does not work with zero age and will assign 6 months as age (0.5 years).
*convert age of item in years to months.

gen agem = (age*12)  
replace agem=6 if age==0
lab var agem "Age of item (imputed 6 months for zero year)"


***METHOD 1: used in 2003.
**median depreciation rates.
*Monthly savings interest rate Jan-June 2011: 6.19, 6.19, 6.35, 6.65, 6.65, 6.62,  
*Monthly savings interest rate Jul-Dec  2011: 6.48, 6.48, 6.42, 6.42, 6.42, 6.42
*Average 2011 rate of interest for savings was 6.440833%.
*Monthly inflation rate Jan-June 2011: 13.53, 13.88, 14.92, 15.42, 17.82, 16.79,  
*Monthly inflation rate Jul-Dec  2011: 16.82, 16.4, 15.7, 17.15, 17.24, 16.64
*Average 2011 inflation was 16.025%.
*Refer to Deaton and Zaidi page 107.

gen rate=6.440833/100
lab var rate "Estimated average Jan-Dec 2011 interest rate"

gen inflation=16.025/100
lab var rate "Estimated average Jan-Dec 2011 rate of inflation"

gen depre1 = 1 - (sale1/purchase1)^(1/(agem/12)) + inflation  //depre by item range from negative to positive values.
lab var depre1 "Depreciation rate by item at the HH"
tabstat depre1,by(itemno)  s(mean N median min max)           //observe depreciation rates generated from table.

gen depre2 = 1 - (sale1/purchase1)^(1/(agem/12))    
lab var depre2 "Depreciation rate by item at the HH"
tabstat depre2,by(itemno)  s(mean N median min max)           //observe depreciation rates generated from table.

compress
saveold "$slihs2011temp\durable1-2.dta", replace 


bys itemno: egen depre1_mn=mean(depre1)
bys itemno: egen depre1_md=median(depre1)    //assumes that durables purchases are uniformly distributed in time and thus use median.
bys itemno: egen depre1_nu=count(depre1)

list hid itemno age1 purchase purchase1 sale sale1 depre1 if depre1<=-10


bys itemno: egen depre2_mn=mean(depre2)
bys itemno: egen depre2_md=median(depre2)    //assumes that durables purchases are uniformly distributed in time and thus use median.
bys itemno: egen depre2_nu=count(depre2)

list hid itemno age1 purchase purchase1 sale sale1 depre2 if depre2<=-10

replace depre1_md=.     if itemno==10      //negative use values and only few observations
replace depre2_md=.     if itemno==10      //negative use values and only few observations

*observe depreciation rates generated from table.
*make sure no negative use value.

gen usevalue1 = sale1*((rate-inflation) + depre1_md)
lab var usevalue1 "Use value - method 1"

gen usevalue1a = sale1*(rate+depre2_md)/(1-depre2_md) 
lab var usevalue1a "Use value - method 1a"


***METHOD 2: uses sale (value of durable good at time of survey) of item and age.

bys itemno: egen age_mn=mean(age)

gen age_mn2=age_mn*2          	//average lifetime of each duable good
								//under the assumption that purchases are uniformly distributed over time

gen lifetime=(age_mn2-age)
replace lifetime=2   if lifetime<2    //arbitrarily "rounded up"to 2 years when less.

gen usevalue2=sale1/(age_mn2-age)
lab var usevalue2 "Use value - method 2"


***METHOD 3: uses sale price and age 
*age inverse is the depreciation rate.

gen depre3 = 1/(2*agem)             					//where 2*age is the expected lifespan of durable good
gen usevalue3 = sale1*((rate+depre3)/(1-depre3))
lab var usevalue3 "Use value - method 3"

tabstat usevalue1 usevalue1a usevalue2 usevalue3,by(itemno)  s(mean N median min max)
list slihseacode hhnum age sale purchase sale1 purchase1 usevalue1 usevalue1a usevalue2 usevalue3  if itemno==10

compress
saveold "$slihs2011temp\Sec7_usevalue.dta", replace


**aggregate total use value irrespective of asset to HH-level.
	
collapse (sum) usevalue1 usevalue1a usevalue2 usevalue3, by(hid)

order hid usevalue1 usevalue1a usevalue2 usevalue3

sum usevalue1 usevalue1a usevalue2 usevalue3

sort hid

compress
saveold "$slihs2011temp\Sec7_nfdusevalue.dta", replace


**********************************************************

***durables last 12 months.
*these are items purchased during the survey period.  Survey period was 12 months.
*kitchen utensils fall under NFDFMTN.
*large items (NFDINVES) will not be included in the final household consumption as these are durables.
*classification of assets is based on COICOP classification.
*see USE VALUE computations above on durables.

use "$slihs2011temp\durable stacked1.dta", clear

keep if s7q03a<=1
gen nonfooditem=s7q04a*1000

drop s7q03a s7q04a s7q05a item

compress
saveold "$slihs2011temp\Filtered Sec7_durable stacked.dta", replace


**above file will be merged for all consumption for CPI unit.
*see section ALL ITEMS MERGED FOR CPI.

collapse (sum)  nonfooditem,by(hid)        //outliers present as this was what HH stated.  For USEVALUE edits done to purchase and sale
ren  nonfooditem nfdinves
lab var nfdinves "Large investment expenditure (purchase of household durable assets)"

sort hid

compress
saveold "$slihs2011temp\Sec7_large investments.dta", replace


**********************************************************

***Electric and non-eletric appliances.

use "$slihs2011temp\Filtered Sec13B-B2_nonfood infreq purchases", clear        //see above in health section how file generated.

gen nfdseppl=ann_purch   if inrange(nonfooditem,2401,2403)
gen nfdsnppl=ann_purch   if (nonfooditem>=2404 & nonfooditem<=2405) 

collapse (sum) nfdseppl nfdsnppl,by(hid)
lab var nfdseppl "Electrical items"
lab var nfdsnppl "Non-electric items"

sort hid

compress
saveold "$slihs2011temp\Sec13B2_appliances.dta", replace


**********************************************************

***ceremonies.

use "$slihs2011final\Section 15 Part D Income miscellaneous outgoings.dta", clear

egen nfdcerem = rsum(s15dq2 s15dq3 s15dq4 s15dq5 s15dq6 s15dq9) 

collapse (sum) nfdcerem, by(hid)
lab var nfdcerem  "Ceremonies"

sort hid

compress
saveold "$slihs2011temp\Sec15D_ceremonies.dta", replace


**********************************************************

***Out-transfer.
*includes cash, food and in-kind transfers.
*food gift would be double counting food expenditure if included.
*it will be assumed that the value derived here is reflected in total food and will not be included again.

use "$slihs2011final\Section 15 Part B Income transfers received.dta", clear

collapse (sum) s15bq9 s15bq10 s15bq11,by(hid)

ren s15bq9  nfdremcs
ren s15bq10 nfdremfd
ren s15bq11 nfdremot

lab var nfdremcs "Cash transfer payment"
lab var nfdremfd "Food transfer payment"
lab var nfdremot "Other transfer payment"

compress
saveold "$slihs2011temp\Sec15B_remittances.dta", replace


**********************************************************

***merge all above files.

use "$slihs2011temp\Sec7_large investments.dta", clear

sort hid
merge  hid using "$slihs2011temp\Sec7_nfdusevalue.dta"
tab _merge
drop _merge
sort hid
merge  hid using "$slihs2011temp\Filtered Sec6_nfdrepar.dta" 
tab _merge
drop _merge
sort hid
merge  hid using "$slihs2011temp\Sec13B2_appliances.dta" 
tab _merge
drop _merge
sort hid
merge  hid using "$slihs2011temp\Sec15D_ceremonies.dta"
tab _merge
drop _merge 
sort hid
merge  hid using "$slihs2011temp\Sec15B_remittances.dta"
tab _merge
drop _merge

gen nfdioth=0
gen nfdusevl=usevalue1 
gen nfdrepar=nfdrepar2 

recode nfd* (.=0) 

egen nfditexp = rsum(nfdseppl nfdsnppl nfdusevl nfdrepar nfdioth)  

lab var nfdseppl    "Electric small appliances"
lab var nfdsnppl    "Non-electric small appliances"
lab var nfdinves    "Large investment expenditure (purchase of household durable assets)"
lab var nfdusevl    "Use value of large investments"
lab var nfdcerem    "Non-regular expenditure"
lab var nfdremcs    "Cash transfer payments (remittances) received"
lab var nfdremfd    "Food transfer payments (remittances) received"
lab var nfdremot    "Other transfer payments (remittances) received"
lab var nfdrepar    "Maintenance and repairs of dwelling unit"
lab var nfdioth     "Expenditures on infrequent non-food not mentioned elsewhere"
lab var nfditexp    "Total infrequent non-food expenditure excluding rent, education and health"

keep  hid nfdseppl nfdsnppl nfdinves nfdusevl nfdcerem nfdremcs nfdremfd nfdremot nfdrepar nfdioth nfditexp

order hid nfdseppl nfdsnppl nfdinves nfdusevl nfdcerem nfdremcs nfdremfd nfdremot nfdrepar nfdioth nfditexp

d
sort hid

compress
saveold "$slihs2011fintabs\Table 7 nfoodnonfreqexp.dta", replace



