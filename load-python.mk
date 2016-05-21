py-this-makefile := $(abspath $(lastword $(MAKEFILE_LIST)))
py-this-path := $(dir $(py-this-makefile))

PYTHONPATH += $(py-this-path)

# Save this so we can restore it
last-default := $(.DEFAULT_GOAL)

PYTHON_CLEAN ?= clean

# Sanity check
ifeq ($(words $(MAKEFILE_LIST)),1)
ifneq ($(MAKELEVEL),0)
$(error Do not call this file recursively! Include it instead)
endif
endif

# Build using make instead of setuptools, though we will generally mimic
# setuptools settings.
#
# The point of this is to bootstrap this module directly from a git checkout.
#

ifndef PYTHON
	PYTHON := python3
endif

ifndef PYTHON_INCLUDE
	PYTHON_INCLUDE := $(shell $(PYTHON) -c \
		'import sysconfig as s; print(s.get_path("include"))')
endif

ifndef PYTHON_LIBDIR
	PYTHON_LIBDIR := $(shell $(PYTHON) -c \
		'import sysconfig as s; print(s.get_config_var("LIBDIR"))')
	PYTHON_LIBDIR := $(PYTHON_LIBDIR)$(shell $(PYTHON) -c \
		'import sysconfig as s; print(s.get_config_var("multiarchsubdir") or "")')
endif

ifndef PYTHON_LDLIBRARY
	PYTHON_LDLIBRARY := $(shell $(PYTHON) -c \
		'import sysconfig as s; print(s.get_config_var("LDLIBRARY"))')
	PYTHON_LDLIBRARY := $(PYTHON_LIBDIR)/$(PYTHON_LDLIBRARY)
endif

python-gnumake-sources := $(wildcard $(py-this-path)/src/*.c)

python-cppflags := -DPYTHON_NAME=L\"$(shell which $(PYTHON))\" \
				   -I$(PYTHON_INCLUDE)  \
				   -pthread -g -O0 #-O2 -DNDEBUG
python-cflags := -fPIC -Wall -Werror

python-ldflags := -L$(PYTHON_LIBDIR) \
				  -Wl,-rpath=$(PYTHON_LIBDIR) \
				  -pthread 

python-gnumake-objs := $(python-gnumake-sources:.c=.o)
$(python-gnumake-objs): CC = gcc
$(python-gnumake-objs): CFLAGS += $(python-cflags)
$(python-gnumake-objs): CPPFLAGS += $(python-cppflags)

python-gnumake-lib := $(py-this-path)/gnumake/_gnumake.so
$(python-gnumake-lib) : LDFLAGS += $(python-ldflags)
$(python-gnumake-lib) : LDLIBS += $(PYTHON_LDLIBRARY)
$(python-gnumake-lib) : CC = gcc

$(python-gnumake-lib): $(python-gnumake-objs)
	$(CC) -o $@ -shared $(LDFLAGS) $^ $(LDLIBS)


ifeq ($(filter $(PYTHON_CLEAN),$(MAKECMDGOALS)),)
# Skip deps on clean
python-gnumake-deps := $(python-gnumake-sources:.c=.d)
-include $(python-gnumake-deps)

%.d.tmp: CPPFLAGS += $(python-cppflags)
%.d.tmp: CFLAGS += $(python-cflags)
%.d.tmp: %.c
	$(CC) -M $(CPPFLAGS) $< > $@

%.d: %.d.tmp
	sed 's,\($*\)\.o[ :]*,\1.o $@ : ,g' < $@.tmp > $@

endif # clean

$(PYTHON_CLEAN):
	rm -f src/*.o src/*.d
	rm -rf $(py-this-path)/gnumake/__pycache__ $(py-this-path)/gnumake/*.so

.PHONY: $(PYTHON_CLEAN)


###############################3
# Actually load the library
define is-file
$(shell [ -f "$(1)" ] && echo "$(1)")
endef


ifeq ($(filter $(PYTHON_CLEAN),$(MAKECMDGOALS)),)
# Don't load at all on clean
ifeq ($(call is-file,$(python-gnumake-lib)),)
# Hasn't been built yet. Load optionally so that we can actually build it.
-load $(python-gnumake-lib)
else
load $(python-gnumake-lib)
endif # is-file
endif # clean

ifneq ($(filter $(python-gnumake-lib),$(.LOADED)),)
PYTHON_LOADED := 1
else
undefine PYTHON_LOADED
endif


# Restore the default goal
.DEFAULT_GOAL := $(last-default)
