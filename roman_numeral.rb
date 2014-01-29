class String
  def to_arabic_numeral
    if self =~ RomanNumeral::REGEXP
      # The following is some insane magic I won't even touch, but it would work
      # n=s=0;bytes{|c|s+=n-2*n%n=10**(205558%c%7)%9995};s+n
      RomanNumeral.get(self)
    else
      raise "String is not a Roman numeral"
    end
  end
end

def Object.const_missing sym
  unless RomanNumeral::REGEXP === sym.to_s
    super
  else
    # We could also 'cache' it this way, but I didn't want to:
    # const_set(sym, RomanNumeral.get(sym))
    RomanNumeral.get(sym)
  end
end

class RomanNumeral
  CHARS = "IVXLCDM"
  CHAR_ORDER = CHARS.split('')
  CHAR_VALUES = [1, 5, 10, 50, 100, 500, 1000]
  REGEXP = /^[#{CHARS}]+$/io
  ROMAN_MAP = CHAR_ORDER.each_with_object({}).with_index{ |(c,h),i| h[c]=CHAR_VALUES[i] }
  ARABIC_MAP = CHAR_VALUES.reverse_each.with_object({}).with_index{ |(v,h),i| h[v]=CHAR_ORDER[6-i]}
  def self.get(sym)
    last_order_pos=0
    add_mode = 1
    sym.to_s.upcase.split('').reverse.inject(0) do |sum, char|
      order_pos = (CHARS =~ /#{char}/)
      add_mode = 1 if order_pos>last_order_pos && add_mode<0
      add_mode = -1 if order_pos<last_order_pos && add_mode>0
      last_order_pos = order_pos
      sum + (add_mode * ROMAN_MAP[char])
    end
  end
end

class Integer
  def to_roman_numeral
    str = ''
    m = self
    RomanNumeral::ARABIC_MAP.each do |v,c|
      q, m = m.divmod(v)
      str << (c * q)
    end
    str.gsub!(/DCCCC/,'CM')
    str.gsub!(/LXXXX/, 'XC')
    str.gsub!(/VIIII/, 'IX')
    str
  end
end

if __FILE__==$PROGRAM_NAME
  require 'test/unit'
  class RomanNumeralTest < Test::Unit::TestCase
    def test_constant_to_integer_and_back_fucking_magic
      assert_equal 'MCMLXXVII', MCMLXXVII.to_roman_numeral
    end
    def test_not_roman_numeral
      assert_raise(NameError) { MIB }
    end
    def test_integer_to_arabic_numeral_and_back
      assert_equal 1972, 1972.to_roman_numeral.to_arabic_numeral
    end
    def test_zero_not_invented_yet_apparently
      assert_equal '', 0.to_roman_numeral
    end
    def test_420_in_roman
      assert_equal '', 420.to_roman_numeral
    end
  end
end