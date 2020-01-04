/*==========================================================*
Project: 		EBRD-IFS Mongolia

Purpose:		Estimate all results presented in the AEJ
				Applied Special Issue on Microfinance
				
Code Author: 	IFS 
Date created: 	April 2014
Last modified:  
Note:			To run this do-file you need to change the path 
				in line 23. In the folder this path leads to,
				you need to have two sub-folder:
				(i) "data" (with all files we submitted), and
				(ii) "output" -- here is where the results will be
				     stored. This folder needs again two subfolders:
					 (a) "Results - simple diff (G&C only)" and
					 (b) "Results - double diff (G&C only)"
*===========================================================*/
capture log close
set more off
adopath+"C:\ado"
drop _all
global workdir "XXX\Analysis files"		
cap mkdir "${workdir}"	
cd "${workdir}"						

*-- DATA SET:
	use "data\Baseline\all_outcomes_controls.dta", clear
	*-- Merge in additional data:
	// add income data (other than totla hhincome): hhwageinc "total household income from wage employment", hhbenefits "total household benefits from wage employment", food_inc "household income income from producing food products", entprofit "household income from enterprise profits"
	drop id_number // not the same typeof var for some reason
	merge 1:1 rescode followup using "data\Followup\Income.dta", nogen	// merge in food_income just using food received as gift
	merge m:1 rescode using "data\Baseline\Baseline outcomes.dta", nogen

*-- GLOBALS FOR ANALYSIS
	global Xvar "loan_baseline eduvoc edusec age16 under16 marr_cohab age age_sq buddhist hahl aug_b sep_f nov_f"

*-- PREPARE DATA:
	drop if reint==0
	gen age16=age16m + age16f

	*-- Aimag dummies
	ta aimag, gen(aimagd)

	*-- INDICATORS FOR PROGRAM EVALUATION:
	gen GLEF = (group == 1 & edusec == 0 & followup == 1)
	gen GHEF = (group == 1 & edusec == 1 & followup == 1)
	gen ILEF = (indiv == 1 & edusec == 0 & followup == 1)
	gen IHEF = (indiv == 1 & edusec == 1 & followup == 1)
	gen FLE  = (edusec == 0 & followup == 1)
	gen FHE  = (edusec == 1 & followup == 1)
	gen GEL = (group == 1 & edusec == 0)
	gen GEH = (group == 1 & edusec == 1)
	gen IEL = (indiv == 0 & edusec == 0)
	gen IEH = (indiv == 0 & edusec == 1)
	
	*-- GLOBALS FOR Double-Difference ANALYSIS (not presented in paper, left here for completeness):
	global SimpleSpecDD "followup group GF"
	global InterSpecDD "followup FLE FHE group GLEF GHEF"
	

/* --------------------------------------------------------------------------------------
   ---------------------------------------------------------------------------------------
   We next conduct the impact analysis by Table as presented in the paper.
   We start with Table 2 (Table 1 is constructed in a separate do-file)
   For each Table, we have here the impact regressions for the simple-diff specification
   (as presented in the paper) as well as the double-difference specification for
   completeness. 
   ---------------------------------------------------------------------------------------
   ---------------------------------------------------------------------------------------*/
	

* ----------------------------------------- *
* 	Table 2 -- Credit (Survey data)
* ----------------------------------------- *
/* This table uses data from the household survey as well as from the admin data 
   we received from our implementing partner (columns 5 and 7).
   In this section we only estimate impacts on outcomes using the survey data. 
   The admin data will be analysed below (at the end of the do-fiel -- ~line 450).*/
   
    *-- Merge in debt data:
	merge 1:1 rescode followup using "data\Followup\Debt.dta"
	drop if _merge==2	// These are households that were not reinterviewed at followup (#187)	
	drop _merge
	
	*-- GLOBAL for the variabls presented in the Table:
	    //(other variables looked at are in comments behind the globals)
	global VariablesT2PA "dum_loan_x dum_loan_formalnonX dum_loan_nonbank dum_any_loan dum_default dum_late_installment"	//dum_loan_bank dum_loan_informal dum_default_late
		// Panel A further includes regressions with XacBank and not survey data -> these regressions are done at the end of this file (as XacBank admin data set is used)
	global VariablesT2PB "tot_amount_x tot_amount_formal_nonX tot_amount_nonbank tot_amount_loans"	// tot_amount_other_banks
	
	*-- Some data cleaning and creating of variables for the analysis:
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
	

	*===== SIMPLE DIFFERENCE ====*
	local table = "replace"
	foreach x of varlist $VariablesT2PA $VariablesT2PB { 
		qui reg `x' group BL`x' $Xvar aimagd* if indiv!=1 & followup==1, robust cl(soum)
				
		qui sum `x' if e(sample) & group == 0 & indiv == 0 & followup == 1
		local meanfollow = r(mean)
		qui sum `x' if e(sample) & followup == 1
		local numberhh = r(N)
		
		outreg2 group using "output\Results - simple diff (G&C only)\table_2_credit", cttop("`x'") nocons ///
		sortvar(group) noobs ///
		addstat(Number of households, `numberhh', Mean Control Follow, `meanfollow') dec(3) ///
		excel `table' ///
		title("Table 2. Credit.") nor2
		local table = "append"
		}
		
	*===== DOUBLE DIFFERENCE ====*
	local table = "replace"
	foreach x of varlist $VariablesT2PA $VariablesT2PB { 
		qui reg `x' $SimpleSpecDD $Xvar if indiv!=1, robust cl(soum)
				
		qui sum `x' if e(sample) & group == 0 & indiv == 0 & followup == 1
		local meanfollow = r(mean)
		qui sum `x' if e(sample) & followup == 1
		local numberhh = r(N)
		
		outreg2 GF using "output\Results - double diff (G&C only)\table_2_credit", cttop("`x'") nocons ///
		sortvar(GF) noobs ///
		addstat(Number of households, `numberhh', Mean Control Follow, `meanfollow') dec(3) ///
		excel `table' ///
		title("Table 2. Credit.") nor2
		local table = "append"
		}


* --------------------------------------------------------------------- *
* 	Table 3 -- Self-employment activities, revenues, assets and profits
* --------------------------------------------------------------------- *

	*-- GLOBAL for the variabls presented in the Table:
	global VariablesT3 "scaled_assets_all BAI enterprise nrents scaled_profit soleent scaled_profit_r r_started_bus_since_bas "

	*-- Some data cleaning and creating of variables for the analysis:
	foreach outcome in assets_all profit profit_r  {	// we scale outcomes
		gen scaled_`outcome' = `outcome' / 1000
		}
		// business asset index
		factor tools1 unsold1 vehicle redieqi1, pcf // Principal Component Factor analysis
		predict BAI 
	
	*===== SIMPLE DIFFERENCE ====*
	local table = "replace"
	foreach x of varlist $VariablesT3 { 
		qui reg `x' group BL`x'  $Xvar aimagd* if indiv!=1 & followup==1, robust cl(soum)
		
		qui sum `x' if e(sample) & group == 0 & indiv == 0 & followup == 1
		local meanfollow = r(mean)
		qui sum `x' if e(sample) & followup == 1
		local numberhh = r(N)
		
		outreg2 group using "output\Results - simple diff (G&C only)\table_3_self_employment", cttop("`x'") nocons ///
		sortvar(group) noobs ///
		addstat(Number of households, `numberhh', Mean Control Follow, `meanfollow') dec(3) ///
		excel `table' ///
		addnote("Asset and profit scaled by a factor of 1000. Only respondents considered.") ///
		title("Table 3. Self-employment") nor2
		local table = "append"
		}
	

	*===== DOUBLE DIFFERENCE ====*
	foreach x of varlist $VariablesT3 { 
		qui reg `x' $SimpleSpecDD $Xvar if indiv!=1, robust cl(soum)
				
		qui sum `x' if e(sample) & group == 0 & indiv == 0 & followup == 1
		local meanfollow = r(mean)
		qui sum `x' if e(sample) & followup == 1
		local numberhh = r(N)
		
		outreg2 GF using "output\Results - double diff (G&C only)\table_3_self_employment", cttop("`x'") nocons ///
		sortvar(GF) noobs ///
		addstat(Number of households, `numberhh', Mean Control Follow, `meanfollow') dec(3) ///
		excel `table' ///
		addnote("Asset and profit scaled by a factor of 1000. Only respondents considered.") ///
		title("Table 3. Self-employment") nor2
		local table = "append"
		}

	
* ----------------------------------------- *
* 	Table 4 -- Income
* ----------------------------------------- *

    *-- Merge in income data:
	merge m:1 rescode using "data\Followup\HH benefits.dta"	// had to be reconstructed due to a mistake - so far only done for followup... 3 obs missing
	drop _m
	*merge m:1 rescode followup using "data\outcome_income_BL_FY.dta"
	*drop _m
	
	*-- GLOBAL for the variabls presented in the Table:
	global VariablesT4 "scaled_profit scaled_hhwageinc scaled_benefitvalHH scaled_food_inc"

	*-- Some data cleaning and creating of variables for the analysis:
	foreach v in hhwageinc valuerec_y food_inc benefitvalHH {
		gen scaled_`v' = `v' / 1000 
	}
	
	*===== SIMPLE DIFFERENCE ====*
	local table = "replace"
	foreach x of varlist $VariablesT4 { 
		qui reg `x' group BL`x' $Xvar aimagd* if indiv!=1 & followup==1, robust cl(soum)
		
		qui sum `x' if e(sample) & group == 0 & indiv == 0 & followup == 1
		local meanfollow = r(mean)
		qui sum `x' if e(sample) & followup == 1
		local numberhh = r(N)
		
		outreg2 group using "output\Results - simple diff (G&C only)\table_4_income", cttop("`x'") nocons ///
		sortvar(group) noobs ///
		addstat(Number of households, `numberhh', Mean Control Follow, `meanfollow') dec(1) ///
		excel `table' ///
		title("Table 4. Income.") nor2
		local table = "append"
		}
	
		
	*===== DOUBLE DIFFERENCE ====*
	local table = "replace"
	foreach x of varlist $VariablesT4 { 
		qui reg `x' $SimpleSpecDD $Xvar if indiv!=1, robust cl(soum)
		
		qui sum `x' if e(sample) & group == 0 & indiv == 0 & followup == 1
		local meanfollow = r(mean)
		qui sum `x' if e(sample) & followup == 1
		local numberhh = r(N)
		
		outreg2 GF using "output\Results - double diff (G&C only)\table_4_income", cttop("`x'") nocons ///
		sortvar(GF) noobs ///
		addstat(Number of households, `numberhh', Mean Control Follow, `meanfollow') dec(0) ///
		excel `table' ///
		title("Table 4. Income.") nor2
		local table = "append"
		}


* ----------------------------------------- *
* 	Table 5 -- Time worked by household members
* ----------------------------------------- *
    *-- Merge in XXX data:
	merge 1:1 rescode followup using "data\Followup\Labour Supply.dta", nogen
	drop if reint == 0

	*-- GLOBAL for the variabls presented in the Table:
	global VariablesT5 "hours hours_own hours_other hours_wage hours_teen hours_own_teen hours_other_teen hours_wage_teen hours_prime hours_own_prime hours_other_prime hours_wage_prime"

	*===== SIMPLE DIFFERENCE ====*
	local table = "replace"
	foreach x of varlist $VariablesT5 { 
		qui reg `x' group BL`x' $Xvar aimagd* if indiv!=1 & followup==1, robust cl(soum)

		qui sum `x' if e(sample) & group == 0 & indiv == 0 & followup == 1
		local meanfollow = r(mean)
		qui sum `x' if e(sample) & followup == 1
		local numberhh = r(N)
		
		outreg2 group using "output\Results - simple diff (G&C only)\table_5_labor_supply", cttop("`x'") nocons ///
		sortvar(group) noobs ///
		addstat(Number of households, `numberhh', Mean Control Follow, `meanfollow') dec(3) ///
		excel `table' ///
		title("Table 5. Labor Supply.") nor2
		local table = "append"
		}		
	
	*===== DOUBLE DIFFERENCE ====*
	local table = "replace"
	foreach x of varlist $VariablesT5 { 
		qui reg `x' $SimpleSpecDD $Xvar if indiv!=1, robust cl(soum)
				
		qui sum `x' if e(sample) & group == 0 & indiv == 0 & followup == 1
		local meanfollow = r(mean)
		qui sum `x' if e(sample) & followup == 1
		local numberhh = r(N)
		
		outreg2 GF using "output\Results - double diff (G&C only)\table_5_labor_supply", cttop("`x'") nocons ///
		sortvar(GF) noobs ///
		addstat(Number of households, `numberhh', Mean Control Follow, `meanfollow') dec(3) ///
		excel `table' ///
		title("Table 5. Labor Supply.") nor2
		local table = "append"
		}

		
* ----------------------------------------- *
* 	Table 6 -- Consumption
* ----------------------------------------- *
    *-- Merge in savings data:
	merge 1:1 rescode followup using "data\Followup\Savings.dta", nogen

	*-- GLOBAL for the variabls presented in the Table:
	global VariablesT6 "ln_totalpc ln_durc ln_nondurc ln_foodc scaled_school scaled_tempt scaled_totalsav_hh HDGI"

	*-- Some data cleaning and creating of variables for the analysis:
	gen totalpc	= totalc/hhsize
	lab var totalpc "total per capital cons - last month"
	gen tempt = recreat_cm + cigaret8 + alcohol_cm /*temptation + entertainment, last month */
	lab var tempt "recreation, cig, alcohol - last month"		
	gen school = schoo12/12
	lab var school "educ expenses - last month"
	replace durc=durc/12 // this was multiplied by 12 in the initial do-file which is wrong!!!
		// home durable good index: 
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

		
	*===== SIMPLE DIFFERENCE ====*
	local table = "replace"
	foreach x of varlist $VariablesT6 { 
		qui reg `x' group BL`x' $Xvar aimagd* if indiv!=1 & followup==1, robust cl(soum)
				
		qui sum `x' if e(sample) & group == 0 & indiv == 0 & followup == 1
		local meanfollow = r(mean)
		qui sum `x' if e(sample) & followup == 1
		local numberhh = r(N)
				
		outreg2 group using "output\Results - simple diff (G&C only)\table_6_consumption", cttop("`x'") nocons noobs ///
		addstat(Number of households, `numberhh', Mean Control Follow, `meanfollow') dec(3) ///
		excel addnote("Festival & Celebration expenditures subsumed in Temptation & Entertainment. Outcome variables scaled by a factor of 1000.") `table' ///
		title("Table 6. Consumption") nor2
		local table = "append"
			}
	
	*===== DOUBLE DIFFERENCE ====*
	local table = "replace"
	foreach x of varlist $VariablesT6 { 
		qui reg `x' $SimpleSpecDD $Xvar if indiv!=1, robust cl(soum)
				
		qui sum `x' if e(sample) & group == 0 & indiv == 0 & followup == 1
		local meanfollow = r(mean)
		qui sum `x' if e(sample) & followup == 1
		local numberhh = r(N)
				
		outreg2 GF using "output\Results - double diff (G&C only)\table_6_consumption", cttop("`x'") nocons noobs ///
		addstat(Number of households, `numberhh', Mean Control Follow, `meanfollow') dec(3) ///
		excel addnote("Festival & Celebration expenditures subsumed in Temptation & Entertainment. Outcome variables scaled by a factor of 1000.") `table' ///
		title("Table 6. Consumption") nor2
		local table = "append"
			}

			
* ----------------------------------------- *
* 	Table 7 -- Social Effects
* ----------------------------------------- *
    *-- Merge in XXX data:
	merge 1:1 rescode followup using "data\Followup\share_in_school.dta"	
	drop if _merge != 3
	drop _merge

	*-- GLOBAL for the variabls presented in the Table:
	global VariablesT7 "share_6_15 hours_own_child hours_other_child hours_child_tot share_16_20 rectrans_y scaled_valuerec_y gavetrans_y scaled_valuegave_y "

	*-- Some data cleaning and creating of variables for the analysis:
	drop BLscaled_valuerec_y
	foreach outcome in valuegave_y valuerec_y0 valuegave_y0{
		recode `outcome' . = 0
		gen scaled_`outcome' = `outcome' / 1000
	}
	rename scaled_valuerec_y0 BLscaled_valuerec_y
	*rename scaled_valuegave_y0 BLscaled_valuegave_y	// these are identical in value and obs
	egen hours_child_tot=rowtotal(hours_own_child hours_other_child hours_wage_child)
	
	
	*===== SIMPLE DIFFERENCE ====*
	local table = "replace"
	foreach x of varlist $VariablesT7 { 
		qui reg `x' group BL`x' $Xvar aimagd* if indiv!=1 & followup==1, robust cl(soum)
				
		qui sum `x' if e(sample) & group == 0 & indiv == 0 & followup == 1
		local meanfollow = r(mean)
		qui sum `x' if e(sample) & followup == 1
		local numberhh = r(N)
				
		outreg2 group using "output\Results - simple diff (G&C only)\table_7_social_outcomes", cttop("`x'") nocons ///
		sortvar(group) noobs ///
		addstat(Number of households, `numberhh', Mean Control Follow, `meanfollow') dec(3) ///
		excel `table' ///
		title("Table 7. Social Outcomes.") nor2
		local table = "append"
		}
	
	*===== DOUBLE DIFFERENCE ====*
	local table = "replace"
	foreach x of varlist $VariablesT7 { 
		qui reg `x' $SimpleSpecDD $Xvar if indiv!=1, robust cl(soum)
				
		qui sum `x' if e(sample) & group == 0 & indiv == 0 & followup == 1
		local meanfollow = r(mean)
		qui sum `x' if e(sample) & followup == 1
		local numberhh = r(N)
				
		outreg2 GF using "output\Results - double diff (G&C only)\table_7_social_outcomes", cttop("`x'") nocons ///
		sortvar(GF) noobs ///
		addstat(Number of households, `numberhh', Mean Control Follow, `meanfollow') dec(3) ///
		excel `table' ///
		title("Table 7. Social Outcomes.") nor2
		local table = "append"
		}
		
		
		
*===============================================================*		
* ----------------------------------------- *
* 	Table 2 -- Credit (XacBank Admin Data)
* ----------------------------------------- *
    *-- Merge in XXX data:
	use "data\XacBank admin debt data\loan_data_new_delay.dta", clear
	gen rin=Rin
	gen followup=1
	// merge in HHid
	merge m:1 rin using "data\HHid and Rin.dta"
	keep if _m==3 // problem: not all matched: 89 loans not able to match to HHid
	drop _m
	// merge in other data:
	merge m:1 hhid followup using "data\Baseline\all_outcomes_controls.dta"
	drop _m
	merge m:1 rescode using "data\Baseline\Baseline outcomes.dta"
	drop if _m==2
	drop _m
	drop if reint==0
	drop id_number // not the same typeof var for some reason

	*-- GLOBAL for the variabls presented in the Table:
	global VariablesT2XacBank "delay_default delayed_30"	// Delayed_30 Delayed_60 Default delay_default

	*-- INDICATORS FOR PROGRAM EVALUATION:
	gen GLEF = (group == 1 & edusec == 0 & followup == 1)
	gen GHEF = (group == 1 & edusec == 1 & followup == 1)
	gen ILEF = (indiv == 1 & edusec == 0 & followup == 1)
	gen IHEF = (indiv == 1 & edusec == 1 & followup == 1)
	gen FLE  = (edusec == 0 & followup == 1)
	gen FHE  = (edusec == 1 & followup == 1)
	gen GEL = (group == 1 & edusec == 0)
	gen GEH = (group == 1 & edusec == 1)
	gen IEL = (indiv == 0 & edusec == 0)
	gen IEH = (indiv == 0 & edusec == 1)
	
	*-- GLOBALS FOR Double-Difference ANALYSIS (not presented in paper, left here for completeness):
	global SimpleSpecDD "followup group GF"
	global InterSpecDD "followup FLE FHE group GLEF GHEF"
	
	*-- Some data cleaning and creating of variables for the analysis:
		foreach x of varlist Delayed_30 Delayed_60 Delayed_90 Default { 
			replace `x'=0 if treatment==0
			replace `x'=0 if followup==0
			}
	egen delay_default=rowmax(Delayed_90 Default)
	rename Delayed_30 delayed_30
	egen age16=rowtotal(age16m age16f)

	*-- Aimag dummies
	ta aimag, gen(aimagd)


	*===== SIMPLE DIFFERENCE ====*
	foreach x of varlist $VariablesT2XacBank { 
		qui reg `x' group $Xvar aimagd* if indiv!=1 & followup==1, robust cl(soum)
					
		qui sum `x' if e(sample) & group == 0 & indiv == 0 & followup == 1
		local meanfollow = r(mean)
		qui sum `x' if e(sample) & followup == 1
		local numberhh = r(N)
		
		outreg2 group using "output\Results - simple diff (G&C only)\table_2_creditXacBank", cttop("`x'") nocons ///
		sortvar(group) noobs addstat(Number of households, `numberhh', Mean Control Follow, `meanfollow') dec(3) ///
		excel `table' 
		local table = "append"
		}

