THIS_MAKEFILE := $(lastword $(MAKEFILE_LIST))
THIS_PATH := $(dir $(THIS_MAKEFILE))
TEST_NAME := python-file

include $(THIS_PATH)/common.mk

RESULT := $(python-file $(THIS_PATH)/scripts/1.py)
$(call assert-empty,PYTHON_LAST_ERROR)
$(call assert-empty,RESULT)

RESULT := $(python-file $(THIS_PATH)/scripts/2.py)
$(call assert-empty,PYTHON_LAST_ERROR)
$(call assert-equal,Hello,$(RESULT))

RESULT := $(python-file $(THIS_PATH)/scripts/3.py)
$(call assert-empty,PYTHON_LAST_ERROR)
$(call assert-empty,RESULT)

RESULT := $(python-file $(THIS_PATH)/scripts/4.py)
$(call assert-empty,PYTHON_LAST_ERROR)
$(call assert-equal,123,$(RESULT))

RESULT := $(python-file $(THIS_PATH)/scripts/5.py)
$(call assert-empty,RESULT)
$(call assert-match,^SyntaxError: invalid syntax,$(PYTHON_LAST_ERROR))


define expected
foo
bar
baz
endef

RESULT := $(python-file $(THIS_PATH)/scripts/6.py)
$(call assert-equal,$(expected),$(RESULT))
$(call assert-empty,PYTHON_LAST_ERROR)

