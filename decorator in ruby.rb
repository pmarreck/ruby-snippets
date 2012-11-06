# Decorator module
module Decorator
  attr_reader :decorated
  DELEGATED = [:is_a?, :kind_of?, :respond_to?, :method_missing, :class]

  def initialize(dec)
    @decorated = dec
  end

  DELEGATED.each do |delegated_method|
    define_method delegated_method do |*args|
      decorated.send(*(args.unshift(delegated_method)))
    end
  end

end

# Test setup classes

class Milk
  include Decorator

  def cost
    decorated.cost + 0.4
  end
end

class Whip
  include Decorator

  def cost
    decorated.cost + 0.2
  end
end

class Sprinkles
  include Decorator

  def cost
    decorated.cost + 0.3
  end
end

class Coffee
  def cost
    1.25
  end
end

########## inline tests
if __FILE__==$PROGRAM_NAME
  require 'test/unit'
  class RubyDecoratorTest < Test::Unit::TestCase

    def test_coffee_cost
      assert_equal 1.85, Whip.new(Milk.new(Coffee.new)).cost.round(2)
    end

    def test_coffee_is_a
      assert Whip.new(Milk.new(Coffee.new)).is_a?(Coffee), "Whipped milk coffee is_a not a coffee!"
    end

    def test_coffee_kind_of
      assert Whip.new(Milk.new(Coffee.new)).kind_of?(Coffee), "Whipped milk coffee is not a kind_of coffee!"
    end

    def test_coffee_double_whip
      assert_equal 1.65, Whip.new(Whip.new(Coffee.new)).cost.round(2)
    end

    def test_decorators_are_class_coffee
      assert_equal Coffee, Whip.new(Milk.new(Coffee.new)).class
    end

  end
end
