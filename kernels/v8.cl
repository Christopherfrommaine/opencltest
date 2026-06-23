#define TOPMOSTBITSMASK 0xE000000000000000UL
#define TOPMOSTBITSMASKPLUSSIXTEEN 0xFFFFE00000000000UL
#define BOTTOMMOSTBITSMASK 0x0000000000000007UL




#define DEBUG 1
#define PRINTIF_CONDITION oOrig == 10469510870511



#define STACK_SIZE 8
#define MAX_STACK_DEPTH 10



#ifdef __APPLE__
inline uint ctz(ulong x)
{
    if (x == 0UL) {
        return 64u;
    }

    return (uint)(63u - clz(x & (~x + 1UL)));
}
#endif

ulong reverse_bits(ulong x) {
    x = ((x & 0xAAAAAAAAAAAAAAAAULL) >> 1)  | ((x & 0x5555555555555555ULL) << 1);
    x = ((x & 0xCCCCCCCCCCCCCCCCULL) >> 2)  | ((x & 0x3333333333333333ULL) << 2);
    x = ((x & 0xF0F0F0F0F0F0F0F0ULL) >> 4)  | ((x & 0x0F0F0F0F0F0F0F0FULL) << 4);
    x = ((x & 0xFF00FF00FF00FF00ULL) >> 8)  | ((x & 0x00FF00FF00FF00FFULL) << 8);
    x = ((x & 0xFFFF0000FFFF0000ULL) >> 16) | ((x & 0x0000FFFF0000FFFFULL) << 16);
    x = (x >> 32) | (x << 32);
    return x;
}


/// U256 Workings
typedef ulong4 u256;

#define U256_ZERO ((u256)(0UL, 0UL, 0UL, 0UL))

inline int u256_is_zero(const u256 x)
{
    return (x.s0 | x.s1 | x.s2 | x.s3) == 0UL;
}

inline int u256_ne(const u256 a, const u256 b)
{
    return (a.s0 != b.s0) | (a.s1 != b.s1) | (a.s2 != b.s2) | (a.s3 != b.s3);
}

inline int u256_eq(const u256 a, const u256 b)
{
    return (a.s0 == b.s0) & (a.s1 == b.s1) & (a.s2 == b.s2) & (a.s3 == b.s3);
}

inline int u256_ge_u64(const u256 a, const ulong b)
{
    return (int)((a.s1 | a.s2 | a.s3) != 0UL) | (int)(a.s0 >= b);
}

inline int u256_lt(const u256 a, const u256 b)
{
    int lt3 = a.s3 < b.s3,  eq3 = a.s3 == b.s3;
    int lt2 = a.s2 < b.s2,  eq2 = a.s2 == b.s2;
    int lt1 = a.s1 < b.s1,  eq1 = a.s1 == b.s1;
    int lt0 = a.s0 < b.s0;
    return lt3 | (eq3 & (lt2 | (eq2 & (lt1 | (eq1 & lt0)))));
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

inline u256 u256_shr_2(const u256 x)
{
    return (u256)(
        (x.s0 >> 2) | (x.s1 << 62),
        (x.s1 >> 2) | (x.s2 << 62),
        (x.s2 >> 2) | (x.s3 << 62),
        x.s3 >> 2
    );
}

inline u256 u256_shr_8(const u256 x)
{
    return (u256)(
        (x.s0 >> 8) | (x.s1 << 56),
        (x.s1 >> 8) | (x.s2 << 56),
        (x.s2 >> 8) | (x.s3 << 56),
        x.s3 >> 8
    );
}

inline u256 u256_small_shr(const u256 x, const uint n)
{   
    if (n == 0) {return x;}

    if (n >= 64) {
        return (u256)(
            x.s1,
            x.s2,
            x.s3,
            0UL
        );
    }

    return (u256)(
        (x.s0 >> n) | (x.s1 << (64 - n)),
        (x.s1 >> n) | (x.s2 << (64 - n)),
        (x.s2 >> n) | (x.s3 << (64 - n)),
        x.s3 >> n
    );
}

inline uint u256_ctz(const u256 x)
{
    if (x.s0 != 0UL) {return ctz(x.s0);}
    if (x.s1 != 0UL) {return 64u + ctz(x.s1);}
    if (x.s2 != 0UL) {return 128u + ctz(x.s2);}
    if (x.s3 != 0UL) {return 192u + ctz(x.s3);}
    return 256u;
}

inline u256 u256_significant_bits_mask(const u256 n)
{
    if (n.s3) return (u256)(~0UL, ~0UL, ~0UL, ~0UL >> clz(n.s3));
    if (n.s2) return (u256)(~0UL, ~0UL, ~0UL >> clz(n.s2), 0UL);
    if (n.s1) return (u256)(~0UL, ~0UL >> clz(n.s1), 0UL, 0UL);
    if (n.s0) return (u256)(~0UL >> clz(n.s0), 0UL, 0UL, 0UL);
    return (u256)(0UL, 0UL, 0UL, 0UL);
}


inline u256 u256_low_bits_mask(const uint k)
{
    if (k >= 256u) return (u256)(~0UL, ~0UL, ~0UL, ~0UL);
    const uint q = k >> 6, r = k & 63u;
    const ulong m = r ? (~0UL >> (64u - r)) : 0UL;
    if (q == 0u) return (u256)(m, 0UL, 0UL, 0UL);
    if (q == 1u) return (u256)(~0UL, m, 0UL, 0UL);
    if (q == 2u) return (u256)(~0UL, ~0UL, m, 0UL);
    return (u256)(~0UL, ~0UL, ~0UL, m);
}

inline u256 u256_shr_bits_lt64(const u256 x, const uint n)
{
    if (n == 0u) return x;
    const uint r = 64u - n;
    return (u256)(
        (x.s0 >> n) | (x.s1 << r),
        (x.s1 >> n) | (x.s2 << r),
        (x.s2 >> n) | (x.s3 << r),
        x.s3 >> n
    );
}

inline u256 u256_shr(const u256 x, const uint n)
{
    const uint q = n >> 6, r = n & 63u;
    u256 y = (q == 0u) ? x : (q == 1u) ? (u256)(x.s1, x.s2, x.s3, 0UL) :
             (q == 2u) ? (u256)(x.s2, x.s3, 0UL, 0UL) : (q == 3u) ? (u256)(x.s3, 0UL, 0UL, 0UL) : U256_ZERO;
    return u256_shr_bits_lt64(y, r);
}

inline u256 u256_shr_ctz(const u256 x)
{
    if (x.s0 & 1UL) return x;
    if (x.s0) return u256_shr_bits_lt64(x, ctz(x.s0));
    if (x.s1) return u256_shr_bits_lt64((u256)(x.s1, x.s2, x.s3, 0UL), ctz(x.s1));
    if (x.s2) return u256_shr_bits_lt64((u256)(x.s2, x.s3, 0UL, 0UL), ctz(x.s2));
    if (x.s3) return (u256)(x.s3 >> ctz(x.s3), 0UL, 0UL, 0UL);
    return U256_ZERO;
}

inline bool u256_fits_in_ulong(const u256 a)
{
    return !(a.s1 | a.s2 | a.s3);
}







#if DEBUG
#define PRINTIF(...) do { \
    if (PRINTIF_CONDITION) { \
        printf(__VA_ARGS__); \
    } \
} while(0)
#else
#define PRINTIF(...)
#endif



uint gap_pos_gt_four(ulong n) {
    ulong col = (~n) & (~0UL >> clz(n));  // mask off leading zeros of n
    col = (col) & (col << 1) & (col << 2) & (col << 3);
    return ctz(col);
}

uint gap_pos_gt_four256(u256 n) {
    u256 col = (~n) & u256_significant_bits_mask(n);  // mask off leading zeros of n
    col = col & u256_shl_1(col) & u256_shl_2(col) & u256_shl_3(col);
    return u256_ctz(col);
}

#define RECURSE(retval) do { \
if (depth && stack_ptr < STACK_SIZE && (retval) != oStart) { \
    stack_o[stack_ptr] = retval; \
    stack_depth[stack_ptr] = depth - 1; \
    stack_ptr++; \
} else { \
    ulong idx = atomic_inc(match_count); \
    if (idx < max_matches) { \
        matches[idx] = minim; /* OVERRIDE HERE override pverride  */ \
    } \
} \
} while(0)

inline ulong update64(ulong o) {
    ulong a = o << 3;
    ulong b = o << 2;
    ulong c = o << 1;
    ulong d = o >> 1;
    return (a | b | c | d | o) ^ (a ^ b ^ c ^ d ^ o);
}

inline ulong update64_noshift(ulong o) {
    ulong a = o << 2;
    ulong b = o << 1;
    ulong c = o >> 1;
    ulong d = o >> 2;
    return (a | b | c | d | o) ^ (a ^ b ^ c ^ d ^ o);
}


#define RUN64(steps) do { \
    count = 0; \
    first = o; \
    minim = o; \
    col = o; \
    while (minim >= oOrig && (o != first || count == 0) && count < (steps) && (o & TOPMOSTBITSMASK) == 0) { \
        count++; \
        o = update64(o); \
        o = o >> ctz(o); \
        minim = min(minim, o); \
        col = col | o; \
    } \
} while (0)

#define RUN64_NOSHIFT(steps) do { \
    o = o << 16; \
    count = 0; \
    first = o; \
    col = o; \
    while ((o != first || count == 0) && count < (steps) && (o & TOPMOSTBITSMASK) == 0 && (o & BOTTOMMOSTBITSMASK) == 0) { \
        count++; \
        o = update64_noshift(o); \
        col = col | o; \
    } \
} while (0)

inline u256 update256(const u256 o) {
    u256 a = u256_shl_3(o);
    u256 b = u256_shl_2(o);
    u256 c = u256_shl_1(o);
    u256 d = u256_shr_1(o);
    return (a | b | c | d | o) ^ (a ^ b ^ c ^ d ^ o);
}

#define RUN256(steps) do { \
    count = 0; \
    first256 = o256; \
    minim256 = o256; \
    col256 = o256; \
    while (u256_ge_u64(minim256, oOrig) && count < (steps) && (o256.s3 & TOPMOSTBITSMASK) == 0 && (u256_ne(o256, first256) || count == 0)) { \
        count++; \
        o256 = update256(o256); \
        o256 = u256_shr_ctz(o256); \
        minim256 = u256_min(minim256, o256); \
        col256 = col256 | o256; \
    } \
} while (0)

__kernel void search_matches(const ulong min_i,
                             const ulong max_i,
                             __global ulong *matches,
                             __global uint *match_count,
                             const ulong max_matches)
{
    size_t gid = get_global_id(0);
    ulong n = min_i + (ulong)gid;

    if (n >= max_i) { return; }

    ulong oOrig = (n << 1) | 1;

    PRINTIF("STARTING WITH INITIAL O: %lu\n", oOrig);

    ulong oOrigRev = reverse_bits(oOrig) >> clz(oOrig);
    if (oOrigRev < oOrig) { return; }

    ulong stack_o[STACK_SIZE];
    ushort stack_depth[STACK_SIZE];
    ushort stack_ptr = 0;

    PRINTIF("  continuing...");

    stack_o[stack_ptr] = oOrig;
    stack_depth[stack_ptr] = MAX_STACK_DEPTH;
    stack_ptr++;

    while (stack_ptr) {
        stack_ptr--;
        ulong oStart = stack_o[stack_ptr];
        ushort depth = stack_depth[stack_ptr];

        ulong o = oStart;

        PRINTIF("  1 DEPTH %u STARTING %lu\n", depth, o);

        if (o < oOrig) { continue; }

        uint count = 0;
        ulong first;
        ulong minim;
        ulong col;
        RUN64(100);

        if (minim < oOrig) { continue; }

        PRINTIF("  2 After first run: %lu\n", o);

        uint gap_pos_col;
        if (first == o && count != 0) {
            // DEFINITLY PERIODIC
            // Try to separate solutions

            PRINTIF("  3.1 first: %lu, o: %lu, minim: %lu, count: %u\n", first, o, minim, count);

            gap_pos_col = gap_pos_gt_four(col);
            if (gap_pos_col != 64) {
                ulong o1 = o & (~0UL >> (64 - gap_pos_col));
                ulong o2 = o >> gap_pos_col;
                o2 = o2 >> ctz(o2);

                PRINTIF("  3.15 recursing with: col: %lu, gap: %u, o1: %lu, o2: %lu\n", col, gap_pos_col, o1, o2);

                RECURSE(o1);
                RECURSE(o2);

                continue;
            }

            PRINTIF("  3.2\n");
            
            uint period = count;
            if ((o & TOPMOSTBITSMASKPLUSSIXTEEN) == 0) {
                PRINTIF("  3.31 o: %lu\n", o);
                
                RUN64_NOSHIFT(period);

                PRINTIF("  3.32 o: %lu\n", o);

                if (o & BOTTOMMOSTBITSMASK || o & TOPMOSTBITSMASK) {
                    RECURSE(minim);
                    continue;
                };

                PRINTIF("  3.33 \n");

                uint colshift = ctz(col);
                col = col >> colshift;
                o = o >> colshift;

                gap_pos_col = gap_pos_gt_four(col);
                if (gap_pos_col != 64) {
                    ulong o1 = o & (~0UL >> (64 - gap_pos_col));
                    ulong o2 = o >> gap_pos_col;
                    o2 = o2 >> ctz(o2);

                    RECURSE(o1);
                    RECURSE(o2);

                    continue;
                }
            }

            PRINTIF("  3.4 o: %lu\n", o);

            // Full split separate solutions algorithm
            uint gap_pos = 0;
            bool finished = true;
            ulong lower_mask = 0;
            ulong last = 0;
            while (gap_pos < 64) {
                gap_pos++;
                lower_mask = (lower_mask << 1) | 1;


                ulong o_lower = o &  lower_mask;
                ulong o_upper = o & ~lower_mask;
                ulong o_full  = o;

                if (o_lower == last) { continue; }
                last = o_lower;

                PRINTIF("    3.5 pos: %u, upper: %lu, lower: %lu\n", gap_pos, o_upper, o_lower);

                if (o_lower == 0) { continue; }
                if (o_upper == 0) { break; }

                bool splittable = true;
                for (uint i = 0; i <= count; i++) {
                    o_full  = update64(o_full );
                    o_upper = update64(o_upper);
                    o_lower = update64(o_lower);

                    if (o_full != (o_upper ^ o_lower)) {
                        splittable = false;
                        PRINTIF("    3.55 split did not work! full: %lu, xored: %lu, lower: %lu, upper: %lu\n", o_full, o_lower ^ o_upper, o_lower, o_upper);
                        break;
                    }

                    if ((o_full & TOPMOSTBITSMASK) != 0) {
                        uint ctzmin = min(ctz(o_upper), ctz(o_lower));
                        o_full = o_full >> ctzmin;
                        if ((o_full & TOPMOSTBITSMASK) != 0) {
                            continue;
                        }

                        o_lower = o_lower >> ctzmin;
                        o_upper = o_upper >> ctzmin;
                    }
                }

                if (splittable) {
                    PRINTIF("    3.6 split worked!\n");

                    RECURSE(o_upper >> ctz(o_upper));
                    RECURSE(o_lower >> ctz(o_lower));

                    finished = false;
                    break;
                }

                PRINTIF("    3.7 split did not work.\n");
            }

            PRINTIF("  3.8 finished: %i\n", finished);

            if (!finished) { continue; }


            // Nothing more we can do! Therefore the solution is valid!
            //   get real minimum
            RUN64(period + 1);
            ulong minim_original = minim;
            o = reverse_bits(o) >> clz(o);
            RUN64(1000 + period + 1);
            minim = min(minim, minim_original);

            PRINTIF("  3.9 oOrig: %lu, o: %lu, minimum: %lu\n", oOrig, o, minim);

            depth = 0;
            RECURSE(minim);
            continue;
        }

        // APERIODIC so far, but may stabalize
        if ((o & TOPMOSTBITSMASK) == 0) {
            PRINTIF("  4\n");
            RECURSE(o);
            continue;
        }

        // WIDTH EXCEEDED. Attempt to split as first resort.
        PRINTIF("  5.1\n");

        gap_pos_col = gap_pos_gt_four(col);
        if (gap_pos_col != 64) {
            ulong o1 = o & (~0UL >> (64 - gap_pos_col));
            ulong o2 = o >> gap_pos_col;
            o2 = o2 >> ctz(o2);

            RECURSE(o1);
            RECURSE(o2);

            continue;
        }

        PRINTIF("  5.2\n");
        
        u256 o256 = (u256)(o, 0, 0, 0);

        u256 first256;
        u256 minim256;
        u256 col256;

        RUN256(420);

        PRINTIF("  5.25 o256:     %lu<>%lu<>%lu<>%lu\n", o256.s3, o256.s2, o256.s1, o256.s0);
        PRINTIF("  5.26 minim256: %lu<>%lu<>%lu<>%lu\n", minim256.s3, minim256.s2, minim256.s1, minim256.s0);
        PRINTIF("  5.27 count: %u", count);

        if (u256_fits_in_ulong(minim256) && minim256.s0 != minim) {
            RECURSE(minim256.s0);
            continue;
        }

        PRINTIF("  5.3\n");

        if (o256.s1 == 0 && o256.s2 == 0) {
            RECURSE(o256.s3 >> ctz(o256.s3));
            RECURSE(o256.s0 >> ctz(o256.s0));
            continue;
        }
        if (o256.s1 == 0 && o256.s3 == 0) {
            RECURSE(o256.s2 >> ctz(o256.s2));
            RECURSE(o256.s0 >> ctz(o256.s0));
            continue;
        }

        PRINTIF("  5.4\n");

        RUN256(100);
        
        if (u256_eq(o256, first256)) {
            // DEFINITLY PERIODIC
            // Try to separate solutions

            PRINTIF("  6.1 col: %lu<>%lu<>%lu<>%lu\n", col256.s3, col256.s2, col256.s1, col256.s0);

            gap_pos_col = gap_pos_gt_four256(col256);
            if (gap_pos_col != 256) {
                u256 o1 = o256 & u256_low_bits_mask(gap_pos_col);
                u256 o2 = u256_shr(o256, gap_pos_col);
                o2 = u256_shr_ctz(o2);

                // match all possible cases
                if (u256_fits_in_ulong(o1)) {
                    if (u256_fits_in_ulong(o2)) {
                        RECURSE(o1.s0);
                        RECURSE(o2.s0);
                        continue;
                    } else {
                        RECURSE(o1.s0);
                        o256 = o2;
                    }
                } else {
                    if (u256_fits_in_ulong(o2)) {
                        RECURSE(o2.s0);
                        o256 = o1;
                    } else {
                        depth = 0;
                        RECURSE(minim);
                        continue;
                    }
                }
            }

            PRINTIF("  6.2\n");

            // Full split separate solutions algorithm
            uint gap_pos = 0;
            bool finished = true;
            u256 lower_mask = U256_ZERO;
            u256 last = U256_ZERO;
            while (gap_pos < 256) {
                gap_pos++;
                lower_mask = u256_shl_1(lower_mask);
                lower_mask.s0 = lower_mask.s0 | 1;
                
                u256 o_lower = o256 &  lower_mask;
                u256 o_upper = o256 & ~lower_mask;
                u256 o_full  = o256;

                PRINTIF("    6.5 pos: %u\n", gap_pos);
                if (u256_eq(last, o_lower)) { continue; }
                last = o_lower;

                if (u256_is_zero(o_lower)) { continue; }
                if (u256_is_zero(o_upper)) { break; }

                bool splittable = true;
                for (uint i = 0; i <= count; i++) {
                    o_full  = update256(o_full );
                    o_upper = update256(o_upper);
                    o_lower = update256(o_lower);

                    if (u256_ne(o_full, (o_upper ^ o_lower))) {
                        splittable = false;
                        PRINTIF("    6.55 split did not work!\n");
                        break;
                    }

                    if ((o_full.s3 & TOPMOSTBITSMASK) != 0) {
                        uint ctzmin = min(u256_ctz(o_upper), u256_ctz(o_lower));
                        o_full = u256_shr(o_full, ctzmin);
                        if ((o_full.s3 & TOPMOSTBITSMASK) != 0) {
                            continue;
                        }

                        o_lower = u256_shr(o_lower, ctzmin);
                        o_upper = u256_shr(o_upper, ctzmin);
                    }
                }

                if (splittable) {
                    PRINTIF("    6.6 split worked!\n");

                    o_lower = u256_shr_ctz(o_lower);
                    o_upper = u256_shr_ctz(o_upper);

                    if (u256_fits_in_ulong(o_lower) && u256_fits_in_ulong(o_upper)) {
                        RECURSE(o_lower.s0);
                        RECURSE(o_upper.s0);
                        continue;
                    }

                    finished = false;
                    break;
                }

                PRINTIF("    6.7 split did not work.\n");
            }

            PRINTIF("  6.8 finished: %i\n", finished);

            if (!finished) { continue; }


            // Nothing more we can do! Therefore the solution is valid!
            PRINTIF("  6.9 oOrig: %lu\n", oOrig);

            depth = 0;
            RECURSE(minim);
            continue;
        }

        depth = 0;
        RECURSE(minim);
        continue;
    }


}