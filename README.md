# py-gnumake 

## Overview

Py-gnumake is a hybrid Python module and GNU make plugin that allows you to
integrate Python code directly into Makefiles. This module requires GNU make
>= 4.0, and currently only supports Python 3.3 or greater. It also currently 
builds on Linux only.

## Rationale

While make is a powerful build system, it is not without its warts. One of
those warts is that although large makefiles often need conditionals, loops,
and other standard programming constructs, makefile syntax is unwieldy for such
tasks (to put it mildly). Yet a need for such complicated makefiles exists:
take for example [this actual makefile from the Android NDK][1], and gaze in
awe of a *topological sort* implemented in pure makefile syntax.

This project aims to address such complexity by allowing these algorithms to
be implemented in a friendlier scripting language such as Python. Embedding
Python directly into the makefile allows for scripts that are not possible with
the $(shell ...) command and increases performance to boot.

## Examples

### Basic inlining




[1]: https://android.googlesource.com/platform/ndk/+/master/build/core/definitions-graph.mk#398
