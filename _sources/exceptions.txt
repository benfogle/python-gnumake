=====================
Handling Exceptions
=====================

Errors happen, and when they do, in traditional make fashion, the make functions
described in :doc:`makefile_funcs` as well as any make functions created by
using :py:func:`~gnumake.export` simply return an empty string. Assuming that
at some point you would like to know what when wrong, Py-gnumake provides some
basic debugging facilities.

.. _PYTHON_LAST_ERROR:

Getting the last error
======================

Any time an uncaught exception occurs, the make variable ``.PYTHON_LAST_ERROR``
is set with the exception type and text. For example, it might contain the
string ``SyntaxError: invalid syntax``. This variable is unset any time Python
code is run without an uncaught exception.

.. _PYTHON_PRINT_TRACEBACK:

Showing the full traceback
==========================

If the make variable ``.PYTHON_PRINT_TRACEBACK`` is set to some non-empty
value,  the Python stack trace will be printed to stderr anytime that an
uncaught exception occurs. This is very useful for debugging, and it is
convenient to set this variable via the command line.

Using the Python debugger
==========================

The Python debugger works just fine from within Py-gnumake. You can break into
arbitrary Python code by inserting the following line:

.. code-block:: python

    import pdb; pdb.set_trace()
