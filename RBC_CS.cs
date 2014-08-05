using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace EconomicsCSharp {
  class Program {
    static void Main(string[] args) {
      var stopWatch = new System.Diagnostics.Stopwatch();
      stopWatch.Restart();
      run();
      stopWatch.Stop();
      Console.WriteLine(string.Format("Elapsed Time: {0:0.000} seconds", stopWatch.Elapsed.TotalSeconds));      
    }

    static void run() {

      ///////////////////////////////////////////////////////////////////////////////////////////
      // 1. Calibration
      ///////////////////////////////////////////////////////////////////////////////////////////

      const double aalpha = 0.33333333333;     // Elasticity of output w.r.t. capital
      const double bbeta = 0.95;              // Discount factor;

      // Productivity values

      var vProductivity = new double[] { 0.9792, 0.9896, 1.0000, 1.0106, 1.0212 };

      // Transition matrix
      var mTransition = new double[,] {
      { 0.9727, 0.0273, 0.0000, 0.0000, 0.0000 },
      { 0.0041, 0.9806, 0.0153, 0.0000, 0.0000 },
      { 0.0000, 0.0082, 0.9837, 0.0082, 0.0000 },
      { 0.0000, 0.0000, 0.0153, 0.9806, 0.0041 },
      { 0.0000, 0.0000, 0.0000, 0.0273, 0.9727 }
  };

      ///////////////////////////////////////////////////////////////////////////////////////////
      // 2. Steady State
      ///////////////////////////////////////////////////////////////////////////////////////////

      double capitalSteadyState = Math.Pow(aalpha * bbeta, 1 / (1 - aalpha));
      double outputSteadyState = Math.Pow(capitalSteadyState, aalpha);
      double consumptionSteadyState = outputSteadyState - capitalSteadyState;

      Console.WriteLine("Output = " + outputSteadyState + ", Capital = " + capitalSteadyState + ", Consumption = " + consumptionSteadyState);

      // We generate the grid of capital
      int nCapital, nCapitalNextPeriod, gridCapitalNextPeriod, nProductivity, nProductivityNextPeriod;
      const int nGridCapital = 17820;
      const int nGridProductivity = 5;
      var vGridCapital = new double[nGridCapital];

      for (nCapital = 0; nCapital < nGridCapital; ++nCapital) {
        vGridCapital[nCapital] = 0.5 * capitalSteadyState + 0.00001 * nCapital;
      }

      // 3. Required matrices and vectors

      var mOutput = new double[nGridCapital, nGridProductivity];
      var mValueFunction = new double[nGridCapital, nGridProductivity];
      var mValueFunctionNew = new double[nGridCapital, nGridProductivity];
      var mPolicyFunction = new double[nGridCapital, nGridProductivity];
      var expectedValueFunction = new double[nGridCapital, nGridProductivity];

      // 4. We pre-build output for each point in the grid

      for (nProductivity = 0; nProductivity < nGridProductivity; ++nProductivity) {
        for (nCapital = 0; nCapital < nGridCapital; ++nCapital) {
          mOutput[nCapital, nProductivity] = vProductivity[nProductivity] * Math.Pow(vGridCapital[nCapital], aalpha);
        }
      }

      // 5. Main iteration

      double maxDifference = 10.0, diff, diffHighSoFar;
      double tolerance = 0.0000001;
      double valueHighSoFar, valueProvisional, consumption, capitalChoice;

      int iteration = 0;

      while (maxDifference > tolerance) {

        for (nProductivity = 0; nProductivity < nGridProductivity; ++nProductivity) {
          for (nCapital = 0; nCapital < nGridCapital; ++nCapital) {
            expectedValueFunction[nCapital, nProductivity] = 0.0;
            for (nProductivityNextPeriod = 0; nProductivityNextPeriod < nGridProductivity; ++nProductivityNextPeriod) {
              expectedValueFunction[nCapital, nProductivity] += mTransition[nProductivity, nProductivityNextPeriod] * mValueFunction[nCapital, nProductivityNextPeriod];
            }
          }
        }

        for (nProductivity = 0; nProductivity < nGridProductivity; ++nProductivity) {

          // We start from previous choice (monotonicity of policy function)
          gridCapitalNextPeriod = 0;

          for (nCapital = 0; nCapital < nGridCapital; ++nCapital) {

            valueHighSoFar = -100000.0;
            capitalChoice = vGridCapital[0];

            for (nCapitalNextPeriod = gridCapitalNextPeriod; nCapitalNextPeriod < nGridCapital; ++nCapitalNextPeriod) {

              consumption = mOutput[nCapital, nProductivity] - vGridCapital[nCapitalNextPeriod];
              valueProvisional = (1 - bbeta) * Math.Log(consumption) + bbeta * expectedValueFunction[nCapitalNextPeriod, nProductivity];

              if (valueProvisional > valueHighSoFar) {
                valueHighSoFar = valueProvisional;
                capitalChoice = vGridCapital[nCapitalNextPeriod];
                gridCapitalNextPeriod = nCapitalNextPeriod;
              }
              else {
                break; // We break when we have achieved the max
              }

              mValueFunctionNew[nCapital, nProductivity] = valueHighSoFar;
              mPolicyFunction[nCapital, nProductivity] = capitalChoice;
            }

          }

        }

        diffHighSoFar = -100000.0;
        for (nProductivity = 0; nProductivity < nGridProductivity; ++nProductivity) {
          for (nCapital = 0; nCapital < nGridCapital; ++nCapital) {
            diff = Math.Abs(mValueFunction[nCapital, nProductivity] - mValueFunctionNew[nCapital, nProductivity]);
            if (diff > diffHighSoFar) {
              diffHighSoFar = diff;
            }
            mValueFunction[nCapital, nProductivity] = mValueFunctionNew[nCapital, nProductivity];
          }
        }
        maxDifference = diffHighSoFar;

        iteration = iteration + 1;
        if (iteration % 10 == 0 || iteration == 1) {
          Console.WriteLine("Iteration = " + iteration + ", Sup Diff = " + maxDifference);
        }
      }

      Console.WriteLine("Iteration = " + iteration + ", Sup Diff = " + maxDifference);
      Console.WriteLine("My check = " + mPolicyFunction[999, 2]);

    }
  }
}
