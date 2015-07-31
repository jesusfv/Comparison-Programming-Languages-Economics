//============================================================================
// Name        : RBC_Swift.swift
// Description : Basic RBC model with full depreciation
// Date        : July 4, 2014
// Santiago González <sangonz@gmail.com>
//
// This code is for Apple's Swift language
// Compile: swiftc -O -sdk $(xcrun --show-sdk-path --sdk macosx) RBC_Swift.swift
//============================================================================

import Foundation

func get_cpu_time() -> Double {
    return Double(clock()) / Double(CLOCKS_PER_SEC)
}

var cpu0  = get_cpu_time()

///////////////////////////////////////////////////////////////////////////////////////////
// 1. Calibration
///////////////////////////////////////////////////////////////////////////////////////////

let aalpha = 0.33333333333     // Elasticity of output w.r.t. capital
let bbeta  = 0.95              // Discount factor

// Productivity values

let vProductivity = [0.9792, 0.9896, 1.0000, 1.0106, 1.0212]

// Transition matrix
let mTransition = [
    [0.9727, 0.0273, 0.0000, 0.0000, 0.0000],
    [0.0041, 0.9806, 0.0153, 0.0000, 0.0000],
    [0.0000, 0.0082, 0.9837, 0.0082, 0.0000],
    [0.0000, 0.0000, 0.0153, 0.9806, 0.0041],
    [0.0000, 0.0000, 0.0000, 0.0273, 0.9727]
]

///////////////////////////////////////////////////////////////////////////////////////////
// 2. Steady State
///////////////////////////////////////////////////////////////////////////////////////////

let capitalSteadyState = pow(aalpha*bbeta,1/(1-aalpha))
let outputSteadyState  = pow(capitalSteadyState,aalpha)
let consumptionSteadyState = outputSteadyState-capitalSteadyState

println("Output = \(outputSteadyState), Capital = \(capitalSteadyState), Consumption = \(consumptionSteadyState)")
println()

// We generate the grid of capital
//var nCapital, nCapitalNextPeriod, gridCapitalNextPeriod, nProductivity, nProductivityNextPeriod
let nGridCapital = 17820
let nGridProductivity = 5
var vGridCapital = [Double](count: nGridCapital, repeatedValue: 0.0)

for nCapital in 0..<nGridCapital {
    vGridCapital[nCapital] = 0.5*capitalSteadyState+0.00001*Double(nCapital)
}

// 3. Required matrices and vectors

func Double2(cols: Int, rows: Int) -> [[Double]] {
    return [[Double]](count: cols, repeatedValue:[Double](count: rows, repeatedValue:Double(0.0)))
}

var mOutput = Double2(nGridCapital, nGridProductivity)
var mValueFunction = Double2(nGridCapital, nGridProductivity)
var mValueFunctionNew = Double2(nGridCapital, nGridProductivity)
var mPolicyFunction = Double2(nGridCapital, nGridProductivity)
var expectedValueFunction = Double2(nGridCapital, nGridProductivity)

// 4. We pre-build output for each point in the grid
    
for nProductivity in 0..<nGridProductivity {
    for nCapital in 0..<nGridCapital {
        mOutput[nCapital][nProductivity] = vProductivity[nProductivity]*pow(vGridCapital[nCapital],aalpha)
    }
}

// 5. Main iteration

var maxDifference = 10.0, diff, diffHighSoFar: Double
var tolerance = 0.0000001
var valueHighSoFar, valueProvisional, consumption, capitalChoice: Double

var iteration = 0

while (maxDifference>tolerance){
    
    for nProductivity in 0..<nGridProductivity {
        for nCapital in 0..<nGridCapital {
            expectedValueFunction[nCapital][nProductivity] = 0.0
            for nProductivityNextPeriod in 0..<nGridProductivity {
                expectedValueFunction[nCapital][nProductivity] += mTransition[nProductivity][nProductivityNextPeriod]*mValueFunction[nCapital][nProductivityNextPeriod]
            }
        }
    }
    
    for nProductivity in 0..<nGridProductivity {
        
        // We start from previous choice (monotonicity of policy function)
        var gridCapitalNextPeriod = 0
        
        for nCapital in 0..<nGridCapital {
            
            valueHighSoFar = -100000.0
            capitalChoice  = vGridCapital[0]
            
            for nCapitalNextPeriod in gridCapitalNextPeriod..<nGridCapital {
                
                consumption = mOutput[nCapital][nProductivity]-vGridCapital[nCapitalNextPeriod]
                valueProvisional = (1-bbeta)*log(consumption)+bbeta*expectedValueFunction[nCapitalNextPeriod][nProductivity]
                
                if (valueProvisional>valueHighSoFar){
                    valueHighSoFar = valueProvisional
                    capitalChoice = vGridCapital[nCapitalNextPeriod]
                    gridCapitalNextPeriod = nCapitalNextPeriod
                }
                else{
                    break // We break when we have achieved the max
                }
                
                mValueFunctionNew[nCapital][nProductivity] = valueHighSoFar
                mPolicyFunction[nCapital][nProductivity] = capitalChoice
            }
            
        }
        
    }
    
    diffHighSoFar = -100000.0
    for nProductivity in 0..<nGridProductivity {
        for nCapital in 0..<nGridCapital {
            diff = fabs(mValueFunction[nCapital][nProductivity]-mValueFunctionNew[nCapital][nProductivity])
            if (diff>diffHighSoFar){
                diffHighSoFar = diff
            }
            mValueFunction[nCapital][nProductivity] = mValueFunctionNew [nCapital][nProductivity]
        }
    }
    maxDifference = diffHighSoFar
    
    iteration = iteration+1
    if iteration % 10 == 0 || iteration == 1 {
        println("Iteration = \(iteration), Sup Diff = \(maxDifference)")
    }
}

println("Iteration = \(iteration), Sup Diff = \(maxDifference)")
println()
println("My check = \(mPolicyFunction[999][2])")
println()

let cpu1  = get_cpu_time()

println("Elapsed time is   = \(cpu1  - cpu0)")
println()


