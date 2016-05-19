#ifndef PY_GNUMAKE_API_H
#define PY_GNUMAKE_API_H

#include <gnumake.h>

typedef struct {
    void (*add_function)(const char *name, gmk_func_ptr func,
            unsigned int min_args, unsigned int max_args,
            unsigned int flags);
    char* (*alloc)(unsigned int size);
    void (*free)(char* p);
    void (*eval)(const char* s, const gmk_floc* floc);
    char* (*expand)(const char* s);
} gmk_api_funcs;

extern gmk_api_funcs gmk_api;

/**
 * @brief Load GNU Make API
 *
 * Loads the API from the current program. Will fail if not called from a
 * module loaded by make.
 *
 * @return 0 on success, -1 on failure.
 */
int load_gmk_api(void);

/**
 * @brief Check to see if the api was loaded
 *
 * @return 1 if the API as loaded, or 0 if it was not.
 */
int gmk_api_loaded(void);


#endif
