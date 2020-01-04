#import everything you need
#for now, make a collection of functions that you can call by:
    #from methods import <name function>
import pandas as pd
import seaborn as sns
import matplotlib.pyplot as plt
import seaborn as sns
import math

# returns a data frame of the given file
#fileName: "f_Sections F,G,h - Ent.dta"
#filePath: "Analysis files/data/Followup/{0}"
def create_df(fileName, filePath):
    return pd.read_stata(filePath.format(fileName), convert_categoricals=False)

def remove_attrition(baseline, followup):
    followup[['rescode']].drop_duplicates()
    baseline["rescode"].drop_duplicates()
    
    updated_baseline = followup.merge(baseline, on="rescode", how="left") 

    print("Number of households at followup: ", len(followup['rescode']))
    print("Number of households at adjusted baseline: ", len(updated_baseline['rescode']))
    
    return updated_baseline

def percentages(dataframe, variable):
    #Finding increase in enterprise with control
    numBaseline = dataframe[variable].sum()
    numFollowUp = dataframe["f_" + variable].sum()
    totalNumHH = len(dataframe.index)

    percentageBaselineEnterpriseC = numBaseline/totalNumHH * 100
    percentageFollowUpEnterpriseC = numFollowUp/totalNumHH * 100
    print("Percentage of " + variable + " @ baseline: ", percentageBaselineEnterpriseC)
    print("Percentage of " + variable + " @ followup: ", percentageFollowUpEnterpriseC)

def conversionRate(positive, dataframe):
    if positive:
        #create a new dataframe with participants without enterprise at baseline
        withoutVarAtBaselineDF = dataframe[dataframe.soleent == 0]
        if len(withoutVarAtBaselineDF) == 0:
            return 0
        #identify number of these participants with enterprise at followup
        withVarAtFollowup = len(withoutVarAtBaselineDF[withoutVarAtBaselineDF.f_soleent > 0])
        #take ratio
        return withVarAtFollowup / len(withoutVarAtBaselineDF)
    else:
        #create a new dataframe with participants with enterprise at baseline
        withVarAtBaselineDF = dataframe[dataframe.soleent > 0]
        if len(withVarAtBaselineDF) == 0:
            return 0
        #identify number of these participants without enterprise at followup
        withoutVarAtFollowup = len(withVarAtBaselineDF[withVarAtBaselineDF.f_soleent == 0])
        #take ratio
        return withoutVarAtFollowup / len(withVarAtBaselineDF)

def nCr(n,r):
    f = math.factorial
    return f(n) / (f(r) * f(n-r))

def binRanVarPMF(n, p):
    def pmf(k):
        return nCr(n, k) * math.pow(p, k) * math.pow(1-p, n-k)
    return pmf

def mean(pmf, n):
    sum = 0
    for x in range(1, n+1):
        sum += x * pmf(x)
    return sum

def crTableAge(i, POSITIVE, treatment, ent_edu_conv, ageGroup):
    ap = len(ent_edu_conv[(ent_edu_conv['treatment_x'] == treatment)&(ent_edu_conv['age'] == i)])
    agebin = ent_edu_conv[(ent_edu_conv['age'] == i)].iloc[0]['agebin']
    if ap != 0:
        cr = conversionRate(POSITIVE, ent_edu_conv[(ent_edu_conv['treatment_x'] == treatment)&(ent_edu_conv['age'] == i)])
        if POSITIVE: #set baseline sample size to be number of people without soleent at baseline
            blSS = len(ent_edu_conv[(ent_edu_conv['treatment_x'] == treatment)&(ent_edu_conv['age'] == i)& \
                        (ent_edu_conv['soleent'] == 0)])
            pmf = binRanVarPMF(blSS, cr)
            ageGroup = ageGroup.append({'age': i, 'agebin': agebin, 'conv. rate': cr, 'mean' : mean(pmf, blSS), 'all people' : \
                        ap, 'people w/o BL soleent':blSS, 'fraction w/o BL soleent' : blSS/ap}, ignore_index=True)
        else: #set baseline sample size to be number of people with soleent at baseline
            blSS = len(ent_edu_conv[(ent_edu_conv['treatment_x'] == treatment)&(ent_edu_conv['age'] == i)& \
                        (ent_edu_conv['soleent'] == 1)])
            pmf = binRanVarPMF(blSS, cr)
            ageGroup = ageGroup.append({'age': i, 'agebin': agebin, 'conv. rate': cr, 'mean' : mean(pmf, blSS), 'all people' : \
                        ap, 'people w/ BL soleent':blSS, 'fraction w/ BL soleent' : blSS/ap}, ignore_index=True)
    else:
        ageGroup = ageGroup.append({'age': i, 'agebin': agebin, 'conv. rate': 0, 'mean' : 0, 'all people' : 0, \
                        'people w/o BL soleent': 0, 'fraction w/o BL soleent' : 0}, ignore_index=True)
    return ageGroup
    
    
def crTableEdu(i, POSITIVE, treatment, ent_edu_conv, eduGroup):
    ap = len(ent_edu_conv[(ent_edu_conv.treatment_x == treatment)&(ent_edu_conv.edu == i)])
    if ap != 0:
        cr = conversionRate(POSITIVE, ent_edu_conv[(ent_edu_conv.treatment_x == treatment)&(ent_edu_conv.edu == i)])
        if POSITIVE: #set baseline sample size to be number of people without soleent at baseline
            blSS = len(ent_edu_conv[(ent_edu_conv.treatment_x == treatment)&(ent_edu_conv.edu == i) & (ent_edu_conv.soleent ==\
                                                                                                       0)])
            pmf = binRanVarPMF(blSS, cr)
            eduGroup = eduGroup.append({'edu': i, 'conv. rate': cr, 'mean' : mean(pmf, blSS), 'all people' : \
                                        ap, 'people w/o BL soleent':blSS, 'fraction w/o BL soleent' : blSS/ap},ignore_index=True)
        else: #set baseline sample size to be number of people with soleent at baseline
            blSS = len(ent_edu_conv[(ent_edu_conv.treatment_x == treatment)&(ent_edu_conv.edu == i) & (ent_edu_conv.soleent ==\
                                                                                                       1)])
            pmf = binRanVarPMF(blSS, cr)
            eduGroup = eduGroup.append({'edu': i, 'conv. rate': cr, 'mean' : mean(pmf, blSS), 'all people' : \
                                        ap, 'people w/ BL soleent':blSS, 'fraction w/ BL soleent' : blSS/ap}, ignore_index=True)
    else:
        eduGroup = eduGroup.append({'edu': i, 'conv. rate': 0, 'mean' : 0, 'all people' : 0, 'people w/o BL soleent':\
                                    0, 'fraction w/o BL soleent' : 0}, ignore_index=True)
    return eduGroup

