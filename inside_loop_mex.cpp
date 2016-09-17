/*********************************************************************
 * inside_loop_mex.cpp
 *
 * 
 * Keep in mind:
 * <> Use 0-based indexing as always in C or C++
 * <> Indexing is column-based as in Matlab (not row-based as in C)
 * <> Use linear indexing. [x*dimy+y] instead of [x][y]
 *
 * Adapted by: Pablo Cuba-Borda. June 2nd, 2014.
 *
 ********************************************************************/

/* Include libraries */
#include <mex.h>        // Always include this header

#ifndef HAVE_OCTAVE
#include <matrix.h>
#endif

#include <math.h>       // power
#include <cmath>        // abs
#include <ctime>        // time


/* Definitions to keep compatibility with earlier versions of ML */
#ifndef MWSIZE_MAX
typedef int mwSize;
typedef int mwIndex;
typedef int mwSignedIndex;

#if (defined(_LP64) || defined(_WIN64)) && !defined(MX_COMPAT_32)
/* Currently 2^48 based on hardware limitations */
# define MWSIZE_MAX    281474976710655UL
# define MWINDEX_MAX   281474976710655UL
# define MWSINDEX_MAX  281474976710655L
# define MWSINDEX_MIN -281474976710655L
#else
# define MWSIZE_MAX    2147483647UL
# define MWINDEX_MAX   2147483647UL
# define MWSINDEX_MAX  2147483647L
# define MWSINDEX_MIN -2147483647L
#endif
#define MWSIZE_MIN    0UL
#define MWINDEX_MIN   0UL
#endif

// This is the gateway function
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
   
//declare input-output variables
    mxArray *v_in_1, *v_in_2, *v_in_3, *m_out_1, *m_out_2;
    // input arrays
    double *vGridCapital, *mOutput, *expectedValueFunction;
    // output arrays
    double *mValueFunctionNew,*mPolicyFunction;
    
// local variables
    int nGridCapital, nGridProductivity, gridCapitalNextPeriod, numdims;
    double valueHighSoFar, valueProvisional, consumption, capitalChoice;

// declare counters    
    int nProductivity,nCapital,nCapitalNextPeriod;

// declare constants types and parameters    
    const double bbeta  = 0.95;
    const mwSize *dims;

//associate inputs
    v_in_1 = mxDuplicateArray(prhs[0]);
    v_in_2 = mxDuplicateArray(prhs[1]);
    v_in_3 = mxDuplicateArray(prhs[2]);

//figure out dimensions of all inputs: rows(mxGetM) and columns(mxGetN)

    // Dimensions of expectedValueFunction
    numdims = mxGetNumberOfDimensions(prhs[2]);

    // Dimensions of capital grid
    nGridCapital = (int)mxGetM(prhs[2]); 
    
    // Dimensions of productivity grid
    nGridProductivity = (int)mxGetN(prhs[2]); 
    
//associate outputs
    m_out_1 = plhs[0] = mxCreateDoubleMatrix(nGridCapital,nGridProductivity,mxREAL);
    m_out_2 = plhs[1] = mxCreateDoubleMatrix(nGridCapital,nGridProductivity,mxREAL);

//associate pointers
    vGridCapital = mxGetPr(v_in_1);
    mOutput = mxGetPr(v_in_2);
    expectedValueFunction = mxGetPr(v_in_3);
    mValueFunctionNew = mxGetPr(m_out_1);
    mPolicyFunction = mxGetPr(m_out_2);
    
//main Loop
    for (nProductivity = 0;nProductivity<nGridProductivity;++nProductivity){
    
        // We start from previous choice (monotonicity of policy function)
        gridCapitalNextPeriod = 0;
        
        for (nCapital = 0;nCapital<nGridCapital;++nCapital){
          
            valueHighSoFar = -1000.0;
            capitalChoice  = vGridCapital[0];
            
            for (nCapitalNextPeriod = gridCapitalNextPeriod;nCapitalNextPeriod<nGridCapital;++nCapitalNextPeriod){
                
                consumption = mOutput[nProductivity*nGridCapital+nCapital]-vGridCapital[nCapitalNextPeriod];
                valueProvisional = (1-bbeta)*log(consumption)+bbeta*expectedValueFunction[nProductivity*nGridCapital+nCapitalNextPeriod];
                
                if (valueProvisional>valueHighSoFar){
                    valueHighSoFar = valueProvisional;
                    capitalChoice = vGridCapital[nCapitalNextPeriod];
                    gridCapitalNextPeriod = nCapitalNextPeriod;
                }
                else{
                    break; // We break when we have achieved the max
                }
                
                mValueFunctionNew[nProductivity*nGridCapital+nCapital] = valueHighSoFar;
                mPolicyFunction[nProductivity*nGridCapital+nCapital] = capitalChoice;
            }
            
        }
        
    }
    
    return;
}
