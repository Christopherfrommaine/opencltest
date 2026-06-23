#!/bin/bash

# Job Flags
#SBATCH -p mit_preemptable
#SBATCH -G 4
#SBATCH -t 02:00:00 
module load cuda

make
./main > out.txt 2> >(tee out_err.txt >&2)
