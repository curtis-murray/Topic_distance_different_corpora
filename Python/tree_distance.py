import pandas as pd
import numpy as np
import os
import timeit
import cProfile
import re
import time
import sys

if not os.path.exists("data/Tree_Distance"):
    os.system("mkdir data/Tree_Distance")

sub1_id = int(sys.argv[1])
sub2_id = int(sys.argv[2])

# Consult the sub_info dataframe to work out what sub we should work with
sub_info = pd.read_csv("data/Subs.info/sub_id.csv")
sub1 = sub_info.query("sub_id == @sub1_id")['sub'].iloc[0]
sub2 = sub_info.query("sub_id == @sub2_id")['sub'].iloc[0]

#os.system("touch data/Tree_Distance/running_sample_"+str(sample))
print("Tree distance on sub: " + sub1 + " and: " + sub2)

# Data loading
# Tidy topics
df = pd.read_csv("data/Tidy_Topics/tidy_topics_str.csv")
# Vocab
Vocab = pd.read_csv("data/Vocab/Vocab.csv")[['word_ID_full', 'freq']].set_index('word_ID_full').T.to_dict('list')
n_words = len(Vocab)

# Preprocessing data
# Filter to full data
sub1_data = df.query("Sub == @sub1")[["word_ID_full","topic"]].set_index('word_ID_full').T.to_dict('list')
# Get sample data
sub2_data = df.query("Sub == @sub2")[["word_ID_full","topic"]].set_index('word_ID_full').T.to_dict('list')

# TODO:
# This is not the most efficent implementation of finding pairwise distances between subs. Can reduce runtime by doing a whole row at a time instead of single element as we recompute everything n times
# The benefit of this way is that it is more readable and no time to setup code as its salvaged from other project.

def total_dist(sub1_data, sub2_data):
    total_d = 0
    max_depth_sub1 = len(list(sub1_data.items())[1][1][0].split("-"))
    max_depth_sub2 = len(list(sub2_data.items())[1][1][0].split("-"))
    # Nested through upper triangle of adjacency matrix computing weighted
    # path length on each itteration
    for i in range(1,n_words+1):
        for j in range(i+1,n_words+1):
            total_d += weighted_diff_path_length(i,j, sub1_data, sub2_data, max_depth_sub1, max_depth_sub2)
    return total_d

def weighted_diff_path_length(i,j, sub1_data, sub2_data, max_depth_sub1, max_depth_sub2):
    # Computed the weighted difference in path lenghts
    # weighted by p_word(i) and p_word(j)
    d_sub1 = path_length(i,j, sub1_data, max_depth_sub1)
    d_sub2 = path_length(i,j, sub2_data, max_depth_sub2)
    d = abs((d_sub1 - d_sub2)*p_word(i)*p_word(j))
    return d

def p_word(i):
    # Returns p(word | full corpus)
    # Given as the empirical frequency
    p = Vocab.get(i)[0]
    return p

def path_length(i,j,data, max_depth):
    # Funciton to compute path lengths between distinct words

    topic_i = data.get(i)
    topic_j = data.get(j)
    # If either or both words are not part of the data return the max path length (2*depth)
    if (topic_i is None) | (topic_j is None):
        return max_depth*2
    # If the words are the same then the path length is 0
    # Never true as only take upper triangle
    if i == j:
        return 0
    topic_i = topic_i[0].split("-")
    topic_j = topic_j[0].split("-")
    # import string and look for substrings and stuff
    # Loop through hierarchy, starting at deepest level
    # If words are in same topic return distance (starting at 2)
    # Othewise move up hierarcy and add 2 to path length
    for depth in range(max_depth):
        if topic_i[depth] == topic_j[depth]:
            return (depth+1)*2

d = total_dist(sub1_data, sub2_data)

print("Distance of " + str(d))

pd.DataFrame({"sub": [sub], "distance": [d]}).to_csv("data/Tree_Distance/sub_"+str(sub)+".csv", index = False, header=False)