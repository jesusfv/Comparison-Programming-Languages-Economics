% RBC_MATLAB_PERFORN_CODEGEN   Generate MEX-function
%  RBC_Matlab_Get_Value_And_Policy_Functions_mex from
%  RBC_Matlab_Get_Value_And_Policy_Functions.
% 
% Script generated from project 'RBC_Matlab_Get_Value_And_Policy_Functions.prj'
%  on 24-Jun-2017.
% 
% See also CODER, CODER.CONFIG, CODER.TYPEOF, CODEGEN.

%% Create configuration object of class 'coder.MexCodeConfig'.
cfg = coder.config('mex');
cfg.EnableMemcpy = false;
cfg.InitFltsAndDblsToZero = false;
cfg.EnableOpenMP = false;
cfg.CustomSourceCode = sprintf('#define muDoubleScalarIsNaN( x ) false\n#define muDoubleScalarIsInf( x ) false');
cfg.MATLABSourceComments = true;
cfg.ConstantInputs = 'Remove';
cfg.GenerateReport = true;
cfg.LaunchReport = false;
cfg.ReportPotentialDifferences = false;
cfg.ConstantFoldingTimeout = 2147483647;
cfg.CompileTimeRecursionLimit = 2147483647;
cfg.DynamicMemoryAllocation = 'AllVariableSizeArrays';
cfg.SaturateOnIntegerOverflow = false;
cfg.InlineThreshold = 2147483647;
cfg.InlineThresholdMax = 2147483647;
cfg.InlineStackLimit = 2147483647;
cfg.IntegrityChecks = false;
cfg.ResponsivenessChecks = false;
cfg.ExtrinsicCalls = false;
cfg.GlobalDataSyncMethod = 'NoSync';

%% Define argument types for entry-point
%  'RBC_Matlab_Get_Value_And_Policy_Functions'.
ARGS = cell(1,1);
ARGS{1} = cell(4,1);
ARGS{1}{1} = coder.typeof(0);
ARGS{1}{2} = coder.typeof(0);
ARGS{1}{3} = coder.typeof(0,[1 5]);
ARGS{1}{4} = coder.typeof(0,[5 5]);

%% Invoke MATLAB Coder.
codegen -config cfg RBC_Matlab_Get_Value_And_Policy_Functions -args ARGS{1}

