//============================================================================
// Name        : RBC_CPP.cpp
// Description : Basic RBC model with full depreciation
// Date        : July 21, 2013
//============================================================================

#include <iostream>
#include <math.h>       // power
#include <cmath>        // abs
#include <ctime>        // time

using namespace std;

int main() {

  clock_t begin = clock();

  ///////////////////////////////////////////////////////////////////////////////////////////
  // 1. Calibration
  ///////////////////////////////////////////////////////////////////////////////////////////

  const double aalpha = 0.33333333333;     // Elasticity of output w.r.t. capital
  const double bbeta  = 0.95;              // Discount factor;

  // Productivity values

  double vProductivity[5] ={0.9792, 0.9896, 1.0000, 1.0106, 1.0212};

  // Transition matrix
  double mTransition[5][5] = {
			{0.9727, 0.0273, 0.0000, 0.0000, 0.0000},
			{0.0041, 0.9806, 0.0153, 0.0000, 0.0000},
			{0.0000, 0.0082, 0.9837, 0.0082, 0.0000},
			{0.0000, 0.0000, 0.0153, 0.9806, 0.0041},
			{0.0000, 0.0000, 0.0000, 0.0273, 0.9727}
			};

  ///////////////////////////////////////////////////////////////////////////////////////////
  // 2. Steady State
  ///////////////////////////////////////////////////////////////////////////////////////////

  double capitalSteadyState = pow(aalpha*bbeta,1/(1-aalpha));
  double outputSteadyState  = pow(capitalSteadyState,aalpha);
  double consumptionSteadyState = outputSteadyState-capitalSteadyState;

  cout <<"Output = "<<outputSteadyState<<", Capital = "<<capitalSteadyState<<", Consumption = "<<consumptionSteadyState<<"\n";
  cout <<" ";

  // We generate the grid of capital
  int nCapital, nCapitalNextPeriod, gridCapitalNextPeriod, nProductivity, nProductivityNextPeriod;
  const int nGridCapital = 17820, nGridProductivity = 5;
  double vGridCapital[nGridCapital];

  for (nCapital = 0; nCapital < nGridCapital; ++nCapital){
    vGridCapital[nCapital] = 0.5*capitalSteadyState+0.00001*nCapital;
  }

  // 3. Required matrices and vectors

  double mOutput[nGridCapital][nGridProductivity];
  double mValueFunction[nGridCapital][nGridProductivity];
  double mValueFunctionNew[nGridCapital][nGridProductivity];
  double mPolicyFunction[nGridCapital][nGridProductivity];
  double expectedValueFunction[nGridCapital][nGridProductivity];

  // 4. We pre-build output for each point in the grid

  for (nProductivity = 0; nProductivity<nGridProductivity; ++nProductivity){
    for (nCapital = 0; nCapital < nGridCapital; ++nCapital){
      mOutput[nCapital][nProductivity] = vProductivity[nProductivity]*pow(vGridCapital[nCapital],aalpha);
    }
  }

  // 5. Main iteration

  double maxDifference = 10.0, diff, diffHighSoFar;
  double tolerance = 0.0000001;
  double valueHighSoFar, valueProvisional, consumption, capitalChoice;

  int iteration = 0;

  while (maxDifference>tolerance){

    for (nProductivity = 0;nProductivity<nGridProductivity;++nProductivity){
      for (nCapital = 0;nCapital<nGridCapital;++nCapital){
	expectedValueFunction[nCapital][nProductivity] = 0.0;
	for (nProductivityNextPeriod = 0;nProductivityNextPeriod<nGridProductivity;++nProductivityNextPeriod){
	  expectedValueFunction[nCapital][nProductivity] += mTransition[nProductivity][nProductivityNextPeriod]*mValueFunction[nCapital][nProductivityNextPeriod];
	}
      }
    }

    for (nProductivity = 0;nProductivity<nGridProductivity;++nProductivity){

      // We start from previous choice (monotonicity of policy function)
      gridCapitalNextPeriod = 0;

      for (nCapital = 0;nCapital<nGridCapital;++nCapital){

	valueHighSoFar = -100000.0;
	capitalChoice  = vGridCapital[0];

	for (nCapitalNextPeriod = gridCapitalNextPeriod;nCapitalNextPeriod<nGridCapital;++nCapitalNextPeriod){

	  consumption = mOutput[nCapital][nProductivity]-vGridCapital[nCapitalNextPeriod];
	  valueProvisional = (1-bbeta)*log(consumption)+bbeta*expectedValueFunction[nCapitalNextPeriod][nProductivity];

	  if (valueProvisional>valueHighSoFar){
	    valueHighSoFar = valueProvisional;
	    capitalChoice = vGridCapital[nCapitalNextPeriod];
	    gridCapitalNextPeriod = nCapitalNextPeriod;
	  }
	  else{
	    break; // We break when we have achieved the max
	  }

	  mValueFunctionNew[nCapital][nProductivity] = valueHighSoFar;
	  mPolicyFunction[nCapital][nProductivity] = capitalChoice;
	}

      }

    }

    diffHighSoFar = -100000.0;
    for (nProductivity = 0;nProductivity<nGridProductivity;++nProductivity){
      for (nCapital = 0;nCapital<nGridCapital;++nCapital){
	diff = std::abs(mValueFunction[nCapital][nProductivity]-mValueFunctionNew[nCapital][nProductivity]);
	if (diff>diffHighSoFar){
	  diffHighSoFar = diff;
	}
	mValueFunction[nCapital][nProductivity] = mValueFunctionNew [nCapital][nProductivity];
      }
    }
    maxDifference = diffHighSoFar;

    iteration = iteration+1;
    if (iteration % 10 == 0 || iteration ==1){
      cout <<"Iteration = "<<iteration<<", Sup Diff = "<<maxDifference<<"\n";
    }
  }

  cout <<"Iteration = "<<iteration<<", Sup Diff = "<<maxDifference<<"\n";
  cout <<" \n";
  cout <<"My check = "<< mPolicyFunction[999][2]<<"\n";
  cout <<" \n";

  clock_t end = clock();
  double elapsed_secs = double(end - begin) / CLOCKS_PER_SEC;
  cout <<"Elapsed time is "<<elapsed_secs<<" seconds.";
  cout <<" \n";  

  return 0;

}
