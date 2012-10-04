class Fixnum
  def method_missing(*args, &block)
    if l=instance_variable_get("@_meth_#{m=args.shift}")
      # instance_exec is like instance_eval but it takes parameters
      self.instance_exec(*args, &l)
    else
      raise NoMethodError, "undefined method `#{m}' for #{self}:#{self.class}"
    end
  end
  def respond_to?(m)
    !!instance_variable_get("@_meth_#{m}") || super
  end
  def define_method(m, &block)
    instance_variable_set("@_meth_#{m}", block)
  end
end

if __FILE__==$0
  require 'test/unit'
  class FixnumMethodsTest < Test::Unit::TestCase
    def setup
      # note that self is defined as 5 here and it still takes the param n
      5.define_method(:go){|n| "Went #{self * n} times!"}
    end
    def test_assigment
      assert_equal "Went 20 times!", 5.go(4)
    end
    def test_respond_to
      assert 5.respond_to?(:go)
      assert !6.respond_to?(:go)
    end
    def test_raise
      assert_raise(NoMethodError){ 5.what }
    end
  end
end
