require_relative 'embedded_unit_tests'

# Two ideas here:
# 1) All classes know how to test themselves
# 2) All classes have a matching Shim class, so Object has ObjectShim
#    - If it is not defined, it's dynamically defined as a pass-through
# 3) Purpose of the Shim class is to encapsulate the API between its object and any outside objects
# 4) Shim classes will return a mock based on whether their shimmed class is loaded or not
# 5) The mock that the shim returns can be based on the binding of the passed-in block (interesting?)
#    such as its class and method, or default to something, via block.binding.eval("[self.class, __method__]")
# 5) Shim classes pass the call through to the shimmed class if it's loaded


class TweetType
  class << self
    def new(*args, &block)
      puts "initialized a new TweetType"
      super(*args, &block)
    end
  end
  def operation
    {a: 'expensive'}
  end
end

class TweetMock
  class << self
    def new(*args, &block)
      puts "initialized a new TweetMock"
      super(*args, &block)
    end
  end
  def operation
    {a: 'fixture'}
  end
end

class OtherClass
  def TweetType(*args, &block)
    o = args.first
    klass ||= begin
      if ENV['unit'] || !Module.const_defined?(:TweetType)
        puts "Returning a mocked TweetType instead of the original."
        TweetMock
      else
        TweetType
      end
    end
    o ||= klass
    if Symbol===o
      if block_given?
        klass.send(*args, &block)
      else
        klass.send(*args)
      end
    else
      if block.arity > 0
        yield o
      else
        o.instance_eval &block
      end
    end
  end

  def op
    g = TweetType{ new }
    puts out = g.operation
    out
  end

  unit :op do
    assert_equal 'fixture', OtherClass.new.op[:a]
  end

end

if __FILE__==$PROGRAM_NAME
  ENV['unit'] = 'true'
  OtherClass.test
end