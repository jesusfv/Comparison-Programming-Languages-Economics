import
  math, times

let aalpha: float64 = 1/3
let bbeta: float64 = 0.95

let vProductivity = [0.9792, 0.9896, 1.0000, 1.0106, 1.0212]

let mTransition = [[0.9727, 0.0273, 0.0000, 0.0000, 0.0000],
                   [0.0041, 0.9806, 0.0153, 0.0000, 0.0000],
                   [0.0000, 0.0082, 0.9837, 0.0082, 0.0000],
                   [0.0000, 0.0000, 0.0153, 0.9806, 0.0041],
                   [0.0000, 0.0000, 0.0000, 0.0273, 0.9727]]

let capitalSteadyState = pow( (aalpha*bbeta), (1/(1-aalpha)) )
let outputSteadyState = pow( capitalSteadyState, aalpha )
let consumptionSteadyState = outputSteadyState-capitalSteadyState

echo "Output = ", outputSteadyState, " Capital = ", capitalSteadyState, " Consumption = ", consumptionSteadyState


var nCapital, nCapitalNextPeriod, gridCapitalNextPeriod, nProductivity, nProductivityNextPeriod : int = 0
var vGridCapital: array[0..17820, float64]
const nGridCapital: int = 17820
const nGridProductivity: int = 5

for nCapital in 0..<nGridCapital:
  vGridCapital[nCapital] = 0.5 * capitalSteadyState + 0.00001 * nCapital.tofloat

var mOutput: array[0..nGridCapital, array[0..nGridProductivity, float64]]
var mValueFunction: array[0..nGridCapital, array[0..nGridProductivity, float64]]
var mValueFunctionNew: array[0..nGridCapital, array[0..nGridProductivity, float64]]
var mPolicyFunction: array[0..nGridCapital, array[0..nGridProductivity, float64]]
var expectedValueFunction: array[0..nGridCapital, array[0..nGridProductivity, float64]]

for nProductivity in 0..<nGridProductivity:
  for nCapital in 0..<nGridCapital:
    mOutput[nCapital][nProductivity] = vProductivity[nProductivity] * pow( vGridCapital[nCapital], aalpha )

var maxDifference, diff, diffHighSoFar: float64 = 10.0
const tolerance: float64 = 0.0000001


var iteration = 0
var valueHighSoFar, valueProvisional, consumption, capitalChoice : float64

while maxDifference > tolerance:

  for nProductivity in 0..<nGridProductivity:
    for nCapital in 0..<nGridCapital:
      expectedValueFunction[nCapital][nProductivity] = 0.0
      for nProductivityNextPeriod in 0..<nGridProductivity:
        expectedValueFunction[nCapital][nProductivity] += mTransition[nProductivity][nProductivityNextPeriod] * mValueFunction[nCapital][nProductivityNextPeriod]

  for nProductivity in 0..<nGridProductivity:
    gridCapitalNextPeriod = 0

    for nCapital in 0..<nGridCapital-1:
      valueHighSoFar = -100000.0
      capitalChoice = vGridCapital[0]

      for nCapitalNextPeriod in gridCapitalNextPeriod..<nGridCapital:
        consumption = mOutput[nCapital][nProductivity] - vGridCapital[nCapitalNextPeriod]
        valueProvisional = (1-bbeta)* math.ln(consumption)+bbeta*expectedValueFunction[nCapitalNextPeriod][nProductivity]

        if valueProvisional > valueHighSoFar:
          valueHighSoFar = valueProvisional
          capitalChoice = vGridCapital[nCapitalNextPeriod]
          gridCapitalNextPeriod = nCapitalNextPeriod
        else:
          break

        mValueFunctionNew[nCapital][nProductivity] = valueHighSoFar
        mPolicyFunction[nCapital][nProductivity] = capitalChoice

  diffHighSoFar = -100000.0
  for nProductivity in 0..<nGridProductivity:
    for nCapital in 0..<nGridCapital:
      diff = ( mValueFunction[nCapital][nProductivity] - mValueFunctionNew[nCapital][nProductivity] ).abs
      if diff > diffHighSoFar:
        diffHighSoFar = diff
      mValueFunction[nCapital][nProductivity] = mValueFunctionNew[nCapital][nProductivity]
  maxDifference = diffHighSoFar

  iteration = iteration + 1
  if iteration mod 10 == 0 or iteration == 1:
    echo "Iteration = ", iteration, ", Sup Diff = ", maxDifference

echo "Iteration = ", iteration, ", Sup Diff = ", maxDifference
echo "My Check = ", mPolicyFunction[999][2]
echo "Time taken: ", cpuTime()
