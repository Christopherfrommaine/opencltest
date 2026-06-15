__kernel void search_matches(const ulong start,
                             const ulong count,
                             __global ulong *matches,
                             __global uint *match_count,
                             const ulong max_matches)
{
    size_t gid = get_global_id(0);
    if (gid >= count) {
        return;
    }

    ulong n = start + (ulong)gid;

    // Example predicate: primality test
    int is_match = 1;

    if (n < 2) {
        is_match = 0;
    } else if (n == 2) {
        is_match = 1;
    } else if ((n & 1) == 0) {
        is_match = 0;
    } else if ((n % 1000000) != 43) {
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