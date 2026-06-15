__kernel void search_matches(const ulong min,
                             const ulong max,
                             __global ulong *matches,
                             __global uint *match_count,
                             const ulong max_matches)
{
    size_t gid = get_global_id(0);
    if (min + (ulong)gid >= max) {
        return;
    }

    ulong n = min + (ulong)gid;

    // Example predicate: primality test
    int is_match = 1;

    if (n < 2) {
        is_match = 0;
    } else if (n == 2) {
        is_match = 1;
    } else if ((n & 1) == 0) {
        is_match = 0;
    } else if ((n % 10000000) != 43) {
        is_match = 0;
    } else {
        for (ulong i = 3; i * i <= n; i += 2) {
            if (n % i == 0) {
                is_match = 0;
                break;
            }
        }
    }

    if (is_match) {
        ulong idx = atomic_inc(match_count);
        if (idx < max_matches) {
            matches[idx] = n;
        }
    }
}