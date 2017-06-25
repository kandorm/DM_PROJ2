from nltk.corpus import stopwords
from nltk.tokenize import word_tokenize
from nltk.stem.lancaster import LancasterStemmer
from pandas import read_csv, DataFrame
from sklearn.feature_extraction.text import TfidfTransformer
from sklearn.feature_extraction.text import CountVectorizer
import string
import re
import numpy


def remove_nword(text):
    for item in string.punctuation:
        text = text.replace(item, " ")
    return re.sub('([\d]+)', '', text).lower()

df = read_csv('./precondition/dataframe.csv')
News = [remove_nword(text) for text in list(df['Text']) if not isinstance(text, float)]
print News[0]

texts_tokenized = [[word for word in word_tokenize(text.decode('utf-8'))] for text in News]
print texts_tokenized[0]

st = LancasterStemmer()
texts_stemmed = [[st.stem(word) for word in text] for text in texts_tokenized]
print texts_stemmed[0]

english_stopwords = stopwords.words('english')
texts = [[word for word in text if not word in english_stopwords] for text in texts_stemmed]
print texts[0]

vectorizer = CountVectorizer()
transformer = TfidfTransformer()
tfidf=transformer.fit_transform(vectorizer.fit_transform(texts))
print tfidf
numpy.save('tfidf.npy', tfidf)

save = DataFrame(tfidf)
save.to_csv('tfidf.csv', tfidf)