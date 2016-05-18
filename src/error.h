#ifndef GNUMAKE_ERROR_H
#define GNUMAKE_ERROR_H

#include <Python.h>

int errors_are_fatal(void);
void set_error_from_exception(void);
void set_error_from_string(const char* s, int escape);

#endif

