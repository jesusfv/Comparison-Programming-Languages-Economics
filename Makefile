all: testc testf
	@echo RUNNING ALL TESTS
	@echo 
	@echo FORTRAN:
	./testf
	@echo 
	@echo C++:
	./testc
	@echo 
	@echo JULIA v0.6:
	julia6 RBC_Julia.jl

testc:
	g++ -o testc -O3 RBC_CPP.cpp

testf: 
	gfortran -o testf -O3 RBC_F90.f90

clean:
	rm -rf testc testf
		
