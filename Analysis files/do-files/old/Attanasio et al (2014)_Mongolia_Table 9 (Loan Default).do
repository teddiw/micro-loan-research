/*==========================================================*
Project: 		EBRD-IFS Mongolia

Purpose:		Table 9 for the AEJ Applied special issue
				(Determinants of Loan Default)
				
Code Author: 	IFS 
Date created: 	April 2014
Last modified:  
Note:			
*===========================================================*/
capture log close
set more off
adopath+"C:\ado"
drop _all
global workdir "XXX\Analysis files"		
cap mkdir "${workdir}"	
cd "${workdir}"						

*-- DATA:
use "data\XacBank admin debt data\ALL monthly repayment (April 08 - June 10) - long clean first loan only.dta", clear

*-- SOME CLEANING/PREPARATION:
	replace currentdebt=currentdebt/1000000
	replace amount=amount/1000000
	replace loan_clmark=loan_clmark/1000000
	
*-- GLOBALS:
	global XvarBL "currentdebt nloans_baseline age age_sq buddhist hahl marr_cohab hhsize eduhigh eduvoc age16m age16f under16 ownsfence dwellingtype2 otherdwelling  land1 car1 tv1 savings enterprise harvest_y disaster_y death_y"
	global XVarXacBank "amount loan_clmark  noinstal2 nomonths"
	
	global show "amount currentdebt  nomonths land1 tv1 enterprise eduhigh eduvoc"
	global hide1 "nloans_baseline age age_sq buddhist hahl marr_cohab hhsize age16m age16f under16 ownsfence dwellingtype2 otherdwelling car1 savings  harvest_y disaster_y death_y"
	global hide2 "amount loan_clmark  noinstal2 "

/*==========================*
		LOAN DEFAULT	
*==========================*/

// FIRST LOAN:
	* no covariates
		eststo def1_1: probit default treatm if noinstal2<100, robust cl(soum)
		outreg2 using "output\Loan default\Determinants of Default.xls", cttop("First") addstat(R2, e(r2_p)) replace
	* regression with XacBank and baseline data:
		eststo def1_2: probit default treatm $show $hide1 $hide2  if noinstal2<100 , robust cl(soum)
		outreg2 using "output\Loan default\Determinants of Default.xls", cttop("First") addstat(R2, e(r2_p)) append

// ALL LOANS:
	*-- RELEVANT DATA:
	use "data\XacBank admin debt data\ALL monthly repayment (April 08 - June 10) - long clean loans.dta", clear
	*-- SOME CLEANING/PREPARATION:
	replace currentdebt=currentdebt/1000000
	replace amount=amount/1000000
	replace loan_clmark=loan_clmark/1000000

	* no covariates
		eststo def2_1: probit default treatm if noinstal2<100, robust cl(soum)
		outreg2 using "output\Loan default\Determinants of Default.xls", cttop("All") addstat(R2, e(r2_p)) append
	* regression with XacBank and baseline data:
		eststo def2_2: probit default treatm $show no_previousloans $hide1 $hide2  $XVarXacBank if noinstal2<100 , robust cl(soum)
		outreg2 using "output\Loan default\Determinants of Default.xls", cttop("All") addstat(R2, e(r2_p)) append
		

