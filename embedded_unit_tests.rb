class Module
  # def subclasses
  #   classes = []
  #   ObjectSpace.each_object do |klass|
  #     next unless Module === klass
  #     classes << klass if self > klass
  #   end
  #   classes
  # end
  def unit(*args, &block)
    @_tests ||= {}
    @_tests[args.first] = block
  end
  def defn(*args, &inner_block)
    meth = args.shift
    define_method(meth) do |*args|
      # either run the original code, or the mock
      # maybe track the caller.length and use mocks if it has increased, otherwise the original?
      # what context do we store caller.length in? a global one?
      # computing caller on every method dispatch could get expensive, but if it's only computed in a test context it might not matter much
      inner_block.call(*args)
      # ???
    end
  end
  def mock(*args, &block)
    self.const_set(:Mocks, Class.new) unless defined?(Mocks)
    meth = args.shift
    hash = args.shift
    Mocks.class_eval do
      define_method(meth) do |*args|
        val = hash[args]
        val ||= hash[args.first] if args.length == 1
        if val
          val
        else
          raise StandardError.new("Method #{meth}'s mock does not have an output defined for input #{args.inspect}")
        end
      end
    end
  end

  def test
    @_tests.each do |m, t|
      puts
      puts "Running tests for #{self}##{m}"
      EmbeddedUnitTests::RESULTS[:start_time] ||= Time.now
      Runner.new.instance_eval &t
    end
  end
end

module EmbeddedUnitTests
  AssertionError = Class.new(RuntimeError)
  RESULTS = {}
  at_exit do
    if [RESULTS[:failures], RESULTS[:errors]].all?{|r| r.nil? || r.zero?}
      puts; puts "Passed!"
    # else
    #   RESULTS[:failures].each{ |e| puts e } if RESULTS[:failures]
    #   RESULTS[:errors].each{ |e| puts e } if RESULTS[:errors]
    end
    tot_t = Time.now - RESULTS[:start_time] rescue 1
    puts
    puts "Finished tests in #{tot_t}s, #{RESULTS[:asserts].to_f/tot_t} assertions/s."
    puts
    puts "#{RESULTS[:asserts] || 0} assertions, #{RESULTS[:successes] || 0} successes, #{RESULTS[:failures] || 0} failures, #{RESULTS[:errors] || 0} errors"
  end
  def success; RESULTS[:successes]||=0; RESULTS[:successes]+=1; print '.'; true; end
  def failure; RESULTS[:failures]||=0; RESULTS[:failures]+=1; print 'F'; false; end
  def _ainc; RESULTS[:asserts]||=0; RESULTS[:asserts]+=1; end
  def assert(*args); _ainc; args.first ? success :                 failure || raise(AssertionError.new(args[1] || "#{args[0].inspect} is not true")); end
  def assert_equal(*args); _ainc; args[0]==args[1] ? success :     failure || raise(AssertionError.new(args[2] || "#{args[0].inspect} expected; got #{args[1]}")); end
  def assert_not_equal(*args); _ainc; args[0]!=args[1] ? success : failure || raise(AssertionError.new(args[2] || "#{args[0].inspect} not expected; got it")); end
  def assert_nil(*args); _ainc; args.first.nil? ? success :        failure || raise(AssertionError.new(args[1] || "#{args[0].inspect} expected to be nil")); end
  def assert_not_nil(*args); _ainc; !args.first.nil? ? success :   failure || raise(AssertionError.new(args[1] || "#{args[0].inspect} expected to not be nil")); end
  def assert_raise(klass = Exception, *args, &block); _ainc; (begin; block.call; false; rescue klass; true; end) ? success : failure || raise(AssertionError.new(args[0] || "Expected to raise #{klass}")); end
  alias assert_raised assert_raise
  def assert_no_raise(klass = Exception, *args, &block); _ainc; (begin; block.call; true; rescue klass; false; end) ? success : failure || raise(AssertionError.new(args[0] || "Expected to not raise #{klass}")); end
  alias assert_not_raised assert_no_raise
  alias assert_nothing_raised assert_no_raise

  unit :assert do
    require 'stringio'
    orig_successes = RESULTS[:successes] || 0
    orig_failures =  RESULTS[:failures]  || 0
    assert(begin
      orig_stdout, $stdout = $stdout, StringIO.new
      assert false
      false
    rescue AssertionError
      true
    ensure
      $stdout = orig_stdout
    end)
    assert(begin
      assert true
      true
    rescue AssertionError
      false
    end)
    assert_equal 3, RESULTS[:successes] - orig_successes
    assert_equal 1, RESULTS[:failures]  - orig_failures
    RESULTS[:failures] -= 1
    RESULTS[:asserts] -= 1
  end

end

class Runner
  include EmbeddedUnitTests
end

require "ostruct"
class Object
  def stub(*h)
    OpenStruct.new(*h)
  end
end

########## inline tests
EmbeddedUnitTests.test if __FILE__==$PROGRAM_NAME
