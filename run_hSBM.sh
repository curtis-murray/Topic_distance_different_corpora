#!/bin/bash

source n_sub

for i in $(seq 1 $n_sub)
	echo $(date -u) "Running hSBM on sub $i" 
	sbatch hSBM.sh $i
done
