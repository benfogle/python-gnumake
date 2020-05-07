import gnumake

@gnumake.export
def say_hello(arg):
    return "Hello " + arg + "!"