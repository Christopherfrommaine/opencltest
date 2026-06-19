rm out.txt
make
# time ./main > out.txt
time ./main > out.txt 2> >(tee out_err.txt >&2)
