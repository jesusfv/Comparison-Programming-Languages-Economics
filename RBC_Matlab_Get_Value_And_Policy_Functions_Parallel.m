function [ vGridCapital, mValueFunction, mPolicyFunction ] = RBC_Matlab_Get_Value_And_Policy_Functions_Parallel( aalpha, bbeta, vProductivity, mTransition )

%% 2. Steady State

capitalSteadyState = (aalpha*bbeta)^(1/(1-aalpha));
outputSteadyState = capitalSteadyState^aalpha;
consumptionSteadyState = outputSteadyState-capitalSteadyState;

fprintf(' Output = %2.6f, Capital = %2.6f, Consumption = %2.6f\n', outputSteadyState, capitalSteadyState, consumptionSteadyState); 
fprintf('\n')

% We generate the grid of capital
vGridCapital = 0.5*capitalSteadyState:0.00001:1.5*capitalSteadyState;

nGridCapital = length(vGridCapital);
nGridProductivity = length(vProductivity);

%% 3. Required matrices and vectors

mValueFunction    = zeros(nGridCapital,nGridProductivity);
mValueFunctionNew = zeros(nGridCapital,nGridProductivity);
mPolicyFunction   = zeros(nGridCapital,nGridProductivity);

%% 4. We pre-build output for each point in the grid

mOutput = (vGridCapital'.^aalpha)*vProductivity;

%% 5. Main iteration

maxDifference = 10.0;
tolerance = 0.0000001;
iteration = 0;

while (maxDifference>tolerance)  
    
    expectedValueFunction = mValueFunction*mTransition';
    
    parfor nProductivity = 1:nGridProductivity
        
        % We start from previous choice (monotonicity of policy function)
        gridCapitalNextPeriod = 1;
        
        for nCapital = 1:nGridCapital
                        
            valueHighSoFar = -1000.0;
            capitalChoice  = vGridCapital(1); %#ok<PFBNS>
            
            for nCapitalNextPeriod = gridCapitalNextPeriod:nGridCapital
                
                consumption = mOutput(nCapital,nProductivity)-vGridCapital(nCapitalNextPeriod);
                valueProvisional = (1-bbeta)*log(consumption)+bbeta*expectedValueFunction(nCapitalNextPeriod,nProductivity);
            
                if (valueProvisional>valueHighSoFar)
                    valueHighSoFar = valueProvisional;
                    capitalChoice = vGridCapital(nCapitalNextPeriod);
                    gridCapitalNextPeriod = nCapitalNextPeriod;
                else
                    break; % We break when we have achieved the max
                end    
                  
            end
            
            mValueFunctionNew(nCapital,nProductivity) = valueHighSoFar;
            mPolicyFunction(nCapital,nProductivity) = capitalChoice;
            
        end
        
    end
    
    maxDifference = max(max(abs(mValueFunctionNew-mValueFunction)));
    mValueFunction = mValueFunctionNew;
    
    iteration = iteration+1;
    if (mod(iteration,10)==0 || iteration ==1)
        fprintf(' Iteration = %d, Sup Diff = %2.8f\n', int32( iteration ), maxDifference); 
    end
           
end

fprintf(' Iteration = %d, Sup Diff = %2.8f\n', int32( iteration ), maxDifference); 
fprintf('\n')

fprintf(' My check = %2.6f\n', mPolicyFunction(1000,3)); 
fprintf('\n')

end
