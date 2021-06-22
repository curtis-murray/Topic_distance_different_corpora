#!/bin/bash -l
#SBATCH -p batch                                                # partition (this is the queue yourjob will be added to)
#SBATCH -N 1                                                    # number of nodes (no MPI, so we only use a single node)
#SBATCH -n 1                                                    # number of cores
#SBATCH --ntasks-per-node=1
#SBATCH --time=0-00:10:00                                       # walltime allocation, which has the format (D-HH:MM:SS), here set to 1 hour
#SBATCH --mem=32GB                                              # memory required per node (here set to 4 GB)

# Notification configuration
#SBATCH --mail-type=END                                         # Send a notification email when the job is done (=END)
#SBATCH --mail-type=FAIL                                        # Send a notification email when the job fails (=FAIL)
#SBATCH --mail-user=curtis.murray@adelaide.edu.au               # Email to which notifications will be sent

module load Anaconda3/2020.07
module load R

conda activate /hpcfs/users/$USER/myconda/envs/gt

mpirun -np 1 ./my_program.sh

conda deactivate
