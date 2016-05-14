load $(shell python3 -m gnumake)

# Enable the good stuff
$(python-exec import gnumake.internals)

foo: bar baz

$(info foo depends on $(prereqs foo))

foo: qwerty

$(info foo depends on $(prereqs foo))
