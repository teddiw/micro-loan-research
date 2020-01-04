import csv
class readCSV

    def __init__(self, fileName):
        self.file = fileName

    def toList(self):
        data = [[], [], [], [], [], [], [], [], [], []]
        with open(fileName) as csvfile:
            readCSV = csv.reader(csvfile, delimiter=',')
            i = 0
            for row in readCSV:
                j = 0
                for el in row:
                    data[j][i] = el
                    j = j + 1
                i = i + 1
        return data
