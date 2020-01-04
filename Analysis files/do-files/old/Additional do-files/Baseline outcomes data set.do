/*==========================================================*
Project: 		EBRD-IFS Mongolia

Purpose:		This do-file creates BASELINE variables 
				
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

	use "data\all_outcomes_controls.dta", clear
	drop if reint==0
	drop id_number // not the same typeof var for some reason
	merge 1:1 rescode followup using "data\Income.dta"	
	drop if _merge != 3
	drop _m

* ----------------------------------------- *
* 	Table 2 -- Credit (Survey data)
* ----------------------------------------- *
	merge 1:1 rescode followup using "data\Debt.dta"
	drop if _merge != 3
	drop _merge
	replace nloans_x = 0 if nloans_x == . 
	replace totalamo_e = 0 if totalamo_e == .
							
	foreach v of varlist amount*	{
		recode `v' . = 0	
		}
	gen tot_amount_x = amount1_x + amount2_x + amount3_x
	gen tot_amount_loans = tot_amount_x + totalamo_e
	gen tot_amount_other_banks = amount1_e + amount2_e + amount3_e if (source1_e == 1 | source2_e == 1 | source3_e == 1)
	gen tot_amount_other_formal = amount1_e + amount2_e + amount3_e if (source1_e == 5 | source2_e == 5 | source3_e == 5)
	gen tot_amount_informal = amount1_e + amount2_e + amount3_e if (source1_e == 7 | source2_e == 7 | source3_e == 7 | ///
						source1_e == 2 | source2_e == 2 | source3_e == 2 | ///
						source1_e == 8 | source2_e == 8 | source3_e == 8 )
	egen tot_amount_formal_nonX=rowtotal(tot_amount_other_banks tot_amount_other_formal)
	egen tot_amount_nonbank=rowtotal(tot_amount_other_formal tot_amount_informal)
	foreach v of varlist tot_amount_*	{
		recode `v' . = 0
		gen scaled_`v' = `v' / 1000
		}
	gen dum_loan_x = (nloans_x > 0)
	gen dum_loan_bank = (tot_amount_other_banks > 0)
	gen dum_loan_other_formal = (tot_amount_other_formal > 0)
	gen dum_loan_informal = (tot_amount_informal > 0)
	gen dum_loan_formalnonX = (tot_amount_formal_nonX > 0)
	gen dum_any_loan = (tot_amount_loans > 0)
	gen dum_loan_nonbank = (tot_amount_nonbank > 0)
	
	gen dum_default = (def1_x == 1 | def2_x == 1 | def3_x == 1 | def1_e == 1 | def2_e == 1 | def3_e == 1 )
	gen dum_late_installment = (late1_x == 1 | late2_x == 1 | late3_x == 1 | late1_e == 1 | late2_e == 1 | late3_e == 1)
	gen dum_default_late = (dum_default == 1 | dum_late_installment == 1)
	
* ----------------------------------------- *
* 	Table 3 -- Self-employment activities, revenues, assets and profits
* ----------------------------------------- *
	 foreach outcome in assets_all profit profit_r totalrev_r {
		gen scaled_`outcome' = `outcome' / 1000
		}
	* business asset index
		factor tools1 unsold1 vehicle redieqi1, pcf // Principal Component Factor analysis
		predict BAI 

* ----------------------------------------- *
* 	Table 4 -- Income
* ----------------------------------------- *
	merge 1:1 rescode followup using "data\HH benefits (followup only).dta"
	drop _m
	merge 1:1 rescode followup using "data\outcome_income_BL_FY.dta"
	drop _m
	foreach v in hhwageinc valuerec_y food_inc benefitvalHH f_benefitvalHH {
		gen scaled_`v' = `v' / 1000 
	}
	egen temp=rowtotal(scaled_food_inc scaled_profit)
	
* ----------------------------------------- *
* 	Table 5 -- Time worked by household members
* ----------------------------------------- *
	merge 1:1 rescode followup using "data\Labour Supply.dta"
	drop if reint == 0
	drop if _merge != 3	
	drop _m
	
* ----------------------------------------- *
* 	Table 6 -- Consumption
* ----------------------------------------- *
	gen totalpc	= totalc/hhsize
	lab var totalpc "total per capital cons - last month"
	gen tempt = recreat_cm + cigaret8 + alcohol_cm /*temptation + entertainment, last month */
	lab var tempt "recreation, cig, alcohol - last month"		
	gen school = schoo12/12
	lab var school "educ expenses - last month"
	replace durc=durc/12 // this was multiplied by 12 in the initial do-file which is wrong!!!
	merge 1:1 rescode followup using "data\Savings.dta"
	drop _m
		foreach x of varlist compphonesat tv1 vcrradio smalle1 largehhapp {
			gen `x'_dum = (`x'! = 0 & `x' != . )
			}
		factor *_dum, pcf // Principal Component Factor analysis
		rotate
		predict HDGI 
	foreach outcome in totalpc totalc foodc nondurc durc tempt school valuegave_m totalsav_hh  {
		sum `outcome' if group == 0 & indiv == 0 & followup == 0
		scalar base_`outcome' = r(mean)
		gen scaled_`outcome' = `outcome' / base_`outcome' 
		gen ln_`outcome' = log(`outcome')
		}

* ----------------------------------------- *
* 	Table 7 -- Social Effects
* ----------------------------------------- *
	merge 1:1 rescode followup using "data\Labour Supply.dta"	// merge in food_income just using food received as gift
	drop if _merge != 3
	drop _merge
	merge 1:1 rescode followup using "data\share_in_school.dta"	
	drop if _merge != 3
	drop _merge
	egen hours_child_tot=rowtotal(hours_own_child hours_other_child hours_wage_child)

	foreach outcome in /*valuerec_y*/ valuegave_y  {
		recode `outcome' . = 0
		gen scaled_`outcome' = `outcome' / 1000
	}
	
	
*===============================================================*		
*===============================================================*		

* GLOBALS:
global VariablesT2PA "dum_loan_x dum_loan_formalnonX dum_loan_nonbank dum_any_loan dum_default dum_late_installment"	//dum_loan_bank dum_loan_informal dum_default_late
global VariablesT2PB "tot_amount_x tot_amount_formal_nonX tot_amount_nonbank tot_amount_loans"	// tot_amount_other_banks
global VariablesT3 "scaled_assets_all BAI enterprise nrents scaled_profit soleent scaled_profit_r r_started_bus_since_bas scaled_totalrev_r"
global VariablesT4 "scaled_hhwageinc scaled_f_benefitvalHH scaled_food_inc hhwageinc_earn_scaled scaled_benefitvalHH benefit01 benefitHHmem"
global VariablesT5 "hours hours_own hours_other hours_wage hours_teen hours_own_teen hours_other_teen hours_wage_teen hours_prime hours_own_prime hours_other_prime hours_wage_prime"
global VariablesT6 "ln_totalpc ln_durc ln_nondurc ln_foodc scaled_school scaled_tempt scaled_totalsav_hh HDGI"
global VariablesT7 "share_6_15 hours_own_child hours_other_child hours_child_tot hours_wage_child share_16_20 rectrans_y scaled_valuerec_y gavetrans_y scaled_valuegave_y "

keep rescode followup $VariablesT2PA  $VariablesT2PB  $VariablesT3  $VariablesT4  $VariablesT5  $VariablesT6 $VariablesT7 temp*
keep if followup==0
drop followup
foreach x of varlist $VariablesT2PA  $VariablesT2PB  $VariablesT3  $VariablesT4  $VariablesT5  $VariablesT6 $VariablesT7 temp* {
	rename `x' BL`x'
	}
save "data\Baseline outcomes.dta", replace


* ----------------------------------------- *
* 	Table 2 -- Credit (XacBank Admin Data)
* ----------------------------------------- *
	use "data\XacBank admin debt data\loan_data_new_delay.dta", clear
	gen rin=Rin
	gen followup=1
	// merge in HHid
	merge m:1 rin using "data\HHid and Rin.dta"
	keep if _m==3 // problem: not all matched: 89 loans not able to match to HHid
	drop _m
	merge m:1 hhid followup using "data\all_outcomes_controls.dta"
		foreach x of varlist Delayed_30 Delayed_60 Delayed_90 Default { 
			replace `x'=0 if treatment==0
			replace `x'=0 if followup==0
			}
	drop if reint==0
	drop id_number // not the same typeof var for some reason
	egen delay_default=rowmax(Delayed_90 Default)
	global VariablesT2XacBank "Default Delayed_90"	// Delayed_30 Delayed_60 Default delay_default
	keep rescode followup $VariablesT2XacBank
	keep if followup==0
	drop followup
	foreach x of varlist $VariablesT2XacBank {
		rename `x' BL`x'
		}
	
save "data\Baseline outcomes temp.dta", replace
use "data\Baseline outcomes.dta", clear
merge 1:1 rescode using "data\Baseline outcomes temp.dta"
	drop if _m==2
	drop _m
save "data\Baseline outcomes.dta", replace
erase "data\Baseline outcomes temp.dta"
