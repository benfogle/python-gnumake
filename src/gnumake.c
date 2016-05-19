#include "gmk_api.h"
#include <assert.h>
#include <Python.h>

static struct PyModuleDef pygnumake_module = {
    PyModuleDef_HEAD_INIT,
    "gnumake._gnumake",
    "Internal extension module for gnumake.\n\n"
        "Load this module into make with the load directive.\n"
        "Don't use the functions in this module directly\n",
    -1,
    NULL
};


/** @brief Python module init function
 *
 * Called when imported by Python
 */
PyMODINIT_FUNC
PyInit__gnumake(void)
{
    PyObject* mod = NULL;

    mod = PyModule_Create(&pygnumake_module);

    return mod;

fail:
    Py_XDECREF(mod);
    return NULL;
}

/** Required by GNU make */
int plugin_is_GPL_compatible;

/** @brief Clean up Python on exit
 *
 * GNU make provides no other way to clean up except an atexit handler
 */
static void pygnumake_gmk_cleanup(void)
{
    PyGILState_Ensure(); // make it safe to run Python
    Py_Finalize();
}

/** @brief Get the current Makefile
 *
 * This will allow us to set the path appropriately so we can import
 * packages relative to the Makefile.
 *
 * @return The wide character conversion of the makefile. This must be
 * freed by the caller.
 */
static wchar_t* get_makefile(void)
{
    size_t n;
    char* makefile;
    wchar_t* ret = NULL;

    // This could do weird things if the load directive is in a function
    // or $(eval ...). Better than nothing.
    makefile = gmk_api.expand("$(lastword $(MAKEFILE_LIST))");
    if (!makefile)
    {
        return NULL;
    }

    n = strlen(makefile);
    ret = calloc(n+1, sizeof(wchar_t));
    if (!ret)
    {
        goto done;
    }

    n = mbstowcs(ret, makefile, n);
    if (n == (size_t)-1)
    {
        free(ret);
        ret = NULL;
    }

done:
    gmk_api.free(makefile);
    return ret;
}


/** @brief Initialize Python for GNU make
 *
 * Called when this .so is loaded into GNU make with the load directive. This
 * will cause PyInit__gnumake() to be called as well when we load the
 * appropriate module
 *
 * @return 1 on success, -1 on error
 */
int _gnumake_gmk_setup(void)
{
    PyObject* gnumake = NULL;
    PyObject* locals = NULL;
    PyObject* globals = NULL;
    wchar_t* argv[] = { NULL, NULL };
    int argc = 1;

    if (load_gmk_api() < 0)
    {
        return 0;
    }

    // Figure out the makefile. If we are loaded in a function, or some
    // other non-direct way, this could be wrong... Still, we want to try
    // so that we can load our module from the same directory as the makefile
    argv[0] = get_makefile();
    if (!argv[0])
    {
        argv[0] = wcsdup(L"");
        if (!argv[0])
        {
            argc = 0;
        }
    }

    Py_SetProgramName(PYTHON_NAME);
    Py_Initialize();
    PySys_SetArgv(argc, argv);

    free(argv[0]);

    if (atexit(pygnumake_gmk_cleanup) != 0)
    {
        PyErr_SetFromErrno(PyExc_OSError);
        goto done;
    }

    globals = PyDict_New();
    if (!globals)
    {
        goto done;
    }

    locals = PyDict_New();
    if (!locals)
    {
        goto done;
    }

    gnumake = PyImport_ImportModuleEx("gnumake", globals, locals, NULL);
    if (!gnumake)
    {
        goto done;
    }

done:
    Py_XDECREF(gnumake);
    Py_XDECREF(locals);
    Py_XDECREF(globals);

    return 1;
}

