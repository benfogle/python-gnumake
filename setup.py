from setuptools import setup, find_packages, Extension
from distutils.sysconfig import get_python_inc
import sysconfig
import os

# We dynamically link against Python so that when we are loaded from make
# we can host an interpreter ourselves. When we are loaded from Python,
# this will be benign.

python_libdir = sysconfig.get_config_var('LIBDIR')
multiarchsubdir = sysconfig.get_config_var('multiarchsubdir') # may be empty
python_libdir = os.path.join(python_libdir, multiarchsubdir)
python_library = sysconfig.get_config_var("LDLIBRARY")
python_library = os.path.join(python_libdir, python_library)

# Guess binary name from include dir
# Is there an official way to do this?
python_name = os.path.basename(sysconfig.get_path('include'))

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
                     extra_link_args = [
                         '-Wl,-rpath={}'.format(python_libdir),
                     ],
                     define_macros = [
                         ('PYTHON_NAME', 'L"{}"'.format(python_name)),
                     ],
                )

setup(
    name = "gnumake",
    version = "0.1",
    packages = [ 'gnumake' ],
    ext_modules = [ _gnumake ],
)
