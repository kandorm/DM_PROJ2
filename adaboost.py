import time
from sklearn.ensemble import AdaBoostClassifier
from sklearn.tree import DecisionTreeClassifier
from sklearn.metrics import precision_score
from sklearn.metrics import recall_score
from sklearn.metrics import f1_score

def adaboost(data_train, data_test, target_train, target_test):
    time1 = time.time()
    adaclf = AdaBoostClassifier(
        DecisionTreeClassifier(max_depth=5),
        n_estimators=10,
        learning_rate=1)
    print "begin fit"
    adaclf.fit(data_train, target_train)
    print "end fit"
    time2 = time.time()

    pred =  adaclf.predict(data_test)
    print "end pred"
    precision = precision_score(target_test, pred)
    recall = recall_score(target_test, pred)
    f1 = f1_score(target_test, pred)
    return [precision, recall, f1, time2-time1]

