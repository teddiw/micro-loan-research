

	drop if reint==0	// keep 

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
	* Double-Difference:
	global SimpleSpecDD "followup group GF"
	global InterSpecDD "followup FLE FHE group GLEF GHEF"
	* merge in additional data:
	merge 1:1 rescode followup using "data\Followup\Income.dta"	// merge in food_income just using food received as gift
	drop if _merge != 3
	drop _m
	merge 1:1 rescode followup using "data\Followup\Enterprises.dta", keepusing(nrents )	//r_started_bus_since_bas
	drop if _merge != 3
	drop _m
	merge m:1 rescode using "data\Baseline\Baseline outcomes.dta"
	drop if _m==2
	drop _m
	* aimag dummies
	ta aimag, gen(aimagd)
	
	gen age16=age16m + age16f
* 	Table 2 -- Credit (Survey data)
	merge 1:1 rescode followup using "data\Followup\Debt.dta"
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
	
	local table = "replace"

	global VariablesT2PA "dum_loan_x dum_loan_formalnonX dum_loan_nonbank dum_any_loan dum_default dum_late_installment"	//dum_loan_bank dum_loan_informal dum_default_late
		// Panel A further includes regressions with XacBank and not survey data -> these regressions are done at the end of this file (as XacBank admin data set is used)
	global VariablesT2PB "tot_amount_x tot_amount_formal_nonX tot_amount_nonbank tot_amount_loans"	// tot_amount_other_banks

* 	Table 3 -- Self-employment activities, revenues, assets and profits
	 foreach outcome in assets_all profit profit_r  {
		gen scaled_`outcome' = `outcome' / 1000
		}
	local table = "replace"

	global VariablesT3 "scaled_assets_all BAI enterprise nrents scaled_profit soleent scaled_profit_r r_started_bus_since_bas "
	* business asset index: tools and machinery, unsold stock, lorry or tractor, riding equipment
		factor tools1 unsold1 vehicle redieqi1, pcf // Principal Component Factor analysis
		*rotate
		predict BAI 
	
* 	Table 4 -- Income
	merge 1:1 rescode followup using "data\Followup\HH benefits (followup only).dta"
	drop _m
	merge 1:1 rescode followup using "data\Followup\outcome_income_BL_FY.dta"
	drop _m

	foreach v in hhwageinc valuerec_y food_inc benefitvalHH f_benefitvalHH {
		gen scaled_`v' = `v' / 1000 
	}
	
	egen temp=rowtotal(scaled_food_inc scaled_profit)
	global VariablesT4 "scaled_profit scaled_hhwageinc scaled_benefitvalHH scaled_food_inc hhwageinc_earn_scaled benefit01 benefitHHmem temp"

* 	Table 5 -- Time worked by household members
	merge 1:1 rescode followup using "data\Followup\Labour Supply.dta"
	drop if reint == 0
	drop if _merge != 3	
	drop _m
	global VariablesT5 "hours hours_own hours_other hours_wage hours_teen hours_own_teen hours_other_teen hours_wage_teen hours_prime hours_own_prime hours_other_prime hours_wage_prime"

* 	Table 6 -- Consumption
	gen totalpc	= totalc/hhsize
	lab var totalpc "total per capital cons - last month"
	gen tempt = recreat_cm + cigaret8 + alcohol_cm /*temptation + entertainment, last month */
	lab var tempt "recreation, cig, alcohol - last month"		
	gen school = schoo12/12
	lab var school "educ expenses - last month"
	replace durc=durc/12 // this was multiplied by 12 in the initial do-file which is wrong!!!
	merge 1:1 rescode followup using "data\Followup\Savings.dta", nogen
	* home durable good index: 
		*foreach x of varlist cladul12 clchil12 schoo12 furnit12 happli12 textil12 books12 vehicl12 repair12 {
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

	global VariablesT6 "ln_totalpc ln_durc ln_nondurc ln_foodc scaled_school scaled_tempt scaled_totalsav_hh HDGI"

* 	Table 7 -- Social Effects
	merge 1:1 rescode followup using "data\Followup\Labour Supply.dta"	// merge in food_income just using food received as gift
	drop if _merge != 3
	drop _merge
	merge 1:1 rescode followup using "data\Followup\share_in_school.dta"	
	drop if _merge != 3
	drop _merge
	
	foreach outcome in valuegave_y  {
		recode `outcome' . = 0
		gen scaled_`outcome' = `outcome' / 1000
		}
	recode scaled_valuerec_y .=0
	egen hours_child_tot=rowtotal(hours_own_child hours_other_child hours_wage_child)

