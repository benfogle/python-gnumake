"""
Python integration into GNU Make
"""
import sys
import tempfile
import os
import inspect
import traceback

import gnumake._gnumake as gmk
import gnumake
import ctypes

try:
    this_module = ctypes.PyDLL(None)
    this_module['gmk_add_function']
except AttributeError:
    pass
else:
    from gnumake.core import *
