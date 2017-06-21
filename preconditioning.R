#Build data.frame of xml files
#param:
#    path: targe files' directory absolute address
build_dataframe <- function(path) {
  library(XML)
  
  #convert vector to string, every item separate with '/'
  #param:
  #    v : vector used for converting
  #using for multi-classify saving
  vector2string <- function(v) {
    result = character(0)
    for(item in v) {
      if(length(result) == 0)
        result = as.character(item)
      else
        result = paste(result, as.character(item), sep = "/")
    }
    return(result)
  }
  
  #if string(vector) is empty, return NA, or return original value
  #param:
  #    v : string or vector for chack and convert
  #using for filling empty in data.frame with NA
  empty2NA <- function(v) {
    if(length(v) == 0)
      return(NA)
    else
      return(v)
  }
  
  #Take content like 'Top/News/U.S./' or 'Top/Features/Travel/'
  #param:
  #    s : string for substring
  #    g : integer. The first element to be replaced
  #using for function getclassify
  getcontent <- function(s,g) {
    result = substring(s,g,g+attr(g,'match.length')-1)
    return(result)
  }
  
  #Take all valid classify in text list
  #param:
  #    list : the texts which may have classify
  #    pat : regex for get valid text
  #    begin : first word position of classify in text
  #return all classify in list which has been unique
  getclassify <- function(list, pat, begin) {
    result = character(0)
    if(length(list) == 0)
      return(result)
    gregout = gregexpr(pat, list)  #first word position list which meet the regex
    for(i in 1:length(list)) {
      content = getcontent(list[i], gregout[[i]])
      if(nchar(content) != 0) {
        classify = substring(content,begin, nchar(content))
        classify = gsub("/", "", classify)
        result = append(result, classify)
      }
    }
    result = unique(result)
    return(result)
  }
  
  #return value
  data_frame = data.frame()
  
  c_path = getwd()
  setwd(path)
  flist = list.files()
  #i = 0
  for(f in flist) {
    doc = xmlParse(f)
    #i = i + 1
    #if(i %% 1000 == 0)
    #  print.default(i)
    full_text = as.character(xpathSApply(doc, "//block[@class='full_text']", xmlValue))
    publication_year = as.character(xpathSApply(doc, path = "//meta[@name='publication_year']", xmlGetAttr, "content"))
    publication_month = as.character(xpathSApply(doc, path = "//meta[@name='publication_month']", xmlGetAttr, "content"))
    publication_day_of_month = as.character(xpathSApply(doc, path = "//meta[@name='publication_day_of_month']", xmlGetAttr, "content"))
    
    
    classify_vector = character(0)
    c_list = xpathSApply(doc, "//classifier", xmlValue)
    pat = "Top/Features/(.*?)(/|$)"
    classify_vector = c(classify_vector, getclassify(c_list, pat, 14))
    pat = "Top/News/(.*?)(/|$)"
    classify_vector = c(classify_vector, getclassify(c_list, pat, 9))
    classify_vector = unique(classify_vector)
    classify = vector2string(classify_vector)
    
    news <- data.frame(
      File = f,
      Year = empty2NA(publication_year), 
      Month = empty2NA(publication_month), 
      Day = empty2NA(publication_day_of_month), 
      Classify = empty2NA(classify),
      Text = empty2NA(full_text))
    
    data_frame = rbind.data.frame(data_frame, news)
  }
  
  setwd(c_path)
  return(data_frame)
}

#Build corpus with clean full text
#param:
#    full_text : full_text vector
#return corpus used for tdm
text_pre <- function(full_text) {
  library(NLP)
  library(tm)
  reuters = Corpus(VectorSource(full_text))
  reuters = tm_map(reuters, tolower)
  reuters = tm_map(reuters, removePunctuation)
  reuters = tm_map(reuters, removeWords, stopwords("english"))
  reuters = tm_map(reuters, removeNumbers)
  reuters = tm_map(reuters, stripWhitespace)
  reuters = tm_map(reuters, stemDocument)
  return(reuters)
}

#Create directory in this workspace named dname and output reuters into it,
#if there is file or directory has the same name, if will not work
#param:
#    dname : directory name
#    reuters : reuters
#no return
reuters_output <- function(dname, reuters) {
  library(NLP)
  library(tm)
  if(!file.exists(dname)) {
    dir.create(dname)
    c_path = getwd()
    setwd(paste(c_path, dname, sep = "/"))
    writeCorpus(reuters)
    setwd(c_path) 
  }
}

#build bag of words with reuters
#param:
#    reuters : reuters
#return a matrix of bag of words
build_BOW <- function(reuters) {
  tdm = TermDocumentMatrix(reuters)
  matrix = as.matrix(tdm)
  return(matrix)
  
}

#Take words which freq over 100
#param:
#    m : tdm matrix
#return a dataframe with word and freq
words_filter <- function(m) {
  word_freqs = sort(rowSums(m), decreasing=TRUE)
  dm = data.frame(word = names(word_freqs), freq = word_freqs)
  result = subset(dm, freq > 100)
  return(result)
}

#paint wordcloud
#param:
#    m : tdm matrix
#no return and paint a png image in path getwd()
paint_wordcloud <- function(m) {
  library(RColorBrewer)
  library(wordcloud)
  
  word_freqs = sort(rowSums(m), decreasing=TRUE)
  dm = data.frame(word = names(word_freqs[1:100]), freq = word_freqs[1:100])
  png(file="wordcloud.png", bg="white",width = 480, height = 480)
  wordcloud(dm$word, dm$freq, random.order = FALSE, colors = brewer.pal(8, "Dark2"))
  dev.off()  
}

#paint wordlength_histogram
#param:
#    m : tdm matrix
#no return and paint a png image in path getwd()
paint_wordlength_histogram <- function(m) {
  library(ggplot2)
  dictionary = row.names(m)
  wordlength = nchar(dictionary)
  png(file="wordlength_histogram.png", bg="white",width = 980, height = 480)
  barplot(table(unlist(wordlength)), col = "lightblue")
  dev.off()
}

#paint classify_histogram
#param:
#    classify : classify vector
#no return and paint a png image in path getwd()
paint_classify_histogram <- function(classify) {
  library(ggplot2)
  png(file="classify_histogram.png", bg="white",width = 480, height = 3000)
  barplot(table(unlist(classify)), col = "lightblue", horiz = TRUE)
  dev.off()
}

#paint month_histogram
#param:
#    month : month vector
#no return and paint a png image in path getwd()
paint_month_histogram <- function(month) {
  library(ggplot2)
  png(file="month_histogram.png", bg="white",width = 480, height = 480)
  barplot(table(unlist(month)), col = "lightblue")
  dev.off()
}

build_cosine <- function(m) {
  result = matrix(NA, nrow = ncol(m), ncol = ncol(m))
  for(i in 1:ncol(m)) {
    for(j in i:ncol(m)) {
      cosine = sum(m[,i]*m[,j])/sqrt(sum(m[,i]^2)*sum(m[,j]^2))
      if(is.nan(cosine)){
        cosine = 0
      }
      result[i,j] = cosine
    }
    print(paste("cosine count num ", i))
  }
  return(result)
}

inclass_similarity <- function(cosine, class_list) {
  result <- list()
  for(class in names(class_list)){
    #    print(class)
    result[[class]]=0
    for(i in 3:length(class_list[[class]])){
      for(j in 2:(i-1)){
        x=class_list[[class]][[i]]
        y=class_list[[class]][[j]]
        if(x>y){
          z=x
          x=y
          y=z
        }
        result[[class]]=result[[class]] + cosine[x,y]
      }
    }
    #    print(result[[class]])
  }
  for( class_item in names(result) ) {
    result[[class_item]]=result[[class_item]]/length(class_list[[class_item]])
  }
  return(result)
}

pro_class_list <- function(classify) {
  result<- list()
  class_list <- list()
  class_table <- table(unlist(classify))
  item_num=0
  for(item in classify) {
    item_num=item_num+1
    if(is.na(item))
      next
    for( class in item ){
      if(is.null(result[class][[1]])) {
        result[class]=0
        class_list[[class]] = vector('list', class_table[[class]]+1)
        class_list[[class]][[1]]=1
      }
      class_list[[class]][[1]]=class_list[[class]][[1]]+1
      class_list[[class]][[ class_list[[class]][[1]] ]]=item_num
    }
  }
  return(class_list)
}

cal_ave_sim <- function (class1, class2, class_list,cosine){
  result = 0
  len1 = length(class_list[[class1]])
  len2 = length(class_list[[class2]])
  for(i in 2:len1) {
    ar1 = class_list[[class1]][[i]]
    for(j in 2:len2 ){
      ar2 = class_list[[class2]][[j]]
      if(ar1>ar2){
        t=ar1
        ar1=ar2
        ar2=t
      }
      result=result + cosine[ar1,ar2]
    }
  }
  result = result / ((len1-1)*(len2-1))
  return(result)
}


current_path = getwd()
target_path = paste(current_path, "samples_50000", sep = '/')

#dataframe = build_dataframe(target_path)
#write.csv(dataframe, file = "dataframe.csv")

dataframe = read.csv(file = "dataframe.csv", sep = ",", header = TRUE)
#print("News dataframe make success! Please check file 'dataframe.csv'!")

reuters = text_pre(dataframe[["Text"]])
#reuters_output('Pre', reuters)
#print("Data clean success! Please check directory 'Pre/'")

dtm_ctrl = list(weighting = weightTfIdf)
dtm = DocumentTermMatrix(reuters, dtm_ctrl)
#m = build_BOW(reuters)
#print("BOW make success! Please check variable 'm'!")

#wordover100 = words_filter(m)
#write.csv(wordover100, file="wordfilter.csv")
#print("Words which length over 100 search success! Please check file 'wordfilter.csv'!")

#paint_wordcloud(m)
#print("Wordcloud make success! Please check file 'wordcloud.png'!")

#paint_wordlength_histogram(m)
#print("WordLength histogram make success! Please check file 'wordlength_histogram.png'!")

dataframe$Classify <- sapply(as.vector(dataframe$Classify), strsplit, split="/")
#paint_classify_histogram(dataframe[["Classify"]])
#print("Classify histogram make success! Please check file 'classify_histogram.png'!")

#paint_month_histogram(dataframe[["Month"]])
#print("Month histogram make success! Please check file 'classify_histogram.png'!")

#cosine_matrix = build_cosine(m)
#print("Cosine matrix make success! Please check variable 'cosine_matrix'!")
# question 2.2
#class_list = pro_class_list(dataframe[['Classify']])
#inclass_sim= inclass_similarity(cosine_matrix, class_list)
#print("inclass_sim make success! Please check variable 'inclass_sim'!")
# question 2.3
# ca1='Travel'
# ca2='World'
# cal_ave_sim(ca1,ca2,class_list,cosine_matrix)
