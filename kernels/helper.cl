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
#define U256_MAX ((u256)(0xFFFFFFFFFFFFFFFFUL, 0xFFFFFFFFFFFFFFFFUL, 0xFFFFFFFFFFFFFFFFUL, 0xFFFFFFFFFFFFFFFFUL))

inline int u256_is_zero(const u256 x)
{
    return !(x.s0 | x.s1 | x.s2 | x.s3);
}

inline int u256_is_nonzero(const u256 x)
{
    return (x.s0 | x.s1 | x.s2 | x.s3);
}

inline int u256_ne(const u256 a, const u256 b)
{
    return u256_is_nonzero(a ^ b);
}

inline int u256_eq(const u256 a, const u256 b)
{
    return u256_is_zero(a ^ b);
}

inline int u256_ge_u64(const u256 a, const ulong b)
{
    return (a.s1 | a.s2 | a.s3) || (a.s0 >= b);
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

inline uint u256_clz(const u256 x)
{
    if (u256_is_zero(x)) {return 256;}
    if (x.s3 != 0UL) {return clz(x.s3);}
    if (x.s2 != 0UL) {return 64u + clz(x.s2);}
    if (x.s1 != 0UL) {return 128u + clz(x.s1);}
    if (x.s0 != 0UL) {return 192u + clz(x.s0);}
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

inline bool u256_fits_in_ulong(const u256 a)
{
    return !(a.s1 | a.s2 | a.s3);
}



inline u256 u256_shl_bits_lt64(const u256 x, const uint n)
{
    if (n == 0u) return x;

    const uint r = 64u - n;

    return (u256)(
        x.s0 << n,
        (x.s1 << n) | (x.s0 >> r),
        (x.s2 << n) | (x.s1 >> r),
        (x.s3 << n) | (x.s2 >> r)
    );
}

inline u256 u256_shl(const u256 x, const uint n)
{
    const uint q = n >> 6;
    const uint r = n & 63u;

    u256 y =
        (q == 0u) ? x :
        (q == 1u) ? (u256)(0UL, x.s0, x.s1, x.s2) :
        (q == 2u) ? (u256)(0UL, 0UL, x.s0, x.s1) :
        (q == 3u) ? (u256)(0UL, 0UL, 0UL, x.s0) :
                    U256_ZERO;

    return u256_shl_bits_lt64(y, r);
}


u256 u256_reverse_bits(u256 x) {
    return (u256)(reverse_bits(x.s3), reverse_bits(x.s2), reverse_bits(x.s1), reverse_bits(x.s0));
}