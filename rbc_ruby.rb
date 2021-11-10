# frozen_string_literal: true

# use --jit or --yjit flags for 2-3x speedup
start = Time.now

aalpha = 1 / 3.0
bbeta = 0.95

vproductivity = [0.9792, 0.9896, 1.0000, 1.0106, 1.0212]

mtransition = [[0.9727, 0.0273, 0.0000, 0.0000, 0.0000],
               [0.0041, 0.9806, 0.0153, 0.0000, 0.0000],
               [0.0000, 0.0082, 0.9837, 0.0082, 0.0000],
               [0.0000, 0.0000, 0.0153, 0.9806, 0.0041],
               [0.0000, 0.0000, 0.0000, 0.0273, 0.9727]]

capital_steady_state = (aalpha * bbeta)**(1 / (1 - aalpha))
output_steady_state = capital_steady_state**aalpha
consumption_steady_state = output_steady_state - capital_steady_state

puts "Output = #{output_steady_state}. Capital = #{capital_steady_state}.  Consumption = #{consumption_steady_state}."

vgrid_capital = ((0.5 * capital_steady_state)..(1.5 * capital_steady_state)).step(0.00001).to_a
ngrid_capital = vgrid_capital.length
ngrid_productivity = vproductivity.length

moutput = Array.new(ngrid_capital) { Array.new(ngrid_productivity, 0) }
mvalue_function = Array.new(ngrid_capital) { Array.new(ngrid_productivity, 0) }
mvalue_function_new = Array.new(ngrid_capital) { Array.new(ngrid_productivity, 0) }
mpolicy_function = Array.new(ngrid_capital) { Array.new(ngrid_productivity, 0) }
expected_value_function = Array.new(ngrid_capital) { Array.new(ngrid_productivity, 0) }

(0...ngrid_productivity).each do |nproductivity|
  (0...ngrid_capital).each do |ncapital|
    moutput[ncapital][nproductivity] = vproductivity[nproductivity] * vgrid_capital[ncapital]**aalpha
  end
end

grid_capital_next_period = 0
max_difference = 10.0
diff = 10.0
diff_high_so_far = 10.0
tolerance = 0.0000001
iteration = 0
value_high_so_far = 0.0
value_provisional = 0.0
consumption = 0.0
capital_choice = 0.0

while max_difference > tolerance

  (0...ngrid_productivity).each do |nproductivity|
    (0...ngrid_capital).each do |ncapital|
      expected_value_function[ncapital][nproductivity] = 0.0
      (0...ngrid_productivity).each do |nproductivity_next_period|
        expected_value_function[ncapital][nproductivity] += mtransition[nproductivity][nproductivity_next_period] * mvalue_function[ncapital][nproductivity_next_period]
      end
    end
  end

  (0...ngrid_productivity).each do |nproductivity|
    grid_capital_next_period = 0
    (0...ngrid_capital).each do |ncapital|
      value_high_so_far = -100_000.0
      capital_choice = vgrid_capital[0]
      (grid_capital_next_period...ngrid_capital).each do |ncapital_next_period|
        consumption = moutput[ncapital][nproductivity] - vgrid_capital[ncapital_next_period]
        value_provisional = (1 - bbeta) * Math.log(consumption) + bbeta * expected_value_function[ncapital_next_period][nproductivity]
        if value_provisional > value_high_so_far
          value_high_so_far = value_provisional
          capital_choice = vgrid_capital[ncapital_next_period]
          grid_capital_next_period = ncapital_next_period
        else
          break
        end
        mvalue_function_new[ncapital][nproductivity] = value_high_so_far
        mpolicy_function[ncapital][nproductivity] = capital_choice
      end
    end
  end

  diff_high_so_far = -100_000.0

  (0...ngrid_productivity).each do |nproductivity|
    (0...ngrid_capital).each do |ncapital|
      diff = (mvalue_function[ncapital][nproductivity] - mvalue_function_new[ncapital][nproductivity]).abs
      if diff > diff_high_so_far
        diff_high_so_far = diff
      end
      mvalue_function[ncapital][nproductivity] = mvalue_function_new[ncapital][nproductivity]
    end
  end

  max_difference = diff_high_so_far
  iteration += 1

  if (iteration % 10).zero? || iteration.equal?(1)
    puts "Iteration = #{iteration}, Sup Diff = #{max_difference}"
  end

end

puts "Iteration = #{iteration}, Sup Diff = #{max_difference}"
puts "My Check = #{mpolicy_function[999][2]}"
puts "Time elapsed = #{Time.now - start}"
