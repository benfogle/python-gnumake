"""
Python integration into GNU Make

This module exposes the raw GNU make API, if available. You should not use
the functions in this module directly.
"""

import ctypes

GMK_FUNC_DEFAULT  = 0x00
GMK_FUNC_NOEXPAND = 0x01

this_module = ctypes.CDLL(None)

gmk_func_ptr = ctypes.CFUNCTYPE(ctypes.c_char_p, 
                                 ctypes.c_char_p, 
                                 ctypes.c_uint, 
                                 ctypes.POINTER(ctypes.c_char_p))

try:
    gmk_add_function = this_module['gmk_add_function']
    gmk_add_function.restype = None
    gmk_add_function.argtypes = [ ctypes.c_char_p, gmk_func_ptr,
                                   ctypes.c_uint, ctypes.c_uint, ctypes.c_uint ]

    gmk_alloc = this_module['gmk_alloc']
    gmk_alloc.restype = ctypes.c_void_p
    gmk_alloc.argtypes = [ctypes.c_uint]

    gmk_free = this_module['gmk_free']
    gmk_free.restype = None
    gmk_free.argtypes = [ctypes.c_void_p]

    gmk_eval = this_module['gmk_eval']
    gmk_eval.restype = None
    gmk_eval.argtypes = [ctypes.c_char_p, ctypes.c_void_p]

    gmk_expand = this_module['gmk_expand']
    gmk_expand.restype = ctypes.c_void_p # Need to manually convert to str
    gmk_expand.argtypes = [ ctypes.c_char_p ]
    gmk_detected = True
except AttributeError:
    # In this case we return non-functional versions. We do this so that you
    # can still import the main module from a standard Python interpreter,
    # which can be useful if you want to see the documentation. (Sphinx, for
    # example likes to import modules to automatically generate documentation.)

    def dummy_function(*args):
        raise ImportError("GNU make not detected")

    gmk_add_function = dummy_function
    gmk_alloc = dummy_function
    gmk_free = dummy_function
    gmk_eval = dummy_function
    gmk_expand = dummy_function
    gmk_detected = False
