#include "error.h"
#include "stubs.h"
#include "utils.h"
#include <gnumake.h>

int errors_are_fatal(void)
{
    char* ret;
    char c;

    ret = gmk_api.expand("$(PYTHON_FATAL_ERRORS)");
    c = ret ? ret[0] : 0;
    gmk_api.free(ret);
    return c;
}


void set_error_from_string(const char* s, int escape)
{
    const char define_format[] = 
        "define PYTHON_LAST_ERROR\n"
        "%s\n"
        "endef\n";

    char* escaped_str = NULL;
    size_t total;
    int n;
    char* eval_str = NULL;

    if (escape)
    {
        escaped_str = escape_string(s);
        s = escaped_str;
    }

    if (!s)
    {
        s = "";
    }

    total = sizeof(define_format) + strlen(s);
    eval_str = malloc(total);
    if (!malloc)
    {
        gmk_api.eval("$(error Out of memory)", NULL);
        goto done;
    }
    
    n = snprintf(eval_str, total, define_format, s);
    if (n < 0 || (size_t)n >= total)
    {
        gmk_api.eval("$(error Internal error)", NULL);
        goto done;
    }

    gmk_api.eval(eval_str, NULL);

    if (errors_are_fatal())
    {
        gmk_api.eval("$(error $(PYTHON_LAST_ERROR))", NULL);
    }

done:
    free(eval_str);

    if (escaped_str)
    {
        gmk_api.free(escaped_str);
    }
}

void set_error_from_exception(void)
{
    PyObject* type = NULL;
    PyObject* val = NULL;
    PyObject* traceback = NULL;
    PyObject* format_string = NULL;
    PyObject* str = NULL;
    PyObject* type_name = NULL;
    PyObject* bytes = NULL;

    if (!PyErr_Occurred())
    {
        gmk_api.eval("undefine PYTHON_LAST_ERROR", NULL);
        return;
    }

    PyErr_Fetch(&type, &val, &traceback);
    PyErr_NormalizeException(&type, &val, &traceback);

    type_name = PyObject_GetAttrString(type, "__name__");
    if (!type_name)
    {
        gmk_api.eval("$(error Internal error)", NULL);
        goto done;
    }

    format_string = PyUnicode_FromString("{}: {}");
    if (!format_string)
    {
        gmk_api.eval("$(error Internal error)", NULL);
        goto done;
    }

    str = PyObject_CallMethod(format_string, "format", "OO", type_name, val);
    if (!str)
    {
        gmk_api.eval("$(error Internal error)", NULL);
        goto done;
    }

    bytes = PyUnicode_EncodeLocale(str, "strict");
    if (!str)
    {
        gmk_api.eval("$(error Internal error)", NULL);
        goto done;
    }

    set_error_from_string(PyBytes_AsString(bytes), 1);

done:
    Py_DECREF(bytes);
    Py_DECREF(str);
    Py_DECREF(format_string);
    Py_DECREF(type_name);
    Py_DECREF(type);
    Py_DECREF(val);
    Py_DECREF(traceback);
}
