//============================================================================
// Name        : RBC_CPP.cpp
// Description : Basic RBC model with full depreciation, more idiomatic C++ version
// Date        : July 21, 2013
// Corrected by: Dziubinski, Matt P, matt@math.aau.dk 
//============================================================================

#include <array>
#include <chrono>       // time measurement
#include <cmath>        // std::abs, std::log, std::pow
#include <cstddef>      // std::size_t
#include <iostream>
#include <limits>       // std::numeric_limits

// fixed-size vector, size: Rows
template <std::size_t Rows> using Vector = std::array<double, Rows>;

// fixed-size matrix, size: Rows * Columns
template <std::size_t Rows, std::size_t Columns> using Matrix = std::array<Vector<Columns>, Rows>;

int main()
{
	const auto time_0 = std::chrono::steady_clock::now();

	///////////////////////////////////////////////////////////////////////////////////////////
	// 1. Calibration
	///////////////////////////////////////////////////////////////////////////////////////////

	const auto aalpha = 1. / 3.;          // Elasticity of output w.r.t. capital
	const auto bbeta = 0.95;              // Discount factor;

	// Productivity values

	const std::size_t nGridProductivity = 5;
	const Vector<nGridProductivity> vProductivity{ { 0.9792, 0.9896, 1.0000, 1.0106, 1.0212 } };

	// Transition matrix
	const Matrix<nGridProductivity, nGridProductivity> mTransition{ {
		{ 0.9727, 0.0273, 0.0000, 0.0000, 0.0000 },
		{ 0.0041, 0.9806, 0.0153, 0.0000, 0.0000 },
		{ 0.0000, 0.0082, 0.9837, 0.0082, 0.0000 },
		{ 0.0000, 0.0000, 0.0153, 0.9806, 0.0041 },
		{ 0.0000, 0.0000, 0.0000, 0.0273, 0.9727 }
	} };

	///////////////////////////////////////////////////////////////////////////////////////////
	// 2. Steady State
	///////////////////////////////////////////////////////////////////////////////////////////

	const auto capitalSteadyState = std::pow(aalpha * bbeta, 1. / (1. - aalpha));
	const auto outputSteadyState = std::pow(capitalSteadyState, aalpha);
	const auto consumptionSteadyState = outputSteadyState - capitalSteadyState;

	std::cout << "Output = " << outputSteadyState << ", Capital = " << capitalSteadyState << ", Consumption = " << consumptionSteadyState << "\n";

	// We generate the grid of capital
	const std::size_t nGridCapital = 17820;
	Vector<nGridCapital> vGridCapital;

	for (std::size_t nCapital = 0; nCapital < nGridCapital; ++nCapital)
		vGridCapital[nCapital] = 0.5 * capitalSteadyState + 0.00001 * nCapital;

	// 3. Required matrices and vectors

	Matrix<nGridCapital, nGridProductivity> mOutput; // default-initialization (indeterminate value)
	Matrix<nGridCapital, nGridProductivity> mValueFunction = {}; // value-initialization
	Matrix<nGridCapital, nGridProductivity> mValueFunctionNew = {}; // value-initialization
	Matrix<nGridCapital, nGridProductivity> mPolicyFunction = {}; // value-initialization
	Matrix<nGridCapital, nGridProductivity> expectedValueFunction; // default-initialization (indeterminate value)

	// 4. We pre-build output for each point in the grid

	for (std::size_t nProductivity = 0; nProductivity < nGridProductivity; ++nProductivity)
	{
		for (std::size_t nCapital = 0; nCapital < nGridCapital; ++nCapital)
			mOutput[nCapital][nProductivity] = vProductivity[nProductivity] * std::pow(vGridCapital[nCapital], aalpha);
	}

	// 5. Main iteration

	const double tolerance = 0.0000001;
	auto maxDifference = 10.0;
	std::size_t iteration = 0;

	while (maxDifference > tolerance)
	{
		for (std::size_t nProductivity = 0; nProductivity < nGridProductivity; ++nProductivity)
		{
			for (std::size_t nCapital = 0; nCapital < nGridCapital; ++nCapital)
			{
				expectedValueFunction[nCapital][nProductivity] = 0.0;
				for (std::size_t nProductivityNextPeriod = 0; nProductivityNextPeriod < nGridProductivity; ++nProductivityNextPeriod)
					expectedValueFunction[nCapital][nProductivity] += mTransition[nProductivity][nProductivityNextPeriod] * mValueFunction[nCapital][nProductivityNextPeriod];
			}
		}

		for (std::size_t nProductivity = 0; nProductivity < nGridProductivity; ++nProductivity)
		{
			// We start from previous choice (monotonicity of policy function)
			std::size_t gridCapitalNextPeriod = 0;
			for (std::size_t nCapital = 0; nCapital < nGridCapital; ++nCapital)
			{
				auto valueHighSoFar = -std::numeric_limits<double>::infinity();
				auto capitalChoice = vGridCapital[0];

				for (std::size_t nCapitalNextPeriod = gridCapitalNextPeriod; nCapitalNextPeriod < nGridCapital; ++nCapitalNextPeriod)
				{
					const auto consumption = mOutput[nCapital][nProductivity] - vGridCapital[nCapitalNextPeriod];
					const auto valueProvisional = (1. - bbeta) * std::log(consumption) + bbeta * expectedValueFunction[nCapitalNextPeriod][nProductivity];
					if (valueProvisional > valueHighSoFar)
					{
						valueHighSoFar = valueProvisional;
						capitalChoice = vGridCapital[nCapitalNextPeriod];
						gridCapitalNextPeriod = nCapitalNextPeriod;
					}
					else
					{
						mValueFunctionNew[nCapital][nProductivity] = valueHighSoFar;
						mPolicyFunction[nCapital][nProductivity] = capitalChoice;
						// We break when we have achieved the max (note: of a monotonic function)
						break;
					}
					mValueFunctionNew[nCapital][nProductivity] = valueHighSoFar;
					mPolicyFunction[nCapital][nProductivity] = capitalChoice;
				}
			}
		}

		double diffHighSoFar = -std::numeric_limits<double>::infinity();
		for (std::size_t nProductivity = 0; nProductivity < nGridProductivity; ++nProductivity)
		{
			for (std::size_t nCapital = 0; nCapital<nGridCapital; ++nCapital)
			{
				const auto diff = std::abs(mValueFunction[nCapital][nProductivity] - mValueFunctionNew[nCapital][nProductivity]);
				if (diff > diffHighSoFar) diffHighSoFar = diff;
				mValueFunction[nCapital][nProductivity] = mValueFunctionNew[nCapital][nProductivity];
			}
		}
		maxDifference = diffHighSoFar;
		++iteration;
		if ((iteration % 10 == 0) || (iteration == 1))
			std::cout << "Iteration = " << iteration << ", Sup Diff = " << maxDifference << "\n";
	}

	std::cout << "Iteration = " << iteration << ", Sup Diff = " << maxDifference << "\n";
	endl(std::cout);
	std::cout << "My check = " << mPolicyFunction[999][2] << "\n";
	endl(std::cout);

	const auto time_1 = std::chrono::steady_clock::now();
	const auto elapsed_seconds = std::chrono::duration_cast<std::chrono::duration<double>>(time_1 - time_0).count();
	std::cout << "Elapsed time is   = " << elapsed_seconds << " seconds." << std::endl;
	endl(std::cout);

	return 0;
}
