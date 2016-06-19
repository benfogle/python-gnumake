.. highlight:: makefile

Makefile Functions
==================

This section details the functions exported to the makefile by default.

None of the Python code run by the functions below is executed in a subprocess.
All code shares the same globals and imports, can interact with the makefile,
etc.

Any errors encountered in the functions below will result in an empty
expansion.  See :doc:`exceptions` for more complete error-handling.

.. note::
    Please excuse the syntax highlighting. The highlighter that can do makefile
    and Python correctly together in the same snippet does not yet exist (and
    probably never should).

.. _python-eval:

python-eval 
-----------

**Usage:**
``$(python-eval <expression>)``

**Description:** Expands to the result of a Python expression. Only single-line
Python expressions are allowed. The result is converted to a string according
to the rules given in :py:func:`~gnumake.export`.

**Example**::

    FILE := somefile
    RESULT1 := $(python-eval 'Hello')
    RESULT2 := $(python-eval 1+2+3+4)
    RESULT3 := $(python-eval os.path.getmtime('$(FILE)'))
    $(info RESULT1=$(RESULT1))
    $(info RESULT2 = $(RESULT2))
    $(info RESULT3 = $(RESULT3))

This makefile snippet will print out something like:

.. code-block:: text

    RESULT1 = Hello
    RESULT2 = 10
    RESULT3 = 1464398588.835386

.. _python-exec:

python-exec
-----------
**Usage:** ``$(python-exec <expression>)``

**Description:** Executes one or more Python statements. It is more convenient
to use ``define`` with this function if you want to execute multiple lines.
Anything written to stdout will be the result of his function's expansion, much
like ``$(shell ...)``.

**Example**::

    $(python-exec import random) # Further Python code can now use random

    RESULT1 := $(python-exec print("Random is", random.randint(1,100)))

    # We expect no output here
    RESULT2 := $(python-exec tmp1 = random.randint(1,100))

    define python-code
    tmp1 = random.randint(1,100)
    tmp2 = random.randint(1,100)
    print("tmp1*tmp2 = ", tmp1*tmp2)
    endef
    RESULT3 := $(python-exec $(python-code))

    $(info RESULT1 = $(RESULT1))
    $(info RESULT2 = $(RESULT2))
    $(info RESULT3 = $(RESULT3))

This makefile snippet will print out something like:

.. code-block:: text

    RESULT1 = Random is 47
    RESULT2 = 
    RESULT3 = tmp1*tmp2 =  7760

.. _python-file:

python-file
-----------

**Usage:** ``$(python-file <script>,<arg1>,<arg2>,...)``

**Description:** Exactly like :ref:`$(python-exec ...) <python-exec>` but
executes statements from a file. Any arguments will be passed to the script in
``sys.argv``. Note that the script is not run in a separate process and it
shares globals with other Python code.

**Example**:

The file python.py contains the following:

.. code-block:: python

    import re
    import sys

    global1 = 'abc'

    pattern = sys.argv[1]
    strings = sys.argv[2:]

    print("Matches:", ' '.join(s for s in strings if re.match(pattern, s)))


The makefile snippet contains the following::

    # Match words where the first and last letters are the same
    # Note double $$ in pattern
    PAT = ^(.).*\1$$
    RESULT1 = $(python-file python.py,$(PAT),dare,dead,edge,tooth)
    RESULT2 = $(python-eval global1)

    $(info RESULT1 = $(RESULT1))
    $(info RESULT2 = $(RESULT2))

This snippet will produce the following output:

.. code-block:: text

    RESULT1 = Matches: dead edge
    RESULT2 = abc

