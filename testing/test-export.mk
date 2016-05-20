THIS_MAKEFILE := $(lastword $(MAKEFILE_LIST))
THIS_PATH := $(dir $(THIS_MAKEFILE))
TEST_NAME := exported functions

include $(THIS_PATH)/common.mk

define python_code
from functools import reduce
from operator import mul

@gnumake.export
def product(*args):
	return reduce(mul, (int(a) for a in args))

gnumake.export(product, name='product_two')

@gnumake.export(name='product-sqr')
def product_square(*args):
	return reduce(mul, (int(a)**2 for a in args))

endef

$(python-exec $(python_code))
$(call assert-empty,PYTHON_LAST_ERROR)

RESULT := $(product 1,2,3,4,5)
$(call assert-equal,120,$(RESULT))
$(call assert-empty,PYTHON_LAST_ERROR)

RESULT := $(product 1,2,3,4,5,cow)
$(call assert-empty,RESULT)
$(call assert-match,^ValueError: invalid literal for int,$(PYTHON_LAST_ERROR))

RESULT := $(product_two 1,2,3,4,5)
$(call assert-equal,120,$(RESULT))
$(call assert-empty,PYTHON_LAST_ERROR)

RESULT := $(product-sqr 1,2,3,4,5)
$(call assert-equal,14400,$(RESULT))
$(call assert-empty,PYTHON_LAST_ERROR)

RESULT := $(product-square 1,2,3,4,5)
$(call assert-empty,RESULT)

# Can't test argument count without crashing the makefile. Probably need to
# call something from the shell.
