from nltk.corpus import stopwords
from nltk.tokenize import word_tokenize
from nltk.stem.lancaster import LancasterStemmer
from pandas import read_csv
from sklearn.feature_extraction.text import TfidfTransformer
from sklearn.feature_extraction.text import CountVectorizer
import string
import re

def cmpt_tf_idf(path):
    def remove_nword(text):
        for item in string.punctuation:
            text = text.replace(item, " ")
        return re.sub('([\d]+)', '', text).lower()

    df = read_csv(path)
    News = [remove_nword(text) for text in list(df['Text']) if not isinstance(text, float)]
    print News[0]

    texts_tokenized = [[word for word in word_tokenize(text.decode('utf-8'))] for text in News]
    print texts_tokenized[0]

    st = LancasterStemmer()
    texts_stemmed = [[st.stem(word) for word in text] for text in texts_tokenized]
    print texts_stemmed[0]

    english_stopwords = stopwords.words('english')
    texts_stopwords_filter = [[word for word in text if not word in english_stopwords] for text in texts_stemmed]
    print texts_stopwords_filter[0]

    texts = [" ".join(text) for text in texts_stopwords_filter]

    vectorizer = CountVectorizer()
    transformer = TfidfTransformer()
    tfidf=transformer.fit_transform(vectorizer.fit_transform(texts))
    return tfidf