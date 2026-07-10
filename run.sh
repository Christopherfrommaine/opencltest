#!/bin/bash

# Job Flags
#SBATCH -p mit_preemptable
#SBATCH -G 2
#SBATCH -t 00:30:00 
module load cuda

make
./main $1 $2 > out.txt 2> >(tee out_err.txt >&2)
