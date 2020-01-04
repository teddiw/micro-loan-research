import csv

data = [[], [], [], [], [], [], [], [], [], []]

with open("baseline_ent.csv") as csvfile:
    readCSV = csv.reader(csvfile, delimiter=',')
    i = 0
    for row in readCSV:
        j = 0
        for el in row:
            if i != 0:
                data[j].append(int(el))
            #data[j].append(el)
            j = j + 1
        i = i + 1

def gbEntHH():
    s = 0
    for i in range(len(data[0])):
        if data[5][i] == 2 and data[7][i] > 0:
            s = s + 1
    return s


def cbEntHH():
    s = 0
    for i in range(len(data[0])):
        if data[5][i] == 0 and data[7][i] > 0:
            s = s + 1
    return s

#Useful functions below

def gbJointEntHH():
    s = 0
    for i in range(len(data[0])):
        if data[5][i] == 2 and data[8][i] > 0:
            s = s + 1
    return s

def cbJointEntHH():
    s = 0
    for i in range(len(data[0])):
        if data[5][i] == 0 and data[8][i] > 0:
            s = s + 1
    return s

def ibJointEntHH():
    s = 0
    for i in range(len(data[0])):
        if data[5][i] == 1 and data[8][i] > 0:
            s = s + 1
    return s

def controlHH():
    s = 0
    for i in range(len(data[0])):
        if data[5][i] == 0:
            s = s + 1
    return s

def groupHH():
    s = 0
    for i in range(len(data[0])):
        if data[5][i] == 2:
            s = s + 1
    return s

def indivHH():
    s = 0
    for i in range(len(data[0])):
        if data[5][i] == 1:
            s = s + 1
    return s
"""
print("Number of households in the control group:")
print(controlHH())
print("Number of households in the individual loan group:")
print(indivHH())
print("Number of households in the group loan group:")
print(groupHH())
"""
#percentage of HH with joint enterprise
"""
print("Percentage of control group w/ joint enterprises:")
print(cbJointEntHH()/controlHH() * 100)

print("Percentage of individual loan group w/ joint enterprises:")
print(ibJointEntHH()/indivHH() * 100)

print("Percentage of group-loan group w/ joint enterprises:")
print(gbJointEntHH()/groupHH() * 100)
"""
#big overview

print("Number of households in the control group:")
print(controlHH())
print("Number of control group households with joint enterprise:")
print(cbJointEntHH())
print(cbJointEntHH()/controlHH() * 100)

print("Number of households in the individual loan group:")
print(indivHH())
print("Number of individual loan group households with joint enterprise:")
print(ibJointEntHH())
print(ibJointEntHH()/indivHH() * 100)

print("Number of households in the group loan group:")
print(groupHH())
print("Number of group loan group households with joint enterprise:")
print(gbJointEntHH())
print(gbJointEntHH()/groupHH() * 100)
