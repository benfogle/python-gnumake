# This is a dangerous module! It hooks into internal GNU make functions.
# What could go wrong?

import ctypes
import gnumake

this_module = ctypes.PyDLL(None) # Don't release the GIL
_version_string = ctypes.c_char_p.in_dll(this_module, 'version_string')
version_string = _version_string.value


assert version_string == b'4.0', 'TODO! Only working with version 4.0'

class gmk_floc(ctypes.Structure):
    _fields_ = [
            ('filenm', ctypes.c_char_p),
            ('lineno', ctypes.c_ulong),
        ]

class gmk_file(ctypes.Structure): pass
gmk_file_p = ctypes.POINTER(gmk_file)

class gmk_dep(ctypes.Structure): pass
gmk_dep_p = ctypes.POINTER(gmk_dep)

class gmk_commands(ctypes.Structure): pass
gmk_commands_p = ctypes.POINTER(gmk_commands)

gmk_commands._fields_ = [
        ('commands', ctypes.c_char_p),
        ('command_lines', ctypes.POINTER(ctypes.c_char_p)),
        ('lines_flags', ctypes.POINTER(ctypes.c_uint8)),
        ('ncommand_lines', ctypes.c_ushort),
        ('recipe_prefix', ctypes.c_char),
        ('any_recurse', ctypes.c_uint)
    ]

gmk_dep._fields_ = [
        ('next', gmk_dep_p),
        ('name', ctypes.c_char_p),
        ('stem', ctypes.c_char_p),
        ('file', gmk_file_p),
        ('flags', ctypes.c_ushort)
    ]

gmk_file._fields_ = [
        ('name', ctypes.c_char_p),  
        ('hname', ctypes.c_char_p), # hashed name
        ('vpath', ctypes.c_char_p),
        ('deps', gmk_dep_p),
        ('cmds', gmk_commands_p),
        ('stem', ctypes.c_char_p),
        ('also_make', gmk_dep_p),
        ('prev', gmk_file_p),
        ('last', gmk_file_p),
        ('renamed', gmk_file_p),
        ('variables', ctypes.c_void_p),
        ('pat_variables', ctypes.c_void_p),
        ('parent', gmk_file_p),
        ('double_colon', gmk_file_p),
        ('last_mtime', ctypes.c_uint64),
        ('mtime_before_update', ctypes.c_uint64),
        ('command_flags', ctypes.c_int),
        # There's more...TODO. Lots of bitfields.
    ]   

lookup_file = this_module['lookup_file']
lookup_file.restype = gmk_file_p
lookup_file.argtypes = [ ctypes.c_char_p ]

def iter_prereqs(name):
    f = lookup_file(name.encode())
    if not f:
        return
    
    d = f[0].deps

    while d:
        if d[0].file:
            yield d[0].file[0].name
        d = d[0].next

@gnumake.export
def prereqs(name):
    return b' '.join(iter_prereqs(name))
