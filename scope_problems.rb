a = 5

lambda { a = 7 }.call
puts "a is now: #{a}"

def change_a
  a = 9
end

change_a

puts "a is now: #{a}" # does not change in this scope

begin
rescue => err
end
puts "err is actually defined here as #{err.inspect} even without an error being raised" if defined?(err)

def change_a_ref(a)
  a = 1
end

change_a_ref(10)

puts "a is now: #{a}"
