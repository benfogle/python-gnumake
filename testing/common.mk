include $(THIS_PATH)/../load-python.mk

comma=,
empty=
space=$(empty) $(empty)
tab=$(empty)	$(empty)

# If we define these as is, then on a clean build, before our python module
# has been built, the assertions will fail. This will cause the makefile to
# exit before we have a chance to build and reload.
ifdef .PYTHON_LOADED

define assert-equal-ev
ifneq ($$(1),$$(2))
$$(info -------------------------------------------------------------------)
$$(info - $$(strip Test $$(TEST_NAME) FAILED))
$$(info -     Expected '$$(1)', got '$$(2)')
$$(info -------------------------------------------------------------------)
$$(error $$(strip Test $$(TEST_NAME) FAILED))
endif
endef

define assert-equal
$(eval $(call assert-equal-ev,$(1),$(2)))
endef

define assert-not-equal-ev
ifeq ($$(1),$$(2))
$$(info -------------------------------------------------------------------)
$$(info - $$(strip Test $$(TEST_NAME) FAILED))
$$(info -     Expected '$$(1)', got '$$(2)')
$$(info -------------------------------------------------------------------)
$$(error $$(strip Test $$(TEST_NAME) FAILED))
endif
endef

define assert-not-equal
$(eval $(call assert-not-equal-ev,$(1),$(2)))
endef


define assert-contains-ev
ifeq ($$(filter $$(1),$$(2)),)
$$(info -------------------------------------------------------------------)
$$(info - $$(strip Test $$(TEST_NAME) FAILED))
$$(info -     Value '$$(1)' not in '$$(2)')
$$(info -------------------------------------------------------------------)
$$(error $$(strip Test $$(TEST_NAME) FAILED))
endif
endef

define assert-contains
$(eval $(call assert-contains-ev,$(1),$(2)))
endef


define assert-match-ev
_pattern := $$(subst \,\\,$$(2))
_pattern := $$(subst $$$$,\\$$$$,$$(2))
_pattern := $$(subst ",\",$$(_pattern))
_result := $$(shell ( echo "$$(_pattern)" | grep -q '$$(1)' ) && echo 1)
ifneq ($$(_result),1)
$$(info -------------------------------------------------------------------)
$$(info - $$(strip Test $$(TEST_NAME) FAILED))
$$(info -     '$$(2)' does not match pattern '$$(1)')
$$(info -------------------------------------------------------------------)
$$(error $$(strip Test $$(TEST_NAME) FAILED))
endif
endef

define assert-match
$(eval $(call assert-match-ev,$(1),$(2)))
endef

define assert-not-empty-ev
ifeq ($$($$(1)),)
$$(info -------------------------------------------------------------------)
$$(info - $$(strip Test $$(TEST_NAME) FAILED))
$$(info -     Value of $$(1) was empty or undefined)
$$(info -------------------------------------------------------------------)
$$(error $$(strip Test $$(TEST_NAME) FAILED))
endif
endef

define assert-not-empty
$(eval $(call assert-not-empty-ev,$(1)))
endef


define assert-empty-ev
ifneq ($$($$(1)),)
$$(info -------------------------------------------------------------------)
$$(info - $$(strip Test $$(TEST_NAME) FAILED))
$$(info -     Value of $$(1) should be empty or undefined, was '$$($$(1))')
$$(info -------------------------------------------------------------------)
$$(error $$(strip Test $$(TEST_NAME) FAILED))
endif
endef

define assert-empty
$(eval $(call assert-empty-ev,$(1)))
endef

define assert-defined-ev
ifndef $$(1)
$$(info -------------------------------------------------------------------)
$$(info - $$(strip Test $$(TEST_NAME) FAILED))
$$(info -     Value of $$(1) was undefined
$$(info -------------------------------------------------------------------)
$$(error $$(strip Test $$(TEST_NAME) FAILED))
endif
endef

define assert-defined
$(eval $(call assert-defined-ev,$(1)))
endef

define assert-undefined-ev
ifdef $$(1)
$$(info -------------------------------------------------------------------)
$$(info - $$(strip Test $$(TEST_NAME) FAILED))
$$(info -     Value of $$(1) should be undefined, was '$$($$(1))')
$$(info -------------------------------------------------------------------)
$$(error $$(strip Test $$(TEST_NAME) FAILED))
endif
endef

define assert-undefined
$(eval $(call assert-undefined-ev,$(1)))
endef


define fail-test-ev
$$(info -------------------------------------------------------------------)
$$(info - $$(strip Test $$(TEST_NAME) FAILED))
ifneq ($(strip $(1)),)
$$(info -     $$(1))
endif
$$(info -------------------------------------------------------------------)
$$(error $$(strip Test $$(TEST_NAME) FAILED))
endef

define fail-test
$(eval $(call fail-test-ev,$(1)))
endef




run_tests:
	@echo '-------------------------------------------------------------------'
	@echo '- $(strip Test $(TEST_NAME) PASSED)'
	@echo '-------------------------------------------------------------------'
	@echo



endif	# .PYTHON_LOADED
