# Is there a way I can make this work with a Delegator?

class WrappedValue < Object
  undef_method :class, :respond_to?, :to_s, :==, :eql?, :hash
  # don't undefine inspect, it's for debugging, you'll be angry if you don't see what something really is…

  attr_accessor :_

  def initialize(value)
    @_ = value
  end

  def method_missing(*args, &block)
    @_.__send__(*args, &block) # generic implementations should use __send__, not send
  end
end

class ExtraAttributes < WrappedValue
  attr_reader :extra_return_attributes

  def initialize(*)
    super
    @extra_return_attributes = {}
  end
  def method_missing(name, *args, &block)
    if args.empty? && block.nil? && @extra_return_attributes.has_key?(name)
      @extra_return_attributes[name]
    elsif block.nil? && (name.to_s.match(/[^\=]+\=$/)) && args.length == 1
      @extra_return_attributes[name.to_s.gsub(/\=$/,'').to_sym] = args[0]
    else
      super
    end
  end
end

if __FILE__==$0
  require 'test/unit'
  class ReturnValueTest < Test::Unit::TestCase

    def some_method_returning_loaded_int
      b = ExtraAttributes.new(5)
      b.debug="info"
      b
    end

    def some_method_returning_loaded_string
      b = ExtraAttributes.new("five")
      b.debug="info"
      b
    end

    def test_working

      a = some_method_returning_loaded_int

      assert a
      assert a == 5
      assert a._ == 5
      assert 5 == a
      assert a.class == Fixnum
      assert a.debug == "info"
      assert_equal a.extra_return_attributes, {debug: "info"}
      assert (a + 10 == 15)
      assert (10 + a == 15)
      assert -a == -5
      a._ = 6
      assert a == 6

      a = some_method_returning_loaded_string

      assert a
      assert a == "five"
      assert a._ == "five"
      assert "five" == a
      assert a.class == String
      assert a.debug == "info"
      assert (a + "six" == "fivesix")
      assert ("six" + a == "sixfive")
      assert a[0] == "f"
      assert a._[0] == "f"
      assert a.gsub("i","a") == "fave"
      assert a.gsub!("i","a") == "fave"
      assert_respond_to a, :_

      a._ = "69"
      assert a.to_i == 69
      assert a.to_f == 69.0

    end
  end

end