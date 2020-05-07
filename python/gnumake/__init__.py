"""
Python integration into GNU Make

This is the main module, which is loaded automatically by the py-gnumake
plugin.

You can import this module into a regular Python interpreter, but most
functions will raise an ImportError if you try to call them.
"""

import sys
import tempfile
import os
import inspect
import traceback
import ctypes
import runpy
import string
import importlib

import gnumake
import gnumake._api as _api

# Make info pages say that () are actually legal, but we won't allow them
# because in practice the parsing is too problematic. It also says that $
# is legal, but that clearly doesn't work.
ILLEGAL_VAR_CHARS = frozenset(string.whitespace + ':#=$()')

# Python code in a Makefile shares globals, but it shouldn't share _my_
# globals.
_python_globals = { '__builtins__' : __builtins__,
                   'gnumake' : gnumake,
                   'os' : os,
                   'sys' : sys,
                 }



def object_to_string(obj):
    """
    Convert a Python object to a string in a way that will be somewhat sensible
    to the makefile:

    - True becomes '1'
    - False and None become an empty string
    - Strings are unchanged.
    - Bytes, bytearrays, and anything supporting the buffer protocol are
      converted to a string using the default encoding.
    - Anything else returns str(obj)

    Args:
        obj (object):  The object to convert.

    Returns:
        string: a string representation of the object.
    """

    if obj is True:
        return '1'
    elif obj is False or obj is None:
        return ''
    elif isinstance(obj, str):
        return obj
    elif isinstance(obj, bytes):
        return obj.decode()
    elif isinstance(obj, bytearray):
        return bytes(obj).decode()
    else:
        try:
            return bytes(memoryview(obj)).encode()
        except TypeError:
            try:
                return str(obj)
            except:
                return ''

def is_legal_name(name):
    """Check that a name is a legal makefile variable name"""
    return not frozenset(name).intersection(ILLEGAL_VAR_CHARS)

def escape_string(s):
    """
    Escape a string such that it can appear in a define directive.
    We need to escape 'endef' and backslash-newline.
    """
    s = s.replace('endef', '$()endef')
    s = s.replace('\\\n', '\\$()\n')
    return s

def fully_escape_string(s):
    """
    Escape a string such that it can appear verbatim in a define directive.
    This version also escapes $ so that variable expansion does not occur.
    We need to escape 'endef', backslash-newline, and $.
    """
    s = s.replace('endef', '$()endef')
    s = s.replace('\\\n', '\\$()\n')
    s = s.replace('$', '$$')
    return s


# Holds all of the function implementations
_callback_registry = {}

def _real_callback(name, argc, argv):
    """
    This is the real code that interfaces between gnumake and Python.
    It converts the arguments from ctypes into a more Pythonic format, and
    it converts the return value into a string usable by gnumake.

    Args:
        name (bytes):   name of the function being called
        argc (int):     The number of arguments in argv
        argv (list):    The arguments as an array of bytes objects

    Returns:
        ctypes.c_void_p: A string allocated by gmk_alloc
    """

    ret = None

    try:
        if name in _callback_registry:
            args = [ argv[i].decode() for i in range(argc) ]
            val = _callback_registry[name](*args)

        # Don't return, or we never get to the 'else'
        val = object_to_string(val).encode()
        ret = _api.gmk_alloc(len(val) + 1)
        # So the C API guarantees that a bytes object has a null just after the
        # end, so we could memmove len(val)+1...how terrible of an idea is it
        # to actually do this?
        ctypes.memmove(ret, val, len(val))
        ctypes.memset(ret + len(val), 0, 1)
    except Exception as e:
        if expand('$(.PYTHON_PRINT_TRACEBACK)'):
            traceback.print_exc()

        err = fully_escape_string("{}: {}".format(type(e).__name__, e))
        evaluate('define .PYTHON_LAST_ERROR\n{}\nendef'.format(err))
    else:
        evaluate('undefine .PYTHON_LAST_ERROR')

    return ret

_real_callback = _api.gmk_func_ptr(_real_callback)


def guess_function_parameters(func):
    """
    Guess function parameters. We only count positional arguments.

    This function does not work on builtins.

    Args:
        func (function object):    Function to inspect

    Returns:
        (int, int): 2-tuple of min_args, max_args, where max_args may be
                    -1 to indicate variable arguments.
    """

    min_args = 0
    max_args = 0

    sig = inspect.signature(func)
    for param in sig.parameters.values():
        if param.kind in (param.POSITIONAL_ONLY, param.POSITIONAL_OR_KEYWORD):
            if max_args != -1:
                max_args += 1
            if param.default is param.empty:
                min_args += 1
        elif param.kind == param.VAR_POSITIONAL:
            max_args = -1

    return min_args, max_args


def export(func=None, *, name=None, expand=True, min_args=-1,
                                                 max_args=-1):
    """
    Decorator to expose a function to Python.

    All parameters passed to the Python function will be strings. The return
    value of the function will be converted to a string according to the
    following rules:

    1. Strings are unchanged
    2. True becomes '1'
    3. False and None become an empty string
    4. Bytes, bytearrays, and anything supporting the buffer protocol will be
       converted to a string using the default encoding.
    5. All other objects use str(obj)

    Args:
        func (function):    Function to decorate
        name (string):      The GNU make name of the function. If omitted,
                            defaults to the unqualified function name
        expand (bool):      If True (default) arguments to the function are
                            expanded by make before the function is called.
                            Otherwise the function receives the arguments
                            verbatim, $(variables) and all.
        min_args (int):     The minimum number of arguments to the function.
                            If -1, (default) then the number of arguments will
                            be guessed.
        max_args (int):     If > 0, the maximum number of arguments to the
                            function. A value of 0 means any number of
                            arguments. A value of -1 (default) means that the
                            number of parameters will be guessed.

    Examples:

        >>> @gnumake.export
        ... def newer(file1, file2):
        ...    '''Returns the newer file'''
        ...    if os.path.getmtime(file1) > os.path.getmtime(file2):
        ...        return file1
        ...    else:
        ...        return file2

        This function can then be used in a makefile as $(newer f1.txt,f2.txt)

        >>> @gnumake.export(name='repeat-loop', expand=False):
        ... def repeat_loop(condition, loop):
        ...   '''A while-loop for the makefile'''
        ...    while gnumake.expand(condition):
        ...        gnumake.expand(loop)

        This function can be used in a makefile as
        $(repeat-loop condition,loop). Both arguments are repeatedly expanded
        each time through the loop.


    May also be used as a function::

        >>> export(os.path.isfile, min_args=1, max_args=1)

    """
    if func is None:
        if not _api.gmk_detected:
            return lambda f: f

        # Decorator with arguments
        def inner(func):
            if func is None:
                raise ValueError("callback must not be None")
            _name = name
            if _name is None:
                _name = func.__name__
            export(func,  name=_name,
                          min_args=min_args,
                          max_args=max_args,
                          expand=expand)
            return func
        return inner
    else:
        # Decorator or functional form
        if not _api.gmk_detected:
            return func

        if name is None:
            name = func.__name__

        if expand:
            expand = _api.GMK_FUNC_DEFAULT
        else:
            expand = _api.GMK_FUNC_NOEXPAND

        if max_args == -1 or min_args == -1:
            guessed_min, guessed_max = guess_function_parameters(func)

        if max_args == -1:
            if guessed_max == 0:
                raise ValueError("Function must take at least one parameter")
            elif guessed_max == -1:
                max_args = 0
            else:
                max_args = guessed_max

        if min_args == -1:
            min_args = guessed_min
            if min_args == 0:
                min_args = 1



        # Error check here because GNU make will just exit on error.
        if max_args != 0 and max_args < min_args:
            raise ValueError("max_args < min_args")
        if max_args > 255 or min_args > 255:
            raise ValueError("too many args")
        if min_args < 0 or max_args < 0:
            raise ValueError("negative args")
        if min_args == 0:
            raise ValueError("min_args is zero")

        name = name.encode()
        if len(name) > 255:
            raise ValueError("name too long")

        _callback_registry[name] = func
        _api.gmk_add_function(name, _real_callback, min_args, max_args, expand)

        return func


def evaluate(s):
    """
    Evaluate a string as Makefile syntax, as if $(eval ...) had been used.

    Note:
        GNU make handles errors by exiting the entire program.
    """
    _api.gmk_eval(s.encode(), None)

def expand(s):
    """
    Expand a string according to Makefile rules

    Note:
        GNU make handles errors by exiting the entire program.
    """
    s = _api.gmk_expand(s.encode())

    if not s:
        return ''

    s = ctypes.cast(s, ctypes.c_char_p)
    ret = s.value.decode()
    _api.gmk_free(s)
    return ret

@export(name='python-eval')
def python_eval(arg):
    """
    Implements $(python-eval ...)
    Evaluate a Python expression and return the result
    """
    return eval(arg, _python_globals)

@export(name='python-file')
def python_file(script, *args):
    """
    Implements $(python-file ...)

    Run a Python script, optionally passing arguments to it. Any output
    (stdout only) of the script will be the return value.

    Unlike a script run with $(shell ...), this script will have
    access to Makefile variables, etc., through this module.
    """

    argv_original = sys.argv
    stdout_original = os.dup(1)
    try:
        sys.argv = [script] + list(args)
        with tempfile.TemporaryFile() as capture:
            os.dup2(capture.fileno(), 1)

            with open(script) as fp:
                code = compile(fp.read(), script, 'exec')
                exec(code, _python_globals, _python_globals)

            capture.seek(0)
            return capture.read().rstrip(b'\n')
    finally:
        os.dup2(stdout_original, 1)
        sys.argv = argv_original

@export(name='python-mod')
def python_mod(mod, *args):
    """
    Implements $(python-mod ...)

    Import a Python module, exposing any 'exported' functions. This does not
    invoke a function by default, as it is intended to provide access to the
    library instead.
    """
    argv_original   = sys.argv
    stdout_original = os.dup(1)
    try:
        with tempfile.TemporaryFile() as capture:
            os.dup2(capture.fileno(), 1)
            runpy.run_module(mod, init_globals=_python_globals)
            capture.seek(0)
            return capture.read().rstrip(b'\n')
    finally:
        os.dup2(stdout_original, 1)
        sys.argv = argv_original

@export(name="python-exec")
def python_exec(arg):
    """
    Implements $(python-exec ...)
    Run inline Python code
    """
    stdout_original = os.dup(1)
    try:
        with tempfile.TemporaryFile() as capture:
            os.dup2(capture.fileno(), 1)

            code = compile(arg, '<python>', 'exec')
            exec(code, _python_globals, _python_globals)

            capture.seek(0)
            return capture.read().rstrip(b'\n')
    finally:
        os.dup2(stdout_original, 1)


class Variables:
    """
    Convenience class for manipulating variables in a more Pythonic manner.

    An instance of this class is available as ``gnumake.variables`` or
    ``gnumake.vars``
    """

    def get(self, name, default = '', expand_value=True):
        """
        Get a variable name

        Args:
            name (string):      The name of the variable. This should not
                                contain a $(...), and computed names are not
                                allowed.

            default (string):   Value to return if the result is undefined.
                                Defaults to an empty string. This value will be
                                returned only if the variable is undefined, not
                                if it has been defined to an empty string.

            expand (bool):      If true (default), the value will be expanded
                                according to the flavor of the variable. This
                                is usually what you want. Note that this makes
                                no difference for simply expanded variables,
                                which are fully expanded on assignment.

        Returns:
            string: The value of the variable
        """

        if not is_legal_name(name):
            raise ValueError("Illegal name")

        if not expand_value:
            expand_func = 'value '
        else:
            expand_func = ''

        ret = expand('$({}{})'.format(expand_func, name))

        if not ret and default:
            if not self.defined(name):
                ret = default
        return ret

    def set(self, name, value, flavor='recursive'):
        """
        Set a variable

        Args:
            name:   The variable name
            value:  The variable value. This string will be escaped to preserve
                    newlines, etc. Dollar signs ($) are _not_ escaped.
            flavor: May be 'recursive' or 'simple'. Specifying 'recursive' is
                    equivalent to name=value, while 'simple' is equivalent to
                    name:=value. Default is recursive.
        """

        if not is_legal_name(name):
            raise ValueError("Illegal name")

        if flavor == 'recursive':
            equals = '='
        elif flavor == 'simple':
            equals = ':='
        else:
            raise ValueError("Valid flavors are 'recursive' and 'simple'")

        value = escape_string(object_to_string(value))

        evaluate('define {} {}\n{}\nendef'.format(name, equals, value))

    def undefine(self, name):
        """Undefine a variable"""
        if not is_legal_name(name):
            raise ValueError("Illegal name")
        evaluate('undefine {}'.format(name))

    def append(self, name, value):
        """
        Append a value to a possibly existing variable. Values will
        be appended with a single space between the old value and the new
        one. The flavor of the variable will remain unchanged.
        """
        if not is_legal_name(name):
            raise ValueError("Illegal name")

        value = escape_string(object_to_string(value))
        evaluate('define {} +=\n{}\nendef'.format(name, value))


    def origin(self, name):
        """
        Return the origin of a variable. See make documentation for possible
        values and their meanings.
        """
        if not is_legal_name(name):
            raise ValueError("Illegal name")
        return expand('$(origin {})'.format(name))

    def flavor(self, name):
        """
        Returns the flavor of a variable. May return 'simple', 'recursive'
        or 'undefined'
        """
        if not is_legal_name(name):
            raise ValueError("Illegal name")
        return expand('$(flavor {})'.format(name))

    def defined(self, name):
        """Returns True if a variable has been defined, or False otherwise"""
        return self.origin(name) != 'undefined'

    def __getitem__(self, name):
        """Synonym for get(name)"""
        return self.get(name)

    def __setitem__(self, name, value):
        """Synonym for set(name, value)"""
        self.set(name, value)

    def __delitem__(self, name):
        """Synonym for undefine(name)"""
        self.undefine(name)

    def __contains__(self, name):
        """Synonym for defined(name)"""
        return self.defined(name)

# Object to use to access variables in a Pythonic manner
variables = Variables()

# Synonym for variables object. This is for Python code inlined in a makefile,
# where terse one-liners may be desirable
var = variables


