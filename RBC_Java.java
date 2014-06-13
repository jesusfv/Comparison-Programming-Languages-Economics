/*Basic RBC model with full depreciation
 * 
 * Jesus Fernandez-Villaverde
 *Haverford, July 3, 2013
 */

//package rbc_java;

public class RBC_Java {
    
    public static void main(String[] args) {
        /////////////////////////////////////////////////////////////////////
        // 0. Housekeeping
        /////////////////////////////////////////////////////////////////////
        
        long start = System.nanoTime();
        
        /////////////////////////////////////////////////////////////////////
        // 1. Calibration
        /////////////////////////////////////////////////////////////////////
        
        double aalpha = 0.33333333333; //Elasticity of output w.r.t. capital
        double bbeta = 0.95; //Discount factor
        
        //Productivity values
        double[] vProductivity = {0.9792, 0.9896, 1.0000, 1.0106, 1.0212};
        
        //Transition matrix
        double[][] mTransition = {
        {0.9727, 0.0273, 0.0000, 0.0000, 0.0000},
        {0.0041, 0.9806, 0.0153, 0.0000, 0.0000},
        {0.0000, 0.0082, 0.9837, 0.0082, 0.0000},
        {0.0000, 0.0000, 0.0153, 0.9806, 0.0041},
        {0.0000, 0.0000, 0.0000, 0.0273, 0.9727}
        };
        
        /////////////////////////////////////////////////////////////////////
        // 2. Steady State
        /////////////////////////////////////////////////////////////////////
        
        double capitalSteadyState = Math.pow(aalpha*bbeta,1/(1-aalpha));
        double outputSteadyState = Math.pow(capitalSteadyState,aalpha);
        double consumptionSteadyState = outputSteadyState-capitalSteadyState;
        
        System.out.println("Output = " + outputSteadyState + ", Capital = " + 
                capitalSteadyState + ", Consumption = " + consumptionSteadyState
                + "\n");
        
        //We generate the grid of capital
        int nCapital, nCapitalNextPeriod, gridCapitalNextPeriod, nProductivity,
                nProductivityNextPeriod;
        int nGridCapital = 17820, nGridProductivity = 5;
        double[] vGridCapital = new double[nGridCapital];
        
        for (nCapital = 0; nCapital < nGridCapital; nCapital++){
            vGridCapital[nCapital] = 0.5*capitalSteadyState+0.00001*nCapital;
        }
        
        /////////////////////////////////////////////////////////////////////
        // 3. Required matrices and vectors
        /////////////////////////////////////////////////////////////////////
    
        double[][] mOutput = new double[nGridCapital][nGridProductivity];
        double[][] mValueFunction = new double[nGridCapital][nGridProductivity];
        double[][] mValueFunctionNew = new double[nGridCapital][nGridProductivity];
        double[][] mPolicyFunction = new double[nGridCapital][nGridProductivity];
        double[][] expectedValueFunction = new double[nGridCapital][nGridProductivity];
        
        /////////////////////////////////////////////////////////////////////
        // 4. We pre-build output for each point in the grid
        /////////////////////////////////////////////////////////////////////
        
        for(nProductivity = 0; nProductivity < nGridProductivity; nProductivity++){
            for(nCapital = 0; nCapital < nGridCapital; nCapital++){
                mOutput[nCapital][nProductivity] = 
                        vProductivity[nProductivity]*Math.pow(vGridCapital[nCapital],aalpha);
            }
        }
        
        /////////////////////////////////////////////////////////////////////
        // 5. Main iteration
        /////////////////////////////////////////////////////////////////////
        
        double maxDifference = 10.0, diff, diffHighSoFar;
        double tolerance = 0.0000001;
        double valueHighSoFar, valueProvisional, consumption, capitalChoice;
        
        int iteration = 0;
        
        while(maxDifference > tolerance){
            for(nProductivity = 0; nProductivity < nGridProductivity; nProductivity++){
                for(nCapital = 0; nCapital < nGridCapital; nCapital++){
                    expectedValueFunction[nCapital][nProductivity] = 0.0;
                    for(nProductivityNextPeriod = 0; nProductivityNextPeriod < nGridProductivity; nProductivityNextPeriod++){
                        expectedValueFunction[nCapital][nProductivity] += 
                                mTransition[nProductivity][nProductivityNextPeriod]*
                                mValueFunction[nCapital][nProductivityNextPeriod];
                    }
                }
            }
            
            for(nProductivity = 0; nProductivity < nGridProductivity; nProductivity++){
                //We start from previous choice (monotonicity of policy function)
                gridCapitalNextPeriod = 0;
           
                for(nCapital = 0; nCapital < nGridCapital; nCapital++){
                  
                valueHighSoFar = -100000.0;
                capitalChoice = vGridCapital[0];
                
                    for(nCapitalNextPeriod = gridCapitalNextPeriod; nCapitalNextPeriod < nGridCapital; nCapitalNextPeriod++){
                        consumption = mOutput[nCapital][nProductivity] - vGridCapital[nCapitalNextPeriod];
                        valueProvisional = (1 - bbeta)*Math.log(consumption)+bbeta*expectedValueFunction[nCapitalNextPeriod][nProductivity];
                    
                        if(valueProvisional > valueHighSoFar){
                            valueHighSoFar = valueProvisional;
                            capitalChoice = vGridCapital[nCapitalNextPeriod];
                            gridCapitalNextPeriod = nCapitalNextPeriod;
                        }
                        else{
                            break; //We break when we have achieved the max
                        }
                    
                        mValueFunctionNew[nCapital][nProductivity] = valueHighSoFar;
                        mPolicyFunction[nCapital][nProductivity] = capitalChoice;
                    }
                }
            }
                
            diffHighSoFar = -100000.0;
            for(nProductivity = 0; nProductivity < nGridProductivity; nProductivity++){
                for(nCapital = 0; nCapital < nGridCapital; nCapital++){
                    diff = Math.abs(mValueFunction[nCapital][nProductivity] - 
                        mValueFunctionNew[nCapital][nProductivity]);
                    if(diff > diffHighSoFar){
                        diffHighSoFar = diff;
                    }
                    mValueFunction[nCapital][nProductivity] = mValueFunctionNew[nCapital][nProductivity];
                }
            }
            maxDifference = diffHighSoFar;
        
            iteration = iteration + 1;
            if(iteration % 10 == 0 || iteration == 1){
                System.out.println("Iteration = " + iteration + ", Sup Diff = " + maxDifference);
            }
        }
        
        System.out.println("Iteration = " + iteration + ", Sup Diff = " + maxDifference + "\n");
        System.out.println("My check = " + mPolicyFunction[999][2] + "\n");
        

        long end = System.nanoTime();
        long timeDifference = end - start;
        double nanoSecs = 1000000000;
        System.out.println("Elapsed time is " + timeDifference/nanoSecs + " seconds.");
    }    
}

