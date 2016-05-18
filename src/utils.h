#ifndef PY_GNUMAKE_UTILS_H
#define PY_GNUMAKE_UTILS_H

#include <Python.h>

char* convert_to_chars(PyObject* obj);
char* escape_string(const char* s);
char* convert_to_chars_escaped(PyObject* obj);

#endif
