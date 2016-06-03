THIS_MAKEFILE := $(lastword $(MAKEFILE_LIST))
THIS_PATH := $(dir $(THIS_MAKEFILE))
TEST_NAME := python-exec

include $(THIS_PATH)/common.mk

RESULT := $(python-exec '1')
$(call assert-empty,.PYTHON_LAST_ERROR)
$(call assert-empty,RESULT)

RESULT := $(python-exec print('Hello'))
$(call assert-empty,.PYTHON_LAST_ERROR)
$(call assert-equal,Hello,$(RESULT))

RESULT := $(python-exec foo=123)
$(call assert-empty,.PYTHON_LAST_ERROR)
$(call assert-empty,RESULT)

RESULT := $(python-exec print(foo))
$(call assert-empty,.PYTHON_LAST_ERROR)
$(call assert-equal,123,$(RESULT))

RESULT := $(python-exec a b c)
$(call assert-empty,RESULT)
$(call assert-match,^SyntaxError: invalid syntax,$(.PYTHON_LAST_ERROR))


define expected
foo
bar
baz
endef

RESULT := $(python-exec print('foo\nbar\nbaz'))
$(call assert-equal,$(expected),$(RESULT))
$(call assert-empty,.PYTHON_LAST_ERROR)

define commands
print("foo")
print("bar")
print("baz")
endef

RESULT := $(python-exec $(commands))
$(call assert-equal,$(expected),$(RESULT))
$(call assert-empty,.PYTHON_LAST_ERROR)

