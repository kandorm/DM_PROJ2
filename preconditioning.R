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

dataframe_deploy <- function(dataframe, colname) {
  data_frame = data.frame()
  for(i in 1:nrow(dataframe)) {
#    if(i%%1000 == 0)
#      print(i)
    news <- dataframe[i,]
    if(length(dataframe[[colname]][[i]]) > 1) {
      for(class in dataframe[[colname]][[i]]) {
        news$Classify = class
        data_frame = rbind.data.frame(data_frame, news)
      }
    } else {
      data_frame = rbind.data.frame(data_frame, news)
    }
  }
  return(data_frame)
}

create_label <- function(classify, class_list) {
  label <- matrix(nrow = length(classify), ncol = length(class_list))
  colnames(label) <- class_list
  for(i in 1:length(classify)) {
    for(j in 1:length(class_list)) {
      label[i, j] <- ifelse(is.element(class_list[j], classify[[i]]), 1, 0)
    }
  }
  return(label)
}

current_path = getwd()
target_path = paste(current_path, "samples_50000", sep = '/')

library(NLP)
library(tm)

#take info of news and write into 'dataframe.csv'(no precondition)
dataframe = build_dataframe(target_path)
write.csv(dataframe, file = "./precondition/dataframe.csv")
dataframe$Classify <- sapply(as.vector(dataframe$Classify), strsplit, split="/")

#compute DTM of News with full_text and removeSparseTerms with sparse=0.98
#write DTM into 'dtm_dataframe.csv'
#dataframe = read.table(file = "dataframe.csv", sep = ",", header = TRUE)
#dataframe$X = NULL
#dataframe$Classify <- sapply(as.vector(dataframe$Classify), strsplit, split="/")
data = dataframe
data = data[complete.cases(data[, 'Text']), ]
reuters = text_pre(data[["Text"]])
dtm_ctrl = list(removePunctuation = TRUE, weighting = weightTfIdf)
dtm = DocumentTermMatrix(reuters, dtm_ctrl)
dtm_dataframe = as.data.frame(as.matrix(removeSparseTerms(dtm, 0.98)))
write.csv(dtm_dataframe, file = "./precondition/dtm_dataframe.csv")

class_list = dimnames(table(unlist(dataframe$Classify)))[[1]]
label = create_label(data$Classify, class_list)
write.csv(as.data.frame(label), file = "./precondition/label.csv")

#dataframe = read.table(file = "dataframe.csv", sep = ",", header = TRUE)
#dataframe$X = NULL
#dataframe$Classify <- sapply(as.vector(dataframe$Classify), strsplit, split="/")
c_dataframe = dataframe
c_dataframe = dataframe_deploy(dataframe, "Classify")
rownames(c_dataframe) = c(1:nrow(c_dataframe))
c_dataframe$Classify = unlist(c_dataframe$Classify)
write.csv(c_dataframe, file = "./precondition/c_dataframe.csv")

#c_dataframe = read.table(file = "./precondition/c_dataframe.csv", sep = ",", header = TRUE)
#c_dataframe$X = NULL
c_data = c_dataframe
c_data = c_data[complete.cases(c_data[, 'Classify']), ]
c_data = c_data[complete.cases(c_data[, 'Text']), ]
c_reuters = text_pre(c_data[["Text"]])
c_dtm_ctrl = list(removePunctuation = TRUE, weighting = weightTfIdf)
c_dtm = DocumentTermMatrix(c_reuters, c_dtm_ctrl)
c_dtm_dataframe = data.frame(row_ind=c_dtm$i, col_ind=c_dtm$j, data=c_dtm$v)
write.csv(c_dtm_dataframe, file = "./precondition/c_dtm_dataframe.csv")

c_classify_dataframe = data.frame(classify = c_data$Classify)
write.csv(c_classify_dataframe, file = "./precondition/c_classify_dataframe.csv")
