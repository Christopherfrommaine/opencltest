// PROBLEMS:
// do the no shift first!


#define STEPS1 100
#define STEPS2 250
#define STEPS3 200
#define STEPS4 75
#define STEPS5 300
#define STEPS6 300

#define RETVAL minim
#define RETVAL256 minim256.s0
// #define RETVAL oOrig
// #define RETVAL256 oOrig


#define printf(...)   (void)0
#define DEBUG_CHECK         0
#define RET_DEBUG_CHECK     0
#define RET_DEBUG_CHECK_256 0
#define EARLY_DEBUG         0
// #define DEBUG_CHECK oOrig == 4923292873
// #define RET_DEBUG_CHECK minim == 122205635609579
// #define RET_DEBUG_CHECK_256 minim256.s0 == 122205635609579
// #define EARLY_DEBUG oOrig == 406342267

#ifdef __APPLE__
inline uint ctz(ulong x)
{
    if (x == 0UL) {
        return 64u;
    }

    return (uint)(63u - clz(x & (~x + 1UL)));
}
#endif


inline int pos_gap_length_greater_than_four256(const u256 n)
{
    u256 col = (~n) & u256_significant_bits_mask(n);
    col = col & u256_shl_1(col) & u256_shl_2(col) & u256_shl_3(col);

    if (col.s0) return ctz(col.s0);
    if (col.s1) return 64 + ctz(col.s1);
    if (col.s2) return 128 + ctz(col.s2);
    if (col.s3) return 192 + ctz(col.s3);
    return 0;
}


#define N_FORBIDDEN_MINIM 90
__constant uint forbidden_minim[N_FORBIDDEN_MINIM] = {23126203, 28970509, 39985339, 46252219, 46252379, 49348795, 57279037, 57282061, 57934397, 57937421, 79970491, 90964155, 92504251, 92504411, 98042043, 98697403, 102105275, 114557501, 114560525, 115867869, 115868085, 115868221, 115868483, 115871245, 159940795, 181928123, 185008315, 185008475, 185008907, 196083899, 197394619, 204210363, 218893837, 229114429, 229117453, 231735517, 231735733, 231735869, 231736131, 231738511, 231738893, 252903611, 319881403, 363856059, 370016443, 370016603, 370017035, 392167611, 394789051, 408420539, 437784077, 458228285, 458231309, 463470813, 463471029, 463471165, 463471427, 463473807, 463474189, 505807035, 639762619, 727711931, 740032859, 740033291, 784335035, 789577915, 816840891, 875564557, 916455997, 916459021, 926941405, 926941621, 926941757, 926942019, 926944399, 1011613883, 1455423675, 1480065803, 1568669883, 1633681595, 1751125517, 1853882589, 1853882805, 1853883203, 1853885583, 2023227579, 2960130827, 3502247437, 3707767951, 4046454971};
inline int is_forbidden_minim(uint minim)
{
    if (minim < 23126203) {return 0;}

    #pragma unroll
    for (int i = 0; i < N_FORBIDDEN_MINIM; i++) {
        if (minim == forbidden_minim[i]) {
            return 1;
        }
    }
    return 0;
}

#define TOPMOSTBITSMASK 0xE000000000000000UL
#define LARGERTOPMOSTBITSMASK 0xFFFFF00000000000UL
#define  MIDDLEBITSMASK 0x0000000FF0000000UL

int pos_gap_length_greater_than_four(ulong n) {
    if (n == 0) {return 0;}

    ulong col = (~n) & (~0UL >> clz(n));  // mask off leading zeros of n

    col = (col) & (col << 1) & (col << 2) & (col << 3);

    return ctz(col);
}

inline uint bit_reverse32(uint x)
{
    x = ((x >> 1)  & 0x55555555u) | ((x & 0x55555555u) << 1);
    x = ((x >> 2)  & 0x33333333u) | ((x & 0x33333333u) << 2);
    x = ((x >> 4)  & 0x0f0f0f0fu) | ((x & 0x0f0f0f0fu) << 4);
    x = ((x >> 8)  & 0x00ff00ffu) | ((x & 0x00ff00ffu) << 8);
    x = (x >> 16) | (x << 16);
    return x;
}

inline ulong bit_reverse(ulong x)
{
    uint lo = (uint)x;
    uint hi = (uint)(x >> 32);

    return ((ulong)bit_reverse32(lo) << 32) | (ulong)bit_reverse32(hi);
}



__kernel void search_matches(const ulong min_i,
                             const ulong max_i,
                             __global ulong *matches,
                             __global uint *match_count,
                             const ulong max_matches)
{
    size_t gid = get_global_id(0);
    ulong n = min_i + (ulong)gid;

    if (n >= max_i) {
        return;
    }

    ulong o = (n << 1) | 1;
    ulong oOrig = o;

    #define STACK_SIZE 10
    #define MAX_DEPTH 10

    ulong stack_o[STACK_SIZE];
    int stack_depth[STACK_SIZE];
    int stack_ptr = 0;

    stack_o[0] = oOrig;
    stack_depth[0] = MAX_DEPTH;
    stack_ptr++;

    if (oOrig > (bit_reverse(oOrig) >> clz(oOrig))) {return;}

    while (stack_ptr) {
        
        stack_ptr--;
        ulong o = stack_o[stack_ptr];
        ulong depth = stack_depth[stack_ptr];
        

        if (EARLY_DEBUG) {
            printf("1 Started on o: %lu\n", o);
        }

        
        // run 64bit
        int count = 0;
        while (o >= oOrig && count < STEPS1 && (o & TOPMOSTBITSMASK) == 0) {
            count++;

            ulong a = o << 3;
            ulong b = o << 2;
            ulong c = o << 1;
            ulong d = o >> 1;
            o = (a | b | c | d | o) ^ (a ^ b ^ c ^ d ^ o);

            o = o >> (((o & 0xF) == 0) << 2);  // approximate shr(o, ctz(o))
        }
        o = o >> ctz(o);

        if (o < oOrig) {continue;}

        if (EARLY_DEBUG) {
            printf("2  passed run64. o: %lu\n", o);
        }

        // run 64 bit w/ periodicity and collected
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

        if (minim < oOrig) {continue;}

        if (DEBUG_CHECK) {
            printf("3  passed run64 with periodicity and col. o: %lu\n", o);
        }

        // 2. aperiodic
        if (first != o) {
            if (DEBUG_CHECK) {
                printf("4    aperiodic.\n");
            }

            count = 0;
            first = o;
            minim = o;
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

            if (minim < oOrig) {continue;}

            if (DEBUG_CHECK) {
                printf("5    passed aperiodicity. o: %lu\n", o);
            }
        }

        // 3. run 64bit NO SHIFT w/ periodicity and collected
        uint gap_pos = pos_gap_length_greater_than_four(collected);
        if (DEBUG_CHECK) {
            printf("6  3. o: %lu (col: %lu, pos %i)\n", o, collected, gap_pos);
        }
        if (gap_pos == 64 && (minim & LARGERTOPMOSTBITSMASK) == 0) {

            if (DEBUG_CHECK) {
                printf("7    no gap. col: %lu, gap_pos: %i\n", collected, gap_pos);
            }

            o = minim << 16;

            count = 0;
            first = o;
            ulong collected_no_shift = o;
            while (count < STEPS2 && (first != o || count == 0) && (o & TOPMOSTBITSMASK) == 0 && (o & 0x7) == 0) {
                count++;

                ulong a = o << 2;
                ulong b = o << 1;
                ulong c = o >> 1;
                ulong d = o >> 2;
                o = (a | b | c | d | o) ^ (a ^ b ^ c ^ d ^ o);

                collected_no_shift = collected_no_shift | o;
            }

            uint ctzcol = ctz(collected_no_shift);
            collected_no_shift = collected_no_shift >> ctzcol;
            o = o >> ctzcol;

            gap_pos = pos_gap_length_greater_than_four(collected_no_shift);

            if (DEBUG_CHECK) {
                printf("8    col: %lu, gap_pos: %i\n", collected_no_shift, gap_pos);
            }

            // 2. special glider check
            if (gap_pos == 64) {
                if (!is_forbidden_minim(minim)) {
                    if (depth && (stack_ptr < STACK_SIZE)) {
                        
                        stack_o[stack_ptr] = minim;
                        stack_depth[stack_ptr] = depth - 1;
                        stack_ptr++;
                        
                    } else {
                        ulong idx = atomic_inc(match_count);
                        if (idx < max_matches) {
                            matches[idx] = RETVAL;

                            if (RET_DEBUG_CHECK) {
                                printf("1 RETURNING: %lu. oOrig: %lu, minim: %lu, o: %lu\n", RETVAL, oOrig, minim, o);
                            }
                        }
                    }
                    continue;
                } else {
                    if (DEBUG_CHECK) {
                        printf("9      failed special glider check. o: %lu\n", o);
                    }
                    continue;
                }
            }

            if (DEBUG_CHECK) {
                printf("10    failed no shift. o: %lu\n", o);
            }
        }

        // 1. col gap
        if ((o & LARGERTOPMOSTBITSMASK) == 0) {
            ulong o1 = o & (~0UL >> (64 - gap_pos));
            ulong o2 = o >> gap_pos;
            o1 = o1 >> ctz(o1);
            o2 = o2 >> ctz(o2);

            stack_o[stack_ptr] = o1;
            stack_depth[stack_ptr] = depth - 1;
            stack_ptr++;

            stack_o[stack_ptr] = o2;
            stack_depth[stack_ptr] = depth - 1;
            stack_ptr++;

            continue;
        }


        // Top branch complete! Moving onto 256-bit evaluation
        if (DEBUG_CHECK) {
            printf("12 steps: %i\n", count);
            printf("13   256 BIT o: %lu<>%lu<>%lu<>%lu\n", 0UL, 0UL, 0UL, o);
        }

        // 2. no MAJOR gap
        u256 o256 = (u256)(o, 0, 0, 0);
        u256 first256;
        u256 minim256;
        u256 collected256;
        if (o & MIDDLEBITSMASK || count == 0) {
            if (DEBUG_CHECK) {
                printf("14  middle gap filled");
            }

            // run 256 bit
            count = 0;
            while (u256_ge_u64(o256, oOrig) && count < STEPS1 && (o256.s3 & TOPMOSTBITSMASK) == 0) {
                count++;

                u256 a = u256_shl_3(o256);
                u256 b = u256_shl_2(o256);
                u256 c = u256_shl_1(o256);
                u256 d = u256_shr_1(o256);
                o256 = (a | b | c | d | o256) ^ (a ^ b ^ c ^ d ^ o256);

                if ((o256.s0 & 0xFF) == 0) {
                    o256 = u256_shr_8(o256);  // approximate shr(o, ctz(o))
                }
            }

            if (o256.s0 == 0 && o256.s1 == 0) { o256 = (u256)(o256.s2, o256.s3, 0, 0); }
            if (o256.s0 == 0) { o256 = (u256)(o256.s1, o256.s2, o256.s3, 0); }
            o256 = u256_small_shr(o256, u256_ctz(o256));

            if (!u256_ge_u64(o256, oOrig)) {continue;}

            if (DEBUG_CHECK) {
                printf("15  256 BIT passed first run o: %lu<>%lu<>%lu<>%lu\n", o256.s3, o256.s2, o256.s1, o256.s0);
            }


            // 2. run 256 bit w/ periodicity and collected
            count = 0;
            first256 = o256;
            minim256 = o256;
            collected256 = o256;
            while (u256_ge_u64(o256, oOrig) && count < STEPS2 && (u256_ne(first256, o256) || count == 0) && (o256.s3 & TOPMOSTBITSMASK) == 0) {
                count++;

                u256 a = u256_shl_3(o256);
                u256 b = u256_shl_2(o256);
                u256 c = u256_shl_1(o256);
                u256 d = u256_shr_1(o256);
                o256 = (a | b | c | d | o256) ^ (a ^ b ^ c ^ d ^ o256);

                o256 = u256_small_shr(o256, u256_ctz(o256));
                minim256 = u256_min(minim256, o256);
                collected256 = collected256 | o256;
            }

            if (o256.s0 == 0 && o256.s1 == 0) { o256 = (u256)(o256.s2, o256.s3, 0, 0); }
            if (o256.s0 == 0) { o256 = (u256)(o256.s1, o256.s2, o256.s3, 0); }
            o256 = u256_small_shr(o256, u256_ctz(o256));

            if (!u256_ge_u64(o256, oOrig)) {continue;}

            if (DEBUG_CHECK) {
                printf("16  256 BIT passed second run o: %lu<>%lu<>%lu<>%lu\n", o256.s3, o256.s2, o256.s1, o256.s0);
            }

            // 3. run 256 bit NO SHIFT w/ periodicity and collected
            gap_pos = pos_gap_length_greater_than_four256(collected256);
            if (gap_pos == 256 && (o256.s3 == 0)) {

                o256 = (u256)(0, o256.s0, o256.s1, o256.s2);

                count = 0;
                first256 = o256;
                collected256 = o256;
                while (count < STEPS2 && (u256_ne(first256, o256) || count == 0) && (o256.s3 & TOPMOSTBITSMASK) == 0 && (o256.s0 & 0x7) == 0) {
                    count++;

                    u256 a = u256_shl_2(o256);
                    u256 b = u256_shl_1(o256);
                    u256 c = u256_shr_1(o256);
                    u256 d = u256_shr_2(o256);
                    o256 = (a | b | c | d | o256) ^ (a ^ b ^ c ^ d ^ o256);

                    collected256 = collected256 | o256;
                }

                while (collected256.s0 & 1) {o256 = u256_shr_1(o256); collected256 = u256_shr_1(collected256);}

                gap_pos = pos_gap_length_greater_than_four256(collected256);

                if (gap_pos == 256) {
                    if (depth && (stack_ptr < STACK_SIZE)) {
                        if (!(minim256.s3 || minim256.s2 || minim256.s1)) {
                            stack_o[stack_ptr] = minim256.s0;
                        } else {
                            stack_o[stack_ptr] = minim;
                        }
                        stack_depth[stack_ptr] = depth - 1;
                        stack_ptr++;
                        continue;
                        
                    } else {
                        ulong idx = atomic_inc(match_count);
                        if (idx < max_matches) {
                            if (!(minim256.s3 || minim256.s2 || minim256.s1)) {
                                matches[idx] = RETVAL256;
                            } else {
                                matches[idx] = RETVAL;
                            }

                            if (RET_DEBUG_CHECK_256) {
                                printf("4 RETURNING: %lu. oOrig: %lu, minim: %lu, o: %lu\n", RETVAL, oOrig, minim, o);
                            }
                        }
                        continue;
                    }
                }
            }
        } else {
            // gap_pos = pos_gap_length_greater_than_four256((u256)(collected, 0, 0, 0));

            if (DEBUG_CHECK) {
                printf("17  middle gap not filled. col: %lu, gap_pos: %i\n", collected, gap_pos);
            }
        }

        // 1. MAJOR gap - - OR - - 1. col gap
        if (DEBUG_CHECK) {
            printf("18  256 BIT SPLIT major gap or col gap at o: %lu<>%lu<>%lu<>%lu, gap: %i\n", o256.s3, o256.s2, o256.s1, o256.s0, gap_pos);
        }

        u256 o2561 = u256_shr_ctz(o256 & u256_low_bits_mask(gap_pos));
        u256 o2562 = u256_shr_ctz(u256_shr(o256, gap_pos));

        if (!(u256_ge_u64(o2561, oOrig) || u256_ge_u64(o2562, oOrig))) {continue;}


        if (DEBUG_CHECK) {
            printf("19  o1: %lu<>%lu<>%lu<>%lu, gap: %i\n", o2561.s3, o2561.s2, o2561.s1, o2561.s0, gap_pos);
            printf("20  o2: %lu<>%lu<>%lu<>%lu, gap: %i\n", o2562.s3, o2562.s2, o2562.s1, o2562.s0, gap_pos);
        }

        // run paired 256 bit w/ periodicity
        count = 0;
        first256 = o2561;
        minim256 = o2561;
        collected256 = o2561;
        while (u256_ge_u64(o2561, oOrig) && count < STEPS2 && (u256_ne(first256, o2561) || count == 0) && (o2561.s3 & TOPMOSTBITSMASK) == 0) {
            count++;

            u256 a = u256_shl_3(o2561);
            u256 b = u256_shl_2(o2561);
            u256 c = u256_shl_1(o2561);
            u256 d = u256_shr_1(o2561);
            o2561 = (a | b | c | d | o2561) ^ (a ^ b ^ c ^ d ^ o2561);

            o2561 = u256_small_shr(o2561, u256_ctz(o2561));
            minim256 = u256_min(minim256, o2561);
            collected256 = collected256 | o2561;
        }

        if (u256_ge_u64(o2561, oOrig)) {
            if (depth && (stack_ptr < STACK_SIZE)) {
                if (!(minim256.s3 || minim256.s2 || minim256.s1)) {
                    stack_o[stack_ptr] = minim256.s0;
                } else {
                    stack_o[stack_ptr] = minim;
                }
                stack_depth[stack_ptr] = depth - 1;
                stack_ptr++;
                
            } else {
                ulong idx = atomic_inc(match_count);
                if (idx < max_matches) {
                    if (!(minim256.s3 || minim256.s2 || minim256.s1)) {
                        matches[idx] = RETVAL256;
                    } else {
                        matches[idx] = RETVAL;
                    }

                    if (RET_DEBUG_CHECK_256) {
                        printf("5 RETURNING: %lu. oOrig: %lu, minim: %lu, o: %lu\n", RETVAL256, oOrig, minim, o);
                    }
                }
            }
        }
        

        // run paired 256 bit w/ periodicity
        count = 0;
        first256 = o2562;
        minim256 = o2562;
        collected256 = o2562;
        while (u256_ge_u64(o2562, oOrig) && count < STEPS2 && (u256_ne(first256, o2562) || count == 0) && (o2562.s3 & TOPMOSTBITSMASK) == 0) {
            count++;

            u256 a = u256_shl_3(o2562);
            u256 b = u256_shl_2(o2562);
            u256 c = u256_shl_1(o2562);
            u256 d = u256_shr_1(o2562);
            o2562 = (a | b | c | d | o2562) ^ (a ^ b ^ c ^ d ^ o2562);

            o2562 = u256_small_shr(o2562, u256_ctz(o2562));
            minim256 = u256_min(minim256, o2562);
            collected256 = collected256 | o2562;
        }

        if (u256_ge_u64(o2562, oOrig)) {
            if (depth && (stack_ptr < STACK_SIZE)) {
                if (!(minim256.s3 || minim256.s2 || minim256.s1)) {
                    stack_o[stack_ptr] = RETVAL256;
                } else {
                    stack_o[stack_ptr] = minim;
                }
                stack_depth[stack_ptr] = depth - 1;
                stack_ptr++;
                
            } else {
                ulong idx = atomic_inc(match_count);
                if (idx < max_matches) {
                    if (!(minim256.s3 || minim256.s2 || minim256.s1)) {
                        matches[idx] = RETVAL256;
                    } else {
                        matches[idx] = RETVAL;
                    }

                    if (RET_DEBUG_CHECK_256) {
                        printf("6 RETURNING: %lu. oOrig: %lu, minim: %lu, o: %lu\n", RETVAL256, oOrig, minim, o);
                    }
                }
            }
        }

    }

    return;
}