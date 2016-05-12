load $(shell python3 -m gnumake)

# A basic Python expression:
VAR1 := $(python-eval 'Hello, make')
$(info VAR1 = $(VAR1))

NUMBERS=1 2 3 4 5 6 7 8 9 10
SUM=$(python-eval sum(int(x) for x in '$(NUMBERS)'.split()))
$(info SUM = $(SUM))

MY_MAKEFILE := $(lastword $(MAKEFILE_LIST))
MY_DIR := $(dir $(MY_MAKEFILE))

# Define some new functions
$(python-file $(MY_DIR)/basic.py)
IS_FILE := $(isfile $(MY_MAKEFILE))
IS_DIR := $(isdir $(MY_MAKEFILE))
$(info IS_FILE = $(IS_FILE))
$(info IS_DIR = $(IS_DIR))


all:
