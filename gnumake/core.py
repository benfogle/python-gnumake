"""
Python integration into GNU Make

Do not import directly. This should be imported by __init__ only if the
_gnumake module loaded successfully.

"""
import sys
import tempfile
import os
import inspect
import traceback
import ctypes
import gnumake

GMK_FUNC_DEFAULT  = 0x00
GMK_FUNC_NOEXPAND = 0x01

# Python code in a Makefile shares globals, but it shouldn't share _my_
# globals.
python_globals = { '__builtins__' : __builtins__,
                   'gnumake' : gnumake }

this_module = ctypes.CDLL(None)

_gmk_func_ptr = ctypes.CFUNCTYPE(ctypes.c_char_p, 
                                 ctypes.c_char_p, 
                                 ctypes.c_uint, 
                                 ctypes.POINTER(ctypes.c_char_p))

_gmk_add_function = this_module['gmk_add_function']
_gmk_add_function.restype = None
_gmk_add_function.argtypes = [ ctypes.c_char_p, _gmk_func_ptr,
                               ctypes.c_uint, ctypes.c_uint, ctypes.c_uint ]

_gmk_alloc = this_module['gmk_alloc']
_gmk_alloc.restype = ctypes.c_void_p
_gmk_alloc.argtypes = [ctypes.c_uint]

_gmk_free = this_module['gmk_free']
_gmk_free.restype = None
_gmk_free.argtypes = [ctypes.c_void_p]

_gmk_eval = this_module['gmk_eval']
_gmk_eval.restype = None
_gmk_eval.argtypes = [ctypes.c_char_p, ctypes.c_void_p]

_gmk_expand = this_module['gmk_expand']
_gmk_expand.restype = ctypes.c_void_p # Need to manually convert to str
_gmk_expand.argtypes = [ ctypes.c_char_p ]


def gmk_char_to_string(s):
    """
    Convert a c_void_p to a Python string.
    This frees s!
    """
    if not s:
        return ''

    s = ctypes.cast(s, ctypes.c_char_p)
    ret = s.value.decode()
    _gmk_free(s)
    return ret


def value_to_gmk_char(obj):
    """
    Convert a Python object to a string suitable for passing to gnumake
    The string will be allocated with gmk_alloc, as required.

    obj: The python object to convert
    returns: A c_void_p that can be returned to gnumake
    """

    if obj is True:
        val = b'1'
    elif obj is False or obj is None:
        return None
    elif isinstance(obj, (bytes, bytearray)):
        val = obj
    elif isinstance(obj, str):
        val = obj.encode()
    else:
        try:
            val = bytes(memoryview(obj))
        except TypeError:
            try:
                val = str(obj).encode()
            except:
                return None

    ret = _gmk_alloc(len(val) + 1)
    ctypes.memmove(ret, val, len(val))
    ctypes.memset(ret + len(val), 0, 1)
    return ret

_callback_registry = {}


def escape_string(s):
    """
    Escape a string such that it can appear in a define directive.
    We need to escape 'endef', backslash-newline, and $.
    """
    s = s.replace('endef', '$()endef')
    s = s.replace('\\\n', '\\$()\n')
    s = s.replace('$', '$$')
    return s

def _real_callback(name, argc, argv):
    """
    This is the real code that interfaces between gnumake and Python.
    It converts the arguments from ctypes into a more Pythonic format, and
    it converts the return value into a string usable by gnumake.

    name:   Bytes/c_char_p name of the function being called
    argc:   The number of arguments in argv
    argv:   The arguments as an array of c_char_p.

    returns: A string allocated by gmk_alloc
    """

    ret = None

    try:
        if name in _callback_registry:
            args = [ argv[i].decode() for i in range(argc) ]
            s = _callback_registry[name](*args)

        # Don't return, or we never get to the 'else'
        ret = value_to_gmk_char(s)
    except Exception as e:
        if expand('$(PYTHON_PRINT_TRACEBACK)'):
            traceback.print_exc()

        err = escape_string("{}: {}".format(type(e).__name__, e))
        evaluate('define PYTHON_LAST_ERROR\n{}\nendef'.format(err))
    else:
        evaluate('undefine PYTHON_LAST_ERROR')

    return ret

_real_callback = _gmk_func_ptr(_real_callback)


def guess_function_parameters(func):
    """Guess function parameters. We only count positional arguments"""
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
    Decorator to expose a function to Python. Calls add_function on the
    given function.

    Examples:
    >>> @export
    ... def foo(*args):
    ...     pass

    >>> @export(name="make_name", min_args=1, max_args=3):
    ... def python_name(arg1, arg2=None, arg3=None):
    ...     pass

    May also be used as a function:
    >>> export(os.path.isfile)


    func:   The function to expose to GNU make
    name:   The GNU make name of the function. If omitted, defaults to the
            unqualified function name
    expand: If True (default) arguments to the function are expanded by make
            before the function is called. Otherwise the function receives
            the arguments verbatim, $(variables) and all.
    min_args:   The minimum number of arguments to the function. 
                If -1, (default) then the number of arguments will be guessed.
    max_args:   If > 0, the maximum number of arguments to the function. A
                value of 0 means any number of arguments. A value of -1
                (default) means that the number of parameters will be guessed.
    """
    if func is None:
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
        if name is None:
            name = func.__name__

        if expand:
            expand = GMK_FUNC_DEFAULT
        else:
            expand = GMK_FUNC_NOEXPAND

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



        # Error check here because GNU make will just exit on error.
        if max_args != 0 and max_args < min_args:
            raise ValueError("max_args < min_args")
        if max_args > 255 or min_args > 255:
            raise ValueError("too many args")
        if min_args < 0 or max_args < 0:
            raise ValueError("negative args")

        name = name.encode()
        if len(name) > 255:
            raise ValueError("name too long")

        _callback_registry[name] = func
        _gmk_add_function(name, _real_callback, min_args, max_args, expand)

        return func


def evaluate(s):
    """
    Evaluate a string as Makefile syntax, as if $(eval ...) had been used.
    """
    _gmk_eval(s.encode(), None)

def expand(s):
    """
    Expand a string according to Makefile rules
    """
    ret = _gmk_expand(s.encode())
    return gmk_char_to_string(ret)

@export(name='python-eval')
def python_eval(arg):
    """Evaluate a Python expression and return the result"""
    return eval(arg)

@export(name='python-file')
def python_file(script, *args):
    """
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
                exec(code, python_globals, python_globals)

            capture.seek(0)
            return capture.read().rstrip(b'\n')
    finally:
        os.dup2(stdout_original, 1)
        sys.argv = argv_original

@export(name="python-exec")
def python_exec(arg):
    """Run inline Python code"""
    stdout_original = os.dup(1)
    try:
        with tempfile.TemporaryFile() as capture:
            os.dup2(capture.fileno(), 1)

            code = compile(arg, '<python>', 'exec')
            exec(code, python_globals, python_globals)

            capture.seek(0)
            return capture.read().rstrip(b'\n')
    finally:
        os.dup2(stdout_original, 1)

