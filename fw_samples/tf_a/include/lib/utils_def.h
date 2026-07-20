#ifndef LIB_UTILS_DEF_H
#define LIB_UTILS_DEF_H
#include <stdint.h>
#define U(x) x##ULL
#define UL(x) x##ULL
#define BIT_32(x) (1U << (x))
#define MIN_SGI_ID 0
#define EXTRACT(_field, _val) ((int)(_val))
#define DIV_ROUND_UP_2EVAL(n, d) (((n) + (d) - 1) / (d))
#endif
