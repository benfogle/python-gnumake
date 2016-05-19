#include "gmk_api.h"
#include <dlfcn.h>
#include <stdlib.h>
#include <string.h>

gmk_api_funcs gmk_api;

/**
 * @brief Load GNU Make API
 *
 * Loads the API from the current program. Will fail if not called from a
 * module loaded by make.
 *
 * @return 0 on success, -1 on failure.
 */
int load_gmk_api(void)
{
    int ret = -1;

    void* dll = dlopen(NULL, RTLD_LAZY);
    if (!dll)
    {
        goto done;
    }

    gmk_api.add_function = dlsym(dll, "gmk_add_function");
    if (!gmk_api.add_function)
    {
        goto done;
    }

    gmk_api.alloc = dlsym(dll, "gmk_alloc");
    if (!gmk_api.alloc)
    {
        goto done;
    }

    gmk_api.free = dlsym(dll, "gmk_free");
    if (!gmk_api.free)
    {
        goto done;
    }

    gmk_api.expand = dlsym(dll, "gmk_expand");
    if (!gmk_api.expand)
    {
        goto done;
    }

    gmk_api.eval = dlsym(dll, "gmk_eval");
    if (!gmk_api.eval)
    {
        goto done;
    }

    ret = 0;

done:
    if (dll)
    {
        dlclose(dll);
    }

    if (ret < 0)
    {
        memset(&gmk_api, 0, sizeof(gmk_api));
    }

    return ret;
}

/**
 * @brief Check to see if the api was loaded
 *
 * @return 1 if the API as loaded, or 0 if it was not.
 */
int gmk_api_loaded(void)
{
    return gmk_api.add_function != NULL;
}

