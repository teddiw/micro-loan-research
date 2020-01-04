******************************************************************
------------------- AEJ APPLIED SPECIAL ISSUE: -------------------
******************************************************************


******************************************************************
TITLE:
++++++++ The Impacts of Microfinance: Evidence from Joint-Liability 
                       Lending in Mongolia

AUTHORS:
++++++++ Orazio Attanasio, Britta Augsburg, Ralph De Haas, Emla 
                    Fitzsimons, Heike Harmgart

******************************************************************


To re-run our analysis, please install a folder "Analysis files"
The structure of this folder is as follows:


----------
STRUCTURE:
----------

XXX\Analysis files\data		<------------------------subfolders: "Baseline", "Followup", "Soum", "XacBank admin debt data", and one stata data file "HHid and Rin"
		  \do-files	<------------------------subfolders: "Additional do-files" and a number of do-files
		  \Multiple hypothesis testing	<--------subfolders: "do-files", "Estimated full model" and an output data set
		  \output

The folder output needs to have subfolder in order for do-files to run:
XXX\Analysis files\output\Attrition
			 \Loan default
			 \Results - double diff (G&C only)
			 \Results - simple diff (G&C only)
			 \Results - Table 8 (I&C only)


------------------------
EXPLANATION OF DO-FILES:
------------------------


The do-files provided in the folders:
- "XXX\Analysis files\do-files", and 
- "Analysis files\Multiple hypothesis testing\do-files"
are described in what follows:



"Attanasio et al (2014)_Mongolia_Table 1 (Randomization).do"
------------------------------------------------------------
- This do-file is best executed quietly -- we just copy-pasetd 
  results into excel. Not beautiful but On the positive side, 
  no folder needs to therefore be created to run this file.
- To run the file all you need to do is change the path of the 
  working directory in line 22.  

- This do-file calls a data set that was created with the do-file
  "Additional do-files\Constructed Vars for baseline balancedness data set.do"



"Attanasio et al (2014)_Mongolia_Tables 2-7 (Impact Analysis).do"
----------------------------------------------------------------
- Estimates all impact results presented in Tables 2-7
- To run this do-file you need to change the path in line 23. 
  In the folder this path leads to, you need to have two sub-folder:
  (i) "data" (with all files we submitted), and
  (ii) "output" -- here is where the results will be stored. 
  This folder needs again two subfolders:
	(a) "Results - simple diff (G&C only)" and
	(b) "Results - double diff (G&C only)"



"Attanasio et al (2014)_Mongolia_Multiple testing_RW (bsample)_T2.do"
---------------------------------------------------------------------
- This do-files conducts the Romano Wolf procedure to adjust for 
  multiple hypothesis testing.
- It calls the do-file "(0) prepare data.do"
- We only provide the do-file for Table 2. Other Tables work arordingly
  (all that needs to be changed is the global Table in line 69 and
  then ideally also names of output files (lines 83, 84, 88, 97, 102, 111
  116, 124, 140, 141, 175-177)
- The file runs the first iteration (do-file is exited in line 220).
  In the case some variables are rejected ("pass") the second iteration needs 
  to be done by hand. This is done by dropping the centered tstats of variables
  that passed and re-defining the global Table with the remaining Variables.
  And then one runs the second iteration.
- To change the level of significance, one changes the "p(99)" in line 205.



"Attanasio et al (2014)_Mongolia_Table 9 (Loan Default).do"
------------------------------------------------------------
- This do-file estimates deterinants of loan dfault.
- To run the file the working directory path has to be adjusted in line 16
  And one needs a folder "output\Loan default" in the working directory.



"Attanasio et al (2014)_Mongolia_Table TA3 (Attrition).do"
------------------------------------------------------------
- This do-file estimates deterinants of attrition.
- To run the file the working directory path has to be adjusted in line 16
  And one needs a folder "output\Attrition" in the working directory.



The folder "\Analysis files\do-files\Additional do-files"
           ------------------------------------------------
creates the data sets in the folder "Analysis files\data\Constructed"










