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

try:
    add_function = gmk.add_function

    def export(func=None, *, name=None, expand=True, min_args=0,
                                                     max_args=0):
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
        """
        if func is None:
            # Decorator with arguments
            def inner(func):
                _name = name
                if _name is None:
                    _name = func.__name__
                add_function(_name, func, min_args, max_args, expand)
                return func
            return inner
        else:
            # Decorator or functional form
            if name is None:
                name = func.__name__
            add_function(name, func, min_args, max_args, expand)
            return func

    
    def evaluate(s):
        """
        Evaluate a string as Makefile syntax, as if $(eval ...) had been used.
        """

        cur_frame = inspect.currentframe()
        _, fname, lineno, _, _, _ = inspect.getouterframes(cur_frame)[1]
        gmk.eval(s, fname, lineno)

    def expand(s):
        """
        Expand a string according to Makefile rules
        """
        return gmk.expand(s)

    @export(name='python-eval', min_args=1, max_args=1)
    def python_eval(arg):
        """Evaluate a Python expression and return the result"""
        try:
            return eval(arg)
        except Exception as e:
            traceback.print_exc()

    @export(name='python-file', min_args=1)
    def python_file(*args):
        """Run a Python script, optionally passing arguments to it.

        Unlike a script run with $(shell ...), this script will have
        access to Makefile variables, etc.
        """

        argv_original = sys.argv
        stdout_original = os.dup(1)
        try:
            script = args[0]
            sys.argv = args
            with tempfile.TemporaryFile() as capture:
                os.dup2(capture.fileno(), 1)

                with open(script) as fp:
                    code = compile(fp.read(), script, 'exec')
                    exec(code, gmk.global_state, gmk.global_state)

                capture.seek(0)
                return capture.read().rstrip(b'\n')
        except Exception as e:
            traceback.print_exc()
        finally:
            os.dup2(stdout_original, 1)
            sys.argv = argv_original

    @export(name="python-exec", min_args=1, max_args=1)
    def python_exec(arg):
        """Run inline Python code"""
        try:
            code = compile(arg, '<python>', 'exec')
            exec(code, gmk.global_state, gmk.global_state)
        except Exception as e:
            traceback.print_exc()
        
except AttributeError:
    pass

