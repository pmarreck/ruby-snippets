require 'active_support/core_ext/module/delegation'

# Decorator module
module Decorator
  attr_reader :decorated
  # DELEGATED = [:is_a?, :kind_of?, :respond_to?, :class,
  # :marshal_dump, :marshal_load,
  # :freeze, :taint, :untaint, :trust, :untrust,
  # :methods, :protected_methods, :public_methods,
  # :object_id,
  # :!, :!=, :==, :===, :eql?, :hash,
  # :dup, :clone, :inspect]

  alias decorator_class class
  alias decorator_respond_to? respond_to?
  alias decorator_object_id object_id

  def initialize(dec)
    @decorated = dec
  end

  delegate :is_a?, :kind_of?, :respond_to?, :class,
    :marshal_dump, :marshal_load,
    :freeze, :taint, :untaint, :trust, :untrust,
    :methods, :protected_methods, :public_methods,
    :object_id,
    :!, :!=, :==, :===, :eql?, :hash,
    :dup, :clone, :inspect,
    to: :decorated

  def method_missing(*args)
    decorated.send(*args)
  end

  # Use this if you don't want to use active_support. Also uncomment the constant
  # DELEGATED.each do |delegated_method|
  #   define_method delegated_method do |*args|
  #     decorated.send(*(args.unshift(delegated_method)))
  #   end
  # end

  def decorators
    # Note: can't use respond_to? because it's delegated...
    # So I also had to either rescue here or monkeypatch Object.
    # Decided to just rescue.
    (decorated.decorators rescue []) << decorator_class
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
  def flavor
    "hazelnut"
  end
end

class ActsLikeTime
  include Decorator
  def days
    self * 86400
  end
end

########## inline tests
if __FILE__==$PROGRAM_NAME
  require 'test/unit'
  class RubyDecoratorTest < Test::Unit::TestCase

    def setup
      @timey_number            ||= ActsLikeTime.new(5)
      @whipmilkcoffee          ||= Whip.new(Milk.new(Coffee.new))
      @whipwhipcoffee          ||= Whip.new(Whip.new(Coffee.new))
      @sprinkleswhipmilkcoffee ||= Sprinkles.new(@whipmilkcoffee)
    end

    def test_coffee_cost
      assert_equal 1.85, @whipmilkcoffee.cost.round(2)
    end

    def test_coffee_is_a
      assert @whipmilkcoffee.is_a?(Coffee), "Whipped milk coffee is_a not a coffee!"
    end

    def test_coffee_kind_of
      assert @whipmilkcoffee.kind_of?(Coffee), "Whipped milk coffee is not a kind_of coffee!"
    end

    def test_coffee_double_whip
      assert_equal 1.65, @whipwhipcoffee.cost.round(2)
    end

    def test_decorators_are_class_coffee
      assert_equal Coffee, @whipmilkcoffee.class
    end

    def test_decorator_inspection
      assert_equal [Milk, Whip, Sprinkles], @sprinkleswhipmilkcoffee.decorators
    end

    def test_method_fallthrough
      assert_equal "hazelnut", @whipmilkcoffee.flavor
    end

    def test_alternative_to_monkeypatching_fixnum
      assert_equal 432000, @timey_number.days
    end

    def test_still_seems_like_a_fixnum
      assert_equal 10, @timey_number + 5
    end

    def test_still_says_its_a_fixnum
      assert @timey_number.is_a?(Fixnum), "num is not saying it's a Fixnum"
    end

    def test_knows_whats_decorating_it
      assert_equal [ActsLikeTime], @timey_number.decorators
    end

    def test_object_equivalence_even_when_decorated
      assert_equal Sprinkles.new(a=Coffee.new), a
    end

    def test_marshal_dump_equivalence
      b = Sprinkles.new(a=Coffee.new)
      # Y U NO PASS?
      assert_equal Marshal.dump(b), Marshal.dump(a)
    end

  end
end
