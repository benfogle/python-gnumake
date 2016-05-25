##############################################################################
# Setup
py-this-makefile := $(lastword $(MAKEFILE_LIST))
py-this-path := $(patsubst %/,%,$(realpath $(dir $(py-this-makefile))))

# Sanity check
ifeq ($(words $(filter-out $(MAKEFILES),$(MAKEFILE_LIST))),1)
ifneq ($(MAKELEVEL),0) # Top level is allowed
$(error Do not call this file recursively! Include it instead)
endif
endif

# Include guard
ifndef load-python-included
load-pyton-included := 1

##############################################################################
# Functions

# Find Python and C source in given subdirectories
#   $(1)   -- List of directories to search
#   Return -- List of source files
define find-python-sources
$(strip \
	$(shell find $(1) -name '*.py' -or -name '*.c' -or -name '*.h' \
				  -and -not -name '.*') \
)
endef

# Test if $(1) is a file
#   $(1)   -- File name
#   Return -- $(1) or empty
define is-file
$(shell [ -f "$(1)" ] && echo "$(1)")
endef



##############################################################################
# Variables that control how the plugin builds/loads

PYTHON_CLEAN ?= clean
PYTHON ?= python3

# Save this so we can restore it -- we don't want to add default rules
last-default := $(.DEFAULT_GOAL)

#############################################################################
# File paths

py-setup := $(py-this-path)/setup.py
py-build-base := $(py-this-path)/build
py-install-dir := $(py-this-path)/local_install
py-src-paths := $(py-this-path)/src $(py-this-path)/python
py-gnumake-plugin := $(wildcard $(py-install-dir)/gnumake/_gnumake*.so)

ifneq ($(words $(py-gnumake-plugin)),1)
# We need to guess the module name because either 1) it doesn't exist, or
# 2) there are multiple Python versions sharing that directory.
ifndef PYTHON_EXT_SUFFIX
PYTHON_EXT_SUFFIX := $(shell $(PYTHON) -c \
	'import sysconfig as s; print(s.get_config_var("EXT_SUFFIX") or \
								  s.get_config_var("SO"))')
endif
py-gnumake-plugin := $(py-install-dir)/gnumake/_gnumake$(PYTHON_EXT_SUFFIX)
endif

# We can't just make this a phony target or the makefiles won't restart
# properly
py-gnumake-sources := $(call find-python-sources,$(py-src-paths))


##############################################################################
# Rules to build the module

$(py-gnumake-plugin): export DISTUTILS_ONLY := 1
$(py-gnumake-plugin): $(py-gnumake-sources) $(py-this-path)/setup.py
	cd $(py-this-path) ;\
	$(PYTHON) $(py-setup) build $(PYTHON_BUILD_FLAGS) \
						--build-base $(py-build-base) \
						  install $(PYTHON_INSTALL_FLAGS) \
				  		--install-lib $(py-install-dir)
	touch $(py-gnumake-plugin)

# setup.py's clean gets this wrong: --build-base doesn't seem to work right.
$(PYTHON_CLEAN): py-clean-plugin

py-clean-plugin:
	rm -rf $(py-install-dir)
	rm -rf $(py-build-base)

.PHONY: py-clean-plugin


########################################################################
# Actually load the library


PYTHONPATH += $(py-install-dir)

# Don't load at all on clean -- it might be broken
ifeq ($(filter $(PYTHON_CLEAN),$(MAKECMDGOALS)),)
ifeq ($(call is-file,$(py-gnumake-plugin)),)
# Hasn't been built yet. Load optionally so that we can actually build it.
-load $(py-gnumake-plugin)
else
load $(py-gnumake-plugin)
endif # is-file
endif # clean

ifneq ($(filter $(py-gnumake-plugin),$(.LOADED)),)
PYTHON_LOADED := 1
else
undefine PYTHON_LOADED
endif


# Restore the default goal
.DEFAULT_GOAL := $(last-default)


endif

