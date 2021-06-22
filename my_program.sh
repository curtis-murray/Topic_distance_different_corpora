#!/bin/bash

rm data/Samples/*
rm data/Tidy_Topics/*
rm data/Tree_Distance/*
rm log

wait
source n_sub
remainder=n_sub%5
wait
t=0

R CMD BATCH R/phoenix_gen_sample_info.R

for i in $(seq 1 $(($n_sub/5)))
do
    for j in $(seq 1 5)
    do
    python3.9 Python/phoenix_hSBM.py $((($i-1)*5+$j-1)) &
    now=$date
    echo "Running sub $((($i-1)*5+$j-1)) at $now" >> log
    done
    wait
done
for i in $(seq 0 $remainder)
do
    python3.9 Python/phoenix_hSBM.py $(($n_sub-$i)) &
    now=date
    echo "Running sub $i at $now" >> log
done
wait
R CMD BATCH R/phoenix_tidy.R
wait
for i in $(seq 1 $n_sub)
do
    for j in $(seq $(($i+1)) $n_sub)
    do
        python3.9 Python/phoenix_tree_dist.py $i $j &
    done
done