#include "utils.h"
#include "stubs.h"

#include <Python.h>



static char* chars_from_buffer(PyObject* s)
{
    Py_buffer view;
    char* ret;

    if (!s)
    {
        return NULL;
    }

    if (PyObject_GetBuffer(s, &view, PyBUF_SIMPLE) < 0)
    {
        return NULL;
    }

    // TODO: only add a nul byte when we need to
    ret = gmk_api.alloc(view.len+1); 
    memcpy(ret, view.buf, view.len);
    ret[view.len] = '\0';

    PyBuffer_Release(&view);
    return ret;
}

static char* chars_from_unicode(PyObject* s)
{
    PyObject* as_bytes = NULL;
    char* ret = NULL;

    if (!s)
    {
        return NULL;
    }

    as_bytes = PyUnicode_EncodeLocale(s, "strict");
    if (!as_bytes)
    {
        return NULL;
    }

    // Remember: bytes objects always allocate an extra null at the end.
    ret = gmk_api.alloc(PyBytes_GET_SIZE(as_bytes) + 1);
    memcpy(ret, PyBytes_AS_STRING(as_bytes),
                PyBytes_GET_SIZE(as_bytes)+1);

    Py_XDECREF(as_bytes);
    return ret;
}

static char* chars_from_other(PyObject* s)
{
    PyObject* str;
    char* ret;

    if (!s || s == Py_None || s == Py_False)
    {
        return NULL;
    }

    if (s == Py_True)
    {
        char* ret = gmk_api.alloc(5);
        if (ret)
        {
            strcpy(ret, "true");
        }
        return ret;
    }

    str = PyObject_Str(s);
    if (!str)
    {
        return NULL;
    }

    ret = chars_from_unicode(str);
    Py_DECREF(str);
    return ret;
}

char* convert_to_chars(PyObject* obj)
{
    if (!gmk_api_loaded())
    {
        return NULL;
    }

    if (obj == NULL || obj == Py_None)
    {
        return NULL;
    }

    if (PyObject_CheckBuffer(obj))
    {
        return chars_from_buffer(obj);
    }

    if (PyUnicode_Check(obj))
    {
        return chars_from_unicode(obj);
    }

    return chars_from_other(obj);
}

