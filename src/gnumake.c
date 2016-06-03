#include "gmk_api.h"
#include <assert.h>
#include <Python.h>
#include <limits.h>

int _gnumake_gmk_setup(void);
PyMODINIT_FUNC PyInit__gnumake(void);

/* From the Python perspective, this is just a dummy module: there's
 * actually nothing here. It exists as a Python module so that we can
 * get its __file__ attribute easily. 
 *
 * Its real purpose is to be loaded into GNU make, where it will start up
 * the Python interpreter and load the real gnumake module.
 */
static struct PyModuleDef pygnumake_module = {
    PyModuleDef_HEAD_INIT,
    "gnumake._gnumake",
    "Internal extension module for gnumake.\n\n"
        "Load this module into make with the load directive.\n"
        "It has no user-accessible functions."
    -1,
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

/** @brief Helper function to set an environment variable from a GNU make
 *  variable.
 *
 *  Needed because even if you mark a variable as exported, it doesn't make it
 *  into the environment until recipes are executed.
 *
 *  @param env_name Name of destination environment variable
 *  @param make_name Name of the source make variable
 */
static void export_var(const char* env_name, const char* make_name)
{
	char* value;
	char buffer[256];
	int ret;

	ret = snprintf(buffer, sizeof(buffer), "$(strip $(%s))", make_name);
	if (ret < 0 || (size_t)ret >= sizeof(buffer))
	{
		return;
	}

	value = gmk_api.expand(buffer);
	if (value)
	{
		if (value[0])
		{
			setenv(env_name, value, 1);
		}
		gmk_api.free(value);
	}
}

/** @brief Helper function to set an environment variable from a GNU make
 *  variable.
 *
 *  As export_var, but appends to an existing variable and joins using a
 *  given separator.
 *
 *  @param env_name Name of destination environment variable
 *  @param make_name Name of the source make variable
 *  @param join     The char to use to join list elements.
 */
static void append_var_list(const char* env_name, 
                            const char* make_name,
                            char join)
{
	char* value;
    char* existing;
	char buffer[256];
	int ret;
    char* c;

	ret = snprintf(buffer, sizeof(buffer), "$(strip $(%s))", make_name);
	if (ret < 0 || (size_t)ret >= sizeof(buffer))
	{
		return;
	}

	value = gmk_api.expand(buffer);
	if (value)
	{
		if (value[0])
		{
            for (c = value; *c; c++)
            {
                if (*c == ' ')
                {
                    *c = join;
                }
            }

            existing = getenv(env_name);
            if (existing && existing[0])
            {
                size_t existing_len = strlen(existing);
                size_t value_len = strlen(value);
                size_t needed = existing_len + value_len + 2;
                char* combined = malloc(needed);
                if (combined)
                {
                    memcpy(combined, existing, existing_len);
                    combined[existing_len] = join;
                    memcpy(combined + existing_len+1, value, value_len);
                    combined[needed-1] = '\0';
                    setenv(env_name, combined, 1);
                    free(combined);
                }
            }
            else
            {
			    setenv(env_name, value, 1);
            }
		}
		gmk_api.free(value);
	}
}

/** @brief Set up environment variables used by Python.
 *
 * This allows the user to control the startup and execution of Python using
 * make variables.
 *
 */
static void set_python_env(void)
{
	export_var("PYTHONHOME",              ".PYTHONHOME");
	append_var_list("PYTHONPATH",         ".PYTHONPATH", ':');
	export_var("PYTHONOPTIMIZE",          ".PYTHONOPTIMIZE");
	export_var("PYTHONDEBUG",             ".PYTYONDEBUG");
	export_var("PYTHONDONTWRITEBYTECODE", ".PYTHONDONTWRITEBYTECODE");
	export_var("PYTHONINSPECT",           ".PYTHONINSPECT"); // does this work?
	export_var("PYTHONIOENCODING",        ".PYTHONIOENCODING");
	export_var("PYTHONUSERSITE",          ".PYTHONUSERSITE");
	export_var("PYTHONUNBUFFERED",        ".PYTHONUNBUFFERED");
	export_var("PYTHONVERBOSE",           ".PYTHONVERBOSE");
	append_var_list("PYTHONWARNINGS",     ".PYTHONWARNINGS", ',');
	export_var("PYTHONHASHSEED",          ".PYTHONHASHSEED");
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
	int ret = 0;
    PyObject* gnumake = NULL;
	wchar_t* argv[1] = { NULL };

    if (load_gmk_api() < 0)
    {
        return 0;
    }

	set_python_env();
    Py_SetProgramName(PYTHON_NAME);
    Py_Initialize();
	PySys_SetArgv(0, argv);

    if (atexit(pygnumake_gmk_cleanup) != 0)
    {
        PyErr_SetFromErrno(PyExc_OSError);
        goto done;
    }

    gnumake = PyImport_ImportModule("gnumake");
    if (!gnumake)
    {
        goto done;
    }

	ret = 1;

done:
	if (PyErr_Occurred())
	{
		// The user will probably want to know.
		PyErr_Print();
	}

    Py_XDECREF(gnumake);

	// Release the GIL
	PyEval_SaveThread();
	return ret;
}

