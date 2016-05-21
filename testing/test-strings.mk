THIS_MAKEFILE := $(lastword $(MAKEFILE_LIST))
THIS_PATH := $(dir $(THIS_MAKEFILE))
TEST_NAME := library.strings

include $(THIS_PATH)/common.mk

$(python-library strings)
$(call assert-contains,strings,$(PYTHON_LIBRARIES))


RESULT := $(strcmp foo,bar)
$(call assert-empty,PYTHON_LAST_ERROR)
$(call assert-equal,>,$(RESULT))

RESULT := $(strcmp foo,foo)
$(call assert-empty,PYTHON_LAST_ERROR)
$(call assert-equal,=,$(RESULT))

RESULT := $(strcmp FOO,FOo)
$(call assert-empty,PYTHON_LAST_ERROR)
$(call assert-equal,<,$(RESULT))

RESULT := $(strlen foobar)
$(call assert-empty,PYTHON_LAST_ERROR)
$(call assert-equal,6,$(RESULT))

RESULT := $(strlen foobar )
$(call assert-empty,PYTHON_LAST_ERROR)
$(call assert-equal,7,$(RESULT))

RESULT := $(strcapitalize foo bar)
$(call assert-empty,PYTHON_LAST_ERROR)
$(call assert-equal,Foo bar,$(RESULT))

RESULT := $(strcenter a,5)
$(call assert-empty,PYTHON_LAST_ERROR)
$(call assert-equal,  a  ,$(RESULT))

RESULT := $(strcenter a,5,-)
$(call assert-empty,PYTHON_LAST_ERROR)
$(call assert-equal,--a--,$(RESULT))

RESULT := $(strcount aabbcccd,c)
$(call assert-empty,PYTHON_LAST_ERROR)
$(call assert-equal,3,$(RESULT))

RESULT := $(strcount aabbcccd,bc)
$(call assert-empty,PYTHON_LAST_ERROR)
$(call assert-equal,1,$(RESULT))

RESULT := $(strcount aabbcccd,c,5)
$(call assert-empty,PYTHON_LAST_ERROR)
$(call assert-equal,2,$(RESULT))

RESULT := $(strcount aabbcccd,c,0,6)
$(call assert-empty,PYTHON_LAST_ERROR)
$(call assert-equal,2,$(RESULT))

RESULT := $(strendswith qwerty,ty)
$(call assert-empty,PYTHON_LAST_ERROR)
$(call assert-not-empty,RESULT)

RESULT := $(strendswith qwerty,xty)
$(call assert-empty,PYTHON_LAST_ERROR)
$(call assert-empty,RESULT)


RESULT := $(strendswith qwerty,rt,0,5)
$(call assert-empty,PYTHON_LAST_ERROR)
$(call assert-not-empty,RESULT)

# Will actually expand to seven spaces, putting 8 chars before y
RESULT := $(strexpandtabs x	y)
$(call assert-empty,PYTHON_LAST_ERROR)
$(call assert-equal,x       y,$(RESULT))

RESULT := $(strexpandtabs xx	y,3)
$(call assert-empty,PYTHON_LAST_ERROR)
$(call assert-equal,xx y,$(RESULT))

RESULT := $(strindex foobar,ob)
$(call assert-empty,PYTHON_LAST_ERROR)
$(call assert-equal,2,$(RESULT))

RESULT := $(strindex foobar,bb)
$(call assert-equal,ValueError: substring not found,$(PYTHON_LAST_ERROR))
$(call assert-empty,RESULT)

RESULT := $(strindex abcabcabc,bc,2)
$(call assert-empty,PYTHON_LAST_ERROR)
$(call assert-equal,4,$(RESULT))

RESULT := $(strindex abcabcabc,bc,2,4)
$(call assert-equal,ValueError: substring not found,$(PYTHON_LAST_ERROR))
$(call assert-empty,RESULT)

RESULT := $(strisalnum ab12)
$(call assert-empty,PYTHON_LAST_ERROR)
$(call assert-not-empty,RESULT)

RESULT := $(strisalnum ab1@2)
$(call assert-empty,PYTHON_LAST_ERROR)
$(call assert-empty,RESULT)

RESULT := $(strisalpha abc)
$(call assert-empty,PYTHON_LAST_ERROR)
$(call assert-not-empty,RESULT)

RESULT := $(strisalnum ab cd)
$(call assert-empty,PYTHON_LAST_ERROR)
$(call assert-empty,RESULT)

RESULT := $(strisdigit 123)
$(call assert-empty,PYTHON_LAST_ERROR)
$(call assert-not-empty,RESULT)

RESULT := $(strisdigit abc)
$(call assert-empty,PYTHON_LAST_ERROR)
$(call assert-empty,RESULT)

RESULT := $(strisidentifier _python2)
$(call assert-empty,PYTHON_LAST_ERROR)
$(call assert-not-empty,RESULT)

RESULT := $(strisidentifier .foobar)
$(call assert-empty,PYTHON_LAST_ERROR)
$(call assert-empty,RESULT)

RESULT := $(strislower whisper)
$(call assert-empty,PYTHON_LAST_ERROR)
$(call assert-not-empty,RESULT)

RESULT := $(strislower Yell)
$(call assert-empty,PYTHON_LAST_ERROR)
$(call assert-empty,RESULT)

RESULT := $(strisprintable gosh darn)
$(call assert-empty,PYTHON_LAST_ERROR)
$(call assert-not-empty,RESULT)

bleep=$(shell echo -e '\b')
RESULT := $(strisprintable mother f$(bleep))
$(call assert-empty,PYTHON_LAST_ERROR)
$(call assert-empty,RESULT)

RESULT := $(strisspace $(space)$(tab))
$(call assert-empty,PYTHON_LAST_ERROR)
$(call assert-not-empty,RESULT)

RESULT := $(strisspace x y)
$(call assert-empty,PYTHON_LAST_ERROR)
$(call assert-empty,RESULT)

RESULT := $(stristitle The Thing From Outer Space)
$(call assert-empty,PYTHON_LAST_ERROR)
$(call assert-not-empty,RESULT)

RESULT := $(strisspace the thing from outer Space)
$(call assert-empty,PYTHON_LAST_ERROR)
$(call assert-empty,RESULT)

RESULT := $(strisupper YELL)
$(call assert-empty,PYTHON_LAST_ERROR)
$(call assert-not-empty,RESULT)

RESULT := $(strisupper whisper)
$(call assert-empty,PYTHON_LAST_ERROR)
$(call assert-empty,RESULT)

RESULT := $(strjoin -,foo bar baz)
$(call assert-empty,PYTHON_LAST_ERROR)
$(call assert-equal,foo-bar-baz,$(RESULT))

RESULT := $(strjoin -,)
$(call assert-empty,PYTHON_LAST_ERROR)
$(call assert-equal,,$(RESULT))

RESULT := $(strjoin -,foo)
$(call assert-empty,PYTHON_LAST_ERROR)
$(call assert-equal,foo,$(RESULT))

RESULT := $(strljust left,10)
$(call assert-empty,PYTHON_LAST_ERROR)
$(call assert-equal,left      ,$(RESULT))

RESULT := $(strljust left,10,-)
$(call assert-empty,PYTHON_LAST_ERROR)
$(call assert-equal,left------,$(RESULT))

RESULT := $(strrindex ababab,ba)
$(call assert-empty,PYTHON_LAST_ERROR)
$(call assert-equal,3,$(RESULT))

RESULT := $(strrindex ababab,x)
$(call assert-equal,ValueError: substring not found,$(PYTHON_LAST_ERROR))
$(call assert-empty,RESULT)

RESULT := $(strindex xxyxy,xx,2)
$(call assert-equal,ValueError: substring not found,$(PYTHON_LAST_ERROR))
$(call assert-empty,RESULT)

RESULT := $(strindex abcabcabc,bc,2,6)
$(call assert-empty,PYTHON_LAST_ERROR)
$(call assert-equal,4,$(RESULT))

RESULT := $(strrjust right,10)
$(call assert-empty,PYTHON_LAST_ERROR)
$(call assert-equal,     right,$(RESULT))

RESULT := $(strrjust right,10,-)
$(call assert-empty,PYTHON_LAST_ERROR)
$(call assert-equal,-----right,$(RESULT))

RESULT := $(strrsplit foo    bar   baz)
$(call assert-empty,PYTHON_LAST_ERROR)
$(call assert-equal,foo bar baz,$(RESULT))

RESULT := $(strrsplit foo-bar-baz,-)
$(call assert-empty,PYTHON_LAST_ERROR)
$(call assert-equal,foo bar baz,$(RESULT))

RESULT := $(strrsplit foo-bar-baz,-,1)
$(call assert-empty,PYTHON_LAST_ERROR)
$(call assert-equal,foo-bar baz,$(RESULT))

RESULT := $(strrsplit foo    bar     baz,,1)
$(call assert-empty,PYTHON_LAST_ERROR)
$(call assert-equal,foo    bar baz,$(RESULT))

RESULT := $(strrstrip $(tab)foo$(tab)$(space))
$(call assert-empty,PYTHON_LAST_ERROR)
$(call assert-equal,$(tab)foo,$(RESULT))

RESULT := $(strrstrip oofoo,o)
$(call assert-empty,PYTHON_LAST_ERROR)
$(call assert-equal,oof,$(RESULT))

RESULT := $(strrstrip xoofoo,of)
$(call assert-empty,PYTHON_LAST_ERROR)
$(call assert-equal,x,$(RESULT))

RESULT := $(strrstrip xoofoo,x)
$(call assert-empty,PYTHON_LAST_ERROR)
$(call assert-equal,xoofoo,$(RESULT))

RESULT := $(strsplit foo    bar   baz)
$(call assert-empty,PYTHON_LAST_ERROR)
$(call assert-equal,foo bar baz,$(RESULT))

RESULT := $(strsplit foo-bar-baz,-)
$(call assert-empty,PYTHON_LAST_ERROR)
$(call assert-equal,foo bar baz,$(RESULT))

RESULT := $(strsplit foo-bar-baz,-,1)
$(call assert-empty,PYTHON_LAST_ERROR)
$(call assert-equal,foo bar-baz,$(RESULT))

RESULT := $(strsplit foo    bar     baz,,1)
$(call assert-empty,PYTHON_LAST_ERROR)
$(call assert-equal,foo bar     baz,$(RESULT))

RESULT := $(strstartswith libc,lib)
$(call assert-empty,PYTHON_LAST_ERROR)
$(call assert-not-empty,RESULT)

RESULT := $(strstartswith libc,lib,1)
$(call assert-empty,PYTHON_LAST_ERROR)
$(call assert-empty,RESULT)

RESULT := $(strstartswith libc,lib,0,2)
$(call assert-empty,PYTHON_LAST_ERROR)
$(call assert-empty,RESULT)

RESULT := $(strswapcase fooBAR QWeRTY)
$(call assert-empty,PYTHON_LAST_ERROR)
$(call assert-equal,FOObar qwErty,$(RESULT))

RESULT := $(strtitle the quick brown fox)
$(call assert-empty,PYTHON_LAST_ERROR)
$(call assert-equal,The Quick Brown Fox,$(RESULT))

RESULT := $(strtranslate the quick brown fox,kciuq, wols)
$(call assert-empty,PYTHON_LAST_ERROR)
$(call assert-equal,the slow  brown fox,$(RESULT))


RESULT := $(strupper the quick brown fox)
$(call assert-empty,PYTHON_LAST_ERROR)
$(call assert-equal,THE QUICK BROWN FOX,$(RESULT))

