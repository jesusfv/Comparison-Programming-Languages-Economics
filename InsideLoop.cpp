#include <Rcpp.h>
#include <math.h>       // power
#include <cmath> 
using namespace Rcpp;

// [[Rcpp::export]]
NumericMatrix InsideLoop(NumericVector vGridCapital, NumericMatrix mOutput, NumericMatrix expectedValueFunction){
  
    const double bbeta  = 0.95;
    const int nGridCapital = 17820, nGridProductivity = 5;
    
    NumericMatrix results(nGridCapital,2*nGridProductivity);
    double valueProvisional, valueHighSoFar, consumption, capitalChoice;
    
    int nProductivity, nCapital, nCapitalNextPeriod, gridCapitalNextPeriod;

    for (nProductivity = 0;nProductivity<nGridProductivity;++nProductivity){

      // We start from previous choice (monotonicity of policy function)
      gridCapitalNextPeriod = 0;

      for (nCapital = 0;nCapital<nGridCapital;++nCapital){

	      valueHighSoFar = -100000.0;
	      capitalChoice  = vGridCapital[0];

	      for (nCapitalNextPeriod = gridCapitalNextPeriod;nCapitalNextPeriod<nGridCapital;++nCapitalNextPeriod){

	        consumption = mOutput(nCapital,nProductivity)-vGridCapital(nCapitalNextPeriod);
	        valueProvisional = (1-bbeta)*log(consumption)+bbeta*expectedValueFunction(nCapitalNextPeriod,nProductivity);
          
	        if (valueProvisional>valueHighSoFar){
	          valueHighSoFar = valueProvisional;
	          capitalChoice = vGridCapital(nCapitalNextPeriod);
	          gridCapitalNextPeriod = nCapitalNextPeriod;
	        }
	        else{
	          break; // We break when we have achieved the max
	        }

	        results(nCapital,nProductivity) = valueHighSoFar;
          results(nCapital,nGridProductivity+nProductivity) = capitalChoice;
	      }

      }

    }
 
  return results;
   
}
