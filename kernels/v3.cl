#define STEPS1 100
#define STEPS2 100
#define STEPS3 300

#define TOPMOSTBITSMASK 0xE000000000000000

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

    ulong n = (min + (8 * (ulong)gid)) << 1;

    ulong8 o = (ulong8)(
        (ulong)(n + 1),
        (ulong)(n + 3),
        (ulong)(n + 5),
        (ulong)(n + 7),
        (ulong)(n + 9),
        (ulong)(n + 11),
        (ulong)(n + 13),
        (ulong)(n + 15)
    );

    ulong combined = o.s0 | o.s1 | o.s2 | o.s3 | o.s4 | o.s5 | o.s6 | o.s7;
    
    int count = 0;
    while (count < STEPS1 && (TOPMOSTBITSMASK & combined) == 0 && combined != 0) {
        count++;

        ulong8 a = o << 3;
        ulong8 b = o << 2;
        ulong8 c = o << 1;
        ulong8 d = o >> 1;
        o = (a | b | c | d | o) ^ (a ^ b ^ c ^ d ^ o);

        ulong combined = o.s0 | o.s1 | o.s2 | o.s3 | o.s4 | o.s5 | o.s6 | o.s7;
    }

    if (o.s0 == 123) {
        ulong idx = atomic_inc(match_count);
        if (idx < max_matches) {
            matches[idx] = o.s0;
        }
    }
}