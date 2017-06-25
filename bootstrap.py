import time
from sklearn.ensemble import BaggingClassifier
from sklearn.tree import DecisionTreeClassifier
from sklearn.metrics import precision_score
from sklearn.metrics import recall_score
from sklearn.metrics import f1_score

def bootstrap(data_train, data_test, target_train, target_test):
    time1 = time.time()
    bsclf = BaggingClassifier(
        DecisionTreeClassifier(max_depth=5),
        n_estimators=10)
    print "begin fit"
    bsclf.fit(data_train, target_train)
    print "end fit"
    time2 = time.time()

    pred =  bsclf.predict(data_test)
    print "end pred"
    precision = precision_score(target_test, pred)
    recall = recall_score(target_test, pred)
    f1 = f1_score(target_test, pred)
    return [precision, recall, f1, time2-time1]
