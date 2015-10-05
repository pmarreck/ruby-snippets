# encoding: UTF-8
require 'delegate'

# ExtraAttributes: An object that lets you sneak as many return values as you want
# through a single scalar-looking return value.
# Any return values set are immutable.
# Example usage:
# def some_method
#   ExtraAttributes.new(200, debug: 'from some_method')
# end
# a = some_method
# a == 200 # true
# puts a.debug
# etc...

class ExtraAttributes < Delegator
  attr_reader :_
  undef_method :class # methods undefined here are pushed to delegate
  def initialize(val, extras={})
    super val
    @extras ||= extras #note! assumes symbol keys passed in
  end
  def __getobj__
    @_
  end
  def __setobj__(o)
    @_ = o.freeze
  end
  def _=(e)
    raise NameError, "undefined method `_='"
  end

  def respond_to?(method_name, include_private=false)
    return true if @extras.key?(method_name) || @_.respond_to?(method_name)
    super
  end

  # unknown getters and setters are added as @extras hash keys
  # unless the delegate has a setter with the same name...
  def method_missing(name, *args, &block)
    unless block_given?
      if args.empty? && @extras.key?(name)
        @extras[name]
      else
        getter_from_setter = name.to_s.gsub(/\=$/,'').to_sym
        if args.length==1 && !@_.respond_to?(name) && !@_.respond_to?(getter_from_setter)
          # we want to imitate immutability; if this attr is already set, raise error
          raise TypeError, "can't modify immutable object" if @extras[getter_from_setter]
          @extras[getter_from_setter] = args[0]
        else
          super
        end
      end
    else
      super
    end
  end
end

if __FILE__==$0
  require 'test/unit'
  class ReturnValueTest < Test::Unit::TestCase

    def some_method_returning_loaded_int
      a = ExtraAttributes.new(5)
      a.debug="info"
      a
    end

    def some_method_returning_loaded_string
      b = ExtraAttributes.new("five")
      b.debug="info"
      b.numericalstring = "69"
      b
    end

    def some_method_returning_loaded_oneliner
      ExtraAttributes.new(200, response: "body", errors: nil)
    end

    def some_method_returning_complex_object_oneliner
      complex_obj = {key: [1,2,3], key2: {key3: [4,5,6]}}
      ExtraAttributes.new(complex_obj, response: 'body', errors: 'none')
    end

    def test_working

      a = some_method_returning_loaded_int

      assert a
      assert_equal a._, 5
      assert_equal 5, a
      assert_equal a._.class, a.class
      assert_respond_to a, :to_f
      assert_equal "info", a.debug
      assert_equal ({debug: "info"}), a.instance_variable_get('@extras')
      assert_equal 15, a + 10
      assert_equal 15, 10 + a # tests commutativity/coerce
      assert_equal -5, -a
      assert_raise NameError do a._ = 6 end
      assert_equal 5, a

      a.something_else = 10
      assert_raise TypeError do a.something_else = 15 end

      a = some_method_returning_loaded_string

      assert a
      assert_equal "five", a
      assert_equal "five", a._
      assert_equal String, a.class
      assert_equal "info", a.debug
      assert_equal "fivesix", a + "six"
      assert_equal "sixfive", "six" + a
      assert_equal "f", a[0]
      assert_equal "f", a._[0]
      assert_equal "fave", a.gsub("i","a")
      assert_raise RuntimeError do a.gsub!("i","a") end
      assert_respond_to a, :_
      assert_equal "five", a._
      assert_equal "info", a.debug

      assert_raise NameError do a._ = "69" end
      assert_equal 69, a.numericalstring.to_i
      assert_equal 69.0, a.numericalstring.to_f
      # try to accidentally overwrite methods on the delegated object
      assert_raise RuntimeError do a.encoding = "UTF-8" end
      assert_equal "".encoding, a.encoding

      a = some_method_returning_loaded_oneliner

      assert a
      assert_equal 200, a
      assert_equal "body", a.response
      assert_equal nil, a.errors

      a = some_method_returning_complex_object_oneliner
      assert a
      assert_equal({key: [1,2,3], key2: {key3: [4,5,6]}}, a)
      assert_equal 'body', a.response


    end
  end

end