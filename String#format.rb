class Module
  def subclasses
    classes = []
    ObjectSpace.each_object do |klass|
      next unless Module === klass
      classes << klass if self > klass
    end
    classes
  end
  def unit(*args, &block)
    @_tests ||= {}
    @_tests[args.first] = block
  end
  def test
    @_tests.each{ |m, t| puts; puts "Running tests for #{self}##{m}"; t.call }
  end
end

class String

  def format(*args)
    super(self, *(args.flatten))
  end

  unit :format do
    require 'test/unit'
    class StringFormatTest < Test::Unit::TestCase
      def test_string_format
        assert_equal '2.00', '%.2f'.format(2.00001)
        assert_equal '1.00 3.00', '%.2f %.2f'.format([1.004, 3.0023])
        assert_equal '1.00 3.00', '%.2f %.2f'.format(1.004, 3.0023)
      end
    end
  end
end

########## inline tests
String.test if __FILE__==$PROGRAM_NAME
