/*==========================================================*
Project: 		EBRD-IFS Mongolia

Purpose:		This do-file creates BASELINE variables 
				related to wage income
				
Code Author: 	IFS 
Date created:	April 2014
Last modified:  
*===========================================================*/

capture log close
set more off
adopath+"C:\ado"
drop _all
global workdir "XXX\Analysis files"		
cap mkdir "${workdir}"	
cd "${workdir}"						

use "data\Baseline\Section j - Empl.dta", clear
merge 1:1 rescode case_id using "data\Baseline\Sections F,G,H - Selfempl.dta"
drop _merge
merge 1:1 rescode ind using "data\Baseline\Sections A,B-Education (updated).dta"

ta typeofempl, gen(typeofempl_)

keep rescode ind empl typeofempl hourswork grossearn periodearn benefit benefitval periodben  emplown emplprimjo emplsecjo emplpartn schlnow typeofempl_*
reshape wide empl typeofempl hourswork grossearn periodearn typeofempl_* benefit benefitval periodben emplown emplprimjo emplsecjo emplpartn schlnow, i(rescode) j(ind)

*--------------------------------------------------*
* number of income sources other than own business:
*--------------------------------------------------*
egen ysource=rowtotal(typeofempl_*)
egen agricwork=rowtotal(typeofempl_1*)
egen shopmarket=rowtotal(typeofempl_2*)
egen bankfinance=rowtotal(typeofempl_3*)
egen mining=rowtotal(typeofempl_4*)
egen inschool=rowtotal(typeofempl_5*)
egen privatebus=rowtotal(typeofempl_7*)
egen hospital=rowtotal(typeofempl_8*)
egen government=rowtotal(typeofempl_9*)
egen workother=rowtotal(typeofempl_10*)
egen benefit=rowtotal(benefit*)
foreach x of varlist agricwork shopmarket bankfinance mining inschool privatebus hospital government workother benefit {
	replace `x'=0 if `x'==.
	gen `x'01=`x'!=0
	}
egen ownbus=rowmax(emplown*)
egen jointbus=rowmax(emplprimjo*)
egen partnerbus=rowmax(emplpartn*)
foreach x of varlist ownbus jointbus partnerbus {
	replace `x'=0 if `x'==.
	}
	
egen nrbusiness=rowtotal(ownbus jointbus partnerbus)

*-----------------------------------*
* amount earned from certain source:
*-----------------------------------*
	
gen agricwork_earn=0
	la var agricwork_earn "HH earnings from agricultur"
gen shopmarket_earn=0
	la var shopmarket_earn "HH earnings from shop/market"
gen bankfinance_earn=0
	la var bankfinance_earn "HH earnings from bank/finance"
gen mining_earn=0
	la var mining_earn "HH earnings from mining"
gen inschool_earn=0
	la var inschool_earn "HH earnings from work in school"
gen tourism_earn=0
	la var tourism_earn "HH earnings from tourism"
gen privatebus_earn=0
	la var privatebus_earn "HH earnings from private business"
gen hospital_earn=0
	la var hospital_earn "HH earnings from work in hospital"
gen government_earn=0
	la var government_earn "HH earnings from government work"
gen workother_earn=0
	la var workother_earn "HH earnings from other"
	
	
// make sure we have values in yearly:
	forvalues i=1(1)12 {
		gen grossearnP`i'=0
		replace hourswork`i'=48.5 if hourswork`i'==6666	// this is the sample average
		replace hourswork`i'=48.5 if hourswork`i'==9999	// this is the sample average
		replace grossearnP`i'=grossearn`i'*hourswork`i'*50 if periodearn`i'==1	// take provided typical weekly hours work and assume that people work on average 50 weeks a year
		replace grossearnP`i'=grossearn`i'*4.5*50 if periodearn`i'==2		// assume that people work 4.5 days a week, 50 weeks a year
		replace grossearnP`i'=grossearn`i'*50 if periodearn`i'==3			// assume that people work 50 weeks a year
		replace grossearnP`i'=grossearn`i'*12 if periodearn`i'==4
		replace grossearnP`i'=grossearn`i'*1 if periodearn`i'==5
		}
	

forvalues i=1(1)12 {
	replace agricwork_earn=agricwork_earn+grossearnP`i' if typeofempl`i'==1
	replace shopmarket_earn=shopmarket_earn+grossearnP`i' if typeofempl`i'==2
	replace bankfinance_earn=bankfinance_earn+grossearnP`i' if typeofempl`i'==3
	replace mining_earn=mining_earn+grossearnP`i' if typeofempl`i'==4
	replace inschool_earn=inschool_earn+grossearnP`i' if typeofempl`i'==5
	replace tourism_earn=tourism_earn+grossearnP`i' if typeofempl`i'==6
	replace privatebus_earn=privatebus_earn+grossearnP`i' if typeofempl`i'==7
	replace hospital_earn=hospital_earn+grossearnP`i' if typeofempl`i'==8
	replace government_earn=government_earn+grossearnP`i' if typeofempl`i'==9
	replace workother_earn=workother_earn+grossearnP`i' if typeofempl`i'==10
	}
	
foreach x of varlist *_earn {
	gen `x'_scaled=`x'/1000
	}

	egen hhwageinc_earn=rowtotal(agricwork_earn shopmarket_earn bankfinance_earn mining_earn inschool_earn privatebus_earn hospital_earn government_earn workother_earn)
	gen hhwageinc_earn_scaled=hhwageinc_earn/1000
	
	
keep rescode ysource nrbusiness benefit agricwork01 shopmarket01 bankfinance01 mining01 inschool01 privatebus01 hospital01 government01 workother01 ownbus jointbus partnerbus *_earn* hhwageinc*
la var ysource "Nr of income sources (other than own self-empl business or benefits"
la var nrbusiness "Nr of business in HH (own, joint, partner)"
la var agricwork01 "=1 if HH gets income from agriwork wage"
la var shopmarket01 "=1 if HH gets income from shop/market wage"
la var ownbus "=1 if someone in HH works on respondents business"
la var jointbus "=1 if someone in HH works on joint business"
la var partnerbus "=1 if someone in HH works on partner's business"
save "data\Baseline\Constructed Vars for baseline balancedness_Oct2013.dta", replace
save "data\Constructed Vars for baseline balancedness_Oct2013.dta", replace



*--------------------------------------------------*
* Reconstruct household benefit info
*--------------------------------------------------*
	
use "data\Baseline\wave1_4.dta", clear
drop if rescode==12301 & id==56
sort rescode

keep rescode j5* j6*
sort rescode

foreach n of numlist 1(1)12 	{
	ren j5_`n' b_benefit`n'
	ren j6_`n'a b_benefitval`n'
	ren j6_`n'b b_periodben`n'
					}
destring b_*, replace


*** RESHAPE

reshape long b_benefit b_benefitval b_periodben , i(rescode) j(ind)
replace b_benefitval=13600 if b_benefitval==136000	// a large part of the sample has value 13600, so the larger value is likely a typo

* Not every household has 12 members

drop if b_benefit==. & b_benefitval==. & b_periodben==.

ta b_benefit, m
su if b_benefit==. 
drop if b_benefit==.
des

// adjust for different reporting periods: make all yearly
replace b_benefit=0 if b_benefit==2
replace b_benefit=. if b_benefit==99
rename b_benefitval b_benefitvalORIG
gen b_benefitval=0
replace b_benefitval=b_benefitvalORIG*52 if b_periodben==1
replace b_benefitval=b_benefitvalORIG*12 if b_periodben==2
replace b_benefitval=b_benefitvalORIG*1 if b_periodben==3
replace b_benefitval=. if b_benefitvalORIG==.

// generate variables of interest
bys rescode: egen b_benefit01=max(b_benefit)
	la var b_benefit01 "=1 if anyone in HH receives benefit"
bys rescode: egen b_benefitvalHH=sum(b_benefitval)
	la var b_benefitvalHH "Value of benefits received by HH, yearly"
	replace b_benefitvalHH=. if b_benefitvalHH>=6000000	// huge outliers
bys rescode: egen b_benefitHHmem=sum(b_benefit)
	la var b_benefitHHmem "=Nr of HH members receiving benefits"
	
keep rescode b_benefit01 b_benefitvalHH b_benefitHHmem
duplicates drop
gen followup=0
destring rescode, replace


merge 1:1 rescode using "data\Baseline\Constructed Vars for baseline balancedness_Oct2013.dta"
drop _m
save "data\Baseline\Constructed Vars for baseline balancedness_Oct2013.dta", replace
