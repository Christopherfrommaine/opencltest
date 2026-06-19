#define STEPS1 100
#define STEPS2 150
#define STEPS3 100
#define STEPS4 75
#define STEPS5 300
#define STEPS6 300

// inline uint ctz(ulong x)
// {
//     if (x == 0UL) {
//         return 64u;
//     }

//     return (uint)(63u - clz(x & (~x + 1UL)));
// }

#define printf(...) (void)0

typedef ulong4 u256;

#define U256_ZERO ((u256)(0UL, 0UL, 0UL, 0UL))

inline int u256_is_zero(const u256 x)
{
    return (x.s0 | x.s1 | x.s2 | x.s3) == 0UL;
}

inline int u256_is_nonzero(const u256 x)
{
    return !u256_is_zero(x);
}

// Returns true if a < b.
inline int u256_lt(const u256 a, const u256 b)
{
    if (a.s3 != b.s3) return a.s3 < b.s3;
    if (a.s2 != b.s2) return a.s2 < b.s2;
    if (a.s1 != b.s1) return a.s1 < b.s1;
    return a.s0 < b.s0;
}

// Returns true if a >= b.
inline int u256_ge(const u256 a, const u256 b)
{
    return !u256_lt(a, b);
}

inline u256 u256_min(const u256 a, const u256 b)
{
    return u256_lt(a, b) ? a : b;
}


inline u256 u256_shl_1(const u256 x)
{
    return (u256)(
        x.s0 << 1,
        (x.s1 << 1) | (x.s0 >> 63),
        (x.s2 << 1) | (x.s1 >> 63),
        (x.s3 << 1) | (x.s2 >> 63)
    );
}

inline u256 u256_shl_2(const u256 x)
{
    return (u256)(
        x.s0 << 2,
        (x.s1 << 2) | (x.s0 >> 62),
        (x.s2 << 2) | (x.s1 >> 62),
        (x.s3 << 2) | (x.s2 >> 62)
    );
}

inline u256 u256_shl_3(const u256 x)
{
    return (u256)(
        x.s0 << 3,
        (x.s1 << 3) | (x.s0 >> 61),
        (x.s2 << 3) | (x.s1 >> 61),
        (x.s3 << 3) | (x.s2 >> 61)
    );
}

inline u256 u256_shr_1(const u256 x)
{
    return (u256)(
        (x.s0 >> 1) | (x.s1 << 63),
        (x.s1 >> 1) | (x.s2 << 63),
        (x.s2 >> 1) | (x.s3 << 63),
        x.s3 >> 1
    );
}

inline u256 u256_shr_4(const u256 x)
{
    return (u256)(
        (x.s0 >> 4) | (x.s1 << 60),
        (x.s1 >> 4) | (x.s2 << 60),
        (x.s2 >> 4) | (x.s3 << 60),
        x.s3 >> 4
    );
}

#define TOPMOSTBITSMASK 0xE000000000000000

int pos_gap_length_greater_than_four(ulong n) {
    if (n == 0) {return 0;}

    ulong col = (~n) & (~0UL >> clz(n));  // mask off leading zeros of n

    col = (col) & (col << 1) & (col << 2) & (col << 3);

    return ctz(col);
}

__kernel void search_matches(const ulong min_i,
                             const ulong max_i,
                             __global ulong *matches,
                             __global uint *match_count,
                             const ulong max_matches)
{
    size_t gid = get_global_id(0);
    if (min_i + (ulong)gid >= max_i) {
        return;
    }

    ulong n = min_i + (ulong)gid;

    ulong o = (n << 1) | 1;
    ulong oOrig = o;

    if (oOrig == 222678959859ULL || oOrig == 477022791 || oOrig == 368754475) {
        printf("1 %lu\n", o);
    }
    
    int count = 0;
    int countsincecollected = 0;
    while (o >= oOrig && count < STEPS1 && (o & TOPMOSTBITSMASK) == 0) {
        count++;

        ulong a = o << 3;
        ulong b = o << 2;
        ulong c = o << 1;
        ulong d = o >> 1;
        o = (a | b | c | d | o) ^ (a ^ b ^ c ^ d ^ o);

        o = o >> (((o & 0xF) == 0) << 2);
    }

    if (oOrig == 222678959859ULL || oOrig == 477022791 || oOrig == 368754475) {
        printf("  steps1 used: %u\n", count);
    }

    o = o >> ctz(o);

    if (o < oOrig) {return;}

    if (oOrig == 222678959859ULL || oOrig == 477022791 || oOrig == 368754475) {
        printf("2 %lu\n", o);
    }

    count = 0;
    ulong first = o;
    ulong minim = o;
    ulong collected = o;
    while (minim >= oOrig && count < STEPS2 && (first != o || count == 0) && (o & TOPMOSTBITSMASK) == 0) {
        count++;

        ulong a = o << 3;
        ulong b = o << 2;
        ulong c = o << 1;
        ulong d = o >> 1;
        o = (a | b | c | d | o) ^ (a ^ b ^ c ^ d ^ o);

        o = o >> ctz(o);
        minim = min(minim, o);
        collected = collected | o;
    }
    countsincecollected += count;

    if (oOrig == 222678959859ULL || oOrig == 477022791 || oOrig == 368754475) {
        printf("  steps2 used: %u\n", count);
    }

    if (o == 0 || minim < oOrig) {return;}

    if (oOrig == 222678959859ULL || oOrig == 477022791 || oOrig == 368754475) {
        printf("3 %lu\n", o);
    }

    int gap_pos = pos_gap_length_greater_than_four(collected);

    if (oOrig == 222678959859ULL || oOrig == 477022791 || oOrig == 368754475) {
        printf("3.1 %lu %lu %u\n", collected, gap_pos, gap_pos);
    }

    if (first == o && gap_pos == 64) {
        ulong idx = atomic_inc(match_count);
        if (idx < max_matches) {
            matches[idx] = minim;
        }
        return;
    }

    if (oOrig == 222678959859ULL || oOrig == 477022791 || oOrig == 368754475) {
        printf("4 %lu\n", o);
    }

    if ((o & TOPMOSTBITSMASK) == 0 && gap_pos == 64) {
        // last run was unfinished

        countsincecollected = 0;
        count = 0;
        first = o;
        collected = o;
        while (minim >= oOrig && count < STEPS3 && (first != o || count == 0) && (o & TOPMOSTBITSMASK) == 0) {
            count++;

            ulong a = o << 3;
            ulong b = o << 2;
            ulong c = o << 1;
            ulong d = o >> 1;
            o = (a | b | c | d | o) ^ (a ^ b ^ c ^ d ^ o);

            o = o >> ctz(o);
            minim = min(minim, o);
            collected = collected | o;
        }
        countsincecollected += count;

        if (oOrig == 222678959859ULL || oOrig == 477022791 || oOrig == 368754475) {
            printf("  steps3 used: %u\n", count);
        }

        if (o == 0 || minim < oOrig) {return;}

        gap_pos = pos_gap_length_greater_than_four(collected);

        if (first == o && gap_pos == 64) {
            ulong idx = atomic_inc(match_count);
            if (idx < max_matches) {
                matches[idx] = minim;
            }
            return;
        }
    }

    if (oOrig == 222678959859ULL || oOrig == 477022791 || oOrig == 368754475) {
        printf("5 %lu, countsincecollected: %u \n", o, countsincecollected);
    }

    // Split Solution
    if (gap_pos != 64 && (countsincecollected > 20 || first == o)) {

        if (oOrig == 222678959859ULL || oOrig == 477022791 || oOrig == 368754475) {
            printf("5 (splitting) %lu col: %lu, gap_pos: %u\n", o, collected, gap_pos);
        }
        ulong o1 = o & (~0UL >> (64 - gap_pos));
        ulong o2 = o >> gap_pos;

        if (oOrig == 222678959859ULL || oOrig == 477022791 || oOrig == 368754475) {
            printf("5.6 o1: %lu, o2: %lu mask1: %lx\n", o1, o2,(~0UL >> (64 - gap_pos)));
        }

        o1 = o1 >> ctz(o1);
        count = 0;
        first = o1;
        minim = o1;
        while (minim >= oOrig && count < STEPS4 && (first != o1 || count == 0) && (o1 & TOPMOSTBITSMASK) == 0) {
            count++;

            ulong a = o1 << 3;
            ulong b = o1 << 2;
            ulong c = o1 << 1;
            ulong d = o1 >> 1;
            o1 = (a | b | c | d | o1) ^ (a ^ b ^ c ^ d ^ o1);

            o1 = o1 >> ctz(o1);
            minim = min(minim, o1);
        }

        if (oOrig == 222678959859ULL || oOrig == 477022791 || oOrig == 368754475) {
            printf("  steps4 used: %u\n", count);
        }

        if (o1 != 0 && minim >= oOrig) {
            ulong idx = atomic_inc(match_count);
            if (idx < max_matches) {
                matches[idx] = minim;
            }
        }

        o2 = o2 >> ctz(o2);
        count = 0;
        first = o2;
        minim = o2;
        while (minim >= oOrig && count < STEPS4 && (first != o2 || count == 0) && (o2 & TOPMOSTBITSMASK) == 0) {
            count++;

            ulong a = o2 << 3;
            ulong b = o2 << 2;
            ulong c = o2 << 1;
            ulong d = o2 >> 1;
            o2 = (a | b | c | d | o2) ^ (a ^ b ^ c ^ d ^ o2);

            o2 = o2 >> ctz(o2);
            minim = min(minim, o2);
        }

        if (o2 != 0 && minim >= oOrig) {
            ulong idx = atomic_inc(match_count);
            if (idx < max_matches) {
                matches[idx] = minim;
            }
        }

        return;
    }

    if (oOrig == 222678959859ULL || oOrig == 477022791 || oOrig == 368754475) {
        printf("6 %lu\n", o);
    }


    // Handle 256-bit
    // {
    //     ulong idx = atomic_inc(match_count);
    //     if (idx < max_matches) {
    //         matches[idx] = minim;
    //     }
    //     return;
    // }


    u256 o256 = U256_ZERO;
    o256.s0 = o;
    
    count = 0;
    while ((o256.s0 >= oOrig || o256.s1 != 0 || o256.s2 != 0 || o256.s3 != 00) && count < STEPS5 && (o256.s3 & TOPMOSTBITSMASK) == 0) {
        count++;

        u256 a = u256_shl_1(o256);
        u256 b = u256_shl_2(o256);
        u256 c = u256_shl_3(o256);
        u256 d = u256_shr_1(o256);
        o256 = (a | b | c | d | o256) ^ (a ^ b ^ c ^ d ^ o256);

        if ((o256.s0 & 0xF) == 0) {
            o256 = u256_shr_4(o256);
        }
    }

    if (oOrig == 222678959859ULL || oOrig == 477022791 || oOrig == 368754475) {
        printf("  steps5 used: %u\n", count);
    }

    if (u256_is_nonzero(o256)) {
        while ((o256.s0 & 1) == 0) {o256 = u256_shr_1(o256); }
    }

    if (oOrig == 222678959859ULL || oOrig == 477022791 || oOrig == 368754475) {
        printf("7 %lu <> %lu <> %lu <> %lu\n", o256.s3, o256.s2, o256.s1, o256.s0);
        printf("7.05 %d %d %d %d\n", o256.s0 < oOrig, o256.s1 == 0, o256.s2 == 0, o256.s3 == 0);
    }

    if (o256.s0 < oOrig && o256.s1 == 0 && o256.s2 == 0 && o256.s3 == 0) {return;}

    if (oOrig == 222678959859ULL || oOrig == 477022791 || oOrig == 368754475) {
        printf("7.1 %lu <> %lu <> %lu <> %lu\n", o256.s3, o256.s2, o256.s1, o256.s0);
    }

    count = 0;
    u256 first256 = o256;
    u256 minim256 = o256;
    u256 collected256 = o256;
    while ((minim256.s0 >= oOrig || minim256.s1 != 0 || minim256.s2 != 0 || minim256.s3 != 0) && count < STEPS6 && (u256_is_nonzero(first256 ^ o256) || count == 0) && (o256.s3 & TOPMOSTBITSMASK) == 0) {
        count++;

        u256 a = u256_shl_1(o256);
        u256 b = u256_shl_2(o256);
        u256 c = u256_shl_3(o256);
        u256 d = u256_shr_1(o256);
        o256 = (a | b | c | d | o256) ^ (a ^ b ^ c ^ d ^ o256);

        if (u256_is_nonzero(o256)) {while ((o256.s0 & 1) == 0) {o256 = u256_shr_1(o256); }}
        collected256 = collected256 | o256;
        minim256 = min(minim256, o256);
    }

    if (oOrig == 222678959859ULL || oOrig == 477022791 || oOrig == 368754475) {
        printf("  steps6 used: %u\n", count);
    }

    if (oOrig == 222678959859ULL || oOrig == 477022791 || oOrig == 368754475) {
        printf("8 %lu <> %lu <> %lu <> %lu\n", o256.s3, o256.s2, o256.s1, o256.s0);
    }

    if (u256_is_zero(o256) || (minim256.s0 < oOrig && minim256.s1 == 0 && minim256.s2 == 0 && minim256.s3)) {return;}

    // Split Solution
    if ((collected256.s1 & TOPMOSTBITSMASK) == 0 && (collected256.s2 & 0x7) == 0) {

        if (oOrig == 222678959859ULL || oOrig == 477022791 || oOrig == 368754475) {
            printf("5 (splitting)\n");
        }
        u256 o2561 = U256_ZERO;
        o2561.s0 = o256.s0;
        o2561.s1 = o256.s1;
        u256 o2562 = U256_ZERO;
        o2562.s0 = o256.s2;
        o2562.s1 = o256.s3;

        if (oOrig == 222678959859ULL || oOrig == 477022791 || oOrig == 368754475) {
            printf("5.6\n");
        }

        if (u256_is_nonzero(o2561)) {while ((o2561.s0 & 1) == 0) {o2561 = u256_shr_1(o2561); }}
        count = 0;
        first256 = o2561;
        minim256 = o2561;
        while ((minim256.s0 >= oOrig || minim256.s1 != 0) && count < STEPS6 && (u256_is_nonzero(first256 ^ o2561) || count == 0) && (o2561.s3 & TOPMOSTBITSMASK) == 0) {
            count++;

            u256 a = u256_shl_1(o2561);
            u256 b = u256_shl_2(o2561);
            u256 c = u256_shl_3(o2561);
            u256 d = u256_shr_1(o2561);
            o256 = (a | b | c | d | o2561) ^ (a ^ b ^ c ^ d ^ o2561);

            if (u256_is_nonzero(o2561)) {while ((o2561.s0 & 1) == 0) {o2561 = u256_shr_1(o2561); }}
            collected256 = collected256 | o2561;
            minim256 = min(minim256, o2561);
        }

        if (oOrig == 222678959859ULL || oOrig == 477022791 || oOrig == 368754475) {
            printf("  steps4 used: %u\n", count);
        }

        if (u256_is_nonzero(o2561) && !(minim256.s0 < oOrig && minim256.s1 == 0 && minim256.s2 == 0 && minim256.s3)) {
            ulong idx = atomic_inc(match_count);
            if (idx < max_matches) {
                matches[idx] = oOrig;
            }
        }

        if (u256_is_nonzero(o2562)) {while ((o2562.s0 & 1) == 0) {o2562 = u256_shr_1(o2562); }}
        count = 0;
        first256 = o2562;
        minim256 = o2562;
        while ((minim256.s0 >= oOrig || minim256.s1 != 0) && count < STEPS6 && (u256_is_nonzero(first256 ^ o2562) || count == 0) && (o2562.s3 & TOPMOSTBITSMASK) == 0) {
            count++;

            u256 a = u256_shl_1(o2562);
            u256 b = u256_shl_2(o2562);
            u256 c = u256_shl_3(o2562);
            u256 d = u256_shr_1(o2562);
            o256 = (a | b | c | d | o2562) ^ (a ^ b ^ c ^ d ^ o2562);

            if (u256_is_nonzero(o2562)) {while ((o2562.s0 & 1) == 0) {o2562 = u256_shr_1(o2562); }}
            collected256 = collected256 | o2562;
            minim256 = min(minim256, o2562);
        }

        if (oOrig == 222678959859ULL || oOrig == 477022791 || oOrig == 368754475) {
            printf("  steps4 used: %u\n", count);
        }

        if (u256_is_nonzero(o2562) && !(minim256.s0 < oOrig && minim256.s1 == 0 && minim256.s2 == 0 && minim256.s3)) {
            ulong idx = atomic_inc(match_count);
            if (idx < max_matches) {
                matches[idx] = oOrig;
            }
        }

        return;
    }

    if (minim256.s1 == 0 && minim256.s2 == 0 && minim256.s3) {
        ulong idx = atomic_inc(match_count);
        if (idx < max_matches) {
            matches[idx] = minim;
        }
        return;
    } else {
        ulong idx = atomic_inc(match_count);
        if (idx < max_matches) {
            matches[idx] = oOrig;
        }
        return;
    }
}