# String utility functions

from gnumake import export
import string


# Many of these require explicit min_args and max_args, because they are
# built-in functions

@export
def strcmp(x, y):
    if   x < y: return '<'
    elif x > y: return '>'
    else: return '='

@export
def strlen(arg):
    return len(arg)

export(str.capitalize, name='strcapitalize', min_args=1, max_args=1)

@export
def strcenter(s, width, fillchar=' '):
    width = int(width)
    return s.center(width, fillchar)


@export
def strcount(s, sub, start='', end=''):
    if not start:
        start = None
    else:
        start = int(start)

    if not end:
        end = None
    else:
        end = int(end)

    return s.count(sub, start, end)


@export
def strendswith(s, suffix, start='', end=''):
    if not start:
        start = None
    else:
        start = int(start)

    if not end:
        end = None
    else:
        end = int(end)

    return s.endswith(suffix, start, end)


@export
def strexpandtabs(s, tabsize=8):
    return s.expandtabs(int(tabsize))



@export
def strindex(s, sub, start='', end=''):
    if not start:
        start = None
    else:
        start = int(start)

    if not end:
        end = None
    else:
        end = int(end)

    return s.index(sub, start, end)



export(str.isalnum, name='strisalnum', min_args=1, max_args=1)
export(str.isalpha, name='strisalpha', min_args=1, max_args=1)
export(str.isdigit, name='strisdigit', min_args=1, max_args=1)
export(str.isidentifier, name='strisidentifier', min_args=1, max_args=1)
export(str.islower, name='strislower', min_args=1, max_args=1)
export(str.isprintable, name='strisprintable', min_args=1, max_args=1)
export(str.isspace, name='strisspace', min_args=1, max_args=1)
export(str.istitle, name='stristitle', min_args=1, max_args=1)
export(str.isupper, name='strisupper', min_args=1, max_args=1)

@export
def strjoin(s, to_join):
    return s.join(to_join.split())

@export
def strljust(s, width, fillchar=' '):
    width = int(width)
    return s.ljust(width, fillchar)

export(str.lower, name='strlower', min_args=1, max_args=1)

@export
def strlstrip(s, chars=''):
    if not chars:
        chars = None
    return s.lstrip(chars)

@export
def strrindex(s, sub, start='', end=''):
    if not start:
        start = None
    else:
        start = int(start)

    if not end:
        end = None
    else:
        end = int(end)

    return s.rindex(sub, start, end)

@export
def strrjust(s, width, fillchar=' '):
    width = int(width)
    return s.rjust(width, fillchar)


@export
def strrsplit(s, sep='', maxsplit=''):
    if not sep:
        sep = None
    if not maxsplit:
        maxsplit = -1

    return ' '.join(s.rsplit(sep, int(maxsplit)))


@export
def strrstrip(s, chars=''):
    if not chars:
        chars = None
    return s.rstrip(chars)


@export
def strsplit(s, sep='', maxsplit=''):
    if not sep:
        sep = None
    if not maxsplit:
        maxsplit = -1

    return ' '.join(s.split(sep, int(maxsplit)))


@export
def strstartswith(s, suffix, start='', end=''):
    if not start:
        start = None
    else:
        start = int(start)

    if not end:
        end = None
    else:
        end = int(end)

    return s.startswith(suffix, start, end)

export(str.swapcase, name='strswapcase', min_args=1, max_args=1)
export(str.title, name='strtitle', min_args=1, max_args=1)

@export
def strtranslate(text, fromchars, tochars):
    return text.translate(dict(zip(map(ord, fromchars), tochars)))

export(str.upper, name='strupper', min_args=1, max_args=1)
