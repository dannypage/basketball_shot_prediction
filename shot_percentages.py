from __future__ import division
import pandas as pd
import numpy as np
from sklearn.cross_validation import KFold
from sklearn.svm import SVC
from sklearn.ensemble import RandomForestClassifier as RF
from sklearn.neighbors import KNeighborsClassifier as KNN
from sklearn.preprocessing import StandardScaler

import glob, os
os.chdir("/Users/danielpage/Projects/basketball/data/2006-2007.regular_season")
allFiles = glob.glob("*.csv")
df = pd.DataFrame()
list_ = []
for file_ in allFiles:
    df = pd.read_csv(file_,index_col=None, header=0)
    list_.append(df)
frame = pd.concat(list_)

shot_list = ['shot']
shot_df = frame[frame['etype'].isin(shot_list)]
shot_df = shot_df[np.isfinite(shot_df['x'])]
shot_df = shot_df[np.isfinite(shot_df['y'])]

shot_result = shot_df['result']
y = np.where(shot_result == 'made',1,0)

to_drop = ['a1', 'a2', 'a3', 'a4', 'a5', 'h1', 'h2', 'h3', 'h4', 'h5', 'period',
    'time','num','outof','team','block','entered','left','opponent','possession',
    'steal','reason','assist','away','home','points','result', 'etype', 'player',
    'type']
shot_feat_space = shot_df.drop(to_drop,axis=1)

features = shot_feat_space.columns
X = shot_feat_space.as_matrix().astype(np.float)

scaler = StandardScaler()
X = scaler.fit_transform(X)

print "Feature space holds %d observations and %d features" % X.shape
print "Unique target labels:", np.unique(y)

def run_cv(X,y,clf_class,**kwargs):
    # Construct a kfolds object
    kf = KFold(len(y),n_folds=5,shuffle=True)
    y_pred = y.copy()

    # Iterate through folds
    for train_index, test_index in kf:
        X_train, X_test = X[train_index], X[test_index]
        y_train = y[train_index]
        # Initialize a classifier with key word arguments
        clf = clf_class(**kwargs)
        clf.fit(X_train,y_train)
        y_pred[test_index] = clf.predict(X_test)
    return y_pred

def accuracy(y_true,y_pred):
    # NumPy interprets True and False as 1. and 0.
    return np.mean(y_true == y_pred)

print "SVM: %.3f" % accuracy(y, run_cv(X,y,SVC))
print "Random forest: %.3f" % accuracy(y, run_cv(X,y,RF))
print "K-nearest-neighbors: %.3f" % accuracy(y, run_cv(X,y,KNN))
