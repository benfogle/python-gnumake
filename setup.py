
import os
import sysconfig

# Are we being built from the command line (for installation) or from 
# load-python.mk (part of a larger build)?
#
# The difference is whether or not we use setuptools. We don't actually _need_
# it, and it's far more 'helpful' in pointing out that non-standard install
# directories won't work for reasons that don't apply during the latter method.
#
# Setuptools is still used for the install version because we can more easily
# work with PyPi, etc.
if os.getenv('DISTUTILS_ONLY'):
    from distutils.core import setup, Extension
else:
    try:
        from setuptools import setup, Extension
    except ImportError:
        from distutils.core import setup, Extension


# We dynamically link against Python so that when we are loaded from make
# we can host an interpreter ourselves. When we are loaded from Python,
# which generally won't happen anyway, this will be benign.

python_libdir = sysconfig.get_config_var('LIBDIR')
python_libdir += sysconfig.get_config_var('multiarchsubdir') or ''
python_library = sysconfig.get_config_var("LDLIBRARY")

python_library = os.path.join(python_libdir, python_library)


_gnumake = Extension('gnumake._gnumake',
                     sources = [
                         'src/gnumake.c',
                         'src/gmk_api.c',
                     ],
                     runtime_library_dirs = [
                         python_libdir,
                     ],
                     export_symbols = [ 
                        'PyInit__gnumake',
                        '_gnumake_gmk_setup',
                     ],
                     extra_compile_args = [
                         '-Wall', 
                         '-Werror' 
                     ],
                     extra_objects = [
                         python_library,
                     ],
                )

setup(
    name = "gnumake",
    version = "0.2",
    package_dir = { '' : 'python' },
    packages = [ 'gnumake',
               ],
    ext_modules = [ _gnumake ],
)
