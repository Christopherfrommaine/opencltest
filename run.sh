#!/bin/bash

# Job Flags
#SBATCH -p mit_preemptable
#SBATCH -G 1
#SBATCH -t 00:15:00 
module load cuda

make
./main > out.txt 2> >(tee out_err.txt >&2)
