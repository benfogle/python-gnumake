.. highlight:: make

======================
Installing and Using
======================

Py-gnumake can be incorporated into your build in one of two ways: Either as a
subdirectory in your source tree, or as a regular installed Python module.

Using from within your source tree
=====================================

In this method, you package Py-gnumake in your source distribution so that the
user doesn't have to have it installed to build you project.

First clone the git repo somewhere in your source tree. (Git submodules work
nicely for this.) In the Py-gnumake directory you will find the makefile
``load-python.mk``. To use Py-gnumake, simply add the following to your
makefile::

    include path/to/load-python.mk

This will build Py-gnumake if necessary and then load it into your makefile.
(Including this file multiple times is benign.)

.. note::
    If your makefile might be run from somewhere other than the current working
    directory, something like the following is recommended at the very top of
    your makefile(s)::

        this-makefile := $(lastword $(MAKEFILE_LIST))
        this-path := $(patsubst %/,%,$(this-makefile))
        include $(this-path)/rel/path/to/load-python.mk

.. note::
    This will cause the makefile to be restarted the first time Py-gnumake is
    built. See `How Makefiles Are Remade
    <https://www.gnu.org/software/make/manual/html_node/Remaking-Makefiles.html#Remaking-Makefiles>`
    for details of this process.

Using as a regular Python module
=====================================

In this method, Py-gnumake must be installed as a regular Python module in
order to build your project.

Either use pip:

.. code-block:: bash

    $ pip install py-gnumake

Or build from source:

.. code-block:: bash

    $ python3 setup.py build
    $ python3 setup.py install

Then to use Py-gnumake, add the following line to your makefile::

    $(eval $(shell python3 -m gnumake))
