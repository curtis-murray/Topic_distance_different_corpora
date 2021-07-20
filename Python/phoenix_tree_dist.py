import pandas as pd
import numpy as np
import os
import timeit
import cProfile
import re
import time
import sys
import glob

if not os.path.exists("data/Tree_Distance"):
    os.system("mkdir data/Tree_Distance")

sub1_id = int(sys.argv[1])
sub2_id = int(sys.argv[2])

# Consult the sub_info dataframe to work out what sub we should work with
sub_info = pd.read_csv("data/Subs.info/sub_info.csv")
sub1 = sub_info.query("sub_id == @sub1_id")['sub'].iloc[0]
sub2 = sub_info.query("sub_id == @sub2_id")['sub'].iloc[0]

if len(glob.glob("data/Tree_Distance/"+str(sub1)+"_"+str(sub2)+".csv")) > 0:
    print("Already done " +  sub1 +" and " + sub2)
    quit()

if len(glob.glob("data/Tree_Distance/"+str(sub2)+"_"+str(sub1)+".csv")) > 0:
    print("Already done " +  sub2 + " and " + sub1)
    quit()

#os.system("touch data/Tree_Distance/running_sample_"+str(sample))
print("Tree distance on sub: " + sub1 + " and: " + sub2)

# Data loading
# Tidy topics
df1 = pd.read_csv("data/Tidy_Topics/"+sub1+".csv")
df2 = pd.read_csv("data/Tidy_Topics/"+sub2+".csv")

# Preprocessing data
# Filter to full data
sub1_data = df1[["word_ID_full","topic"]].set_index('word_ID_full').T.to_dict('list')
sub1_probs = df1[["word_ID_full","p"]].set_index('word_ID_full').T.to_dict('list')

# Get sample data
sub2_data = df2[["word_ID_full","topic"]].set_index('word_ID_full').T.to_dict('list')
sub2_probs = df2[["word_ID_full","p"]].set_index('word_ID_full').T.to_dict('list')

# Vocab
Vocab_full = pd.read_csv("data/Vocab/Vocab.csv")[['word_ID_full', 'freq']].set_index('word_ID_full').T.to_dict('list')

Vocab_sub1 = pd.read_csv("data/Vocab/"+sub1+".csv")[['word_ID_full', 'freq']].set_index('word_ID_full').T.to_dict('list')
Vocab_sub2 = pd.read_csv("data/Vocab/"+sub2+".csv")[['word_ID_full', 'freq']].set_index('word_ID_full').T.to_dict('list')


for key in sub1_data.keys():
    print(key)

# Set key-values to 0 for keys not in Vocab_subs
keys_sub1 = list(Vocab_sub1.keys())
keys_sub2 = list(Vocab_sub2.keys())

keys_both = list(set(keys_sub1 + keys_sub2))

diff_sub1 = set(keys_sub2)-set(keys_sub1)
diff_sub2 = set(keys_sub1)-set(keys_sub2)

for key in diff_sub1:
    Vocab_sub1.update({key:[0]})

for key in diff_sub2:
    Vocab_sub2.update({key:[0]})

n_words = len(Vocab_full)

# TODO:
# This is not the most efficent implementation of finding pairwise distances between subs. Can reduce runtime by doing a whole row at a time instead of single element as we recompute everything n times
# The benefit of this way is that it is more readable and no time to setup code as its salvaged from other project.

def total_dist(sub1_data, sub2_data):
    total_d = [0,0,0,0]
    max_depth_sub1 = len(list(sub1_data.items())[1][1][0].split("-"))
    max_depth_sub2 = len(list(sub2_data.items())[1][1][0].split("-"))
    # Nested through upper triangle of adjacency matrix computing weighted
    # path length on each itteration
    # Note: We only need the element of the upper triangle that correspond to words in the subs of interest
    for i in list(set(range(1,n_words+1)).intersection(set(keys_both))):
        for j in list(set(range(i+1,n_words+1)).intersection(set(keys_both))):
            part_d = weighted_diff_path_length(i,j, sub1_data, sub2_data, max_depth_sub1, max_depth_sub2)
            total_d = [total_d[x] + part_d[x] for x in range(0,4)]
    return total_d

def weighted_diff_path_length(i,j, sub1_data, sub2_data, max_depth_sub1, max_depth_sub2):
    # Computed the weighted difference in path lenghts
    # weighted by p_word(i) and p_word(j)
    # Distance container
    d = [0,0,0,0]
    # Find path lengths
    d_sub1 = path_length(i,j, sub1_data, max_depth_sub1)
    d_sub2 = path_length(i,j, sub2_data, max_depth_sub2)
    # Overall prob of words in corpora
    p_i = Vocab_full.get(i)[0]
    p_j = Vocab_full.get(j)[0]
    # Prop of words in sub corpus
    p1_i = Vocab_sub1.get(i)[0]
    p2_i = Vocab_sub2.get(i)[0]
    p1_j = Vocab_sub1.get(j)[0]
    p2_j = Vocab_sub2.get(j)[0]
    # Prob of words in merged sub corpus TODO: weight by total number of words?
    p12_i = (p1_i + p2_i)/2
    p12_j = (p1_j + p2_j)/2
    # Unweighted distance
    d[0] = abs(d_sub1-d_sub2)
    # Corpora weighted distance
    d[1] = d[0]*p_i*p_j
    # Corpus weighted distance
    d[2] = d[0]*p12_i*p12_j
    # Full weighted distance
    d[3] = abs(d_sub1*p1_i*p1_j - d_sub2*p2_i*p2_j)
    return d

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

pd.DataFrame({"sub1": [sub1],
"sub2": [sub2],"distance_unweighted": [d[0]],
"distance_unweighted": [d[0]],
"distance_all_subs_weighted": [d[1]],
"distance_both_subs_weighted": [d[2]],
"distance_sub_weighted": [d[3]]
}).to_csv("data/Tree_Distance/"+str(sub1)+"_"+str(sub2)+".csv", index = False, header=False)