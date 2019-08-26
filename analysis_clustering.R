# this file performs clustering analysis on project data
# objective: explore different types of publications in 2018 using document clustering
# methods: k-means and hierarchical agglomerative clustering
# data: term document matrix of 2018 news articles

rm(list = ls())
######################################### 
# load libraries
######################################### 
library(magrittr)
library(caret)
library(ggplot2)
library(reshape2)
library(knitr)
library(cluster)
library(mclust)
library(network)
library(igraph)
library(proxy)
library(factoextra)
library(wordcloud)
library(slam)
library(clue)
library(Matrix)
######################################### 
# load data
######################################### 
load('data/2transform.rda')
# just keep the document term matrix
rm(df, trans)

######################################### 
# word cloud of dtm
######################################### 
# word frequencies
vecWords <- colSums(as.matrix(dtm))

# word cloud without stop words
wordcloud(
  words = names(vecWords),
  freq = vecWords,
  scale=c(3,0.5), 
  max.words=150, 
  random.order=FALSE, 
  rot.per=0.35, 
  colors=brewer.pal(8, 'Dark2')
)
# the most common word is 'said' followed by 'trump'.

######################################### 
# distribution of term utilization
######################################### 
dfTermFreq <- data.frame(term = names(vecWords), freq = vecWords)
# Density and Distribution of term frequencies
ggplot(dfTermFreq, aes(x = factor(0), y = freq)) +
  geom_violin() + geom_boxplot(width = 0.4) +
  theme_bw() +
  xlab("Counts") + ggtitle("Distribution of Term Utilization")
# distribution shows a high right-skew meaning that a small subset of terms occur very frequently.

quantile(vecWords) %>% 
  kable(., col.names = 'Term Frequencies',
        caption = 'Quartiles of Term Frequencies')
# 50% of the terms occurred less than 5977 times
# the minimum number of times a term occurred is 2002
# the maximum number of times a term occurred is 789001
######################################### 
# bar plot of most frequent words
######################################### 
head(dfTermFreq[order(dfTermFreq$freq, decreasing = TRUE),],20) %>%
  ggplot(., aes(x = reorder(term, freq), y = freq)) + geom_col() + coord_flip() +
  xlab("Terms") + ggtitle("Top 20 Most Utilized Terms")

######################################### 
# distribution of terms by Publication
######################################### 
# number of terms by document
vecDocs <- rowSums(as.matrix(dtm))
dfDocFreq <- data.frame(doc = names(vecDocs), terms = vecDocs)

# Density and Distribution of document word frequencies
ggplot(dfDocFreq, aes(x = factor(0), y = terms)) +
  geom_violin() + geom_boxplot(width = 0.4) +
  theme_bw() +
  xlab("Counts") + ggtitle("Distribution of Terms by Publication")
# distribution shows a high right-skew meaning that a small subset of documents have a large number of terms

quantile(vecDocs) %>% 
  kable(., col.names = 'Term Counts',
        caption = 'Quartiles of Document Term Counts')
# 50% of the documents had less than 333 terms
# the minimum number of terms a document had is 0
# the maximum number of terms a document had is 22050
# examining the lower percentiles
quantile(vecDocs, probs = seq(0, .1, .01)) %>%
  kable(., col.names = 'Term Counts',
        caption = '0-10th Percentile of Term Counts')
# Action: remove the documents with 0 terms; this will raise minimum term count to 6
dtm <- dtm[vecDocs != 0, ]

######################################### 
# normalize the document term matrix using tf-idf
######################################### 
m <- as.matrix(dtm)
tf <- m
idf <- log(nrow(m)/colSums(m))
tfidf <- m

for(i in names(idf)){
  tfidf[,i] <- tf[,i] * idf[i]
}

mNorm <- tfidf
rm(tf, idf, tfidf)