!============================================================================
! Name        : RBC_F90.f90
! Description : Basic RBC model with full depreciation
! Date        : July 21, 2013
!============================================================================

program RBC_F90
  
  !----------------------------------------------------------------
  ! 0. variables to be defined
  !----------------------------------------------------------------
  
  implicit none

  integer,  parameter :: nGridCapital = 17820
  integer,  parameter :: nGridProductivity = 5
  real(8),  parameter :: tolerance = 0.0000001
  
  integer :: nCapital, nCapitalNextPeriod, gridCapitalNextPeriod, nProductivity, nProductivityNextPeriod 
  integer :: iteration
        
  real    :: elapsed(2), total

  real(8) :: aalpha, bbeta, capitalSteadyState, outputSteadyState, consumptionSteadyState
  real(8) :: valueHighSoFar, valueProvisional, consumption, capitalChoice	
  real(8) :: maxDifference,diff,diffHighSoFar
	       
  real(8), dimension(nGridProductivity) :: vProductivity
  real(8), dimension(nGridProductivity,nGridProductivity) :: mTransition 
  real(8), dimension(nGridCapital) :: vGridCapital
  real(8), dimension(nGridCapital,nGridProductivity) :: mOutput, mValueFunction, mValueFunctionNew, mPolicyFunction
  real(8), dimension(nGridCapital,nGridProductivity) :: expectedValueFunction
  
  !----------------------------------------------------------------
  ! 1. Calibration
  !----------------------------------------------------------------
        
  aalpha = 0.33333333333; ! Elasticity of output w.r.t
  bbeta  = 0.95 ! Discount factor

  ! Productivity value
  vProductivity = (/0.9792, 0.9896, 1.0000, 1.0106, 1.0212/)

  ! Transition matrix
  mTransition = reshape( (/0.9727, 0.0273, 0., 0., 0., &
                          0.0041, 0.9806, 0.0153, 0.0, 0.0, &
                          0.0, 0.0082, 0.9837, 0.0082, 0.0, &
                          0.0, 0.0, 0.0153, 0.9806, 0.0041, &
                          0.0, 0.0, 0.0, 0.0273, 0.9727 /), (/5,5/))
        
  mTransition = transpose(mTransition)

  !----------------------------------------------------------------
  ! 2. Steady state
  !----------------------------------------------------------------

  capitalSteadyState     = (aalpha*bbeta)**(1.0/(1.0-aalpha))
  outputSteadyState      = capitalSteadyState**(aalpha)
  consumptionSteadyState = outputSteadyState-capitalSteadyState
  
  print *, 'Steady State values'
  print *, 'Output: ', outputSteadyState, 'Capital: ', capitalSteadyState, 'Consumption: ', consumptionSteadyState
      
  ! Grid for capital
  do nCapital = 1, nGridCapital
     vGridCapital(nCapital) = 0.5*capitalSteadyState+0.00001*(nCapital-1)
  end do

  !----------------------------------------------------------------
  ! 3. Pre-build Output for each point in the grid
  !----------------------------------------------------------------
  
  do nProductivity = 1, nGridProductivity
     do nCapital = 1, nGridCapital
        mOutput(nCapital, nProductivity) = vProductivity(nProductivity)*(vGridCapital(nCapital)**aalpha)
     end do
  end do

  !----------------------------------------------------------------
  ! 4. Main Iteration
  !----------------------------------------------------------------

  maxDifference = 10.0
  iteration     = 0
  
  do while (maxDifference>tolerance)
     
     expectedValueFunction = matmul(mValueFunction,transpose(mTransition));
   
     do nProductivity = 1,nGridProductivity
               
        ! We start from previous choice (monotonicity of policy function)

        gridCapitalNextPeriod = 1
                
        do nCapital = 1,nGridCapital
                        
           valueHighSoFar = -100000.0
                        
           do nCapitalNextPeriod = gridCapitalNextPeriod,nGridCapital

              consumption = mOutput(nCapital,nProductivity)-vGridCapital(nCapitalNextPeriod)
              valueProvisional = (1.0-bbeta)*log(consumption)+bbeta*expectedValueFunction(nCapitalNextPeriod,nProductivity)

              if (valueProvisional>valueHighSoFar) then ! we break when we have achieved the max
                 valueHighSoFar        = valueProvisional
                 capitalChoice         = vGridCapital(nCapitalNextPeriod)
                 gridCapitalNextPeriod = nCapitalNextPeriod
              else 
                 exit
              end if

           end do

           mValueFunctionNew(nCapital,nProductivity) = valueHighSoFar
           mPolicyFunction(nCapital,nProductivity)   = capitalChoice
                     
        end do
                
     end do

     maxDifference = maxval((abs(mValueFunctionNew-mValueFunction)))
     mValueFunction = mValueFunctionNew
           
     iteration = iteration+1
     if (mod(iteration,10)==0 .OR. iteration==1) then
        print *, 'Iteration:', iteration, 'Sup Diff:', MaxDifference
     end if
        
  end do
  
  !----------------------------------------------------------------
  ! 5. PRINT RESULTS
  !----------------------------------------------------------------
  
  print *, 'Iteration:', iteration, 'Sup Diff:', MaxDifference
  print *, ' '
  print *, 'My check:', mPolicyFunction(1000,3)
  print *, ' '

  total = etime(elapsed)

  print *, 'Elapsed time is ', elapsed(1)

end program RBC_F90
