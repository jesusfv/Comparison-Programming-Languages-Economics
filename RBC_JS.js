/*=================================================================================================
Name        : RBC_JS.js
Date        : January 1st, 2015
Author	    : Marco Lugo (marco.lugo.rodriguez@umontreal.ca)
Description : Basic Real Business Cycle (RBC) model with full depreciation, JavaScript implementation.

Some tests on the author's computer for comparison purposes:
Julia		:   3.29 seconds (using Julia 0.3.4)
JavaScript	:   4.95 seconds (using Mozilla Firefox v34)
C++			:	5.85 seconds (compiled using Bloodshed Dev-C++ 5.8.3/TDM-GCC 4.8.1), RBC_CPP.cpp used
JavaScript	:   9.58 seconds (using Google Chrome v39)
JavaScript	:  13.92 seconds (using NodeJS v0.10.32 on the Windows command line, available from nodejs.org)
Matlab		:  62.89 seconds (using Matlab R2007b)
JavaScript	: 260.20 seconds (using Internet Explorer v11)
R			: 655.47 seconds (using R i386 3.1.1)  
==================================================================================================*/

var initTimestamp = new Date().getTime(); //Start timestamp

//-----------------------------------------------------------------------------
//#1: Calibration
//-----------------------------------------------------------------------------
var aAlpha = 1/3; //Elasticity of output with respect to capital
var bBeta = 0.95; //Discount factor

var vProductivity = [ 0.9792, 0.9896, 1.0000, 1.0106, 1.0212 ]; //Array of productivity values 
var mTransition = []; //Transition matrix
	mTransition[0] = [ 0.9727, 0.0273, 0.0000, 0.0000, 0.0000 ];
	mTransition[1] = [ 0.0041, 0.9806, 0.0153, 0.0000, 0.0000 ];
	mTransition[2] = [ 0.0000, 0.0082, 0.9837, 0.0082, 0.0000 ];
	mTransition[3] = [ 0.0000, 0.0000, 0.0153, 0.9806, 0.0041 ];
	mTransition[4] = [ 0.0000, 0.0000, 0.0000, 0.0273, 0.9727 ];

//--------------------------------------------------------------------------------
//#2: Steady state
//--------------------------------------------------------------------------------
var capitalSteadyState = Math.pow( aAlpha*bBeta, 1/(1 - aAlpha) );
var outputSteadyState = Math.pow( capitalSteadyState, aAlpha );
var consumptionSteadyState = outputSteadyState - capitalSteadyState;

console.log('Output = ' + outputSteadyState + ', Capital = ' + capitalSteadyState + ', Consumption = ' + consumptionSteadyState);

//Grid of capital
var nGridCapital = 17820;
var nGridProductivity = 5;
var vGridCapital = [];
for(var nCapital = 0; nCapital < nGridCapital; nCapital++) 
	vGridCapital[ nCapital ] = 0.5 * capitalSteadyState + 0.00001 * nCapital;
	
//Prepare required matrices and fill with zeros.
var mOutput = [];
var mValueFunction = [];
var mValueFunctionNew = [];
var mPolicyFunction = [];
var expectedValueFunction = [];
	for(var nCapital = 0; nCapital < nGridCapital; nCapital++){
		mOutput[nCapital] = [];
		mValueFunction[nCapital] = [];
		mValueFunctionNew[nCapital] = [];
		mPolicyFunction[nCapital] = [];
		expectedValueFunction[nCapital] = [];
			for(var nProductivity = 0; nProductivity < nGridProductivity; nProductivity++){
				mValueFunction[nCapital][nProductivity] = 0;
				mValueFunctionNew[nCapital][nProductivity] = 0;
				mPolicyFunction[nCapital][nProductivity] = 0;
				expectedValueFunction[nCapital][nProductivity] = 0;
			}
	}

//Pre-build output for each point in the grid
 for(var nProductivity = 0; nProductivity < nGridProductivity; nProductivity++){
    for (var nCapital = 0; nCapital < nGridCapital; nCapital++)
		mOutput[nCapital][nProductivity] = vProductivity[nProductivity] * Math.pow( vGridCapital[nCapital], aAlpha );
 }
 
//Main iteration
var maxDifference = 10;
var tolerance = 0.0000001;
var valueHighSoFar, valueProvisional, consumption, capitalChoice, diff, diffHighSoFar;
var iteration = 0;

while( maxDifference > tolerance ){
		
		for(var nProductivity = 0; nProductivity < nGridProductivity; nProductivity++){
		  for(var nCapital = 0; nCapital < nGridCapital; nCapital++){
			expectedValueFunction[nCapital][nProductivity] = 0;
			for(var nProductivityNextPeriod = 0; nProductivityNextPeriod < nGridProductivity; nProductivityNextPeriod++)
			  expectedValueFunction[nCapital][nProductivity] += mTransition[nProductivity][nProductivityNextPeriod] * mValueFunction[nCapital][nProductivityNextPeriod];
		  }
		}

		for (var nProductivity = 0; nProductivity < nGridProductivity; nProductivity++){
			// We start from previous choice (monotonicity of policy function)
			var gridCapitalNextPeriod = 0;
			  for (var nCapital = 0; nCapital < nGridCapital; nCapital++){
					valueHighSoFar = -100000;
					capitalChoice  = vGridCapital[0];

					for(var nCapitalNextPeriod = gridCapitalNextPeriod; nCapitalNextPeriod < nGridCapital; nCapitalNextPeriod++){
						consumption = mOutput[nCapital][nProductivity] - vGridCapital[nCapitalNextPeriod];
						valueProvisional = (1 - bBeta) * Math.log(consumption) + bBeta*expectedValueFunction[nCapitalNextPeriod][nProductivity];

						if( valueProvisional > valueHighSoFar ){
							valueHighSoFar = valueProvisional;
							capitalChoice = vGridCapital[nCapitalNextPeriod];
							gridCapitalNextPeriod = nCapitalNextPeriod;
						}
						else{
							break; //Exit the loop if the maximum has been reached
						}

						mValueFunctionNew[nCapital][nProductivity] = valueHighSoFar;
						mPolicyFunction[nCapital][nProductivity] = capitalChoice;
					}
			  }

		}
		
		diffHighSoFar = -100000;
		
		for (var nProductivity = 0; nProductivity < nGridProductivity; nProductivity++){
			for (var nCapital = 0; nCapital < nGridCapital; nCapital++){
				diff = Math.abs( mValueFunction[nCapital][nProductivity] - mValueFunctionNew[nCapital][nProductivity] );
				if( diff > diffHighSoFar )	diffHighSoFar = diff;
				mValueFunction[nCapital][nProductivity] = mValueFunctionNew[nCapital][nProductivity];
			}
		}
		
		maxDifference = diffHighSoFar;
		iteration++;
		if(iteration % 10 == 0 || iteration == 1) console.log('Iteration = ' + iteration + ', Sup Diff = ' + maxDifference);
}

//Show final results and elapsed time
console.log('Iteration = ' + iteration + ', Sup Diff = ' + maxDifference);
console.log('My check = ' + mPolicyFunction[999][2] );
console.log('Elapsed time: ' + (new Date().getTime() - initTimestamp)/1000 + 's' ); //Show execution time in seconds