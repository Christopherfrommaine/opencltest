
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
        // mul_hi returns the upper 64 bits of the 128-bit product.
        // If non-zero, the result overflows a ulong.
        if (mul_hi(o, a) != 0UL) {
            return 0; // overflow sentinel
        }
        o = o * a;
    }
    return o;
}

ulong from_packed_integer_radix(u256 xOrig) {
    u256 x = xOrig;
    ulong res = 0;
    uint count = 0;

    while (!u256_is_zero(x)) {
        ulong digit = x.s0 & BOTTOMBITSMASK;
        ulong power = exponent(K, count);

        // For count > 0, K^count is never legitimately 0 (assuming K > 1),
        // so 0 here means exponent() detected an overflow.
        if (count > 0 && power == 0UL) {
            return 0;
        }

        // Check if digit * power overflows.
        if (mul_hi(digit, power) != 0UL) {
            return 0;
        }

        ulong term = digit * power;

        // Check if res + term overflows (standard unsigned wrap detection).
        if (res + term < res) {
            return 0;
        }

        res += term;
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
#define PRINTIF_CONDITION_VALUE 1198059
#define PRINTIF_CONDITION n == PRINTIF_CONDITION_VALUE

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

    /*
    new algo pseudocode:

    let p be the period of the solution

    carun = RunCA(init);
    
    if Join[RunCA(init[[;;start]]), pattern, RunCA(init[[end;;]])] == 
       RunCA(Join[init[[;;start]], pattern, init[[end;;]]])

    
    that is, if infixing the pattern is associative under evolution

    for start_pos:
        for pattern_len:

            pattern = ...
            if basic_checks {return;}

            full = o;
            constructed = o[[;;left]] <> o[[right;;]]
            for i in period:
                update(full)
                update(constructed)

                if constructed[[;;left]] <> pattern <> constructed[[;;right]] != full {
                    break
                }

    */

    return oOrig;

    PRINTIF("STARTING canonicalize_horizontally_repeating_solutions\n");
    u256 o = oOrig;
    u256 col;
    u256 minim;
    u256 first;
    uint count;
    RUN(100);

    if (u256_eq(o, first) && count == 1) {
        if (u256_ne(o, minim)) {
            PRINTIF("ASSERT FALSE!!!! 1");
        }

        // if periodic
        ulong bitlen = BITS * ((256 - u256_clz(o)) / BITS);
        PRINTIF("  bitlen: %lu\n", bitlen);

        for (int start_pos = 0; start_pos < bitlen; start_pos += BITS) {
            for (int pattern_len = BITS; pattern_len <= (bitlen - start_pos) / 2; pattern_len += BITS) {
                PRINTIF("start_pos: %lu, pattern_len: %lu\n", start_pos, pattern_len);

                o = u256_shr(first, start_pos);
                u256 mask = u256_low_bits_mask(pattern_len);
                u256 pattern = o & mask;

                PRINTIF("  o: ");
                PRINTIF256(o);
                PRINTIF("  mask: ");
                PRINTIF256(mask);
                PRINTIF("  pattern: ");
                PRINTIF256(pattern);

                if (u256_is_zero(pattern)) { continue; }

                int pattern_reps = 0;
                while (u256_is_zero(mask & (o ^ pattern))) {
                    pattern_reps++;
                    o = u256_shr(o, pattern_len);
                }

                PRINTIF(" Pattern reps: %lu\n", pattern_reps);

                if (pattern_reps >= 2) {
                    int count_reps = 0;
                    while (count_reps * pattern_len <= BITS * (R + 1)) {
                        o = u256_shl(o, pattern_len) | pattern;
                        count_reps++;
                    }

                    PRINTIF("%lu count reps\n  o: ", count_reps);
                    PRINTIF256(o);

                    u256 transient = first & u256_low_bits_mask(start_pos);
                    o = transient | u256_shl(o, start_pos);

                    PRINTIF("  transient: ");
                    PRINTIF256(transient);
                    PRINTIF("  o: ");
                    PRINTIF256(o);

                    u256 first_temp = first;
                    RUN(100);
                    if (u256_eq(o, first)) {
                        PRINTIF("RETURNING\n");
                        return oOrig;  // TODO! change this back to `return o;`
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
        ulong unpacked = from_packed_integer_radix(minim); \
        if (unpacked) { \
            PRINTIF("  - returning 1: %lu\n", unpacked); \
            matches[idx] = unpacked; \
        } else { \
            PRINTIF("  - returning 2: %lu\n", n); \
            matches[idx] = n; \
        } \
        if (matches[idx] == PRINTIF_CONDITION_VALUE) {printf("(from n: %lu)\n", n);} \
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
        ulong sss_steps = MINIMUM_STEPS_REQ;

        PRINTIF("1.0.0 (depth: %u)\n  oStart = ", depth);
        PRINTIF256(oStart);

        uint count;
        u256 first;
        u256 minim;
        u256 col;

        RUN(100);
        if (u256_lt(minim, oOrig)) { continue; }

        PRINTIF("1.0.1\n  count = %u, o = ", count);
        PRINTIF256(o);
        
        if (u256_eq(o, first)) {
            // periodic
            PRINTIF("1.1.0 (periodic)\n");

            o = minim;
            sss_steps = count;
        } else if (o.s3 & TOPMOSTBITSMASK) {
            // width exceeded
            PRINTIF("1.2.0 (width exceeded at step %lu)\n", count);
            o = oStart;
            if (count > sss_steps + 3) {
                PRINTIF("1.2.1 (backtracking and running for %lu steps)\n", count - sss_steps - 3);
                RUN(count - sss_steps - 3);
            }
        } else {
            // unfinished
            PRINTIF("1.3.0 (unfinished)\n");

            ulong totalcount = count;
            u256 absolute_minim = minim;
            bool get_a_new_one_off_the_stack = false;
            bool go_onto_doing_sss = false;
            for (int i = 6; i < 13; i++) {

                ulong maxsteps = 1 << i;

                RUN(maxsteps);

                absolute_minim = u256_min(absolute_minim, minim);

                totalcount += count;

                PRINTIF("  maxsteps: %lu, count: %lu, o: ", maxsteps, count);
                PRINTIF256(o);
                
                if (u256_lt(minim, oOrig)) {
                    // die-off
                    PRINTIF("1.3.1 (die-off)\n");
                    get_a_new_one_off_the_stack = true;
                    break;
                } else if (u256_eq(first, o)) {
                    // periodic
                    PRINTIF("1.3.2 (periodic)\n");
                    go_onto_doing_sss = true;
                    o = minim;
                    sss_steps = count;
                    break;
                } else if (o.s3 & TOPMOSTBITSMASK) {
                    // width exceeded
                    PRINTIF("1.3.3 (width exceeded)\n");
                    
                    o = oStart;
                    if (totalcount > sss_steps + 3) {
                        // backtrack to find the best possible cantidate
                        ulong backtracking_steps = totalcount - sss_steps - 3;
                        
                        PRINTIF("1.3.3.1 (count: %lu, totalcount: %lu, backtracking_steps: %lu)\n  o_before: ", count, totalcount, backtracking_steps);
                        PRINTIF256(o);

                        RUN(backtracking_steps);
                        
                        PRINTIF("  o_after: ");
                        PRINTIF256(o);
                    }

                    go_onto_doing_sss = true;
                    break;
                }
            }
            if (get_a_new_one_off_the_stack) {
                continue;
            } else if (!go_onto_doing_sss) {
                // unfinished (after all that? wow. I think that this is pretty unlikely...)
                PRINTIF("1.4.0 (die-off)\n");

                depth = 0;
                RECURSE(absolute_minim);
            }
        }

        PRINTIF("2.0.0 (count: %lu, sss_steps: %lu)\n  o: ", count, sss_steps);
        PRINTIF256(o);

        if (count >= sss_steps) {
            // split separate solutions
            PRINTIF("2.1.0 (split separate solutions)\n");

            // Full split separate solutions algorithm
            uint gap_pos = 0;
            bool finished = false;
            u256 lower_mask = U256_ZERO;
            u256 last = U256_ZERO;
            while (gap_pos < 256 && !finished) {
                PRINTIF("  2.1.1\n");

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

                PRINTIF("  2.1.2 (passed pre-checks)\n");

                bool splittable = true;
                for (uint i = 0; i <= MINIMUM_STEPS_REQ; i++) {
                    update256(&o_full );
                    update256(&o_upper);
                    update256(&o_lower);

                    PRINTIF("  (i: %u)\n", i);
                    PRINTIF("    o_full: ");
                    PRINTIF256(o_full);
                    PRINTIF("    o_upper: ");
                    PRINTIF256(o_upper);
                    PRINTIF("    o_lower: ");
                    PRINTIF256(o_lower);

                    if (u256_ne(o_full, o_upper ^ o_lower) || u256_is_zero(o_upper) || u256_is_zero(o_lower)) {
                        PRINTIF("  2.1.2.1 (unsplittable due to wrong answer)\n");
                        PRINTIF("    Expected: ");
                        PRINTIF256(o_full);
                        PRINTIF("    Resulted: ");
                        PRINTIF256(o_upper ^ o_lower)
                        PRINTIF("    i: %u\n", i);
                        splittable = false;
                        break;
                    }

                    if ((o_full.s3 & TOPMOSTBITSMASK) != 0) {
                        PRINTIF("  2.1.2.2 (width exceeded)\n");
                        PRINTIF("    i: %u\n", i);

                        uint ctzmin = min(u256_ctz(o_upper), u256_ctz(o_lower)) / BITS;
                        PRINTIF("1: %lu, 2: %lu, 3: %lu\n", u256_ctz(o_upper), u256_ctz(o_lower), ctzmin);
                        o_full = u256_shr(o_full, BITS * ctzmin);
                        if ((o_full.s3 & TOPMOSTBITSMASK) != 0) {
                            PRINTIF("  2.1.2.3 (width exceeded unavoidably)\n");

                            splittable = false;  // can be changed...
                            break;
                        } else {
                            PRINTIF("    Shifting by %lu cells (%lu bits)\n", ctzmin, BITS * ctzmin);
                        }

                        o_lower = u256_shr(o_lower, BITS * ctzmin);
                        o_upper = u256_shr(o_upper, BITS * ctzmin);

                        PRINTIF("    shifted lower: ");
                        PRINTIF256(o_lower);
                        PRINTIF("    shifted upper: ");
                        PRINTIF256(o_upper); 
                    }
                }

                if (splittable) {
                    PRINTIF("2.1.3.1 (splittable)\n");

                    o_lower = u256_shr_ctz_bits(o_lower);
                    o_upper = u256_shr_ctz_bits(o_upper);

                    RECURSE(o_lower);
                    RECURSE(o_upper);

                    finished = true;
                    
                    break;
                } else {
                    PRINTIF("  2.1.3.2 (unsplittable this round)\n");
                }
            }

            // Nothing more we can do! Therefore the solution is valid!
            if (!finished) {
                PRINTIF("2.1.0.1 (unsplittable and finished)\n");

                depth = 0;
                RECURSE(o);
                continue;
            }
        } else {
            // coarse splitting attempt
            PRINTIF("2.2.0 (coarse splitting)\n");

            u256 blurred = U256_ZERO;

            for (int i = 0; i < BITS; i++) {
                blurred = blurred | (NTHBITSMASK & u256_shr(col, i));
            }
            PRINTIF("3.2.1.0: "); PRINTIF256(o);
            PRINTIF("3.2.1.1: "); PRINTIF256(blurred);

            if (u256_is_zero(u256_shr(blurred, BITS * (u256_ctz(~blurred) / BITS)))) {
                PRINTIF("3.2.1.2: ");

                blurred = U256_ZERO;
                for (int i = 0; i < BITS; i++) {
                    blurred = blurred | (NTHBITSMASK & u256_shr(col, i));
                }

                PRINTIF("3.2.1.3: "); PRINTIF256(o);
                PRINTIF("3.2.1.4: "); PRINTIF256(blurred);
            }

            for (int i = 0; i < BITS; i++) {
                blurred = blurred | u256_shl(blurred, i);
            }
            PRINTIF("3.2.1.5: "); PRINTIF256(blurred);
            u256 blurred_temp = blurred;
            for (int i = 0; i < 2 * R + 1; i++) {
                blurred = blurred | u256_shl(blurred_temp, BITS * i);
            }
            PRINTIF("3.2.1.6: "); PRINTIF256(blurred);
            blurred = ~blurred;

            PRINTIF("3.2.2\n");

            // gap pos greater than 2 * R
            uint pos = 0;
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
            }
            if (u256_is_zero(blurred)) { pos = 256; }


            PRINTIF("2.2.2\n");
            PRINTIF("  pos: %lu\n", pos);


            if (pos == 256) {
                PRINTIF("2.2.3.1\n");

                depth = 0;
                RECURSE(oOrig);
                continue;
                
            } else {
                PRINTIF("2.2.3.2\n");

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