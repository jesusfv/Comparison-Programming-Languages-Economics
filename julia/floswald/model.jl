

# define a custom data type "model"

type Model

	# define types

	aalpha :: Float64
	bbeta  :: Float64 

	vProductivity ::Array{Float64,1}  
	mTransition   ::Array{Float64,2} 

	capitalSteadyState     :: Float64
	outputSteadyState      :: Float64
	consumptionSteadyState :: Float64

	vGridCapital :: Array{Float64,1} 

	nGridCapital :: Int64 
	nGridProductivity :: Int64 

	mOutput               :: Array{Float64,2}
	mValueFunction        :: Array{Float64,2}
	mValueFunctionNew     :: Array{Float64,2}
	mPolicyFunction       :: Array{Float64,2}
	expectedValueFunction :: Array{Float64,2}


	# constructor
	function Model()

		aalpha=1/3
		bbeta =0.95

		vProductivity = [0.9792,0.9896,1.0000,1.0106,1.0212]

		mTransition   = [0.9727 0.0273 0.0000 0.0000 0.0000;
                     0.0041 0.9806 0.0153 0.0000 0.0000;
                     0.0000 0.0082 0.9837 0.0082 0.0000;
                     0.0000 0.0000 0.0153 0.9806 0.0041;
                     0.0000 0.0000 0.0000 0.0273 0.9727]

	    capitalSteadyState = (aalpha*bbeta)^(1/(1-aalpha))
	    outputSteadyState = capitalSteadyState^aalpha
	    consumptionSteadyState = outputSteadyState-capitalSteadyState



	    # We generate the grid of capital
	    vGridCapital = 0.5*capitalSteadyState:0.00001:1.5*capitalSteadyState

	    nGridCapital = length(vGridCapital)
	    nGridProductivity = length(vProductivity)

	    # 3. Required matrices and vectors

	    mOutput           = zeros(nGridCapital,nGridProductivity)
	    mValueFunction    = zeros(nGridCapital,nGridProductivity)
	    mValueFunctionNew = zeros(nGridCapital,nGridProductivity)
	    mPolicyFunction   = zeros(nGridCapital,nGridProductivity)
	    expectedValueFunction = zeros(nGridCapital,nGridProductivity)

	    # 4. We pre-build output for each point in the grid

	    mOutput = (vGridCapital.^aalpha).*vProductivity';

	    # return a model
	    return new(aalpha,bbeta,vProductivity,mTransition,capitalSteadyState,outputSteadyState,consumptionSteadyState,vGridCapital,nGridCapital,nGridProductivity,mOutput,mValueFunction,mValueFunctionNew,mPolicyFunction,expectedValueFunction) 

	end	# constructor

end	# type

# a show method
function show(io::IO, m::Model)
    print(io, "RBC Model object\n")
    print(io, "Capital grid points = $(m.nGridCapital)\n")
    print(io, "Productivity grid points = $(m.nGridProductivity)\n")
    print(io, "Output = $(m.outputSteadyState)\n")
    print(io, "Capital = $(m.capitalSteadyState)\n")
    print(io, "Consumption = $(m.consumptionSteadyState)\n")
end


# the main computation function
function compute(m::Model)

	# pre-allocate some temps
    maxDifference         = 10.0
    tolerance             = 0.0000001
    iteration             = 0
    valueHighSoFar        = -1000.0
    capitalChoice         = m.vGridCapital[1]
    gridCapitalNextPeriod = 1
    consumption           = 0.0
    valueProvisional      = 0.0


    # main loop
    while(maxDifference > tolerance)

    	m.expectedValueFunction = m.mValueFunction * m.mTransition'

    	for nProductivity = 1:m.nGridProductivity

            # We start from previous choice (monotonicity of policy function)
            gridCapitalNextPeriod = 1
        
            for nCapital = 1:m.nGridCapital
        
                valueHighSoFar = -1000.0
                capitalChoice  = m.vGridCapital[1]
            
                for nCapitalNextPeriod = gridCapitalNextPeriod:m.nGridCapital

                    consumption = m.mOutput[nCapital,nProductivity]-m.vGridCapital[nCapitalNextPeriod]
                    valueProvisional = (1-m.bbeta)*log(consumption)+m.bbeta*m.expectedValueFunction[nCapitalNextPeriod,nProductivity]
               
                    if (valueProvisional>valueHighSoFar)
	                	valueHighSoFar = valueProvisional
	                	capitalChoice = m.vGridCapital[nCapitalNextPeriod]
	                	gridCapitalNextPeriod = nCapitalNextPeriod
                    else
                		break # We break when we have achieved the max
                    end
                                 
                end
            
                m.mValueFunctionNew[nCapital,nProductivity] = valueHighSoFar
                m.mPolicyFunction[nCapital,nProductivity] = capitalChoice
          
            end

        end

        maxDifference  = maximum(abs(m.mValueFunctionNew-m.mValueFunction))
        m.mValueFunction    = copy(m.mValueFunctionNew)
        fill!(m.mValueFunctionNew,0.0)

        iteration = iteration+1
        if mod(iteration,10)==0 || iteration == 1
            println(" Iteration = ", iteration, " Sup Diff = ", maxDifference)
        end
           
    end


    println(" Iteration = ", iteration, " Sup Diff = ", maxDifference)
    println(" ")
    println(" My check = ", m.mPolicyFunction[1000,3])


end

# a slightly tuned computation function
# uses linear indices [i + ni * (j-1)] instead of array access[i,j]
# switches off bound checking
function computeTuned(m::Model)

	# pre-allocate some temps
    maxDifference         = 10.0
    tolerance             = 0.0000001
    iteration             = 0
    valueHighSoFar        = -1000.0
    capitalChoice         = m.vGridCapital[1]
    gridCapitalNextPeriod = 1
    consumption           = 0.0
    valueProvisional      = 0.0
    oneminusbeta          = 1-m.bbeta


    # main loop
	@inbounds begin
    while(maxDifference > tolerance)

    	m.expectedValueFunction = m.mValueFunction * m.mTransition'

    	for nProductivity = 1:m.nGridProductivity

            # We start from previous choice (monotonicity of policy function)
            gridCapitalNextPeriod = 1
        
            for nCapital = 1:m.nGridCapital
        
                valueHighSoFar = -1000.0
                capitalChoice  = m.vGridCapital[1]
            
                for nCapitalNextPeriod = gridCapitalNextPeriod:m.nGridCapital

                    consumption = m.mOutput[nCapital,nProductivity]-m.vGridCapital[nCapitalNextPeriod]
                    valueProvisional = oneminusbeta*log(consumption)+m.bbeta*m.expectedValueFunction[nCapitalNextPeriod + m.nGridCapital * (nProductivity-1)]
               
                    if (valueProvisional>valueHighSoFar)
	                	valueHighSoFar = valueProvisional
	                	capitalChoice = m.vGridCapital[nCapitalNextPeriod]
	                	gridCapitalNextPeriod = nCapitalNextPeriod
                    else
                		break # We break when we have achieved the max
                    end
                                 
                end
            
                m.mValueFunctionNew[nCapital + m.nGridCapital * (nProductivity-1)] = valueHighSoFar
                m.mPolicyFunction[nCapital + m.nGridCapital * (nProductivity-1)] = capitalChoice
          
            end

        end

        maxDifference  = maximum(abs(m.mValueFunctionNew-m.mValueFunction))
        m.mValueFunction    = copy(m.mValueFunctionNew)
        fill!(m.mValueFunctionNew,0.0)

        iteration = iteration+1
        if mod(iteration,10)==0 || iteration == 1
            println(" Iteration = ", iteration, " Sup Diff = ", maxDifference)
        end
           
    end
	end # inbounds
end

# reset ValueFucntino method
function resetV!(m::Model)
	fill!(m.mValueFunction,0.0)
	fill!(m.mValueFunctionNew,0.0)
	fill!(m.mPolicyFunction,0.0)
	fill!(m.expectedValueFunction,0.0)
	return nothing
end





