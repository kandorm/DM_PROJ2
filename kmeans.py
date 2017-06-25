from sklearn.cluster import KMeans
from sklearn.metrics import normalized_mutual_info_score
from sklearn.metrics import adjusted_mutual_info_score
from sklearn.decomposition import PCA
import time

def kmeans(data, target):
    time1 = time.time()
    print "begin fit"
    kmeans = KMeans(n_clusters=2, random_state=0).fit(data)
    print "end fit"
    time2 = time.time()
    pred = kmeans.labels_
    print "end pred"
    nmi = normalized_mutual_info_score(target, pred)
    ami = adjusted_mutual_info_score(target, pred)
    return [nmi, ami, time2-time1]