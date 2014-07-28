# Make to_i on a string return nil if there are no actual valid numbers
# or if it doesn't at least start with a number.

String.class_eval do
  unless instance_methods.include?(:to_i_without_nil)
    alias to_i_without_nil to_i
    def to_i_with_nil(base=10)
      if (r=self.to_i_without_nil(base))==0
        if /^[0-9]+/ =~ self
          r
        else
          nil
        end
      else
        r
      end
    end
    alias to_i to_i_with_nil
  end
end

require 'test/unit'

class StringToIWithNil < Test::Unit::TestCase
  def test_no_numbers
    assert_equal nil, 'abirar'.to_i
  end
  def test_starts_with_numbers
    assert_equal 10, '010abd'.to_i
  end
  def test_ends_with_numbers
    assert_equal nil, 'abc0100'.to_i
  end
end
