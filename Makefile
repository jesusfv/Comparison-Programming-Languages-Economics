# Compilation
# Since we want to test combinations of files AND compilers, this Makefile is a little heterodox. 
# We will hardcode compilers and flags.
#

BASENAME = test

CFLAGS = -O3
CPPFLAGS = $(CFLAGS) -std=gnu++11
OBJFLAGS = $(CFLAGS) -x objective-c
SWIFTFLAGS = -O -sdk $(shell xcrun --show-sdk-path --sdk macosx)

all: cfamily swift
cfamily: c cpp objc

c: $(BASENAME)-c-gcc $(BASENAME)-c-clang
cpp: $(BASENAME)-cpp-gcc $(BASENAME)-cpp-clang
objc: $(BASENAME)-objc-gcc $(BASENAME)-objc-clang
swift: $(BASENAME)-swift

$(BASENAME)-c-gcc: RBC_C.c
	gcc -o $@ $(CFLAGS) $<

$(BASENAME)-c-clang: RBC_C.c
	clang -o $@ $(CFLAGS) $<

$(BASENAME)-cpp-gcc: RBC_CPP_2.cpp
	g++ -o $@ $(CPPFLAGS) $<

$(BASENAME)-cpp-clang: RBC_CPP_2.cpp
	clang++ -o $@ $(CPPFLAGS) $<

$(BASENAME)-objc-gcc: RBC_C.c
	gcc -o $@ $(OBJFLAGS) $<

$(BASENAME)-objc-clang: RBC_C.c
	clang -o $@ $(OBJFLAGS) $<
	
$(BASENAME)-swift: RBC_Swift.swift
	swiftc -o $@ $(SWIFTFLAGS) $< 

clean:
	rm -f *.o

cleanall:
	rm $(BASENAME)*
