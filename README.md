## Comparison of Programming Languages in Economics

This project contains the source code referenced in the paper [A Comparison of
Programming Languages in Economics][1] by S. Borağan Aruoba and Jesús
Fernández-Villaverde.

The main fork will remain basically unchanged to allow researchers to check our
basic results.

### Abstract from the paper

> We solve the stochastic neoclassical growth model, the workhorse of modern
> macroeconomics, using `C++11`, `Fortran 2008`, `Java`, `Julia`, `Python`,
> `Matlab`, `Mathematica`, and `R`. We implement the same algorithm, value
> function iteration with grid search, in each of the languages. We report the
> execution times of the codes in a `Mac` and in a `Windows` computer and
> comment on the strength and weakness of each language.

## Files

1. `RBC_C.c`: C code. 
2. `RBC_CPP.cpp`: C++ code
3. `RBC_CPP_2.cpp`: C++ code, more idiomatic but slightly slower.
4. `RBC_F90.f90`: Fortran code.
5. `RBC_Java.java`: Java code.
6. `RBC_Julia.jl`: Julia code, to run `include("RBC_Julia.jl"); @time main()`.
6. `RBC_Matlab.m`: Matlab code.
8. `RBC_Matlab_Inside_Loop.m`: Matlab code with Mex file.
9. `inside_loop_mex.cpp`: Mex file for 8.
10. `RBC_Python.py`: Python code for CPython and Pypy.
11. `RBC_Python_Numba.py`: Python code for Numba.
12. `RBC_R.R`: R code.
13. `RBC_R_Compiler.R`: R code compiled.
14. `RBC_Rcpp.R`: R code with Rcpp.
15. `InsideLoop.cpp`: C++ function for Rcpp.
16. `RBC_Mathematica`: Mathematica code.
17. `RBC_Mathematica_Imperative`: Mathematica code with imperative structure.
18. `RBC_Mathematica_PartialCompilation`: Mathematica code with imperative
    structure and partial compilation.
19. `RBC_CS.cs`: C# code.
20. `RBC_JS.js`: Javascrip code.
21. `RBC_Python_Cython.py`: Cython code.
22. `RBC_Swift.swift`: Swift code.

## Compilation flags

1. GCC compiler (Mac): `g++ -o testc -O3 RBC_CPP.cpp`
2. GCC compiler (Windows): `g++ -Wl,--stack,4000000, -o testc -O3 RBC_CPP.cpp`
3. GCC compiler (Mac): `g++ -o testc -O3 -std=gnu++11 RBC_CPP_2.cpp`
4. Clang compiler: `clang++ -o testclang -O3 RBC_CPP.cpp`
5. Intel compiler: `icpc -o testc -O3 RBC_CPP.cpp`
6. Visual C: `cl /F 4000000 /o testvcpp /O2 RBC_CPP.cpp`
7. GCC compiler: `gfortran -o testf -O3 RBC_F90.f90`
8. Intel compiler: `ifortran -o testf -O3 RBC_F90.f90`
9. `javac RBC_Java.java` and run as `java RBC_Java -XX:+AggressiveOpts`
10. `RBC_C.c` can be compiled in C, C++ and Objective-C: `clang -o testc -x <language> -O3 RBC_C.c` with `<language>` = `c`, `c++` or `objective-c`. Same for GCC.
11. Swift: `swiftc -o testswift -O RBC_Swift.swift -sdk $(xcrun --show-sdk-path --sdk macosx)`

In all cases with a JIT, you may want to warm up the JIT before testing for
speed.

[1]: http://economics.sas.upenn.edu/~jesusfv/comparison_languages.pdf
