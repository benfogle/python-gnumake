THIS_MAKEFILE := $(lastword $(MAKEFILE_LIST))
THIS_PATH := $(dir $(THIS_MAKEFILE))
TEST_NAME := python-mod

include $(THIS_PATH)/common.mk
.PYTHON_PRINT_TRACEBACK = 1

# Test an empty module
RESULT := $(python-mod mod_1)
$(call assert-empty,.PYTHON_LAST_ERROR)
$(call assert-empty,RESULT)

# Test a module that just prints 'Hello'
RESULT := $(python-mod mod_2)
$(call assert-empty,.PYTHON_LAST_ERROR)
$(call assert-equal,Hello,$(RESULT))

# Test a module that assigns a value
RESULT := $(python-mod mod_3)
$(call assert-empty,.PYTHON_LAST_ERROR)
$(call assert-empty,RESULT)

# Test that modules are isolated from each other and global variables are not visible
RESULT := $(python-mod mod_4)
$(call assert-empty,.PYTHON_LAST_ERROR)
$(call assert-empty,RESULT)

# Test an error being triggered
RESULT := $(python-mod mod_5)
$(call assert-empty,RESULT)
$(call assert-match,^SyntaxError: invalid syntax,$(.PYTHON_LAST_ERROR))

# Test printing out multiple items
define expected
foo
bar
baz
endef

RESULT := $(python-mod mod_6)
$(call assert-equal,$(expected),$(RESULT))
$(call assert-empty,.PYTHON_LAST_ERROR)

