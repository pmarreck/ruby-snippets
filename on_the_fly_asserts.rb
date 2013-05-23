module Asserts
  def assert(*args); args.first ? true : raise(args[1] || "#{args} is not true"); end
  def assert_equal(*args); args[0]==args[1] ? true : raise(args[2] || "#{args[0]} expected to be equal to #{args[1]}"); end
  def assert_not_equal(*args); args[0]!=args[1] ? true : raise(args[2] || "#{args[0]} expected to be unequal to #{args[1]}"); end
  def assert_not_nil(*args); !args.first.nil? ? true : raise(args[1] || "#{args[0]} expected to be not nil"); end
  def assert_nil(*args); args.first.nil? ? true : raise(args[1] || "#{args[0]} expected to be nil"); end
end
