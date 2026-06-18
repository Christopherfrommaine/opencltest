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

    ulong n = min + (ulong)gid;

    ulong o = (n << 1) | 1;
    
    int count = 0;
    while (count < STEPS1 && o != 0 && (o & TOPMOSTBITSMASK) == 0) {
        count++;

        ulong a = o << 3;
        ulong b = o << 2;
        ulong c = o << 1;
        ulong d = o >> 1;
        o = (a | b | c | d | o) ^ (a ^ b ^ c ^ d ^ o);
    }

    if (o == 123) {
        ulong idx = atomic_inc(match_count);
        if (idx < max_matches) {
            matches[idx] = o;
        }
    }
}