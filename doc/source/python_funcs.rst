
=============================
Python Functions
=============================

Main API
--------

These functions implement the GNU make API used to interact with a makefile.

.. autofunction:: gnumake.export

.. autofunction:: gnumake.expand

.. autofunction:: gnumake.evaluate

Utilities
-----------------

In addition to the main API, Py-gnumake exposes a few utility functions that
may prove useful.

.. autoclass:: gnumake.Variables
    :members:
    :special-members:

.. autofunction:: gnumake.escape_string

.. autofunction:: gnumake.fully_escape_string

.. autofunction:: gnumake.object_to_string

.. autofunction:: gnumake.is_legal_name


