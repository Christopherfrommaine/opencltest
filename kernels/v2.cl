#define STEPS1 10000
#define STEPS2 100
#define STEPS3 300

#define TOPMOSTBITSMASK 0xE000000000000000

ulong deinterleave_by_four(ulong x)
{
    x &= 0x1111111111111111UL;
    x = (x | (x >> 3))  & 0x0303030303030303UL;
    x = (x | (x >> 6))  & 0x000F000F000F000FUL;
    x = (x | (x >> 12)) & 0x000000FF000000FFUL;
    x = (x | (x >> 24)) & 0x000000000000FFFFUL;
    return x;
}

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

    // o3 contains msb, o0 contains lsb
    ulong o0 = deinterleave_by_four((n << 1) | 1);
    ulong o1 = deinterleave_by_four(n);
    ulong o2 = deinterleave_by_four(n >> 1);
    ulong o3 = deinterleave_by_four(n >> 2);
    
    int count = 0;
    while (count < STEPS1 && (o0 | o1 | o2 | o3) != 0 && ((o2 | o3) & TOPMOSTBITSMASK) == 0) {
        count++;

        ulong o2shl = o2 << 1;
        ulong o3shl = o3 << 1;
        ulong o0shr = o0 >> 1;

        ulong t0 = (o1 | o0 | o2shl | o3shl) ^ (o1 ^ o0 ^ o2shl ^ o3shl);
        ulong t1 = (o2 | o1 | o0 | o3shl) ^ (o2 ^ o1 ^ o0 ^ o3shl);
        ulong t2 = (o3 | o2 | o1 | o0) ^ (o3 ^ o2 ^ o1 ^ o0);
        ulong t3 = (o0shr | o3 | o2 | o1) ^ (o3 ^ o2 ^ o1 ^ o0shr);
        o0 = t0; o1 = t1; o2 = t2; o3 = t3;
    }

    if (o0 == 123) {
        ulong idx = atomic_inc(match_count);
        if (idx < max_matches) {
            matches[idx] = o0;
        }
    }
}