
TEMPLATE_BITS
TEMPLATE_K
TEMPLATE_R

TEMPLATE_SYMMETRIC

TEMPLATE_TOPMOSTBITSMASK
TEMPLATE_BOTTOMMOSTBITSMASK
TEMPLATE_BOTTOMBITSMASK

TEMPLATE_NTHBITSMASK

TEMPLATE_update256

#define STACK_SIZE 10
#define MAX_STACK_DEPTH 10

#define MINIMUM_STEPS_REQ 20

#if SYMMETRIC
#define RES_REV_SET ulong res_rev = 0;
#define RES_REV_SHL res_rev = res_rev << BITS;
#define RES_REV_COL res_rev = res_rev | addition;
#define RES_REV_RET if (res_rev < res) { return 0; }
#else
#define RES_REV_SET 
#define RES_REV_SHL 
#define RES_REV_COL 
#define RES_REV_RET 
#endif


ulong inline generate_packed_integer_radix(ulong idxOrig) {
    ulong n = idxOrig;
    if (BITS == 1) {return idxOrig;}

    ulong idx = idxOrig;
    ulong res = 0;
    RES_REV_SET
    uint count = 0;

    while (idx) {
        RES_REV_SHL
        ulong addition = idx % K;
        res = res | (addition << count);
        RES_REV_COL

        count += BITS;
        idx = idx / K;
    }

    RES_REV_RET

    return res;
}

ulong inline exponent(ulong a, ulong b) {
    ulong o = 1;
    for (int i = 0; i < b; i++) {
        o = o * a;
    }
    return o;
}

ulong inline from_packed_integer_radix(u256 xOrig) {
    u256 x = xOrig;
    ulong res = 0;
    uint count = 0;

    while (!u256_is_zero(x)) {
        res += (x.s0 & BOTTOMBITSMASK) * exponent(K, count);
        x = u256_shr(x, BITS);
        count++;
    }

    return res;
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

inline u256 u256_shr_ctz_bits(const u256 x)
{
    if (x.s0 & BOTTOMBITSMASK) return x;
    return u256_shr(x, BITS * (u256_ctz(x) / BITS));
}


#define DEBUG 1
#define PRINTIF_CONDITION_VALUE 48822395

#define PRINTIF_CONDITION n == PRINTIF_CONDITION_VALUE
// n == 618647

#if DEBUG
#define PRINTIF(...) do { \
    if (PRINTIF_CONDITION) { \
        printf(__VA_ARGS__); \
    } \
} while(0)
#else
#define PRINTIF(...)
#endif

#define PRINTIF256(o) PRINTIF("(u256)(%lu, %lu, %lu, %lu)\n", (o).s3, (o).s2, (o).s1, (o).s0);


#define RUN(steps) count = 0; first = o; minim = U256_MAX; col = o; while (1) { \
    if (u256_lt(o, minim)) { \
        minim = o; \
        if (u256_lt(o, oOrig)) { \
            break; \
        } \
    } \
    if ((count > (steps)) | (o.s3 & TOPMOSTBITSMASK)) { \
        break; \
    } \
    update256(&o); \
    o = u256_shr_ctz_bits(o); \
    if (u256_eq(o, first)) { \
        break; \
    } \
    col = col | o; \
    count++; \
}

#define RUN_NOSHIFT(steps) count = 0; first = o; col = o; while (1) { \
    if ((count > steps) | (o.s3 & TOPMOSTBITSMASK) | (o.s0 & BOTTOMMOSTBITSMASK)) { \
        break; \
    } \
    update256(&o); \
    if (u256_eq(o, first)) { \
        break; \
    } \
    col = col | o; \
    count++; \
}

// bool inline check_valid_packed_integer(ulong x) {
//     if ((x & ((1 << BITS) - 1)) == 0) {
//         return false;
//     }

//     return !(NTHBITSMASK.s0 & (TEMPLATE_VALID_PACKED_INTEGER));
// }

u256 canonicalize_horizontally_repeating_solutions(ulong n, u256 oOrig) {
    u256 o = oOrig;
    u256 col;
    u256 minim;
    u256 first;
    uint count;
    RUN(100);

    if (u256_eq(o, first)) {
        // if periodic

        for (int start_pos = 0; start_pos < 256; start_pos += BITS) {
            for (int pattern_len = 0; pattern_len < (256 - start_pos) / 2; pattern_len += BITS) {
                o = u256_shr(first, start_pos);
                u256 mask = u256_low_bits_mask(pattern_len);
                u256 pattern = o & mask;

                if (u256_is_zero(pattern)) {continue;}

                int pattern_reps = 0;
                while (u256_is_zero(mask & (o ^ pattern))) {
                    pattern_reps++;
                    o = u256_shr(o, pattern_len);
                }

                if (pattern_reps >= 2) {
                    int count_reps = 0;
                    while (count_reps * pattern_len <= BITS * (R + 1)) {
                        o = u256_shl(o, pattern_len) | pattern;
                        count_reps++;
                    }

                    u256 transient = first & u256_low_bits_mask(start_pos);
                    o = transient | u256_shl(o, start_pos);

                    u256 first_temp = first;
                    RUN(100);
                    if (u256_eq(o, first)) {
                        return o;
                    }
                }

            }
        }
    }

    return oOrig;
}

// override Override pverride overide
#define RECURSE(retval) do { \
PRINTIF("recursing...   retval = "); \
PRINTIF256(retval); \
if (depth && stack_ptr < STACK_SIZE) { \
    PRINTIF("  - pushing onto stack: "); \
    PRINTIF256(retval); \
    stack_o[stack_ptr] = retval; \
    stack_depth[stack_ptr] = depth - 1; \
    stack_ptr++; \
} else { \
    ulong idx = atomic_inc(match_count); \
    if (idx <= max_matches) { \
        if (u256_fits_in_ulong(minim)) { \
            PRINTIF("  - returning 1: %lu\n", from_packed_integer_radix(minim)); \
            matches[idx] = from_packed_integer_radix(minim); \
        } else { \
            PRINTIF("  - returning 2: %lu\n", n); \
            matches[idx] = n; \
        } \
        if (matches[idx] == PRINTIF_CONDITION_VALUE) {printf("(from n: %lu)\n", n);} \
        /* matches[idx] = (n << 32) | canonicalize_horizontally_repeating_solutions(n, minim).s0; */ \
    } \
} \
} while(0)

__kernel void search_matches(const ulong min_i,
                             const ulong max_i,
                             __global ulong *matches,
                             __global uint *match_count,
                             const ulong max_matches)
{
    size_t gid = get_global_id(0);
    ulong n = min_i + (ulong)gid;

    PRINTIF("STARTING WITH INITIAL INDEX n = %lu\n- - - - -\n", n);

    if (n > max_i) {return;}

    ulong oOrig64 = generate_packed_integer_radix(n);
    if (!oOrig64) {return;}
    u256 oOrig = (u256)(oOrig64, 0, 0, 0);

    u256 stack_o[STACK_SIZE];
    ushort stack_depth[STACK_SIZE];
    ushort stack_ptr = 0;

    stack_o[stack_ptr] = oOrig;
    stack_depth[stack_ptr] = MAX_STACK_DEPTH;
    stack_ptr++;

    while (stack_ptr) {
        stack_ptr--;
        u256 oStart = stack_o[stack_ptr];
        ushort depth = stack_depth[stack_ptr];
        u256 o = oStart;

        PRINTIF("1.0.0 (depth: %u)\n  oStart = ", depth);
        PRINTIF256(oStart);

        uint count;
        u256 first;
        u256 minim;
        u256 col;

        ulong maxSteps = 100 + (1 << ((MAX_STACK_DEPTH - depth) / 2));
        PRINTIF("  maxSteps: %lu\n", maxSteps);
        RUN(maxSteps);
        uint count_original = count;

        if (u256_lt(minim, oOrig)) { continue; }

        PRINTIF("1.1.0\n  count = %u, o = ", count);
        PRINTIF256(o);

        bool collected_is_accurate = false;
        bool meets_minimum_steps_req = false;  // guarentees that oStart can be run for enough steps to determine separation
        if (!(o.s3 | o.s2) && u256_eq(o, first)) {
            PRINTIF("2.1.0\n");
            
            // re-run to find minim and col
            RUN(count);

            // periodic
            o = u256_shl(o, 32);
            RUN_NOSHIFT(maxSteps);

            PRINTIF("  count: %lu, o: ", count);
            PRINTIF256(o);

            if (count > MINIMUM_STEPS_REQ || u256_eq(o, first)) {
                PRINTIF("2.1.1\n");

                // periodic -> split separate solutions
                meets_minimum_steps_req = true;
                collected_is_accurate = true;
            }
        } else if (!(o.s3 & TOPMOSTBITSMASK) && !u256_eq(o, first)) {
            PRINTIF("2.2.0\n");

            u256 o_temp = o;
            maxSteps = 100 + (1 << ((MAX_STACK_DEPTH - depth) / 2));
            RUN(maxSteps);
            if (u256_lt(minim, oOrig)) { continue; }

            if (u256_eq(first, o)) {
                PRINTIF("2.2.1 (stabalized to periodic)\n");
                RECURSE(minim);
                continue;
            }

            if (!(o.s3 & TOPMOSTBITSMASK)) {
                PRINTIF("2.2.2 (wow this thing's still going)\n");
                RECURSE(o);
                continue;
            }

            o = o_temp;

            if (count_original + count > MINIMUM_STEPS_REQ) {
                PRINTIF("2.2.3 (ready to be split)\n");
                meets_minimum_steps_req = true;
            }
        } else {
            PRINTIF("2.3.0\n");
            if (count > MINIMUM_STEPS_REQ) {
                PRINTIF("2.3.1\n");
                meets_minimum_steps_req = true;
            }
        }

        // else: 
        o = u256_shr_ctz_bits(o);
        PRINTIF("3.0.0\n  o: ");
        PRINTIF256(o);

        if (meets_minimum_steps_req) {
            PRINTIF("3.1.0\n");
            // o = oStart;

            // Full split separate solutions algorithm
            uint gap_pos = 0;
            bool finished = false;
            u256 lower_mask = U256_ZERO;
            u256 last = U256_ZERO;
            while (gap_pos < 256 && !finished) {
                PRINTIF("  3.1.1\n");

                gap_pos += BITS;
                lower_mask = u256_shl(lower_mask, BITS);
                lower_mask.s0 = lower_mask.s0 | BOTTOMBITSMASK;
                
                u256 o_lower = o &  lower_mask;
                u256 o_upper = o & ~lower_mask;
                u256 o_full  = o;

                PRINTIF("    gap pos: %lu\n", gap_pos);
                PRINTIF("    lower_mask: "); PRINTIF256(lower_mask);
                PRINTIF("    o_lower: "); PRINTIF256(o_lower);
                PRINTIF("    o_upper: "); PRINTIF256(o_upper);
                PRINTIF("    o_full: "); PRINTIF256(o_full);

                if (u256_eq(last, o_lower)) { continue; }
                last = o_lower;

                if (u256_is_zero(o_lower)) { continue; }
                if (u256_is_zero(o_upper)) { break; }

                PRINTIF("  3.1.2\n");

                bool splittable = true;
                for (uint i = 0; i <= MINIMUM_STEPS_REQ; i++) {
                    update256(&o_full );
                    update256(&o_upper);
                    update256(&o_lower);

                    if (u256_ne(o_full, (o_upper ^ o_lower)) || u256_is_zero(o_upper) || u256_is_zero(o_lower)) {
                        PRINTIF("    i: %u\n", i);
                        PRINTIF("  3.1.2.1\n");
                        splittable = false;
                        break;
                    }

                    if ((o_full.s3 & TOPMOSTBITSMASK) != 0) {
                        PRINTIF("    i: %u\n", i);
                        PRINTIF("  3.1.2.2\n");

                        uint ctzmin = min(u256_ctz(o_upper), u256_ctz(o_lower)) / BITS;
                        o_full = u256_shr(o_full, BITS * ctzmin);
                        if ((o_full.s3 & TOPMOSTBITSMASK) != 0) {
                            PRINTIF("  3.1.2.3\n");

                            splittable = true;
                            break;
                        }

                        o_lower = u256_shr(o_lower, ctzmin);
                        o_upper = u256_shr(o_upper, ctzmin);
                    }
                }

                if (splittable) {
                    PRINTIF("3.1.3.1\n");

                    o_lower = u256_shr_ctz_bits(o_lower);
                    o_upper = u256_shr_ctz_bits(o_upper);

                    RECURSE(o_lower);
                    RECURSE(o_upper);

                    finished = true;
                    
                    break;
                } else {
                    PRINTIF("  3.1.3.2\n");
                }
            }

            // Nothing more we can do! Therefore the solution is valid!
            if (!finished) {
                PRINTIF("3.1.0.1\n");

                // depth = 0;
                RECURSE(o);
                continue;
            }

        } else {
            PRINTIF("3.2.0\n");

            u256 blurred = U256_ZERO;

            u256 o_temp = o;
            if (collected_is_accurate) {o_temp = col;}

            for (int i = 0; i < BITS; i++) {
                blurred = blurred | (NTHBITSMASK & u256_shr(o_temp, i));
            }

            PRINTIF("3.2.1.0: ");
            PRINTIF256(o);

            PRINTIF("3.2.1.1: ");
            PRINTIF256(blurred);

            for (int i = 0; i < BITS; i++) {
                blurred = blurred | u256_shl(blurred, i);
            }

            PRINTIF("3.2.1.2: ");
            PRINTIF256(blurred);

            u256 blurred_temp = blurred;
            for (int i = 0; i < 2 * R + 1; i++) {
                blurred = blurred | u256_shl(blurred_temp, BITS * i);
            }

            PRINTIF("3.2.1.3: ");
            PRINTIF256(blurred);
            
            blurred = ~blurred;

            PRINTIF("3.2.2\n");

            // gap pos greater than 2 * R
            uint pos = 0;
            count = 0;
            while (!u256_is_zero(blurred)) {
                ulong ctz_temp = u256_ctz(blurred) / BITS;
                pos = pos + ctz_temp;
                blurred = ~u256_shr(blurred, BITS * ctz_temp);


                ctz_temp = u256_ctz(blurred) / BITS;
                if (ctz_temp >= 2 * R && count) {
                    break;
                } else {
                    pos += ctz_temp;
                    blurred = u256_shr(~blurred, BITS * ctz_temp);
                }

                count++;
                // if (count > 100) {return;}
            }
            if (u256_is_zero(blurred)) { pos = 256; }


            PRINTIF("3.2.2\n");
            PRINTIF("  pos: %lu\n", pos);


            if (pos == 256) {
                PRINTIF("3.2.3.1\n");

                depth = 0;
                RECURSE(oOrig);
                continue;
                
            } else {
                PRINTIF("3.2.3.2\n");

                u256 mask = u256_low_bits_mask(pos);
                u256 right = o & mask;
                u256 left = o & ~mask;
                left = u256_shr_ctz_bits(left);

                RECURSE(right);
                RECURSE(left);
                continue;
            }
        }
        
    }

}