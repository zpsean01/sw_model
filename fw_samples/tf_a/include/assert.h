#ifndef _ASSERT_H
#define _ASSERT_H
#ifdef NDEBUG
#define assert(e) ((void)0)
#else
#define assert(e) ((void)((e) || (__assert_fail(#e, __FILE__, __LINE__, __func__), 0)))
#endif
void __assert_fail(const char *expr, const char *file, int line, const char *func);
#endif
