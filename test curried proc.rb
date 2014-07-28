module CurriedMethod
  def self.included(base)
    base.class_eval do
      self.const_set :CURRIED_PROC, ->(o){ puts o }.curry
    end
  end
end

class SomeClass
  include CurriedMethod
  def go
    [1,2,3].each(&CURRIED_PROC)
  end
end

SomeClass.new.go

# 1
# 2
# 3

puts SomeClass.constants
# CURRIED_PROC
