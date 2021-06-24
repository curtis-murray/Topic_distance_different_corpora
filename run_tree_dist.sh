#!/bin/bash

source n_sub

for i in $(seq 1 $(($n_sub-1)))
do
	for j in $(seq $(($i+1)) $n_sub)
	do
		echo $(date -u) "Running subs $i $j" 
		sbatch tree_dist.sh $i $j
	done
done
