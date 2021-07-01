import matplotlib
import os
import pylab as plt
from sbmtm import sbmtm
import graph_tool.all as gt
import pandas as pd
import numpy as np
import re
from itertools import chain
import sys
import glob

# The sample id is passed in as an argument
sub_id = int(sys.argv[1])

# Consult the sub_info dataframe to work out what sub we should work with
sub_info = pd.read_csv("data/Subs.info/sub_info.csv")
sub = sub_info.query("sub_id == @sub_id")['sub'].iloc[0]

if len(glob.glob("data/Samples/words_all_*"+sub+".csv")) > 0:
    print("Already done " + sub)
    quit()

def run_hSBM(texts, titles, sub):
    # Function to run the hSBM given the data, subs
    model = sbmtm()

    ## we have to create the word-document network from the corpus
    model.make_graph(texts,documents=titles)

    ## we can also skip the previous step by saving/loading a graph
    # model.save_graph(filename = 'graph.xml.gz')
    # model.load_graph(filename = 'graph.xml.gz')

    ## fit the model
    #gt.seed_rng(32) ## seed for graph-tool's random number generator --> same results
    model.fit()

    for level in range(0,model.L+1):

        group_results = model.get_groups(l = level)
        p_w_tw = group_results['p_w_tw']
        pd.DataFrame.to_csv(pd.DataFrame(p_w_tw), "".join(["data/Samples/p_w_tw", str(level),"_" ,sub,  ".csv"]))

    pd.DataFrame.to_csv(pd.DataFrame(model.words), "".join(["data/Samples/words_all_", sub, ".csv"]))

data = pd.read_csv("data/Clean/" + sub +  ".csv")

# Get texts and titles
texts = data["Content"].values.tolist()
titles = data["Post_ID"].values.tolist()
texts = [c.split() for c in texts]

# Run hSBM
while(1):
    try:
        print("Running hSBM on sub: " + sub)
        run_hSBM(texts, titles, sub)
        break
    except Exception as e:
        print(e)
        print("Something went wrong, trying again...")


