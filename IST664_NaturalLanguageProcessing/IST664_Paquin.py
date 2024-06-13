'''
  This program shell reads email data for the spam classification problem.
  The input to the program is the path to the Email directory "corpus" and a limit number.
  The program reads the first limit number of ham emails and the first limit number of spam.
  It creates an "emaildocs" variable with a list of emails consisting of a pair
    with the list of tokenized words from the email and the label either spam or ham.
  It prints a few example emails.
  Your task is to generate features sets and train and test a classifier.

  Usage:  python classifySPAM.py  <corpus directory path> <limit number>
'''
# open python and nltk packages needed for processing
import os
import sys
import random
import nltk
from nltk.corpus import stopwords
from nltk import FreqDist
from nltk.collocations import *
import string

# define a feature definition function here
def doc_features(emaildoc, word_features):
    doc_words = set(emaildoc)
    features = {}
    for word in word_features:
        features['V_%s' % word] = (word in doc_words)
    return features

# feature definition for freq dist
def dist_features(emaildoc, word_features):
    doc_words = FreqDist(emaildoc)
    features = {}
    for word in word_features:
        features['V_%s' % word] = doc_words[word]
    return features


# Function to compute precision, recall and F1 for each label
def eval_measures(gold, predicted):
    # get a list of labels
    labels = list(set(gold))
    # these lists have values for each label 
    recall_list = []
    precision_list = []
    F1_list = []
    for lab in labels:
        # for each label, compare gold and predicted lists and compute values
        TP = FP = FN = TN = 0
        for i, val in enumerate(gold):
            if val == lab and predicted[i] == lab:  TP += 1
            if val == lab and predicted[i] != lab:  FN += 1
            if val != lab and predicted[i] == lab:  FP += 1
            if val != lab and predicted[i] != lab:  TN += 1
        # use these to compute recall, precision, F1
        recall = TP / (TP + FP)
        precision = TP / (TP + FN)
        recall_list.append(recall)
        precision_list.append(precision)
        F1_list.append( 2 * (recall * precision) / (recall + precision))
    # the evaluation measures in a table with one row per label
    print('\tPrecision\tRecall\t\tF1')
    # print measures for each label
    for i, lab in enumerate(labels):
        print(lab, '\t', "{:10.3f}".format(precision_list[i]), \
          "{:10.3f}".format(recall_list[i]), "{:10.3f}".format(F1_list[i]))

# Function for checking cross validation     
def cross_validation_accuracy(num_folds, featuresets):
    subset_size = int(len(featuresets)/num_folds)
    print('Each fold size:', subset_size)
    accuracy_list = []
    # iterate over the folds
    for i in range(num_folds):
        test_this_round = featuresets[(i*subset_size):][:subset_size]
        train_this_round = featuresets[:(i*subset_size)] + featuresets[((i+1)*subset_size):]
        # train using train_this_round
        classifier = nltk.NaiveBayesClassifier.train(train_this_round)
        # evaluate against test_this_round and save accuracy
        accuracy_this_round = nltk.classify.accuracy(classifier, test_this_round)
        print (i, accuracy_this_round)
        accuracy_list.append(accuracy_this_round)
    # find mean accuracy over all rounds
    print ('mean accuracy', sum(accuracy_list) / num_folds)

# This function is for part 3, it takes tokens and returns the ratio of words to punctuation  
def word_to_punct(tokens):
    # Remove punctuation tokens from the list
    tokens_without_punctuation = [token for token in tokens if token not in string.punctuation]
    # Calculate the number of words
    words = [token for token in tokens_without_punctuation if token.isalpha()]
    # Calculate the number of punctuation marks
    punctuation = [token for token in tokens if token in string.punctuation]
    # Avoid division by zero
    if len(punctuation) == 0:
        return float('inf')  # Return infinity for cases where there are no punctuation marks
    # Calculate the ratio of words to punctuation
    ratio = len(words) / len(punctuation)
    return ratio
# Feature defining for ratio of words to punctuation
def ratio_features(emaildoc):
    ratio = word_to_punct(emaildoc)
    features = {'word_to_punctuation_ratio': ratio}
    return features

# Feature defining for bigrams
def bigram_document_features(document, word_features, bigram_features):
    document_words = set(document)
    document_bigrams = nltk.bigrams(document)
    features = {}
    for word in word_features:
        features['V_{}'.format(word)] = (word in document_words)
    for bigram in bigram_features:
        features['B_{}_{}'.format(bigram[0], bigram[1])] = (bigram in document_bigrams)    
    return features

# Feature defining for POS tags
def POS_features(document, word_features):
    document_words = set(document)
    tagged_words = nltk.pos_tag(document)
    features = {}
    for word in word_features:
        features['contains({})'.format(word)] = (word in document_words)
    numNoun = 0
    numVerb = 0
    numAdj = 0
    numAdverb = 0
    for (word, tag) in tagged_words:
        if tag.startswith('N'): numNoun += 1
        if tag.startswith('V'): numVerb += 1
        if tag.startswith('J'): numAdj += 1
        if tag.startswith('R'): numAdverb += 1
    features['nouns'] = numNoun
    features['verbs'] = numVerb
    features['adjectives'] = numAdj
    features['adverbs'] = numAdverb
    return features

# function to read spam and ham files, train and test a classifier 
def processspamham(dirPath,limitStr):
  # convert the limit argument from a string to an int
  limit = int(limitStr)
  
  # start lists for spam and ham email texts
  hamtexts = []
  spamtexts = []
  os.chdir(dirPath)
  # process all files in directory that end in .txt up to the limit
  #    assuming that the emails are sufficiently randomized
  for file in os.listdir("./spam"):
    if (file.endswith(".txt")) and (len(spamtexts) < limit):
      # open file for reading and read entire file into a string
      f = open("./spam/"+file, 'r', encoding="latin-1")
      spamtexts.append (f.read())
      f.close()
  for file in os.listdir("./ham"):
    if (file.endswith(".txt")) and (len(hamtexts) < limit):
      # open file for reading and read entire file into a string
      f = open("./ham/"+file, 'r', encoding="latin-1")
      hamtexts.append (f.read())
      f.close()
  
  # print number emails read
  print ("Number of spam files:",len(spamtexts))
  print ("Number of ham files:",len(hamtexts))
  
  # create list of mixed spam and ham email documents as (list of words, label)
  emaildocs = []
  # add all the spam
  for spam in spamtexts:
    tokens = nltk.word_tokenize(spam)
    emaildocs.append((tokens, 'spam'))
  # add all the regular emails
  for ham in hamtexts:
    tokens = nltk.word_tokenize(ham)
    emaildocs.append((tokens, 'ham'))
  
  # randomize the list
  random.shuffle(emaildocs)
  
  # continue as usual to get all words and create word features
  unflatwords = [item[0] for item in emaildocs] #take all words from emaildocs
  flatwords = [element for sublist in unflatwords for element in sublist] #make lists of words into one long list
  
  #NO FILTERING FEATURES
  allwords = nltk.FreqDist(w.lower() for w in flatwords) #freq dist for words
  word_items = allwords.most_common(2000) #most common 2000
  word_features = [word for (word, freq) in word_items] #word features from most common 2000
  featuresets = [(doc_features(d, word_features), c) for (d,c) in emaildocs]

  #STOPWORDS FEATURES
  stopwords = nltk.corpus.stopwords.words('english')
  stopwords_flat = [word for word in flatwords if word not in stopwords]
  stopwords_allwords = nltk.FreqDist(w.lower() for w in stopwords_flat)
  stopword_items = stopwords_allwords.most_common(2000)
  stopword_features = [word for (word, freq) in stopword_items]
  
  #NEGATIONWORDS + STOPWORDS
  negationwords = ['no', 'not', 'never', 'none', 'nowhere', 'nothing', 'noone', 'rather', 'hardly', 'scarcely', 'rarely', 'seldom', 'neither', 'nor']
  negstopwords = [word for word in stopwords if word not in negationwords]
  negstopwords_flat = [word for word in flatwords if word not in negstopwords]
  negstopwords_allwords = nltk.FreqDist(w.lower() for w in negstopwords_flat)
  negstopword_items = negstopwords_allwords.most_common(2000)
  negstopword_features = [word for (word, freq) in negstopword_items]

  #FEATURES BY WORD TO PUNCT RATIO
  wp_featuresets = [(ratio_features(d), c) for (d, c) in emaildocs]

  #BIGRAMS 
  bigram_measures = nltk.collocations.BigramAssocMeasures()
  finder = BigramCollocationFinder.from_words(flatwords)
  bigram_features = finder.nbest(bigram_measures.chi_sq, 500)
  bigram_featuresets = [(bigram_document_features(d, word_features, bigram_features), c) for (d, c) in emaildocs]

  #POS tags
  POS_featuresets = [(POS_features(d, word_features), c) for (d, c) in emaildocs]

  #STOPWORDS AND BIGRAMS COMBINED
  stopfinder = BigramCollocationFinder.from_words(stopwords_flat)
  stopbigram_features = stopfinder.nbest(bigram_measures.chi_sq, 500)
  stopbigram_featuresets = [(bigram_document_features(d, word_features, stopbigram_features), c) for (d, c) in emaildocs]
  
  # FREQDIST TRAIN
  freqfeaturesets = [(dist_features(d, word_features), c) for (d,c) in emaildocs]

  # Train classifier (replace variable featuresets as necessary)
  split_index = int(len(freqfeaturesets) * 0.8)
  train_set, test_set = freqfeaturesets[:split_index], freqfeaturesets[split_index:]
  classifier = nltk.NaiveBayesClassifier.train(train_set)
  print ("Accuracy:", nltk.classify.accuracy(classifier, test_set))
  
  # Precision, recall and F-measure scores
  goldlist = []
  predictedlist = []
  for (features, label) in test_set:
      goldlist.append(label)
      predictedlist.append(classifier.classify(features))
  eval_measures(goldlist, predictedlist)

  # Cross validation
  num_folds = 5
  cross_validation_accuracy(num_folds, freqfeaturesets)

processspamham('/Users/nadiapaquin/Desktop/FinalProjectData/EmailSpamCorpora/Corpus',500)

"""
commandline interface takes a directory name with ham and spam subdirectories
   and a limit to the number of emails read each of ham and spam
It then processes the files and trains a spam detection classifier.

"""
if __name__ == '__main__':
    if (len(sys.argv) != 3):
        print ('usage: python classifySPAM.py <corpus-dir> <limit>')
        sys.exit(0)
    processspamham(sys.argv[1], sys.argv[2])
        
