py-this-makefile := $(lastword $(MAKEFILE_LIST))
py-this-path := $(patsubst %/,%,$(realpath $(dir $(py-this-makefile))))

# Include guard
ifeq ($(words $(filter $(py-this-makefile),$(MAKEFILE_LIST))),1)

# Find Python and C source in given subdirectories
#   $(1) -- List of directories to search
define py-find-sources
$(shell find $(1) -name '*.py' -or -name '*.c' -or -name '*.h' \
				  -and -not -name '.*')
endef

# Test if $(1) is a file
define is-file
$(shell [ -f "$(1)" ] && echo "$(1)")
endef

# Sanity check
ifeq ($(words $(MAKEFILE_LIST)),1)
ifneq ($(MAKELEVEL),0)
$(error Do not call this file recursively! Include it instead)
endif
endif

# Save this so we can restore it -- we don't want to add default rules
last-default := $(.DEFAULT_GOAL)


#############################################################################
# Build the libray, if needed

PYTHON_CLEAN ?= clean
PYTHON ?= python3

py-setup := $(py-this-path)/setup.py
py-build-base := $(py-this-path)/build
py-install-dir := $(py-this-path)/local_install

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
py-gnumake-sources := \
	$(call py-find-sources,$(py-this-path)/src $(py-this-path)/python)
$(py-gnumake-plugin): export CALLED_FROM_LOAD_PYTHON_MK := 1
$(py-gnumake-plugin): $(py-gnumake-sources) $(py-this-path)/setup.py
	cd $(py-this-path) ;\
	$(PYTHON) $(py-setup) build $(PYTHON_BUILD_FLAGS) \
						--build-base $(py-build-base) \
						  install $(PYTHON_INSTALL_FLAGS) \
				  		--install-lib $(py-install-dir)

# setup.py's clean gets this wrong: --build-base doesn't seem to work right.
$(PYTHON_CLEAN):
	rm -rf $(py-install-dir)
	rm -rf $(py-build-base)

.PHONY: $(PYTHON_CLEAN)


########################################################################
# Actually load the library


ifeq ($(filter $(PYTHON_CLEAN),$(MAKECMDGOALS)),)
# Don't load at all on clean -- it might be broken
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

