/*==========================================================*
Project: 		EBRD-IFS Mongolia

Purpose:		Estimate all results presented in the AEJ
				Applied Special Issue on Microfinance
				
				TABLE 2: Test all without the default variables	
				
Code Author: 	IFS 
Date created: 	April 2014
Last modified:  see "readme"-file for info
*===========================================================*/
capture log close
set more off
adopath+"C:\ado"
drop _all
set more off

global workdir "XXX\Analysis files"		
cap mkdir "${workdir}"	
cd "${workdir}"	
					
*-- PUT DATA SET TOGETHER: 
	use "data\Baseline\all_outcomes_controls.dta", clear
	
*-- GLOBALS Variables in Table:
	global Svar "doctors primschl ssteachers aimagcenter"
	global Svar1 "doctors aimagcenter fam livestock"
	global Xvar1 "loan_baseline eduhigh age16 under16 marr_cohab age age_sq buddhist hahl aug_b sep_f nov_f"
	global Xvar "loan_baseline eduvoc edusec age16 under16 marr_cohab age age_sq buddhist hahl aug_b sep_f nov_f"
	
*-------------------*
*	 PREPARE DATA:	*
*-------------------*
	do "Multiple hypothesis testing\do-files\(0) prepare data.do"
	*keep if indiv!=1 & followup==1		
	program drop _all
	
		// when we insheet later, capital letters become small -- therefore change all now
		rename dum_loan_formalnonX dum_loan_formalnonx
		rename BLdum_loan_formalnonX BLdum_loan_formalnonx
		rename BAI bai
		rename BLBAI BLbai
		*rename HDGI hdgi
		*rename BLHDGI BLhdgi
		rename tot_amount_formal_nonX tot_amount_formal_nonx
		rename BLtot_amount_formal_nonX BLtot_amount_formal_nonx
		

*-----------------------*
*	 CHANGE DIRECTORY:	*
*-----------------------*
global workdir "C:\Britta\Dropbox\Mongolia\AEJ Special Issue April 2014\Analysis files\Multiple hypothesis testing"		
cap mkdir "${workdir}"	
cd "${workdir}"	
	
	*---------------------------*
	*	 GLOBALS FOR TABLES:	*
	*---------------------------*
	global VariablesT2 "dum_loan_x dum_loan_formalnonx dum_loan_nonbank dum_any_loan dum_late_installment"	// dum_default default delayed_90 
	global VariablesT2PB "tot_amount_x tot_amount_formal_nonX tot_amount_nonbank tot_amount_loans"	// tot_amount_other_banks
	global VariablesT3 "scaled_assets_all bai enterprise nrents scaled_profit soleent scaled_profit_r r_started_bus_since_bas "
	global VariablesT4 "scaled_profit scaled_hhwageinc scaled_benefitvalHH scaled_food_inc" // NOTE: Profit is not repeated in the data set! (we have it in T3 and T4)
	global VariablesT5 "hours hours_own hours_other hours_wage hours_teen hours_own_teen hours_other_teen hours_wage_teen hours_prime hours_own_prime hours_other_prime hours_wage_prime"
	global VariablesT6 "ln_totalpc ln_durc ln_nondurc ln_foodc scaled_school scaled_tempt scaled_totalsav_hh hdgi"
	global VariablesT7 "share_6_15 hours_own_child hours_other_child hours_child_tot share_16_20 rectrans_y scaled_valuerec_y gavetrans_y scaled_valuegave_y "
	
	* Put here the table you want to check
	global Table "dum_loan_x dum_loan_formalnonx dum_loan_nonbank dum_any_loan tot_amount_x tot_amount_formal_nonx tot_amount_nonbank tot_amount_loans"
		
*-------------------------------*
*	 ESTIMATE FULL MODEL:		*
*-------------------------------*
*1. estimate 'full model', keep b, se, t (to identify largest)
foreach y in $Table  {
	eststo `y': reg `y' group BL`y' $Xvar aimagd* if indiv!=1 & followup==1, robust cl(soum)
		local	b_`y' 	=_b[group]
		local 	se_`y'	=_se[group]
		g t_`y' =abs(_b[group]/_se[group])
	}

	local keep_coeffs "group"
	esttab $Table using "Estimates full model\Coeff_se_MongoliaT2.csv", keep(`keep_coeffs') se(5) label replace plain nopar noobs
	esttab $Table using "Estimates full model\Coeff_t_MongoliaT2.csv", keep(`keep_coeffs') t(5) label replace plain nopar noobs

	preserve
		clear
		insheet using "Estimates full model\Coeff_se_MongoliaT2.csv", names
		drop in 1
		foreach x of varlist $Table {
		rename `x' b_`x'
		destring b_`x', replace
		}
		drop v1
		drop in 2 // drop standard errors 
		gen m=1	// this is for later merging
		save "Estimates full model\Coefficiens from actual regressionsT2.dta", replace
	restore

	preserve
		clear
		insheet using "Estimates full model\Coeff_se_MongoliaT2.csv", names
		drop in 1
		foreach x of varlist $Table {
		rename `x' se_`x'
		destring se_`x', replace
		}
		drop v1
		drop in 1 // drop coefficients
		gen m=1	// this is for later merging
		save "Estimates full model\Standard errors from actual regressionsT2.dta", replace
	restore
	
	preserve
		clear
		insheet using "Estimates full model\Coeff_t_MongoliaT2.csv", names
		drop in 1/2  // drop first row and coefficients
		foreach x of varlist $Table {
		rename `x' t_`x'
		destring t_`x', replace
		}
		drop v1
		gen m=1	// this is for later merging
		save "Estimates full model\T stats from actual regressionsT2.dta", replace
	restore

*---------------------------*
*	 BOOTSTRAPPING b':		*
*---------------------------*

keep $Table BL* soum $Xvar aimagd* group indiv followup
keep if indiv!=1 & followup==1
su $Table
tempfile db_block1
save `db_block1'.dta, replace	/*ORIGINAL DATA SET TO USE IN BS*/

local B = 1000  /* NUMBER OF REPLICATIONS*/
g n = _n
set seed 1
tempname rwT2
postfile `rwT2' iter str22 y bb_ bse_ bn_ using rwT2.dta, replace


* BOOTSTRAP LOOP 
local I = 1
while `I' <= `B' {
	di as error "." _cont
	*qui {
		use `db_block1'.dta, clear
		
		* Block-Bootstrap at soum level */
		bsample 25, cluster(soum) idcluster(clust)	
		local counter = 1
		foreach vary of global Table {											
			qui reg `vary' group BL`vary' $Xvar aimagd* , cluster(soum) // Block-BS
			local b  =_b[group]
			local se =_se[group]
			local n = e(N)

			post `rwT2' (`I') ("`vary'") (`b') (`se') (`n')
			}
			local counter = `counter' + 1
	local I = `I' + 1
} /*END BOOTSTRAP (WHILE) LOOP*/
postclose `rwT2'

exit
*----------------------
* COMBINE DATA SETS:
*----------------------

use "rwT2.dta" , clear
reshape wide bb bse bn, i(iter) j(y) string
gen m=1
merge m:1 m using "Estimates full model\Coefficiens from actual regressionsT2.dta", nogen
merge m:1 m using "Estimates full model\Standard errors from actual regressionsT2.dta", nogen
merge m:1 m using "Estimates full model\T stats from actual regressionsT2.dta", nogen

*---------------------------*
*	 CALCULATE TTESTS:		*
*---------------------------*

*4. compute t-stat of interest = tt_`y' =[(bb_`y' - b_`y') / se_`y']

	foreach y in $Table {
		gen tt_`y' = abs((bb_`y' - b_`y') / se_`y')
		}


*-------------------------*
* 99 Confidence Interval 
*-------------------------*
global Table "dum_loan_x dum_loan_formalnonx dum_loan_nonbank dum_any_loan tot_amount_x tot_amount_formal_nonx tot_amount_nonbank tot_amount_loans"
local j = 1

di "******************Iteration `j'*******************"
	* Highest tstat by iteration (step 4.a - alg 2.4)
	egen	max_tt_`j' = rowmax(tt_*)

	* Critical value as the 99th percentile of the max tstats distribution 
	sort 	max_tt_`j' 
	egen 	d_hat_`j' = pctile(max_tt_`j'), p(99)			
	
	di "********************Variables Above Critical T-stat Iteration `j'*******************"

	foreach y in $Table {
		* Reject S if tsat > critical value (step 3 - alg 4.1)
		g rej_`y'_`j'  = (abs(t_`y') > d_hat_`j')				/*REJECT IF ABS OF T > CRITICAL VALUE*/ 
		}
		
		* Display those that pass the test
		di "******************`y'*****************"
		sum d_hat_`j'
		sum rej_*_`j' t_*
exit	
		// IF SOME VARIABLES PASS (rej_*==1) and some don't (rej_*==0) THEN DO THE FOLLOWING MANUALLY:
		*(1) Drop variable that pass (i.e. those for which rej_*==1)
			*drop tt_XXX
		*(2) update the global "Tables" to the variables that did not pass (rej_*==0)
			*global Table "UPDATES"
		*(3) redo lines 193-214 above

		* Drop variable that pass:
		drop tt_dum_loan_x tt_dum_any_loan tt_tot_amount_x tt_tot_amount_loans
		* Update global:
		global Table "dum_loan_formalnonx dum_loan_nonbank  tot_amount_formal_nonx tot_amount_nonbank"


		// To get the critical value for 95%:
		   *(1) Change in line 202 p(99) to p(95)
