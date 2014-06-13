## Basic RBC model with full depreciation
#
# Jesus Fernandez-Villaverde
# Haverford, July 29, 2013



function main()

    ##  1. Calibration

    aalpha = 1/3     # Elasticity of output w.r.t. capital
    bbeta  = 0.95    # Discount factor

    # Productivity values
    vProductivity = [0.9792 0.9896 1.0000 1.0106 1.0212]

    # Transition matrix
    mTransition   = [0.9727 0.0273 0.0000 0.0000 0.0000;
                     0.0041 0.9806 0.0153 0.0000 0.0000;
                     0.0000 0.0082 0.9837 0.0082 0.0000;
                     0.0000 0.0000 0.0153 0.9806 0.0041;
                     0.0000 0.0000 0.0000 0.0273 0.9727]

    # 2. Steady State

    capitalSteadyState = (aalpha*bbeta)^(1/(1-aalpha))
    outputSteadyState = capitalSteadyState^aalpha
    consumptionSteadyState = outputSteadyState-capitalSteadyState

    println("Output = ",outputSteadyState," Capital = ",capitalSteadyState," Consumption = ",consumptionSteadyState)

    # We generate the grid of capital
    vGridCapital = 0.5*capitalSteadyState:0.00001:1.5*capitalSteadyState

    nGridCapital = length(vGridCapital)
    nGridProductivity = length(vProductivity)

    # 3. Required matrices and vectors

    mOutput           = zeros(nGridCapital,nGridProductivity)
    mValueFunction    = zeros(nGridCapital,nGridProductivity)
    mValueFunctionNew = zeros(nGridCapital,nGridProductivity)
    mPolicyFunction   = zeros(nGridCapital,nGridProductivity)
    expectedValueFunction = zeros(nGridCapital,nGridProductivity)

    # 4. We pre-build output for each point in the grid

    mOutput = (vGridCapital.^aalpha)*vProductivity;

    # 5. Main iteration

    maxDifference = 10.0
    tolerance = 0.0000001
    iteration = 0

    while(maxDifference > tolerance)
        expectedValueFunction = mValueFunction*mTransition';

        for nProductivity = 1:nGridProductivity
        
            # We start from previous choice (monotonicity of policy function)
            gridCapitalNextPeriod = 1
        
            for nCapital = 1:nGridCapital
        
                valueHighSoFar = -1000.0
                capitalChoice  = vGridCapital[1]
            
                for nCapitalNextPeriod = gridCapitalNextPeriod:nGridCapital

                    consumption = mOutput[nCapital,nProductivity]-vGridCapital[nCapitalNextPeriod]
                    valueProvisional = (1-bbeta)*log(consumption)+bbeta*expectedValueFunction[nCapitalNextPeriod,nProductivity]
               
                    if (valueProvisional>valueHighSoFar)
                	valueHighSoFar = valueProvisional
                	capitalChoice = vGridCapital[nCapitalNextPeriod]
                	gridCapitalNextPeriod = nCapitalNextPeriod
                    else
                	break # We break when we have achieved the max
                    end
                                 
                end
            
                mValueFunctionNew[nCapital,nProductivity] = valueHighSoFar
                mPolicyFunction[nCapital,nProductivity] = capitalChoice
          
            end
        
        end

        maxDifference  = maximum(abs(mValueFunctionNew-mValueFunction))
        mValueFunction    = mValueFunctionNew
        mValueFunctionNew = zeros(nGridCapital,nGridProductivity)

        iteration = iteration+1
        if mod(iteration,10)==0 || iteration == 1
            println(" Iteration = ", iteration, " Sup Diff = ", maxDifference)
        end
           
    end

    println(" Iteration = ", iteration, " Sup Diff = ", maxDifference)
    println(" ")
    println(" My check = ", mPolicyFunction[1000,3])

end
