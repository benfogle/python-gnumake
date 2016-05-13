#include "stubs.h"
#include "utils.h"
#include <assert.h>
#include <Python.h>

/** @brief Dictionary of callback functions
 *
 *  Maps byte strings to callable Python objects. This
 *  object is not exposed to Python code.
 */
static PyObject* callback_registry;

/** @brief Globals dictionary
 *
 * Globals shared between Python scripts, evals, etc.
 */
static PyObject* python_globals;

/** @brief Callback function used to implement GNU make functions
 *
 * All exported Python functions are exposed to GNU make through this function.
 * When called it will use the name of the function to invoke the appropriate
 * callable. It does the equivalent of:
 *
 *     return callback_registry[name](*argv)
 *
 * @param name  The name of the called GNU-make function.
 * @param argc  The number of arguments
 * @param argv  The arguments.
 *
 * @return The expansion of the function, or NULL if the function doees not
 * produce any output.
 */
static char* dispatch_callback(const char* name, 
                               unsigned int argc, 
                               char* argv[])
{
    PyObject* py_name = NULL;
    PyObject* args = NULL;
    PyObject* callback = NULL;
    PyObject* py_result = NULL;
    char* ret = NULL;
    unsigned int i;

    if (!callback_registry || !gmk_api_loaded())
    {
        //TODO: Set some sort of return code.
        return NULL;
    }

    py_name = PyBytes_FromString(name);
    if (!py_name)
    {
        goto done;
    }

    callback = PyDict_GetItem(callback_registry, py_name);
    if (!callback)
    {
        goto done;
    }
    Py_INCREF(callback);

    args = PyTuple_New(argc);
    if (!args)
    {
        PyErr_Print();
        goto done;
    }

    for (i = 0; i < argc; i++)
    {
        PyObject* a = PyUnicode_FromString(argv[i]);
        if (!a)
        {
            PyErr_Print();
            goto done;
        }

        PyTuple_SET_ITEM(args, i, a);
    }

    py_result = PyObject_Call(callback, args, NULL);
    if (!py_result)
    {
        goto done;
    }

    ret = convert_to_chars(py_result);

done:
    // Can't do much with an error, so we'll swallow it...
    if (PyErr_Occurred())
    {
        PyErr_Print(); // TODO: Put this in a make variable somewhere
    }

    Py_XDECREF(py_result);
    Py_XDECREF(args);
    Py_XDECREF(callback);
    Py_XDECREF(py_name);
    return ret;
}

/** @brief Exposes gmk_eval() to Python
 *
 * Python signature is:
 * 
 *     def eval(buffer, filename=None, lineno=None):
 *         ...
 *
 * @param buffer    The string to parse as Makefile syntax
 * @param filename  The filename to report in case of error. Optional. Must be
 *                  specified with lineno.
 * @param lineno    The line number to report in case of error. Optional. Must
 *                  be specified with filename.
 *
 * @warning This function will not return on error and will cause the entire
 *          make process to exit with an error.
 */
static PyObject* pygnumake_eval(PyObject* self,
                         PyObject* args,
                         PyObject* kwds)
{
    static char* keywords[] = { "buffer", "filename", "lineno", NULL };

    const char* buffer;
    gmk_floc floc = { NULL, -1 };
    gmk_floc* floc_ptr = NULL;

    if (!callback_registry || !gmk_api_loaded())
    {
        PyErr_SetString(PyExc_SystemError, 
                        "gnumake module not properly initialized");
        return NULL;
    }

    if (PyArg_ParseTupleAndKeywords(args, kwds, "s|sk", keywords, 
                                    &buffer, 
                                    &floc.filenm, 
                                    &floc.lineno) < 0)
    {
        return NULL;
    }

    if (!((floc.lineno == (unsigned long)-1) ^ (floc.filenm != NULL)))
    {
        PyErr_SetString(PyExc_TypeError, 
                "filename and lineno must be specified together");
        return NULL;
    }
    else if (floc.filenm)
    {
        floc_ptr = &floc;
    }

    // Make sure everything is in a good state here: In case of error this
    // function simply won't return. (And do not release the GIL, or we'll
    // segfault on Py_Finalize().)
    gmk_api.eval(buffer, floc_ptr);
    Py_RETURN_NONE;
}

/** @brief Exposes gmk_expand to Python
 *
 * Python signature is:
 *     def expand(s):
 *         ...
 *
 * @param s     The string to expand according to Makefile expansion rules.
 * @return The expanded string
 */
static PyObject* pygnumake_expand(PyObject* self,
                           PyObject* args,
                           PyObject* kwds)
{
    static char* keywords[] = { "s", NULL };
    char* s;
    PyObject* ret;

    if (PyArg_ParseTupleAndKeywords(args, kwds, "s", keywords, &s) < 0)
    {
        return NULL;
    }

    s = gmk_api.expand(s);

    if (s == NULL)
    {
        return PyUnicode_FromString("");
    }

    ret = PyUnicode_FromString(s);
    gmk_api.free(s);
    return ret;
}

/** @brief Exposes gmk_add_function to Python
 *
 * Python signature is:
 *
 *     def add_function(name, func, min_args=0, max_args=0, expand=True):
 *         ...
 *
 * @param name      The function name to export
 * @param func      The Python callable to invoke when the function is called.
 * @param min_args  Minimum number of arguments.
 * @param max_args  Maximum arguments. Max value is 255. A value of 0 indicates
 *                  unlimited arguments. If max_args != 0, then max_args must
 *                  be less than or equal to min_args.
 * @param expand    If True, then arguments to the function will be expanded
 *                  before invoking the function. Otherwise all strings are
 *                  passed verbatim.
 *
 */
static PyObject* pygnumake_add_function(PyObject* self, 
                                   PyObject* args, 
                                   PyObject* kwds)
{
    static char* keywords[] = { "name", 
                                "func", 
                                "min_args", 
                                "max_args",
                                "expand",
                                NULL };

    PyObject* name = NULL;
    PyObject* callback = NULL;
    PyObject* name_unicode = NULL;
    PyObject* name_encoded = NULL;
    PyObject* ret = NULL;
    unsigned int min_args = 0;
    unsigned int max_args = 0;
    int expand = 1;

    const char* name_str;

    if (!callback_registry || !gmk_api_loaded())
    {
        PyErr_SetString(PyExc_SystemError, 
                        "gnumake module not properly initialized");
        return NULL;
    }

    if (PyArg_ParseTupleAndKeywords(args, kwds, "OO|IIp", keywords, 
                                    &name, &callback, &min_args, &max_args,
                                    &expand) < 0)
    {
        return NULL;
    }

    // We have to do error checking here...because make likes to report
    // errors by exiting the program.
    if (min_args > 255 || max_args > 255)
    {
        PyErr_SetString(PyExc_ValueError, 
                        "min_args and max_args must be <= 255");
        return NULL;
    }

    if (max_args != 0 && max_args < min_args)
    {
        PyErr_SetString(PyExc_ValueError, 
                        "max_args is less than min_args");
        return NULL;
    }

    Py_INCREF(name);
    Py_INCREF(callback);

    name_unicode = PyObject_Str(name);
    if (!name_unicode)
    {
        goto done;
    }

    // TODO: check legality of name

    name_encoded = PyUnicode_EncodeLocale(name_unicode, "strict");
    if (!name_encoded)
    {
        goto done;
    }

    if (PyDict_SetItem(callback_registry, name_encoded, callback) < 0)
    {
        goto done;
    }

    name_str = PyBytes_AS_STRING(name_encoded);
    gmk_api.add_function(name_str, dispatch_callback, min_args, max_args, 
                     expand ? GMK_FUNC_DEFAULT : GMK_FUNC_NOEXPAND);

    ret = Py_None;
    Py_INCREF(ret);

done:
    Py_XDECREF(name_encoded);
    Py_XDECREF(name_unicode);
    Py_XDECREF(name);
    Py_XDECREF(callback);
    return ret;
}


static PyMethodDef pygnumake_methods[] = {
    {
        "add_function", 
        (PyCFunction)pygnumake_add_function, 
        METH_VARARGS | METH_KEYWORDS,
        // This function may be used directly, so go the extra mile on documentation.
        "Expose a Python callable to make as a function.\n"
        "\n"
        "    name      The function name to export\n"
        "    func      The Python callable to invoke when the function is called.\n"
        "    min_args  Minimum number of arguments.\n"
        "    max_args  Maximum arguments. Max value is 255. A value of 0 indicates\n"
        "              unlimited arguments. If max_args != 0, then max_args must\n"
        "              be less than or equal to min_args.\n"
        "    expand    If True, then arguments to the function will be expanded\n"
        "              before invoking the function. Otherwise all strings are\n"
        "              passed verbatim.\n"
        "\n"
        "Once defined, the Makefile can invoke the callable as $(name arg1,arg2) etc.\n"
    },
    {
        "eval", 
        (PyCFunction)pygnumake_eval, 
        METH_VARARGS | METH_KEYWORDS,
        "Run $(eval ...) on the provided string"
    },
    {
        "expand", 
        (PyCFunction)pygnumake_expand, 
        METH_VARARGS | METH_KEYWORDS,
        "Run GNU make expansion on the given string"
    },

    { NULL, NULL, 0, NULL }
};

static struct PyModuleDef pygnumake_module = {
    PyModuleDef_HEAD_INIT,
    "gnumake._gnumake",
    "Internal extension module for gnumake.\n\n"
        "Load this module into make with the load directive.\n"
        "Don't use the functions in this module directly\n",
    -1,
    pygnumake_methods
};


/** @brief Python module init function
 *
 * Called when imported by Python
 */
PyMODINIT_FUNC
PyInit__gnumake(void)
{
    PyObject* mod = NULL;

    if (!gmk_api_loaded())
    {
        // Don't expose anything: this is just for __file__ attribute
        pygnumake_module.m_methods = NULL;
    }
    else
    {
        callback_registry = PyDict_New();
        if (!callback_registry)
        {
            return NULL;
        }
    }

    mod = PyModule_Create(&pygnumake_module);

    if (mod && gmk_api_loaded())
    {
        if (!python_globals)
        {
            PyErr_SetString(PyExc_SystemError, 
                            "_gnumake not set up correctly");
            goto fail;
        }

        if (PyObject_SetAttrString(mod, "global_state", python_globals) < 0)
        {
            goto fail;
        }
    }

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
    Py_XDECREF(python_globals);
    Py_XDECREF(callback_registry);
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

    python_globals = PyDict_New();
    if (!python_globals)
    {
        goto done;
    }

    locals = PyDict_New();
    if (!locals)
    {
        goto done;
    }

    gnumake = PyImport_ImportModuleEx("gnumake", python_globals, locals, NULL);
    if (!gnumake)
    {
        goto done;
    }

    PyDict_SetItemString(python_globals, "gnumake", gnumake);

done:
    Py_XDECREF(gnumake);
    Py_XDECREF(locals);

    if (PyErr_Occurred())
    {
        PyErr_Print();
        return 0;
    }

    return 1;
}

