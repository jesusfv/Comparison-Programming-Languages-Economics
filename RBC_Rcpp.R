## 0. Housekeeping

rm(list=ls())
ptm <- proc.time()

##  1. Calibration

aalpha = 1/3;     # Elasticity of output w.r.t. capital
bbeta  = 0.95;    # Discount factor

# Productivity values
vProductivity <- c(0.9792, 0.9896, 1.0000, 1.0106, 1.0212);

# Transition matrix
mTransition <- c(0.9727, 0.0273, 0.0000, 0.0000, 0.0000,
                 0.0041, 0.9806, 0.0153, 0.0000, 0.0000,
                 0.0000, 0.0082, 0.9837, 0.0082, 0.0000,
                 0.0000, 0.0000, 0.0153, 0.9806, 0.0041,
                 0.0000, 0.0000, 0.0000, 0.0273, 0.9727);

mTransition <- matrix(mTransition,nrow=5,ncol=5);
mTransition <- t(mTransition)

## 2. Steady State

capitalSteadyState = (aalpha*bbeta)^(1/(1-aalpha));
outputSteadyState = capitalSteadyState^aalpha;
consumptionSteadyState = outputSteadyState-capitalSteadyState;

cat(" Output = ", outputSteadyState,", Capital = ",capitalSteadyState, ", Consumption = ", consumptionSteadyState,"\n") 
cat(" \n")

# We generate the grid of capital
vGridCapital <- seq(0.5*capitalSteadyState, 1.5*capitalSteadyState, by = 0.00001);

nGridCapital <- length(vGridCapital);
nGridProductivity <- length(vProductivity);

# 3. Required matrices and vectors

mOutput           <- matrix(0,nGridCapital,nGridProductivity);
mValueFunction    <- matrix(0,nGridCapital,nGridProductivity);
mValueFunctionNew <- matrix(0,nGridCapital,nGridProductivity);
mPolicyFunction   <- matrix(0,nGridCapital,nGridProductivity);
mResults          <- matrix(0,nGridCapital,2*nGridProductivity);
expectedValueFunction <- matrix(0,nGridCapital,nGridProductivity);

## 4. We pre-build output for each point in the grid

mOutput = as.matrix(vGridCapital^aalpha)%*%t(as.matrix(vProductivity));

## 5. Main iteration

maxDifference <- 10;
tolerance <- 0.0000001;
iteration <- 0;

while (maxDifference>tolerance){  
  
  expectedValueFunction = mValueFunction %*% t(mTransition);

  Rcpp::sourceCpp('InsideLoop.cpp');
  mResults <- InsideLoop(vGridCapital, mOutput, expectedValueFunction);
  
  mValueFunctionNew <- mResults[,1:5];
    
  maxDifference <- max(abs(mValueFunctionNew-mValueFunction));
  mValueFunction <- mValueFunctionNew;
  
  iteration = iteration+1;
  if ((iteration %% 10)==0 | iteration ==1){
    cat("  Iteration = ", iteration," Sup Diff = ", maxDifference,"\n"); 
  }
  
}

mPolicyFunction <- mResults[,6:10];

cat("  Iteration = ", iteration," Sup Diff = ", maxDifference,"\n"); 
cat(" \n")

cat(" My chek = ", mPolicyFunction[1000,3],"\n"); 
cat(" \n")

cat(" Time = ", proc.time() - ptm,"\n"); 
