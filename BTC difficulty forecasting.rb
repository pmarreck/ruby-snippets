require 'time'

start_date = Time.parse "feb 1 2013"
start_diff = 3100000
end_date = Time.parse "mar 1 2013"
end_diff = 4500000

rate = (end_diff - start_diff) / (end_date - start_date)

p rate

curr_date = Time.now
curr_diff = 5000000

future_date = Time.parse("Sept. 1, 2013")
future_diff = (future_date - curr_date) * rate + curr_diff

puts "Around #{future_diff.to_i} on #{future_date}"
