class MethodCapturer < BasicObject
  include ::Kernel
  attr_reader :lamb

  def initialize(slot, l = nil)
    @lamb = l || lambda{ |bound_args| bound_args[slot] }
    self
  end

  def class
    ::MethodCapturer
  end

  def coerce(something)
    [self, something]
  end

  def inspect
    "\#<MethodCapturer @lamb=#{@lamb}"
  end
  
  undef_method :to_s

  def method_missing(*missing_args)
    l = lambda do |bound_args|
      ma = missing_args.map{|a| a.respond_to?(:call) ? a.call(*bound_args) : a}
      @lamb.call(bound_args).send(*ma)
    end
    self.class.new(@slot, l)
  end
  def respond_to?(*args); true; end

  def call(*args)
    @lamb.call(args)
  end

end

class Integer
  def arg
    MethodCapturer.new(self)
  end
end

# So the idea is you can chain a bunch of argument references (without actual arguments yet to bind to)
# and assign to a variable which is basically a lambda. Later on you actually call it with the args.

if __FILE__==$PROGRAM_NAME
  require 'test/unit'
  class CrazyArgumentSelectionTest < Test::Unit::TestCase
    def test_basic_functionality
      func = ((1.arg * 0.arg) + 0.arg - 1.arg) * 2.arg
      assert_equal(55, func.call(3,4,5))
    end
    def test_strings
      assert_nothing_raised{ MethodCapturer.new(0).to_s }
      assert_equal MethodCapturer, MethodCapturer.new(0).to_s.class
      func = 0.arg.to_s + 1.arg.to_s
      assert_equal("12", func.call(1,2))
    end
    class ::String; def to_regex; Regexp.new(self); end; end
    def test_arbitrary_calculations
      findbob = 0.arg.match(/bob/)[0]
      assert_equal MethodCapturer, findbob.class
      assert_equal "bob", findbob.("whataboutbob?")
      # The following won't pass yet, probably because the interpolation happens early
      # findstring = 0.arg.match(/#{1.arg}/)[0]
      findstring = 0.arg.match(1.arg.to_regex)[0]
      assert_equal "peter", findstring.("peterwashere","peter")
    end
  end
end

