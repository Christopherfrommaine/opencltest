#define STEPS1 100
#define STEPS2 150
#define STEPS3 100
#define STEPS4 50

#define TOPMOSTBITSMASK 0xE000000000000000


ulong min(ulong a, ulong b) {
    if a < b {return a};
    return b;
}

int pos_gap_length_greater_than_four(ulong n) {
    if (n == 0) {return 0;}

    ulong col = (~n) & (~0UL >> clz(n));  // mask off leading zeros of n

    col = (col) & (col << 1) & (col << 2) & (col << 3);

    return ctz(col);
}

__kernel void search_matches(__global ulong *matches,
                             __global uint *match_count,
                             const ulong max_matches)
{
    ulong gid = get_global_id(0);

    ulong n = gid;

    ulong o = (n << 1) | 1;
    ulong oOrig = o;
    
    int count = 0;
    while (o >= oOrig && count < STEPS1 && o != 0 && (o & TOPMOSTBITSMASK) == 0) {
        count++;

        ulong a = o << 3;
        ulong b = o << 2;
        ulong c = o << 1;
        ulong d = o >> 1;
        o = (a | b | c | d | o) ^ (a ^ b ^ c ^ d ^ o);

        o = o >> (((o & 0xF) == 0) << 2);
    }

    o = o >> ctz(o);

    if (o < oOrig) {return;}

    count = 0;
    ulong accum = o;
    ulong minim = o;
    ulong collected = o;
    while (minim >= oOrig && count < STEPS2 && o != 0 && accum != 0 && (o & TOPMOSTBITSMASK) == 0) {
        count++;

        ulong a = o << 3;
        ulong b = o << 2;
        ulong c = o << 1;
        ulong d = o >> 1;
        o = (a | b | c | d | o) ^ (a ^ b ^ c ^ d ^ o);

        o = o >> ctz(o);
        accum = accum ^ o;
        minim = min(minim, o);
        collected = collected | o;
    }

    if (o == 0 || minim < oOrig) {return;}

    int gap_pos = pos_gap_length_greater_than_four(collected);
    if (accum == 0 && gap_pos == 64) {
        ulong idx = atomic_inc(match_count);
        if (idx < max_matches) {
            matches[idx] = oOrig;
        }
        return;
    }

    if ((o & TOPMOSTBITSMASK) == 0 && gap_pos == 64) {
        // last run was unfinished

        count = 0;
        accum = o;
        collected = o;
        while (minim >= oOrig && count < STEPS3 && o != 0 && accum != 0 && (o & TOPMOSTBITSMASK) == 0) {
            count++;

            ulong a = o << 3;
            ulong b = o << 2;
            ulong c = o << 1;
            ulong d = o >> 1;
            o = (a | b | c | d | o) ^ (a ^ b ^ c ^ d ^ o);

            o = o >> ctz(o);
            accum = accum ^ o;
            minim = min(minim, o);
            collected = collected | o;
        }

        if (o == 0 || minim < oOrig) {return;}

        gap_pos = pos_gap_length_greater_than_four(collected);
        if (accum == 0 && gap_pos == 64) {
            ulong idx = atomic_inc(match_count);
            if (idx < max_matches) {
                matches[idx] = oOrig;
            }
            return;
        }
    }

    // 128-bit faffing about
    gap_pos = pos_gap_length_greater_than_four(collected);

    if (gap_pos == 64) {
        ulong idx = atomic_inc(match_count);
        if (idx < max_matches) {
            matches[idx] = oOrig;
        }
        return;
    }

    // Split Solution
    ulong o1 = o & (~0UL >> (64 - gap_pos));
    ulong o2 = o >> gap_pos;

    o1 = o1 >> ctz(o1);
    count = 0;
    accum = o1;
    minim = o1;
    while (minim >= oOrig && count < STEPS4 && o1 != 0 && accum != 0 && (o1 & TOPMOSTBITSMASK) == 0) {
        count++;

        ulong a = o1 << 3;
        ulong b = o1 << 2;
        ulong c = o1 << 1;
        ulong d = o1 >> 1;
        o1 = (a | b | c | d | o1) ^ (a ^ b ^ c ^ d ^ o1);

        o1 = o1 >> ctz(o1);
        accum = accum ^ o1;
        minim = min(minim, o1);
    }

    if (o1 != 0 && minim >= oOrig) {
        ulong idx = atomic_inc(match_count);
        if (idx < max_matches) {
            matches[idx] = oOrig;
        }
    }

    o2 = o2 >> ctz(o2);
    count = 0;
    accum = o2;
    minim = o2;
    while (minim >= oOrig && count < STEPS4 && o2 != 0 && accum != 0 && (o2 & TOPMOSTBITSMASK) == 0) {
        count++;

        ulong a = o2 << 3;
        ulong b = o2 << 2;
        ulong c = o2 << 1;
        ulong d = o2 >> 1;
        o2 = (a | b | c | d | o2) ^ (a ^ b ^ c ^ d ^ o2);

        o2 = o2 >> ctz(o2);
        accum = accum ^ o2;
        minim = min(minim, o2);
    }

    if (o2 != 0 && minim >= oOrig) {
        ulong idx = atomic_inc(match_count);
        if (idx < max_matches) {
            matches[idx] = oOrig;
        }
    }

    return;
}