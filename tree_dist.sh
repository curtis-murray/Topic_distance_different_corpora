#!/bin/bash -l
#SBATCH -p batch                                                # partition (this is the queue your job will be added to)                                                    # number of nodes (no MPI, so we only use a single node)
#SBATCH -N 1                                                    # number of nodes
#SBATCH --time=0-10:00:00                                       # walltime allocation, which has the format (D-HH:MM:SS), here set to 1 hour
#SBATCH --mem=4GB                                              # memory required per node (here set to 4 GB)

# Notification configuration
#SBATCH --mail-type=END                                         # Send a notification email when the job is done (=END)
#SBATCH --mail-type=FAIL                                        # Send a notification email when the job fails (=FAIL)
#SBATCH --mail-user=curtis.murray@adelaide.edu.au               # Email to which notifications will be sent

module load Anaconda3/2020.07

conda activate gt

mpirun -np 1 tree_dist_single.sh $1 $2

conda deactivate

