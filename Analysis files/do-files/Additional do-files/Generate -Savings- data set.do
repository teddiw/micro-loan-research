/*==========================================================*
Project: 		EBRD-IFS Mongolia

Purpose:		This do-file prepares savings data set for
				estimation
				
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

use "data\Followup\Section M - Savings (at individual level).dta"
set more off




***BASIC CLEANUP

drop wheresav*

reshape wide savings valuesav edusav, i(rescode followup) j(label)

order hhid rescode aimag soum treatment treated

recode savings2 .=0
recode savings3 .=0

foreach x of varlist valuesav* edusav*	{
	recode `x' .=0
		}


renpfix valuesav totalsav
ge totalsav_hh=totalsav1+totalsav2+totalsav3
ge edusav_hh=edusav1+edusav2+edusav3

ren totalsav1 totalsav_resp
ren totalsav2 totalsav_joint
ren totalsav3 totalsav_partn

ren edusav1 edusav_resp
ren edusav2 edusav_joint
ren edusav3 edusav_partn


ge group=treatment==2
ge indiv=treatment==1



***CLEAN UP DATASET FOR ESTIMATION

*treatment
gen treated_g=followup*group
gen treated_i=followup*indiv

*exposure
ge exposure_g=group*exposure
ge exposure_i=indiv*exposure

ge nloans_g=group*nloans_soum
ge nloans_i=indiv*nloans_soum
drop nloans_baseline

*education
ge treatg_eduhi=group==1 & eduhigh==1
ge treatg_eduvoc=group==1 & eduvoc==1
ge treati_eduhi=indiv==1 & eduhigh==1
ge treati_eduvoc=indiv==1 & eduvoc==1

*loan at baseline
ge treatgloan=group==1 & loan_baseline==1
ge treatiloan=indiv==1 & loan_baseline==1

*age
ge treatgage=0
replace treatgage=age if group==1
ge treatiage=0
replace treatiage=age if indiv==1



*!! Note that we merged in some additional info into the data se (which we do not do here), which is why we 'commented' the 'save' command
*save "data\Followup\Savings.dta", replace




