
# Ruby fizzbuzz, functional style, no conditionals whatsoever
# I invented this. -Peter Marreck

one_if_divisible_by = lambda{|num, n| (1-((n.to_f / num) % 1).ceil)}.curry
fizz1 = one_if_divisible_by.(3)
buzz1 = one_if_divisible_by.(5)
one_to_word = lambda{|func, word, n| word * func.(n)}.curry
one_to_n_to_s = lambda{|func, n| n.to_s * func.(n)}.curry
fizz = one_to_word.(fizz1,'Fizz')
buzz = one_to_word.(buzz1,'Buzz')
func_or_func = lambda{|func1, func2, n| func1.(n) | func2.(n) }.curry
fizz1_or_buzz1 = func_or_func.(fizz1, buzz1)
not_func = lambda {|func, n| 1 - func.(n)}.curry
not_fizz1_or_buzz1 = not_func.(fizz1_or_buzz1)
not_fizz1_or_buzz1_to_word = one_to_n_to_s.(not_fizz1_or_buzz1)
# future to-do exercise: make the following work!
# concat_funcs = lambda{ |*funcs| funcs.first.(funcs.last) << concat_funcs.(*funcs[1..-1])  }.curry
append_func1_func2_func3 = lambda{|func1, func2, func3, n| func1.(n) << func2.(n) << func3.(n)}.curry
fizzbuzz = append_func1_func2_func3.(fizz, buzz, not_fizz1_or_buzz1_to_word)
puts (1..100).map(&fizzbuzz)
