#!/bin/bash

# Job Flags
#SBATCH -p mit_normal_gpu
#SBATCH -c 2
#SBATCH --mem=16GB
#SBATCH -t 00:02:00

rm out.txt
make
# time ./main > out.txt
time ./main > out.txt 2> >(tee out_err.txt >&2)
