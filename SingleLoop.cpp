#include <Rcpp.h>
#include <math.h>       // power
#include <cmath>

// [[Rcpp::export]]
Rcpp::NumericVector SingleLoop(Rcpp::NumericVector vProductivity, Rcpp::NumericVector vGridCapital,
                         Rcpp::NumericMatrix mOutput, Rcpp::NumericMatrix mTransition){
  
  const double bbeta  = 0.95;
  
  const int nGridCapital = 17820, nGridProductivity = 5;
  
  double valueProvisional, valueHighSoFar, consumption, capitalChoice;
  
  int nProductivity, nCapital, nCapitalNextPeriod, gridCapitalNextPeriod;
  
  double maxDifference = 10.0, diff, diffHighSoFar;
  double tolerance = 0.0000001;
  double iteration = 0;
  
  int nProductivityNextPeriod;
  
  Rcpp::NumericMatrix mValueFunctionNew(nGridCapital,nGridProductivity);
  Rcpp::NumericMatrix mValueFunction(nGridCapital,nGridProductivity);
  Rcpp::NumericMatrix mPolicyFunction(nGridCapital,nGridProductivity);
  Rcpp::NumericMatrix expectedValueFunction(nGridCapital,nGridProductivity);
  
  while(maxDifference > tolerance) {
    
    for (nProductivity = 0;nProductivity<nGridProductivity;++nProductivity){
      for (nCapital = 0;nCapital<nGridCapital;++nCapital){
        expectedValueFunction(nCapital,nProductivity) = 0.0;
        for (nProductivityNextPeriod = 0;nProductivityNextPeriod<nGridProductivity;++nProductivityNextPeriod){
          expectedValueFunction(nCapital,nProductivity) += mTransition(nProductivity,nProductivityNextPeriod)*mValueFunction(nCapital,nProductivityNextPeriod);
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
          
          consumption = mOutput(nCapital,nProductivity)-vGridCapital[nCapitalNextPeriod];
          valueProvisional = (1-bbeta)*log(consumption)+bbeta*expectedValueFunction(nCapitalNextPeriod,nProductivity);
          
          if (valueProvisional>valueHighSoFar){
            valueHighSoFar = valueProvisional;
            capitalChoice = vGridCapital[nCapitalNextPeriod];
            gridCapitalNextPeriod = nCapitalNextPeriod;
          }
          else{
            break; // We break when we have achieved the max
          }
          
          mValueFunctionNew(nCapital,nProductivity) = valueHighSoFar;
          mPolicyFunction(nCapital,nProductivity) = capitalChoice;
        }
      }
    }
    
    diffHighSoFar = -100000.0;
    for (nProductivity = 0;nProductivity<nGridProductivity;++nProductivity){
      for (nCapital = 0;nCapital<nGridCapital;++nCapital){
        diff = std::abs(mValueFunction(nCapital,nProductivity)-mValueFunctionNew(nCapital,nProductivity));
        if (diff>diffHighSoFar){
          diffHighSoFar = diff;
        }
        mValueFunction(nCapital,nProductivity) = mValueFunctionNew(nCapital,nProductivity);
      }
    }
    
    maxDifference = diffHighSoFar;
    
    iteration = iteration+1;
    if (floor(iteration/10)==iteration/10 || iteration ==1){
      Rcpp::Rcout <<"Iteration = "<<iteration<<", Sup Diff = "<< maxDifference<<"\n";
    }
    
  }
  Rcpp::Rcout <<"Iteration = "<<iteration<<", Sup Diff = "<<maxDifference<<"\n";
  Rcpp::Rcout <<" \n";
  Rcpp::Rcout <<"My check = "<< mPolicyFunction(999,2)<<"\n";
  Rcpp::Rcout <<" \n";
  
  return mPolicyFunction;
  
}
