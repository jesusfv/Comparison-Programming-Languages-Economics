# Cython version of the inner loop from the RBC model
cimport numpy as np
cimport cython
# This is the only non-trivial change - using a python function in the core of
# a loop introduces overhead and so should be avoided.  For scalar mathematical
# functions, this is simple using the following syntax
cdef extern from "math.h":
    double log(double x)

# Cython names are different from Python names for floating point, where float
# in Python maps to double in Cython (or C).  Using float in Cython is actual a
# single precision type similar to np.float32
# Data Types
#                           Python                 Cython
# - bbeta                   float                  double
# - nGridCapital:           int64                  int
# - gridCapitalNextPeriod:  int64                  int
# - mOutput:                float (17820 x 5)      ndarray[float64_t, ndims=2]
# - nProductivity:          int64                  int
# - vGridCapital:           float (17820, )        ndarray[float64_t, ndims=1]
# - mValueFunction:         float (17820 x 5)      ndarray[float64_t, ndims=2]
# - mPolicyFunction:        float (17820 x 5)      ndarray[float64_t, ndims=2]

# The only changes are the two decorators here and clear declaration of all
# types both for both the variables in the function declaration as well as the
# local variables
@cython.boundscheck(False)
@cython.wraparound(False)
def innerloop(double bbeta,
              int nGridCapital,
              int gridCapitalNextPeriod,
              np.ndarray[np.float64_t, ndim=2] mOutput not None,
              int nProductivity,
              np.ndarray[np.float64_t, ndim=1] vGridCapital not None,
              np.ndarray[np.float64_t, ndim=2] expectedValueFunction not None,
              np.ndarray[np.float64_t, ndim=2] mValueFunction not None,
              np.ndarray[np.float64_t, ndim=2] mValueFunctionNew not None,
              np.ndarray[np.float64_t, ndim=2] mPolicyFunction not None):

    cdef int nCapital, nCapitalNextPeriod
    cdef double valueHighSoFar, capitalChoice, consumption, valueProvisional

    for nCapital in xrange(nGridCapital):
        valueHighSoFar = -100000.0
        capitalChoice  = vGridCapital[0]

        for nCapitalNextPeriod in xrange(gridCapitalNextPeriod, nGridCapital):
            consumption = mOutput[nCapital,nProductivity] - vGridCapital[nCapitalNextPeriod]
            valueProvisional = (1-bbeta)*log(consumption)+bbeta*expectedValueFunction[nCapitalNextPeriod,nProductivity];

            if  valueProvisional > valueHighSoFar:
                valueHighSoFar = valueProvisional
                capitalChoice = vGridCapital[nCapitalNextPeriod]
                gridCapitalNextPeriod = nCapitalNextPeriod
            else:
                break

        mValueFunctionNew[nCapital,nProductivity] = valueHighSoFar
        mPolicyFunction[nCapital,nProductivity]   = capitalChoice

    return mValueFunctionNew, mPolicyFunction