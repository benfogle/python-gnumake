THIS_MAKEFILE := $(abspath $(lastword $(MAKEFILE_LIST)))
THIS_PATH := $(dir $(THIS_MAKEFILE))

# Save this so we can restore it
last-default := $(.DEFAULT_GOAL)

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
# This makefile _must_ be called recursively. We need to be 100% sure that the
# extension got built before returning, or who knows what the including
# makefile will end up doing. Since we have no dependencies on anything outside
# this directory, and since the user should be including load-python.mk before
# anything else, we can get away with it.

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
		'import sysconfig as s; print(s.get_config_var("multiarchsubdir"))')
endif

ifndef PYTHON_LDLIBRARY
	PYTHON_LDLIBRARY := $(shell $(PYTHON) -c \
		'import sysconfig as s; print(s.get_config_var("LDLIBRARY"))')
	PYTHON_LDLIBRARY := $(PYTHON_LIBDIR)/$(PYTHON_LDLIBRARY)
endif

python-gnumake-sources := $(wildcard $(THIS_PATH)/src/*.c)

python-gnumake-objs := $(python-gnumake-sources:.c=.o)
$(python-gnumake-objs): CFLAGS += -fPIC
$(python-gnumake-objs): CPPFLAGS += -DPYTHON_NAME=L\"$(shell which $(PYTHON))\"
$(python-gnumake-objs): CPPFLAGS += -I$(PYTHON_INCLUDE) 

python-gnumake-lib := $(THIS_PATH)/gnumake/_gnumake.so
$(python-gnumake-lib) : LDFLAGS += -L$(PYTHON_LIBDIR)
$(python-gnumake-lib) : LDFLAGS += -Wl,-rpath=$(PYTHON_LIBDIR)
$(python-gnumake-lib) : LDLIBS += $(PYTHON_LDLIBRARY)

$(python-gnumake-lib): $(python-gnumake-objs)
	$(CC) -o $@ -shared $(LDFLAGS) $^ $(LDLIBS)

python-gnumake-deps := $(SOURCES:.c=.d)
-include $(python-gnumake-deps)

%.d.tmp: %.c
	$(CC) -M $(CPPFLAGS) $< > $@

%.d: %.d.tmp
	sed 's,\($*\)\.o[ :]*,\1.o $@ : ,g' < $@.tmp > $@

clean:
	rm -f $(python-gnumake-objs) $(python-gnumake-deps) $(python-gnumake-lib)

.PHONY: clean


###############################3
# Actually load the library
define is-file
$(shell [ -f "$(1)" ] && echo "$(1)")
endef

ifeq ($(filter clean,$(MAKECMDGOALS)),)
# Don't load at all on clean
ifeq ($(call is-file,$(python-gnumake-lib)),)
# Hasn't been built yet. Load optionally so that we can actually build it.
-load $(python-gnumake-lib)
else
load $(python-gnumake-lib)
endif # is-file
endif # clean


# Restore the default goal
.DEFAULT_GOAL := $(last-default)
