# Py-gnumake 

Please see the [main documentation][1]. This file is a brief summary of how to
use Py-gnumake in your builds.

## Overview

Py-gnumake is the unholy union of Python and makefiles.  It is a GNU make plugin
that lets you write portions of your makefiles in Python.  Python code run
through Py-gnumake has access to makefile variables, functions, and etc., just
like regular makefile code.

## Requirements

This module requires GNU make &gt;= 4.0 and currently only supports Python 3.3
or greater. It has currently been tested on Ubuntu Linux only.

# Using Py-gnumake from within your source tree

First clone the git repo somewhere in your source tree. (Git submodules work
nicely for this.) In the Py-gnumake directory you will find the makefile
`load-python.mk`. To use Py-gnumake, simply add the following to your makefile:
```make
include path/to/load-python.mk
```
This will build Py-gnumake if necessary, and then load it into your makefile.
(Including this file multiple times is benign.)

# Using Py-gnumake as a Python module

Install Py-gnumake from PYPI, or build it from source. Then add the following
to your makefile:
```make
$(eval $(shell python3 -m gnumake))
```
(Note that while you can import `gnumake` into any Python script when it is
installed in this manner, this module is completely nonfunctional unless
invoked from a makefile.)

[1]: https://benfogle.github.io/python-gnumake/
