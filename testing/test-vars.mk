THIS_MAKEFILE := $(lastword $(MAKEFILE_LIST))
THIS_PATH := $(dir $(THIS_MAKEFILE))
TEST_NAME := gnumake.variables

include $(THIS_PATH)/common.mk

FOO := abc

RESULT := $(python-eval gnumake.variables['FOO'])
$(call assert-equal,abc,$(RESULT))
$(call assert-empty,PYTHON_LAST_ERROR)

RESULT := $(python-eval gnumake.var['FOO'])
$(call assert-equal,abc,$(RESULT))
$(call assert-empty,PYTHON_LAST_ERROR)

$(python-exec gnumake.var['QWERTY']=1234)
$(call assert-empty,PYTHON_LAST_ERROR)
$(call assert-equal,1234,$(QWERTY))

RESULT := $(python-eval gnumake.var.get('NOTHERE'))
$(call assert-empty,PYTHON_LAST_ERROR)
$(call assert-empty,RESULT)

RESULT := $(python-eval gnumake.var.get('NOTHERE', 'foo'))
$(call assert-empty,PYTHON_LAST_ERROR)
$(call assert-equal,foo,$(RESULT))

FOO = abc
BAR = x$(FOO)y
RESULT := $(python-eval gnumake.var.get('BAR'))
$(call assert-empty,PYTHON_LAST_ERROR)
$(call assert-equal,xabcy,$(RESULT))

FOO = abc
BAR = x$(FOO)y
RESULT := $(python-eval gnumake.var.get('BAR', expand_value=False))
$(call assert-empty,PYTHON_LAST_ERROR)
$(call assert-equal,x$$(FOO)y,$(RESULT))

# Make sure to escape the $ in inline Python
FOO = abc
$(python-exec gnumake.var.set('BAZ', '-$$(FOO)-'))
FOO = xyz
$(call assert-empty,PYTHON_LAST_ERROR)
$(call assert-equal,-xyz-,$(BAZ))

FOO = abc
$(python-exec gnumake.var['BAZ2'] = '-$$(FOO)-')
FOO = xyz
$(call assert-empty,PYTHON_LAST_ERROR)
$(call assert-equal,-xyz-,$(BAZ2))

FOO = abc
$(python-exec gnumake.var.set('BAZ', '-$$(FOO)-', 'simple'))
FOO = xyz
$(call assert-empty,PYTHON_LAST_ERROR)
$(call assert-equal,-abc-,$(BAZ))

BAZ = blah
$(python-exec gnumake.var.undefine('BAZ'))
$(call assert-empty,PYTHON_LAST_ERROR)
$(call assert-undefined BAZ)

BAZ = blah
$(python-exec del gnumake.var['BAZ'])
$(call assert-empty,PYTHON_LAST_ERROR)
$(call assert-undefined BAZ)

undefine BAZ
RESULT := $(python-eval gnumake.var.defined('BAZ'))
$(call assert-empty,PYTHON_LAST_ERROR)
$(call assert-empty,RESULT)

BAZ = blah
RESULT := $(python-eval gnumake.var.defined('BAZ'))
$(call assert-empty,PYTHON_LAST_ERROR)
$(call assert-not-empty,RESULT)

undefine BAZ
RESULT := $(python-eval 'BAZ' in gnumake.var)
$(call assert-empty,PYTHON_LAST_ERROR)
$(call assert-empty,RESULT)

BAZ = blah
RESULT := $(python-eval 'BAZ' in gnumake.var)
$(call assert-empty,PYTHON_LAST_ERROR)
$(call assert-not-empty,RESULT)

close-paren=)
open-paren=(
RESULT := $(python-eval gnumake.var.get('$(close-paren)$$$(open-paren)shell echo FAIL'))
$(call assert-equal,ValueError: Illegal name,$(PYTHON_LAST_ERROR))
$(call assert-empty,RESULT)

FOO = bar
RESULT := $(python-eval gnumake.var.origin('FOO'))
$(call assert-empty,PYTHON_LAST_ERROR)
$(call assert-equal,file,$(RESULT))

RESULT := $(python-eval gnumake.var.origin('NOTHERE'))
$(call assert-empty,PYTHON_LAST_ERROR)
$(call assert-equal,undefined,$(RESULT))

RESULT := $(python-eval gnumake.var.origin('HOME'))
$(call assert-empty,PYTHON_LAST_ERROR)
$(call assert-equal,environment,$(RESULT))

FOO = bar
RESULT := $(python-eval gnumake.var.flavor('FOO'))
$(call assert-empty,PYTHON_LAST_ERROR)
$(call assert-equal,recursive,$(RESULT))

FOO := bar
RESULT := $(python-eval gnumake.var.flavor('FOO'))
$(call assert-empty,PYTHON_LAST_ERROR)
$(call assert-equal,simple,$(RESULT))

undefine FOO
RESULT := $(python-eval gnumake.var.flavor('FOO'))
$(call assert-empty,PYTHON_LAST_ERROR)
$(call assert-equal,undefined,$(RESULT))

