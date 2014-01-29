# encoding: UTF-8
# Know that it is impossible to do this for the general case. Read: Gödel, Escher, Bach...

module ImperfectStringEncodingDetection

  UmlautsMac  = "äöü".encode(Encoding::MacRoman).force_encoding(Encoding::BINARY)
  UmlautsWin  = "äöü".encode(Encoding::Windows_1252).force_encoding(Encoding::BINARY)

  DiacritsMac = "âàéèô".encode(Encoding::MacRoman).force_encoding(Encoding::BINARY)
  DiacritsWin = "âàéèô".encode(Encoding::Windows_1252).force_encoding(Encoding::BINARY)

  GuessableEncodings = [Encoding::Windows_1252, Encoding::ISO8859_15, Encoding::MacRoman]

  def guess_encoding(string = self.dup)
    return string if string.force_encoding(Encoding::UTF_8).valid_encoding?
    string.force_encoding(Encoding::BINARY)

    # check for non-mapped codepoints
    possible_encodings = GuessableEncodings.dup
    possible_encodings.delete(Encoding::ISO8859_15) if string =~ /[\x80-\x9f]/n
    possible_encodings.delete(Encoding::Windows_1252) if string =~ /[\x81\x8D\x8F\x90\x9D]/n
    return string.force_encoding(possible_encodings.first) if possible_encodings.size == 1

    # Check occurrences of äöü
    case string[0,10_000].count(UmlautsMac) <=> string[0,10_000].count(UmlautsWin)
      when -1 then return string.force_encoding(Encoding::Windows_1252)
      when  1 then return string.force_encoding(Encoding::MacRoman)
    end

    # Check occurrences of âàéèô
    case string[0,10_000].count(DiacritsMac) <=> string[0,10_000].count(DiacritsWin)
      when -1 then return string.force_encoding(Encoding::Windows_1252)
      when  1 then return string.force_encoding(Encoding::MacRoman)
    end

    # Bias for Windows_1252
    string.force_encoding(Encoding::Windows_1252)
  end

  def guess_encoding!
    guess_encoding(self)
  end

end

class SafelyEncodedString
  attr_accessor :string
  def initialize(str)
    self.string = str
  end
  def method_missing(meth, *args, &block)
    begin
      result = self.string.send(meth, *args, &block)
      SafelyEncodedString.new(result)
    rescue ArgumentError
      self.string.guess_encoding!
      retry
    end
  end
  def respond_to?(meth)
    self.string.respond_to? meth
  end
end


# the actual monkeypatch
class String
  include ImperfectStringEncodingDetection
  alias_method :force_encoding_without_guessing, :force_encoding
  def force_encoding_with_guessing(*args)
    if String===args.first && args.first =~ /utf\-?8/i
      SafelyEncodedString.new(self.force_encoding_without_guessing(*args))
    else
      self.force_encoding_without_guessing(*args)
    end
  end
  alias_method :force_encoding, :force_encoding_with_guessing
end

########## inline tests
if __FILE__==$PROGRAM_NAME
  require 'test/unit'
  class ImperfectStringEncodingDetectionTest < Test::Unit::TestCase
    def setup
      @umlaut = "- Men\xFC -"
      assert_equal SafelyEncodedString, ''.force_encoding('UTF-8').class
    end
    def test_force_encoding_on_iso_8851_umlaut_and_calling_string_method_doesnt_raise
      assert_nothing_raised(ArgumentError) do
        assert_equal(["m", "e", "n"], @umlaut.force_encoding('UTF-8').upcase.downcase.split('').join.scan(/\w/))
      end
    end
    def test_guessing_encoding_on_iso_8851_umlaut_before_calling_string_method_doesnt_raise
      assert_nothing_raised do
        assert !@umlaut.force_encoding('UTF-8').empty?
      end
    end
    def test_guessing_encoding_first_allows_smooth_conversion_to_utf8
      assert @umlaut.guess_encoding!.encode('UTF-8').valid_encoding?
    end
  end
end
