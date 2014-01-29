def random_string(length = 2+rand(75))
  alphabet = ('a'..'z').to_a
  Array.new(length).map{ alphabet.sample }.join
end

puts random_string