#define steps1 100
#define steps2 200
#define steps3 200

#define topmostbitsmask 0xE000000000000000

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
    int is_match = 1;

    ulong o = 2 * n + 1;
    ulong o_orig = o;
    
    int count = 0;
    while (o != 0 && count < steps1 && ((topmostbitsmask & o) == 0)) {
        count++;
        ulong a = o << 3;
        ulong b = o << 2;
        ulong c = o << 1;
        ulong d = o >> 1;
        o = (a ^ b ^ c ^ d ^ o) ^ (a | b | c | d | o);
    }

    if (o == 0) {return;}

    while ((o & 1) == 0) {o = o >> 1;}

    count = 0;
    ulong accum = o;
    ulong minim = o;

    while (o != 0 && count < steps2 && accum != 0 && ((topmostbitsmask & o) == 0)) {
        count++;
        ulong a = o << 3;
        ulong b = o << 2;
        ulong c = o << 1;
        ulong d = o >> 1;
        o = (a ^ b ^ c ^ d ^ o) ^ (a | b | c | d | o);

        if (o != 0) { while ((o & 1) == 0) {o = o >> 1;} }
        
        accum = accum ^ o;
        
        if (o < minim) {minim = o;}
    }

    if (o == 0) {return;}


    if (minim == 151 || minim == 221 || minim == 187 || minim == 189 || minim == 15903 || minim == 635) {
        if (o_orig > minim) {
            return;
        }
    }

    if (is_match) {
        ulong idx = atomic_inc(match_count);
        if (idx < max_matches) {
            matches[idx] = minim;
        }
    }
}