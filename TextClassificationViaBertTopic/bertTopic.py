# -*- coding: utf-8 -*-
"""
Spyder Editor

This is a temporary script file.
"""

from sentence_transformers import SentenceTransformer
import pandas as pd
import matplotlib.pyplot as plt
import hdbscan
import os
import time
import numpy as np
from sklearn.manifold import TSNE

import umap

# set working directory
os.chdir("Documents\\GitHub\\LunchAndLearns\\TextClassificationViaBertTopic")

# import data
#df = pd.read_csv("support.csv")
df = pd.read_csv("general.csv", encoding="ISO-8859-1")
#df = pd.read_csv("generalDistinct.csv")
#df = pd.read_csv("parents.csv")

# set up bert sentence tranformer
t0 = time.time()
model = SentenceTransformer("distilbert-base-nli-mean-tokens")
embeddings = model.encode(df['text'].tolist())
t1 = time.time()

elapsed = t1-t0

elapsed

# insspect embeddings
embeddings.shape
embeddings[:3]


#### TSNE ####
for perplexity in range(5,53, 2):
    # perplexifty = 8
    tsne = TSNE(n_components= 2, perplexity= perplexity, learning_rate = 100, n_iter = 5000)

    tsneResult = tsne.fit_transform(embeddings)
    tsneResult.shape

    tsneDf = pd.DataFrame(tsneResult, columns = ['x', 'y'])

    fix, ax = plt.subplots(figsize = (20,10))

    plt.scatter(tsneDf.x, tsneDf.y, s = 1)
    plt.title("Perplexity: " + str(perplexity))

perplexity = 43
tsne = TSNE(n_components= 2, perplexity= perplexity, learning_rate = 100, n_iter = 5000)

tsneResult = tsne.fit_transform(embeddings)
tsneResult.shape

tsneDf = pd.DataFrame(tsneResult, columns = ['x', 'y'])

tsneDf.head()

fix, ax = plt.subplots(figsize = (20,10))

plt.scatter(tsneDf.x, tsneDf.y, s = 1)
plt.title("Perplexity: " + str(perplexity))

# higher dim for clustering
tsne = TSNE(n_components= 3, perplexity= perplexity, learning_rate = 100, n_iter = 5000)

tsneResult = tsne.fit_transform(embeddings)
tsneResult.shape

# cluster

min_cluster_size = 10
min_samples = 8
cluster_selection_epsilon = 0.5

cluster = hdbscan.HDBSCAN(min_cluster_size=min_cluster_size,
                          min_samples=min_samples, 
                          cluster_selection_epsilon=cluster_selection_epsilon, 
                          metric='euclidean').fit(tsneResult)
cluster.labels_.max()

tsneDf['labels'] = cluster.labels_

fix, ax = plt.subplots(figsize = (20,10))

outliers = tsneDf.loc[tsneDf.labels == -1, :]
clustered = tsneDf.loc[tsneDf.labels != -1, :]

plt.scatter(outliers.x, outliers.y, color='#BDBDBD', s = 1)
plt.scatter(clustered.x, clustered.y, c = clustered.labels, s = 1, cmap='hsv_r')

plt.colorbar()

tsneDf.to_csv("generalTsneDf4.csv", sep = ",")

#### umap ####
umapEmbeddings = umap.UMAP(n_neighbors = 10,
                           n_components = 2,
                           metric = 'cosine').fit_transform(embeddings)
umapEmbeddings.shape

umapDf = pd.DataFrame(umapEmbeddings, columns = ['x', 'y'])

fix, ax = plt.subplots(figsize = (20,10))

plt.scatter(umapDf.x, umapDf.y, s = 1)

umapEmbedding5D = umap.UMAP(n_neighbors = 10,
                           n_components = 2,
                           metric = 'cosine').fit_transform(embeddings)


min_cluster_size = 10
min_samples = 5
cluster_selection_epsilon = 0

cluster = hdbscan.HDBSCAN(min_cluster_size=min_cluster_size,
                          min_samples=min_samples, 
                          #cluster_selection_epsilon=cluster_selection_epsilon, 
                          metric='euclidean').fit(umapEmbedding5D)
cluster.labels_.max()

umapDf['labels'] = cluster.labels_

fix, ax = plt.subplots(figsize = (20,10))

outliers = umapDf.loc[umapDf.labels == -1, :]
clustered = umapDf.loc[umapDf.labels != -1, :]

plt.scatter(outliers.x, outliers.y, color='#BDBDBD', s = 1)
plt.scatter(clustered.x, clustered.y, c = clustered.labels, s = 1, cmap='hsv_r')

plt.colorbar()