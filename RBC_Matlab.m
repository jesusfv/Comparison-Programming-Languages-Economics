%% Basic RBC model with full depreciation
%
% Jesus Fernandez-Villaverde
% Haverford, July 3, 2013

%% 0. Housekeeping

clear variables
close all
clc

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
             
[ vGridCapital, mValueFunction, mPolicyFunction ] = RBC_Matlab_Get_Value_And_Policy_Functions( aalpha, bbeta, vProductivity, mTransition );

toc

%% 6. Plotting results

figure(1)

subplot(3,1,1)
plot(vGridCapital,mValueFunction)
xlim([vGridCapital(1) vGridCapital(end)])
title('Value Function')

subplot(3,1,2)
plot(vGridCapital,mPolicyFunction)
xlim([vGridCapital(1) vGridCapital(end)])
title('Policy Function')

vExactPolicyFunction = aalpha*bbeta.*(vGridCapital.^aalpha);

subplot(3,1,3)
plot((100.*(vExactPolicyFunction'-mPolicyFunction(:,3))./mPolicyFunction(:,3)))
title('Comparison of Exact and Approximated Policy Function')

%set(gcf,'PaperOrientation','landscape','PaperPosition',[-0.9 -0.5 12.75 9])
%print('-dpdf','Figure1.pdf')