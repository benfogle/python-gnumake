THIS_MAKEFILE := $(lastword $(MAKEFILE_LIST))
THIS_PATH := $(dir $(THIS_MAKEFILE))

# Make sure test modules are available on the path
export PYTHONPATH := $(abspath $(THIS_PATH)/scripts):$(PYTHONPATH)

# Test files are called recursively. This way we know that each test is
# independent from the others.

TEST_FILES := $(wildcard $(THIS_PATH)/test*.mk)
tests: $(TEST_FILES)
	set -e; \
	for testfile in $(TEST_FILES); do \
		$(MAKE) -f $$testfile ; \
	done


.PHONY: tests

