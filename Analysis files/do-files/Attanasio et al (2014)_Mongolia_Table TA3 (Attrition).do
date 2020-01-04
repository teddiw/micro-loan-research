/*==========================================================*
Project: 		EBRD-IFS Mongolia

Purpose:		Table 1 for the AEJ Applied special issue
				(Randomization)
				
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

*-- GLOBALS Variables in Table:
	#d ;
		global HHComp "hhsize under16 over16  age edulow buddhist";
		global CreditAccess "debt_bank01 debt_rel01 debt_fr01 debt_other01 loan";
		global CreditAmount "debt_bank debt_rel debt_fr debt_other debt_tot";
		global CreditAmount1000 "debt_bank_1000TR2p debt_rel_1000TR2p debt_fr_1000TR2p debt_other_1000TR2p debt_tot_1000TR2p";
		global SelfEmpl "enterprise soleent";
		global RespBus "rev_r exp_r profit_r";
		global RespBus1000 "rev_r_1000 exp_r_1000 profit_r_1000";
		global Employment "ysource agricwork01 privatebus01 mining01 inschool01 government01 b_benefit01 wages_remain01 agricwork_earn_scaled privatebus_earn_scaled mining_earn_scaled inschool_earn_scaled government_earn_scaled b_benefitvalHH_scaled wages_remain_scaled hhwageinc_earn_scaled ";
		global Consumption "annual_exp consump_yr consump_mth consump_food AssetI AI_huge AI_medium AI_electric AI_animal poor";
		global Consumption1000 "annual_exp_1000 consump_yr_1000 consump_mth_1000 consump_food_1000"; // AI_huge AI_medium AI_electric AI_animal poor
		global ConsumptionLN "ln_annual_exp ln_consump_yr ln_consump_mth ln_consump_food";
	#d cr

*-- PUT DATA SET TOGETHER: 
	use "data\Baseline\Master.dta", clear
	keep aimag soum treatment
	collapse treatment, by(aimag soum)
	merge 1:1 aimag soum using "data\Soum\BL soum level Qs.dta"
		drop _merge
	merge 1:m soum using "data\Baseline\all_outcomes_controls.dta"
	drop _merge
	foreach var of varlist enterprise{
		gen `var'0_temp=`var' if followup==0
		bys rescode: egen `var'0=max(`var'0_temp)
		drop *temp
		}
	keep if followup==0
	merge 1:1 rescode using "data\Baseline\personal info.dta", nogen
	merge 1:1 rescode using "data\Baseline\HH composition.dta", nogen
	merge 1:1 rescode using "data\Baseline\education.dta", nogen
	merge 1:1 rescode using "data\Baseline\loan_baseline.dta", nogen
	merge 1:1 rescode using "data\Baseline\Section K - Debt.dta", nogen
	merge 1:1 rescode using "data\Baseline\Section N - Econshocks.dta", nogen
	merge 1:1 rescode using "data\Baseline\Section Q - Relations.dta", nogen
	merge 1:1 rescode using "data\Baseline\Section R - Family.dta", nogen
	merge 1:1 rescode using "data\Baseline\Sections F,G,h - Ent.dta", nogen
	merge 1:1 rescode using "data\Baseline\Section L - Assets.dta", nogen
	merge 1:1 rescode using "data\Baseline\Constructed Vars for baseline balancedness_Oct2013.dta", nogen
	merge 1:1 hhid using "data\Baseline\totalconsump.dta", nogen
	merge 1:1 rescode using "data\Baseline\List of poor and nonpoor (merged only).dta", nogen
	keep if followup==0

*-- SOME DATA CLEANING:
	// replace missing with mean:
	foreach x of varlist  ppl fam cppl cfam lvstck area river {
		su `x'
		egen temp`x'=mean(`x')
		replace `x'=temp`x' if `x'==.
		drop temp`x'
		}
	egen over16=rowtotal(age16m age16f)
	// credit access/amounts
	forvalues i=1(1)3 {
		gen debt_bank`i'=valueloan_`i' if whomowned_`i'==1
		gen debt_formal`i'=valueloan_`i' if whomowned_`i'==1 | whomowned_`i'==5 | whomowned_`i'==6 
		gen debt_rel`i'=valueloan_`i' if whomowned_`i'==2
		gen debt_fr`i'=valueloan_`i' if whomowned_`i'==3
		gen debt_o`i'=valueloan_`i' if whomowned_`i'==4 | whomowned_`i'==7
		gen debt_other`i'=valueloan_`i' if whomowned_`i'==4 | whomowned_`i'==5 | whomowned_`i'==6 | whomowned_`i'==7
		}
	egen debt_bank=rowtotal(debt_bank1 debt_bank2 debt_bank3)
	egen debt_formal=rowtotal(debt_formal1 debt_formal2 debt_formal3)
	egen debt_rel=rowtotal(debt_rel1 debt_rel2 debt_rel3)
	egen debt_fr=rowtotal(debt_fr1 debt_fr2 debt_fr3)
	egen debt_o=rowtotal(debt_o1 debt_o2 debt_o3)
	egen debt_other=rowtotal(debt_other1 debt_other2 debt_other3)
	egen debt_tot=rowtotal(debt_bank debt_rel debt_fr debt_other)
	egen temp=rowtotal(valueloan_1 valueloan_2 valueloan_3)
		replace debt_bank=. if debt_bank>=1.23e+07	// 2 outliers
	foreach x of varlist debt_bank debt_formal debt_rel debt_fr debt_o debt_other{
		replace `x'=0 if `x'==.
		gen `x'01=`x'!=0
		}
	// Business
	egen exp_r=rowtotal(exponwag_r exponraw_r exponres_r exponmach_r exponequip_r exponmain_r expontrans_r exponfuel_r expontax_r exponint_r exponother_r)
	egen rev_r=rowtotal(revcash_r revkind_r revsale_r revrent_r revother_r)
	foreach x of varlist exp_r rev_r profit_r totalvalue {
		replace `x'=0 if `x'==.
		}
		la var exp_r "Tot expenditure of respondent's business"
	la var rev_r "Tot revenue of respondent's business"
	la var profit_r "Rev-exp respondent's business"
	foreach x of varlist $CreditAmount $RespBus {
		gen `x'_1000=`x'/1000
		su `x'_1000, d
		gen `x'_1000TR1p=`x'_1000 if `x'_1000<=r(p99)
		su `x'_1000TR1p, d
		gen `x'_1000TR2p=`x'_1000 if `x'_1000TR1p<=r(p99)
		}
	//  Consumption
	foreach x of varlist annual_exp consump_yr consump_mth consump_food{
		gen ln_`x'=log(`x')
		}
	foreach x of varlist annual_exp consump_yr consump_mth consump_food{
		gen `x'_1000=`x'/1000
		}
	// Wages
	egen wages_some01=rowmax(shopmarket01 bankfinance01 privatebus01)
	rename benefit benefit_nrmem
	gen benefit=benefit_nrmem!=1 
	replace benefit=. if benefit_nrmem==.
	egen wages_remain01=rowmax(shopmarket01 bankfinance01 hospital01 workother01)
	egen wages_remain_scaled=rowtotal(shopmarket_earn_scale bankfinance_earn_scale hospital_earn_scale workother_earn_scale)
	gen b_benefitvalHH_scaled=b_benefitvalHH/1000

*-- ATTRITION INDICATOR (take from a followup data set)
	merge 1:1 hhid using "data\Followup\f_Section C - Dwelling.dta", force	// this force is simply because there is a variable in string in using data	
	gen attrit=_m==1
	gen T=treatment!=0

	*---------------------------------------------------------------------*
	* (1b) Regression attrit on covariates, including treatment indicator *
	*---------------------------------------------------------------------*
	
	// Globals:
	#d ;
		global HHComp "hhsize under16 over16  age edulow buddhist";
		global CreditAccess "debt_bank01 debt_rel01 debt_fr01 debt_other01 loan"; //(we have data on 'other' but it is very very few...
		global CreditAmount "debt_tot_1000TR2p";
		global SelfEmpl "enterprise soleent";
		global Employment "ysource agricwork01 privatebus01 inschool01 government01 b_benefit01 wages_remain01 agricwork_earn_scaled privatebus_earn_scaled inschool_earn_scaled government_earn_scaled b_benefitvalHH_scaled wages_remain_scaled hhwageinc_earn_scaled ";
		global Consumption "ln_annual_exp ln_consump_yr ln_consump_mth ln_consump_food";
	#d cr
	
	qui probit attrit treatment if treatment!=1, robust
		outreg2 using "output\Attrition\Attrition.xls", replace  dec(3)
	qui probit attrit treatment $HHComp if treatment!=1, robust
		outreg2 using "output\Attrition\Attrition.xls", append  dec(3)
		test $HHComp treatment
		test $HHComp
	qui probit attrit treatment $HHComp $CreditAccess if treatment!=1, robust
		outreg2 using "output\Attrition\Attrition.xls", append  dec(3)
		test $HHComp $CreditAccess treatment
		test $HHComp $CreditAccess
	qui probit attrit treatment $HHComp $CreditAccess $CreditAmount if treatment!=1, robust
		outreg2 using "output\Attrition\Attrition.xls", append  dec(3)
		test $HHComp $CreditAccess $CreditAmount treatment
		test $HHComp $CreditAccess $CreditAmount
	qui probit attrit treatment $HHComp $CreditAccess $CreditAmount $SelfEmpl $Employment if treatment!=1, robust
		outreg2 using "output\Attrition\Attrition.xls", append  dec(3)
		test $HHComp $CreditAccess $CreditAmount $SelfEmpl $Employment treatment
		test $HHComp $CreditAccess $CreditAmount $SelfEmpl $Employment
	qui probit attrit treatment $HHComp $CreditAccess $CreditAmount $SelfEmpl $Employment $Consumption1000 if treatment!=1, robust
		outreg2 using "output\Attrition\Attrition.xls", append  dec(3)
		test $HHComp $CreditAccess $CreditAmount $SelfEmpl $Employment $Consumption1000 treatment
		test $HHComp $CreditAccess $CreditAmount $SelfEmpl $Employment $Consumption1000
	
	
	
	
	
