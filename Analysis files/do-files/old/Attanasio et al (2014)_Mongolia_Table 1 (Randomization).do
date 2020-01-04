/*==========================================================*
Project: 		EBRD-IFS Mongolia

Purpose:		Table 1 for the AEJ Applied special issue
				(Randomization)
				
Code Author: 	IFS 
Date created: 	April 2014
Last modified:  
Note:			This do-file is best executed quietly -- we just
				copy-pasetd results into excel. Not beautiful but
				we did not change it anymore later...
				On the positive side, no folder needs to therefore
				be created to run this file.
				To run the file all you need to do is change the 
				path of the working directory in line 22. 				
*===========================================================*/
capture log close
set more off
adopath+"C:\ado"
drop _all
global workdir "XXX\Analysis files"		
cap mkdir "${workdir}"	
cd "${workdir}"						


*-- PUT DATA SET TOGETHER: 
	use "data\Baseline\Master.dta", clear
	keep aimag soum treatment
	collapse treatment, by(aimag soum)
	merge 1:1 aimag soum using "data\Soum\BL soum level Qs.dta", nogen
	merge 1:m soum using "data\Baseline\all_outcomes_controls.dta", nogen
	keep if followup==0
	drop id_number
	*keep rescode treatment soleent0 dwellingvalue0 hours_wage0 bread20 milk20 loan_baseline hhincome0 followup
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
	merge 1:1 rescode using "data\Baseline\Constructed Vars for baseline balancedness_Oct2013.dta", nogen	// the do-file that created this data set is procided "Constructed Vars for baseline balancedness data set.do"
	merge 1:1 hhid using "data\Baseline\totalconsump.dta", nogen
	merge 1:1 rescode using "data\Baseline\List of poor and nonpoor (merged only).dta", nogen
	keep if followup==0
	keep if treatment!=1	// concentrate on group treatment versus control only
	
*-- GLOBALS Variables in Table:
	#d ;
		global HHComp "hhsize under16 over16  age edulow buddhist";
		global CreditAccess "debt_bank01 debt_rel01 debt_fr01 debt_other01 loan";
		global CreditAmount "debt_bank debt_rel debt_fr debt_other debt_tot";
		global CreditAmount1000 "debt_bank_1000TR2p debt_rel_1000TR2p debt_fr_1000TR2p debt_other_1000TR2p debt_tot_1000TR2p";
		global SelfEmpl "enterprise soleent";
		global RespBus "rev_r exp_r profit_r";
		global RespBus1000 "rev_r_1000 exp_r_1000 profit_r_1000 aimagc ";	//BAI
		global Employment "ysource agricwork01 privatebus01 mining01 inschool01 government01 b_benefit01 wages_remain01 agricwork_earn_scaled privatebus_earn_scaled mining_earn_scaled inschool_earn_scaled government_earn_scaled b_benefitvalHH_scaled wages_remain_scaled hhwageinc_earn_scaled ";
		global Consumption "annual_exp consump_yr consump_mth consump_food BLHDGI"; //AI_huge AI_medium AI_electric AI_animal poor
		global ConsumptionLN "ln_annual_exp ln_consump_yr ln_consump_mth ln_consump_food";
	#d cr

	
*-- SOME DATA CLEANING:
	// replace missing with mean (Soum level variables)
	foreach x of varlist  ppl fam cppl cfam lvstck area river {
		su `x'
		egen temp`x'=mean(`x')
		replace `x'=temp`x' if `x'==.
		drop temp`x'
		}
	foreach var of varlist enterprise{
		gen `var'0_temp=`var' if followup==0
		bys rescode: egen `var'0=max(`var'0_temp)
		drop *temp
		}
	
*+++++++++++++++++++++++++++*
* (Table 1) - Randomization *
*+++++++++++++++++++++++++++*
/* Notes: Data source: Baseline household survey. 
   Unit of observation: household. 
   Panel A: sample includes only households also surveyed at endline. 
   Panel B: sample includes all households surveyed at baseline. */

*-- Create some variables 	
	// Household composition
	egen over16=rowtotal(age16m age16f)
	// Credit access/amounts
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
	// Consumption
	foreach x of varlist annual_exp consump_yr consump_mth consump_food{
		gen ln_`x'=log(`x')
		}
	// Wages
	egen wages_some01=rowmax(shopmarket01 bankfinance01 privatebus01)
	rename benefit benefit_nrmem
	gen benefit=benefit_nrmem!=1 
	replace benefit=. if benefit_nrmem==.
	egen wages_remain01=rowmax(shopmarket01 bankfinance01 hospital01 workother01)
	egen wages_remain_scaled=rowtotal(shopmarket_earn_scale bankfinance_earn_scale hospital_earn_scale workother_earn_scale)
	gen b_benefitvalHH_scaled=b_benefitvalHH/1000

	 // home durable goods index
	merge m:1 rescode using "data\Baseline\Baseline outcomes.dta", keepusing(BLHDGI)
	drop _m
	
	su $HHComp $CreditAccess $CreditAmount1000 $SelfEmpl $RespBus1000 $Employment $Consumption
	
	gen T=treatment!=0

	*--------------------------------------------------------------------*
	* Panel A: sample includes only households also surveyed at endline. *
	*--------------------------------------------------------------------*

	foreach x of varlist $HHComp $CreditAccess $CreditAmount1000 $SelfEmpl $RespBus1000 $Employment $Consumption $ConsumptionLN  {
		su `x' if reint==1 & ind!=1
		gen BLobs`x'=r(N)
		su `x' if T==0 & reint==1 & ind!=1
		gen BLobs`x'C=r(N)
		gen BLmean`x'=r(mean)
		gen BLsd`x'=r(sd)
		
		reg `x' treatment if reint==1 & treatment!=1, robust cl(soum)
		gen betaG`x' =_b[treatment]
		gen t_G`x'=(_b[treatment]/_se[treatment])
		gen p_G`x'=(2 * ttail(e(df_r), abs(_b[treatment]/_se[treatment])))
		}

	** DISPLAY RESULTS
	noi di as txt "PANEL A"
	noi di as txt "{col 32}" "Control Group" as txt "{col 62}" "Treatment-Control"
	noi di as txt "{col 22}" "Obs" as txt "{col 32}" "Obs(C)" as txt "{col 42}" "Mean" as txt "{col 52}" "StdDev" as txt  "{col 62}" "Coeff G" as txt "{col 72}" "p-value" 
	noi di as txt ""
	noi di as txt "Household composition"
	foreach v of varlist $HHComp  {
	   	noi di as txt "`v'" "{col 22}" as res %6.0f  BLobs`v' "{col 32}" as res %6.0f  BLobs`v'C "{col 42}" as res %6.3f  BLmean`v' "{col 52}" as res %6.3f  BLsd`v'  "{col 62}"  as res %6.3f  betaG`v' "{col 72}"  as res %6.3f   p_G`v' 
		}
	noi di as txt ""
	noi di as txt "Access to credit:"
	foreach v of varlist $CreditAccess  {
	   	noi di as txt "`v'" "{col 22}" as res %6.0f  BLobs`v' "{col 32}" as res %6.0f  BLobs`v'C "{col 42}" as res %6.3f  BLmean`v' "{col 52}" as res %6.3f  BLsd`v'  "{col 62}"  as res %6.3f  betaG`v' "{col 72}"  as res %6.3f   p_G`v' 
		}
	noi di as txt ""
	noi di as txt "Amount borrowed from (in BAM):"
	foreach v of varlist $CreditAmount1000  {
	   	noi di as txt "`v'" "{col 22}" as res %6.0f  BLobs`v' "{col 32}" as res %6.0f  BLobs`v'C "{col 42}" as res %6.1f  BLmean`v' "{col 52}" as res %6.1f  BLsd`v'  "{col 62}"  as res %6.3f  betaG`v' "{col 72}"  as res %6.3f   p_G`v' 
		}
	noi di as txt ""
	noi di as txt "Employment Activities:"
	foreach v of varlist $SelfEmpl  {
	   	noi di as txt "`v'" "{col 22}" as res %6.0f  BLobs`v' "{col 32}" as res %6.0f  BLobs`v'C "{col 42}" as res %6.3f  BLmean`v' "{col 52}" as res %6.3f  BLsd`v'  "{col 62}"  as res %6.3f  betaG`v' "{col 72}"  as res %6.3f   p_G`v' 
		}
	noi di as txt ""
	foreach v of varlist $RespBus1000  {
	   	noi di as txt "`v'" "{col 22}" as res %6.0f  BLobs`v' "{col 32}" as res %6.0f  BLobs`v'C "{col 42}" as res %6.3f  BLmean`v' "{col 52}" as res %6.3f  BLsd`v' "{col 62}"  as res %6.3f  betaG`v' "{col 72}"  as res %6.3f   p_G`v' 
		}
	noi di as txt ""
	foreach v of varlist $Employment  {
	   	noi di as txt "`v'" "{col 22}" as res %6.0f  BLobs`v' "{col 32}" as res %6.0f  BLobs`v'C "{col 42}" as res %6.3f  BLmean`v' "{col 52}" as res %6.3f  BLsd`v' "{col 62}"  as res %6.3f  betaG`v' "{col 72}"  as res %6.3f   p_G`v' 
		}
	noi di as txt ""
	noi di as txt "Consumption:"
	foreach v of varlist $Consumption $ConsumptionLN {
	   	noi di as txt "`v'" "{col 22}" as res %6.0f  BLobs`v' "{col 32}" as res %6.0f  BLobs`v'C "{col 42}" as res %6.2f  BLmean`v' "{col 52}" as res %6.2f  BLsd`v' "{col 62}"  as res %6.3f  betaG`v' "{col 72}"  as res %6.3f   p_G`v'  
		}

		
	*--------------------------------------------------------------------*
	* Panel B: Attrition 												 *
	*--------------------------------------------------------------------*
	use "data\Baseline\Master.dta", clear
	keep if followup==0
	drop if treatment==1
	merge 1:1 hhid using "data\Followup\f_Section C - Dwelling.dta", force	

	gen attrit=_m==1
	gen T=treatment!=0
	
		su attrit if treatment!=1
		gen BLobsattrit=r(N)
		su attrit if T==0 & treatment!=1
		gen BLobsattritC=r(N)
		gen BLmeanattrit=r(mean)
		gen BLsdattrit=r(sd)
		
		reg attrit treatment if treatment!=1, robust cl(soum)
		gen betaGattrit =_b[treatment]
		gen t_Gattrit=(_b[treatment]/_se[treatment])
		gen p_Gattrit=(2 * ttail(e(df_r), abs(_b[treatment]/_se[treatment])))
	
	   	noi di as txt "attrit" "{col 22}" as res %6.0f  BLobsattrit "{col 32}" as res %6.0f  BLobsattritC "{col 42}" as res %6.3f  BLmeanattrit "{col 52}" as res %6.3f  BLsdattrit "{col 62}"  as res %6.3f  betaGattrit "{col 72}"  as res %6.3f   p_Gattrit 

