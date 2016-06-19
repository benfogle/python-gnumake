
Introduction
============

Py-gnumake is a GNU make plugin that allows you to extend a makefile with
Python. Python code run through Py-gnumake has access to variables, make
functions, and etc., just like functions built with conventional makefile
syntax.

Rationale
---------
First and foremost, this is a tech demo using the fairly new plugin feature for
GNU make, introduced in version 4.0. But does it have any real applications?

Let's start with a real example: `this actual makefile from the Android NDK
<https://android.googlesource.com/platform/ndk/+/master/build/core/definitions-graph.mk#398>`_.
Peruse that file for a moment and bask in the glory of a topological sort
written in pure make syntax.

The great thing about a makefile is its simplicity, and even though (or perhaps
because) it is simple it scales remarkably well, even to huge builds. Where it
doesn't scale is when builds begin to require more complicated rules than
``.c`` --> ``.o`` --> ``.exe``. It's not that make can't do it, but rather that
complicated flows become difficult to express in make syntax. This becomes
especially acute when makefiles are used to build projects with multiple
interconnected sub-components.


So what exactly does it do?
---------------------------

Py-gnumake adds the following functions to make:

* :ref:`python-eval` -- Expands to the result of the Python
  expression.
* :ref:`python-exec` -- Executes arbitrary Python code. Expands to the
  value of any output printed to stdout (much like ``$(shell ...)``).
* :ref:`python-file` -- Like `python-exec` but runs code from a script, 
  optionally passing arguments to sys.argv.

Python code run using these functions are all run within the same process as
make. They all share globals and imports, and can interact with the makefile
in the same way.

What can the Python code do from within the makefile?
-----------------------------------------------------

You have full access to the Python interpreter. You can import and use any
installed module. To make it easier to interact with the makefile, the
:doc:`gnumake <python_funcs>` module provides the following functions:

* :py:func:`~gnumake.export` -- A decorator that will cause a Python function
  to be exposed to the makefile as a new function. So running the following
  code using one of the above make functions will cause a new function
  ``$(newer <file1>,<file2>)`` to be created, which expands to the name of the
  file with the more recent modification time::

    from gnumake import export
    import os

    @export 
    def newer(file1, file2):
        if os.path.getmtime(file1) > os.path.getmtime(file2):
            return file1
        else:
            return file2

* :py:func:`~gnumake.evaluate` -- Executes the given make code, as if ``$(eval
  ...)`` had been used. This can be used to set variable values, raise errors,
  etc.

* :py:func:`~gnumake.expand` -- Returns the result of expanding the given
  expression, so ``gnumake.expand("$(lastword $(SOME_LIST))")`` could be used
  to get the final word in the variable ``$(SOME_LIST)``

* :py:data:`~gnumake.variables` or :py:data:`~gnumake.vars` -- A
  dictionary-like object of type :py:class:`~gnumake.Variables` that can be
  used in place of :py:func:`~gnumake.expand` and :py:func:`~gnumake.evaluate`
  to access variables.



