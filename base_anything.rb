class BaseN

  SYMBOLS = {
    base58: "123456789abcdefghijkmnopqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ",
    btc_base58: "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz",
    base64: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/",
    binary: "01",
    base_typable: '0123456789`-=~!@#$%^&*()_+qwertyuiop[]QWERTYUIOP{}|asdfghjkl;ASDFGHJKL:zxcvbnm,./ZXCVBNM<>? ',
    base_alphabet: ('a'..'z').to_a.join
  }
  BASES = Hash[SYMBOLS.map{|b,c| [b,c.length]}]

  # Ensures a custom character set has unique values.
  class << self
    def ensure_uniques(charset)
      if charset.length != charset.split(//).uniq.length
        raise "Character set has duplicate characters"
      end
    end
    private :ensure_uniques
  end

  # Converts a base58 string to a base10 integer.
  def self.base_to_int(base, base_val)
    if SYMBOLS[base]
      base_len = BASES[base]
      base = SYMBOLS[base]
    else
      ensure_uniques(base)
      base_len = base.length
    end
    int_val = 0
    base_val.reverse.split(//).each_with_index do |char,index|
      raise ArgumentError, 'Value passed not in specified character set' if (char_index = base.index(char)).nil?
      int_val += (char_index)*(base_len**(index))
    end
    int_val
  end

  # Converts a base10 integer to a baseN string.
  def self.int_to_base(base, int_val)
    if SYMBOLS[base]
      base_len = BASES[base]
      base = SYMBOLS[base]
    else
      ensure_uniques(base)
      base_len = base.length
    end
    raise ArgumentError, 'Value passed is not an Integer.' unless int_val.is_a?(Integer)
    base_val = ''
    while(int_val >= base_len)
      mod = int_val % base_len
      base_val = base[mod,1] + base_val
      int_val = (int_val - mod)/base_len
    end
    base[int_val,1] + base_val
  end

  class << self
    alias_method :encode, :int_to_base
    alias_method :decode, :base_to_int
  end

end

########## inline tests
if __FILE__==$PROGRAM_NAME
  require 'test/unit'
  require 'timeout'
  class BaseNTest < Test::Unit::TestCase
    def crazy_int
      247632993600860153780286963614333301547382186116
    end
    def test_base64_encoding
      assert_equal "CtgP1qjNu7K9OoAneqjR9q6haCE", BaseN.encode(:base64, crazy_int)
    end
    def test_base64_encoding_and_decoding
      assert_equal crazy_int, BaseN.decode(:base64, BaseN.encode(:base64, crazy_int))
    end
    def test_custom_binary_charset_encoding
      as_binary = BaseN.encode("01", crazy_int)
      assert_equal "10101101100000001111110101101010100011001101101110111011001010111101001110101000000000100111011110101010100011010001111101101010111010100001011010000010000100", as_binary
      assert_equal crazy_int.to_s(2), as_binary
      assert_equal as_binary, BaseN.encode(:binary, crazy_int)
    end
    def test_base_typable
      assert_equal "1n}!Xd~Fvr68TX~G>sT0%(+]E", BaseN.encode(:base_typable, crazy_int)
    end
    def test_character_set_with_dupes
      assert_raise(RuntimeError){ BaseN.encode('aa', 1) }
    end
    def test_unary_encoding_works_and_doesnt_hang
      # this currently fails. pending...
      assert_nothing_raised do
        Timeout::timeout(1) { assert_equal '11111', BaseN.encode('1', 5) }
      end
    end
  end
end

# everything is just a number...
p BaseN.decode(:base_typable, 'Include a few obvious configs that need to be exposed, will add more once we receive reqs from the agent team')