from setuptools import setup, find_packages, Extension
from distutils.sysconfig import get_python_inc
import os

# We dynamically link against Python so that when we are loaded from make
# we can host an interpreter ourselves. When we are loaded from Python,
# this will be benign.
# Not sure if there's a better way to get the library name.
python_library = os.path.basename(get_python_inc())

_gnumake = Extension('gnumake._gnumake',
                     sources = [
                         'src/gnumake.c',
                         'src/stubs.c',
                         'src/utils.c'
                     ],
                     libraries = [
                         python_library
                     ],
                     export_symbols = [ 
                        'PyInit__gnumake',
                        '_gnumake_gmk_setup',
                     ],
                     extra_compile_args = [
                         '-Wall', 
                         '-Werror' 
                     ],
                     define_macros = [
                         ('PYTHON_NAME', 'L"{}"'.format(python_library)),
                     ],
                )

setup(
    name = "gnumake",
    version = "0.1",
    packages = [ 'gnumake' ],
    ext_modules = [ _gnumake ],
)
