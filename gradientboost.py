import time
from sklearn.ensemble import GradientBoostingClassifier
from sklearn.metrics import precision_score
from sklearn.metrics import recall_score
from sklearn.metrics import f1_score

def gradientboost(data_train, data_test, target_train, target_test):
    time1 = time.time()
    bst = GradientBoostingClassifier(n_estimators=10, learning_rate=1.0,
        max_depth=5, random_state=0)
    print "begin fit"
    bst.fit(data_train, target_train)
    print "end fit"
    time2 = time.time()

    pred =  bst.predict(data_test.toarray())
    print "end pred"
    precision = precision_score(target_test, pred)
    recall = recall_score(target_test, pred)
    f1 = f1_score(target_test, pred)
    return [precision, recall, f1, time2-time1]

