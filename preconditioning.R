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

dataframe = build_dataframe(target_path)
write.csv(dataframe, file = "./precondition/dataframe.csv")

#dataframe = read.table(file = "./precondition/dataframe.csv", sep = ",", header = TRUE)
#dataframe$X = NULL
c_data = dataframe
c_data = c_data[complete.cases(c_data[, 'Classify']), ]
c_data = c_data[complete.cases(c_data[, 'Text']), ]
write.csv(c_data, file = "./precondition/clean_dataframe.csv")

c_data$Classify <- sapply(as.vector(c_data$Classify), strsplit, split="/")
class_list = dimnames(table(unlist(c_data$Classify)))[[1]]
label = create_label(c_data$Classify, class_list)
write.csv(as.data.frame(label), file = "./precondition/clean_target.csv")