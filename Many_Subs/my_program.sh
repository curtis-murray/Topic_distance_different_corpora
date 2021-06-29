#!/bin/bash

rm log

wait
source n_sub
remainder=n_sub%5
wait
t=0
n_sub=13
R CMD BATCH R/phoenix_gen_sample_info.R

for i in $(seq 1 $(($n_sub/5)))
do
    for j in $(seq 1 5)
    do
    python3.9 Python/phoenix_hSBM.py $((($i-1)*5+$j)) &
    now=$date
    echo "Running sub $((($i-1)*5+$j)) at $now" >> log
    done
    wait
done
for i in $(seq 0 $(($remainder)))
do
    python3.9 Python/phoenix_hSBM.py $(($n_sub-$i)) &
    now=date
    echo "Running sub $(($n_sub-$i)) at $now" >> log
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