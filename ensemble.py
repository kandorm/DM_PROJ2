from textpre import cmpt_tf_idf
from pandas import read_csv
from adaboost import adaboost
from bootstrap import bootstrap
from randomforest import randomforest
from gradientboost import gradientboost

from sklearn.model_selection import train_test_split

def write_result(path, classify, result):
    output = open(path, 'w+')
    output.write(classify+"\n" + "precision:" + str(result[0]) + "\n" + "recall:" + str(
        result[1]) + "\n" + "f1:" + str(result[2]) + "\n" + "time:" + str(result[3]))
    output.close()

classify_list = ['Arts', 'Books', 'Business', 'Corrections', 'Crossword and Games',
                 'Dining and Wine', 'Editors\' Notes', 'Education', 'Front Page', 'Health',
                 'Home and Garden', 'Magazine', 'Movies', 'New York and Region', 'Obituaries',
                 'Science', 'Sports', 'Style', 'Technology', 'Theater',
                 'Travel', 'U.S.', 'Washington', 'Week in Review', 'World']

data = cmpt_tf_idf('./precondition/clean_dataframe.csv')
target = read_csv('./precondition/clean_target.csv')['Arts']

data_train, data_test, target_train, target_test = train_test_split(data,
                                                    target,
                                                    test_size=0.1,
                                                    random_state=0)

result = adaboost(data_train, data_test, target_train, target_test)
write_result('./result/adaboost_score.txt', 'Arts', result)
result = bootstrap(data_train, data_test, target_train, target_test)
write_result('./result/bootstrap_score.txt', 'Arts', result)
result = randomforest(data_train, data_test, target_train, target_test)
write_result('./result/randomforest_score.txt', 'Arts', result)
result = gradientboost(data_train, data_test, target_train, target_test)
write_result('./result/gradientboost_score.txt', 'Arts', result)