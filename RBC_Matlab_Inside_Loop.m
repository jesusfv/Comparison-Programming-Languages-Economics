%% Basic RBC model with full depreciation
%
% Jesus Fernandez-Villaverde
% Haverford, July 3, 2013

%% 0. Housekeeping

clear all
close all
clc

global nGridCapital nGridProductivity bbeta

tic

%%  1. Calibration

aalpha = 1/3;     % Elasticity of output w.r.t. capital
bbeta  = 0.95;    % Discount factor

% Productivity values
vProductivity = [0.9792; 0.9896; 1.0000; 1.0106; 1.0212]';

% Transition matrix
mTransition   = [0.9727, 0.0273, 0.0000, 0.0000, 0.0000;
                 0.0041, 0.9806, 0.0153, 0.0000, 0.0000;
                 0.0000, 0.0082, 0.9837, 0.0082, 0.0000;
                 0.0000, 0.0000, 0.0153, 0.9806, 0.0041;
                 0.0000, 0.0000, 0.0000, 0.0273, 0.9727];

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

mOutput           = zeros(nGridCapital,nGridProductivity);
mValueFunction    = zeros(nGridCapital,nGridProductivity);
expectedValueFunction = zeros(nGridCapital,nGridProductivity);

%% 4. We pre-build output for each point in the grid

mOutput = (vGridCapital'.^aalpha)*vProductivity;

%% 5. Main iteration

maxDifference = 10.0;
tolerance = 0.0000001;
iteration = 0;

while (maxDifference>tolerance)  
    
    expectedValueFunction = mValueFunction*mTransition';    
    
    [mValueFunctionNew,mPolicyFunction] = inside_loop_mex(vGridCapital,mOutput,expectedValueFunction);
    
    maxDifference = max(max(abs(mValueFunctionNew-mValueFunction)));
    mValueFunction = mValueFunctionNew;
    
    iteration = iteration+1;
    if (mod(iteration,10)==0 || iteration ==1)
        fprintf(' Iteration = %d, Sup Diff = %2.8f\n', iteration, maxDifference); 
    end
           
end

fprintf(' Iteration = %d, Sup Diff = %2.8f\n', iteration, maxDifference); 
fprintf('\n')

fprintf(' My check = %2.6f\n', mPolicyFunction(1000,3)); 
fprintf('\n')

toc

% %% 6. Plotting results
% 
% figure(1)
% 
% subplot(3,1,1)
% plot(vGridCapital,mValueFunction)
% xlim([vGridCapital(1) vGridCapital(nGridCapital)])
% title('Value Function')
% 
% subplot(3,1,2)
% plot(vGridCapital,mPolicyFunction)
% xlim([vGridCapital(1) vGridCapital(nGridCapital)])
% title('Policy Function')
% 
% vExactPolicyFunction = aalpha*bbeta.*(vGridCapital.^aalpha);
% 
% subplot(3,1,3)
% plot((100.*(vExactPolicyFunction'-mPolicyFunction(:,3))./mPolicyFunction(:,3)))
% title('Comparison of Exact and Approximated Policy Function')
% 
