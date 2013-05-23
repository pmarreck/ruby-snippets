# Autovivification

# deep = Hash.new { |hash, key| hash[key] = Hash.new(&hash.default_proc) }

class Deephash < Hash
  def initialize
    super { |hash, key| hash[key] = self.class.new(&hash.default_proc) }
  end
end

if __FILE__==$PROGRAM_NAME
  require 'test/unit'
  class TestDeephash < Test::Unit::TestCase
    def test_assignment
      dh = Deephash.new
      dh[:a][:b][:c] = 5
      assert_equal 5, dh[:a][:b][:c]
    end
  end
end
