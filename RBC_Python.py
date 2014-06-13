# Basic RBC model with full depreciation
#
# Jesus Fernandez-Villaverde
# Haverford, July 3, 2013

# 0. Initialization
import numpy as np
import math
import time

t1=time.time()

def main_func():

    #  1. Calibration

    aalpha = 1.0/3.0     # Elasticity of output w.r.t. capital
    bbeta  = 0.95        # Discount factor

    # Productivity values
    vProductivity = np.array([0.9792, 0.9896, 1.0000, 1.0106, 1.0212],float)

    # Transition matrix
    mTransition   = np.array([[0.9727, 0.0273, 0.0000, 0.0000, 0.0000],
                     [0.0041, 0.9806, 0.0153, 0.0000, 0.0000],
                     [0.0000, 0.0082, 0.9837, 0.0082, 0.0000],
                     [0.0000, 0.0000, 0.0153, 0.9806, 0.0041],
                     [0.0000, 0.0000, 0.0000, 0.0273, 0.9727]],float)

    ## 2. Steady State

    capitalSteadyState     = (aalpha*bbeta)**(1/(1-aalpha))
    outputSteadyState      = capitalSteadyState**aalpha
    consumptionSteadyState = outputSteadyState-capitalSteadyState

    print "Output = ", outputSteadyState, " Capital = ", capitalSteadyState, " Consumption = ", consumptionSteadyState 

    # We generate the grid of capital
    vGridCapital           = np.arange(0.5*capitalSteadyState,1.5*capitalSteadyState,0.00001)

    nGridCapital           = len(vGridCapital)
    nGridProductivity      = len(vProductivity)

    ## 3. Required matrices and vectors

    mOutput           = np.zeros((nGridCapital,nGridProductivity),dtype=float)
    mValueFunction    = np.zeros((nGridCapital,nGridProductivity),dtype=float)
    mValueFunctionNew = np.zeros((nGridCapital,nGridProductivity),dtype=float)
    mPolicyFunction   = np.zeros((nGridCapital,nGridProductivity),dtype=float)
    expectedValueFunction = np.zeros((nGridCapital,nGridProductivity),dtype=float)

    # 4. We pre-build output for each point in the grid

    for nProductivity in range(nGridProductivity):
        mOutput[:,nProductivity] = vProductivity[nProductivity]*(vGridCapital**aalpha)

    ## 5. Main iteration

    maxDifference = 10.0
    tolerance = 0.0000001
    iteration = 0

    log = math.log
    zeros = np.zeros
    dot = np.dot

    while(maxDifference > tolerance):

        expectedValueFunction = dot(mValueFunction,mTransition.T)

        for nProductivity in xrange(nGridProductivity):

            # We start from previous choice (monotonicity of policy function)
            gridCapitalNextPeriod = 0

            for nCapital in xrange(nGridCapital):

                valueHighSoFar = -100000.0
                capitalChoice  = vGridCapital[0]

                for nCapitalNextPeriod in xrange(gridCapitalNextPeriod,nGridCapital):

                    consumption = mOutput[nCapital,nProductivity] - vGridCapital[nCapitalNextPeriod]

                    #expectedValueFunction = np.dot(mTransition[nProductivity,:],mValueFunction[nCapitalNextPeriod,:])
                    valueProvisional = (1-bbeta)*log(consumption)+bbeta*expectedValueFunction[nCapitalNextPeriod,nProductivity];

                    if  valueProvisional>valueHighSoFar:
                        valueHighSoFar = valueProvisional
                        capitalChoice = vGridCapital[nCapitalNextPeriod]
                        gridCapitalNextPeriod = nCapitalNextPeriod
                    else:
                        break # We break when we have achieved the max


                mValueFunctionNew[nCapital,nProductivity] = valueHighSoFar
                mPolicyFunction[nCapital,nProductivity]   = capitalChoice

        maxDifference = (abs(mValueFunctionNew-mValueFunction)).max()

        mValueFunction    = mValueFunctionNew
        mValueFunctionNew = zeros((nGridCapital,nGridProductivity),dtype=float)

        iteration += 1
        if(iteration%10 == 0 or iteration == 1):
            print " Iteration = ", iteration, ", Sup Diff = ", maxDifference

    return (maxDifference, iteration, mValueFunction, mPolicyFunction)

maxDiff, iter, mValueF, mPolicyFunction = main_func()

print " Iteration = ", iter, ", Sup Duff = ", maxDiff
print " "
print " My Check = ", mPolicyFunction[1000-1,3-1]
print " "

t2 = time.time()

print "Elapse time = is ", t2-t1