THIS_MAKEFILE := $(lastword $(MAKEFILE_LIST))
THIS_PATH := $(dir $(THIS_MAKEFILE))
TEST_NAME := python-eval

include $(THIS_PATH)/common.mk

RESULT := $(python-eval 'abc')
$(call assert-equal,abc,$(RESULT))
$(call assert-empty,PYTHON_LAST_ERROR)

RESULT := $(python-eval b'abc')
$(call assert-equal,abc,$(RESULT))
$(call assert-empty,PYTHON_LAST_ERROR)

RESULT := $(python-eval b'\x61\x62\x63')
$(call assert-equal,abc,$(RESULT))
$(call assert-empty,PYTHON_LAST_ERROR)

RESULT := $(python-eval None)
$(call assert-empty,RESULT)
$(call assert-empty,PYTHON_LAST_ERROR)

RESULT := $(python-eval False)
$(call assert-empty,RESULT)
$(call assert-empty,PYTHON_LAST_ERROR)

RESULT := $(python-eval True)
$(call assert-not-empty,RESULT)
$(call assert-empty,PYTHON_LAST_ERROR)

RESULT := $(python-eval [1,2,3])
$(call assert-equal,[1$(comma) 2$(comma) 3],$(RESULT))
$(call assert-empty,PYTHON_LAST_ERROR)

RESULT := $(python-eval min(1,2))
$(call assert-equal,1,$(RESULT))
$(call assert-empty,PYTHON_LAST_ERROR)

RESULT := $(python-eval a b c)
$(call assert-empty,RESULT)
$(call assert-match,^SyntaxError: invalid syntax,$(PYTHON_LAST_ERROR))
