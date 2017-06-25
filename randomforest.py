import time
from pandas import Series, read_csv
from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestClassifier
from sklearn.externals import joblib
from sklearn.metrics import precision_score
from sklearn.metrics import recall_score
from sklearn.metrics import f1_score
from scipy.sparse import csc_matrix

data_dataframe = read_csv('./precondition/c_dtm_dataframe.csv')
print "read data_dataframe success"
classify_dataframe = read_csv('./precondition/c_classify_dataframe.csv')
print "read classify_dataframe success"
target = list(Series([""]).append(classify_dataframe['classify']))
print "create classify success"
data = csc_matrix((data_dataframe['data'], (data_dataframe['row_ind'], data_dataframe['col_ind'])))
print "create data success"
#print target
data_train, data_test, target_train, target_test = train_test_split(data, target, test_size=0.1, random_state=1)

time1 = time.time()
rfclf = RandomForestClassifier(n_estimators=10)
print "begin fit"
rfclf.fit(data_train, target_train)
print "end fit"
time2 = time.time()
joblib.dump(rfclf, "randomforest_model.m")
print "create model success"

pred =  rfclf.predict(data_test)
print "end pred"
precision = precision_score(target_test, pred, average=None)
recall = recall_score(target_test, pred, average=None)
f1 = f1_score(target_test, pred, average=None)
print pred
print precision
print recall
print f1

output = open('randomforest_score.txt', 'w+')
output.write("precision:"+str(precision)+"\\n"+"recall:"+str(recall)+"\\n"+"f1:"+str(f1)+"\\n"+"time:"+str(time2-time1))
output.close()
