load $(shell python3 -m gnumake)

# A basic Python expression:
VAR1 := $(python-eval 'Hello, make')
$(info VAR1 = $(VAR1))

NUMBERS=1 2 3 4 5 6 7 8 9 10
SUM=$(python-eval sum(int(x) for x in '$(NUMBERS)'.split()))
$(info SUM = $(SUM))

MY_MAKEFILE := $(lastword $(MAKEFILE_LIST))
MY_DIR := $(dir $(MY_MAKEFILE))

# Execute an inline-script

define mypython
import random

# Function to return a random integer
@gnumake.export(min_args=1, max_args=1)
def gen_random(n):
	import random
	n = int(n)
	return random.randint(1,n)

# Implement a special variable named RANDOM
gnumake.evaluate('RANDOM = $$(gen_random 100)')
endef

$(python-exec $(mypython))
$(info RANDOM = $(RANDOM))
$(info RANDOM = $(RANDOM))
$(info RANDOM = $(RANDOM))


# Define some new functions
$(python-file $(MY_DIR)/basic.py)
IS_FILE := $(isfile $(MY_MAKEFILE))
IS_DIR := $(isdir $(MY_MAKEFILE))
$(info IS_FILE = $(IS_FILE))
$(info IS_DIR = $(IS_DIR))

all:
