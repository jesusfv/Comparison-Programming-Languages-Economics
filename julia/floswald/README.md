
# A Tweak to the Julia Version


## content

This folder slightly changes the Julia code for [A Comparison of Programming Languages in Economics](http://economics.sas.upenn.edu/~jesusfv/comparison_languages.pdf)

## Author

florian.oswald@gmail.com

## My Changes

I propose 2 sets of changes to the code.

1. The first step is to type the Julia code. I noted that the compiler spent a lot of time inferring types in the original implementation. This Version of the code is **identical** to the original code. It just uses a feature of the language (i.e. *typing* of variables as in `C++` for example).
2. The second step uses 1 language feature and 1 trick.
	* Feature: `Julia` comes with an switch to turn off bounds checking in loops, enabled with `@inbounds`. This is equivalent to setting compiler flags to that effect.
	* Trick: I remove array indexing of the form `A[i,j,k]` and replace with `A[linearIndexOf(i,j,k)]`


## My results

1. I achieve a speedup of 18% by typing the model before executing the computation function. 
2. I obtain a speedup of 24% with respect to the original code by using linear indices and by switching off bounds checking.

In order to run my code execute line by line `RBC_codes/julia/main.jl`


