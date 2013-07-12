module Kernel
  AssertionError = Class.new(RuntimeError)
  def assert_equal(*args)
    if defined?(Test::TRACK)
      Test::TRACK[:asserts] ||= 0
      Test::TRACK[:asserts] += 1
    end
    expected, got = args[0], args[1]
    unless expected==got
      msg = "<#{expected}> expected but was\n<#{got}>."
      msg << ": #{args[2]}" if args[2]
      raise AssertionError, msg
    end
  end
  def assert(bool, txt=nil)
    if defined?(Test::TRACK)
      Test::TRACK[:asserts] ||= 0
      Test::TRACK[:asserts] += 1
    end
    unless bool
      msg = "Expected #{bool} to be true"
      msg << ": #{txt}" if txt
      raise AssertionError, msg
    end
  end
end

module Test
  TRACK = {}
  def self.included(base)
    if TRACK[:tests].nil?
      at_exit do
        puts; puts
        if TRACK[:failures].nil? && TRACK[:errors].nil?
          puts "Passed"
        else
          TRACK[:failures].each{ |e| puts e } if TRACK[:failures]
          TRACK[:errors].each{ |e| puts e } if TRACK[:errors]
        end
        tot_t = Time.now - TRACK[:start_time]
        puts
        puts "Finished tests in #{tot_t}s, #{TRACK[:tests].to_f/tot_t} tests/s, #{TRACK[:asserts].to_f/tot_t} assertions/s."
        puts
        puts "#{TRACK[:tests]} tests, #{TRACK[:asserts]} assertions, #{TRACK[:failures] ? TRACK[:failures].length : 0} failures, #{TRACK[:errors] ? TRACK[:errors].length : 0} errors"
      end
    end
    at_exit do
      TRACK[:tests] ||= 0
      TRACK[:tests] += 1
      t = base.new
      base.instance_methods(false).select{|m| m.to_s =~ /^test_/}.each do |m|
        pass = false
        begin
          pass = t.send m
          print '.' if pass
        rescue AssertionError => e
          pass = false
          TRACK[:failures] ||= []
          TRACK[:failures] << e.message
        rescue => e
          pass = false
          TRACK[:errors] ||= []
          TRACK[:errors] << e.message
        end
        print 'F' unless pass
      end
    end
    at_exit do
      puts; puts "# Running tests:"; puts
      TRACK[:start_time] = Time.now
    end
  end
end