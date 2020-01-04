/*==========================================================*
Project: 		EBRD-IFS Mongolia

Purpose:		This do-file prepares enterprise data set for
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


use "data\Followup\Sections F,G,h - Ent.dta"
set more off

****CLEAN UP DATASET VARS

* related variables: partnent soleent jointent nrjointent

recode nrjointent .=0

ge nrents=0
la var nrents "number of enterprises owned"

replace nrents=5 if nrjointent==3 & jointent==1 & soleent==1 & partnent ==1

replace nrents=4 if nrjointent==2 & jointent==1 & soleent==1 & partnent ==1
replace nrents=4 if nrjointent==3 & jointent==1 & soleent==0 & partnent ==1
replace nrents=4 if nrjointent==3 & jointent==1 & soleent==1 & partnent ==0

replace nrents=3 if nrjointent==1 & jointent==1 & soleent==1 & partnent ==1
replace nrents=3 if nrjointent==3 & jointent==1 & soleent==0 & partnent ==0
replace nrents=3 if nrjointent==2 & jointent==1 & soleent==1 & partnent ==0
replace nrents=3 if nrjointent==2 & jointent==1 & soleent==0 & partnent ==1

replace nrents=2 if nrjointent==2 & jointent==1 & soleent==0 & partnent ==0
replace nrents=2 if nrjointent==0 & jointent==0 & soleent==1 & partnent ==1
replace nrents=2 if nrjointent==1 & jointent==1 & soleent==0 & partnent ==1
replace nrents=2 if nrjointent==1 & jointent==1 & soleent==1 & partnent ==0

replace nrents=1 if nrjointent==1 & jointent==1 & soleent==0 & partnent ==0
replace nrents=1 if nrjointent==0 & jointent==0 & soleent==1 & partnent ==0
replace nrents=1 if nrjointent==0 & jointent==0 & soleent==0 & partnent ==1

move nrents jointent


*******generate total expenses for each enterprise

foreach x of varlist expon*	{
	recode `x' .=0
		}

#d ;

ge totalexp_j1= exponwag_j1+ exponraw_j1+ exponres_j1+ exponmach_j1+ exponequip_j1+ 
	exponmain_j1+ expontrans_j1+ exponfuel_j1+ expontax_j1+ exponint_j1+ exponother_j1 ;

ge totalexp_j2= exponwag_j2+ exponraw_j2+ exponres_j2+ exponmach_j2+ exponequip_j2+ 
	exponmain_j2+ expontrans_j2+ exponfuel_j2+ expontax_j2+ exponint_j2+ exponother_j2 ;

ge totalexp_r= exponwag_r+ exponraw_r+ exponres_r+ exponmach_r+ exponequip_r+ 
	exponmain_r+ expontrans_r+ exponfuel_r+ expontax_r+ exponint_r+ exponother_r ;

ge totalexp_p= exponwag_p+ exponraw_p+ exponres_p+ exponmach_p+ exponequip_p+ 
	exponmain_p+ expontrans_p+ exponfuel_p+ expontax_p+ exponint_p+ exponother_p ;

#d cr

foreach x of varlist totalexp_*	{
	la var `x' "Aggregated expenditure"
	replace `x'=. if `x'>10000000
		}


*******generate total revenues for each enterprise

foreach x of varlist rev*	{
	recode `x' .=0
		}


ge totalrev_j1=  revcash_j1+ revkind_j1+ revsale_j1+ revrent_j1+ revother_j1

ge totalrev_j2=  revcash_j2+ revkind_j2+ revsale_j2+ revrent_j2+ revother_j2

ge totalrev_r=  revcash_r+ revkind_r+ revsale_r+ revrent_r+ revother_r

ge totalrev_p=  revcash_p+ revkind_p+ revsale_p+ revrent_p+ revother_p


foreach x of varlist totalrev_*	{
	la var `x' "Aggregated revenue"
		}

***enterprise2

ge enterprise2=nrents==2|nrents==3|nrents==4|nrents==5

********Profits


ge netprofit_j1=totalrev_j1-totalexp_j1
ge netprofit_j2=totalrev_j2-totalexp_j2
ge netprofit_r=totalrev_r-totalexp_r
ge netprofit_p=totalrev_p-totalexp_p

foreach x of varlist profit_*	{
	la var `x' "aggregated profit"
		}

la var enterprise2 "respondent owns 2 or more enterprises?"

***GENERATE TOTAL EXPENDITURE/REV/PROFIT ON ALL HH BUSINESS

ge totalexp=totalexp_j1+totalexp_j2+totalexp_r+totalexp_p
ge totalrev=totalrev_j1+totalrev_j2+totalrev_r+totalrev_p
ge netprofit=totalrev-totalexp

ge totalexp_j=totalexp_j1+totalexp_j2
ge totalrev_j=totalrev_j1+totalrev_j2
ge netprofit_j=totalrev_j-totalexp_j

renpfix total
renpfix net


recode jointent 2=0 .=0
recode soleent .=0
recode partnent .=0

la var exp "total expenditure on all ents"
la var rev "total revenue from all ents"
la var exp "total profit from all ents"

la var exp_j "total expenditure on all joint ents"
la var rev_j "total revenue from all joint ents"
la var exp_j "total profit from all joint ents"

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
*save "data\Followup\Enterprises.dta", replace
























