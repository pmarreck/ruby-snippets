# A futile attempt to do "math" via the cleverest regex I could come up with.

class String
  def prev
    (ord-1).chr
  end
  def carry!
    # puts "called carry! with #{self}"
    return self unless self =~ /2/
    gsub!(/02/, '10')
    gsub!(/12/, '20')
    gsub!(/^2/, '10')
    # gsub!(/(.?)2/, "#{$1 ? ($1.succ) : '1'}0")
    carry!
  end

  def add_1_binary
    succ!
    carry!
  end
end

if __FILE__==$PROGRAM_NAME
  require 'test/unit'
  class RegexMathTest < Test::Unit::TestCase
    def test_increments
      assert_equal '100', '011'.add_1_binary
      assert_equal '101', '100'.add_1_binary
      assert_equal '110', '101'.add_1_binary
      assert_equal '111', '110'.add_1_binary
      assert_equal '1000', '111'.add_1_binary
    end
  end
end
