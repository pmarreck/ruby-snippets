class Duh
  def self.int32(n) # :nodoc:
    n -= 4_294_967_296 while (n >= 2_147_483_648)
    n += 4_294_967_296 while (n <= -2_147_483_648)
    n.to_i
  end
end
class Ah
  def self.int32(n)
    # ((n+2**31) % 2**32) - 2**31
    ((n+2_147_483_648) % 4_294_967_296) - 2_147_483_648
  end
end

if __FILE__==$0
  require 'test/unit'
  class ReturnValueTest < Test::Unit::TestCase

    def test_equalities
      inputs = [9999999999, -1000]
      inputs.each do |i|
        assert_equal Duh.int32(i), Ah.int32(i), "input was #{i}"
      end
    end
  end
end
