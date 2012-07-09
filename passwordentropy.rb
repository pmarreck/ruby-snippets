class Array
  def sum
    self.inject(:+)
  end
end

class Point
  def initialize(*a)
    array = a.flatten
    raise "Too many numbers" if array.length > 2
    @array = []
    self.x = array[0]
    self.y = array[1]
  end
  def to_a
    @array
  end

  def x; @array[0]; end
  def y; @array[1]; end
  def x=(v); @array[0]=v; end
  def y=(v); @array[1]=v; end

  def [](i)
    case i
    when 0
      self.x
    when 1
      self.y
    else
      nil
    end
  end
  def []=(i,v)
    case i
    when 0
      self.x = v
    when 1
      self.y = v
    else
      raise IndexError
    end
  end
  def distance(other)
    o = other.is_a?(Point) ? other : Point.new(other)
    Math.hypot(o.x-self.x, o.y-self.y)
  end
end

module PasswordEvaluator
  # Note: This way to pull in an english dictionary ONLY works on *nix/OS X machines!
  Dictionary = ["leet","haxor"] #+ (File.readlines("/usr/share/dict/words") + File.readlines("/usr/share/dict/web2a")).map {|w| w.downcase.chomp }
  Hexlower = ("a".."f").to_a
  Hexupper = ("A".."F").to_a
  Lowercase = ("g".."z").to_a
  Uppercase = ("G".."Z").to_a
  Numbers = ("0".."9").to_a
  CompoundWordSeparators = [" ","-"]
  CommonPunctuation = ["_",".","@"]
  OtherPunctuation = %w[` ~ ! # $ % ^ & * ( ) = + \[ \] \\ { } | : ; " ' < > , / ? ]
  WordCharacters = Hexlower + Lowercase + CompoundWordSeparators

  def entropy(pass)
    pwlength = pass.size.to_f
    unleeted_pass = pass.dup
    [["0","O"],["3","E"],["4","A"],["5","S"],["6","G"],["7","T"]].each do |leet|
      unleeted_pass.gsub! leet[0], leet[1]
    end
    unleeted_pass1 = unleeted_pass.gsub("1","L").downcase # two variations
    unleeted_pass2 = unleeted_pass.gsub("1","I").downcase
    pw = pass.split('')
    unleeted_pw1 = unleeted_pass1.split('')
    unleeted_pw2 = unleeted_pass2.split('')
    # Skip expensive dictionary check if password contains unusual characters
    if (unleeted_pw1 - WordCharacters).size == 0 # it might be a dictionary word
      # if your dictionary has plurals then some of the following "chomp" logic may be superfluous
      return [0.0, "Common word!"] if Dictionary.include?(pass.downcase) or Dictionary.include?(pass.downcase.chomp("s"))
      return [1.0, "Simple number substitution of letters of a common word!"] if Dictionary.include?(unleeted_pass1) or Dictionary.include?(unleeted_pass2) or Dictionary.include?(unleeted_pass1.chomp("s")) or Dictionary.include?(unleeted_pass2.chomp("s"))
    end
    symbol_set = []
    [Hexlower, Lowercase, Hexupper, Uppercase, Numbers, CompoundWordSeparators, CommonPunctuation, OtherPunctuation].each do |set|
      symbol_set += set if (set & pw).size > 0
    end
    freq = {}
    symbol_set_length = symbol_set.size.to_f
    symbol_set.each {|s| freq[s] = 1.0/symbol_set_length } # Is this the correct initialization? Zero leads to a crash. See below comment
    pw.each {|c| freq[c] += 1.0 }
    sum = p = 0.0
    freq.each {|k,v| p=v/pwlength; sum -= p * Math.log(p); }
    [pwlength * sum, "OK"]
  end

  def valid(pass, minimum)
    e = entropy(pass)
    return [e[0] > minimum, e[0], e[1]]
  end

  def shannon_entropy(pass = self) # http://www.bearcave.com/misl/misl_tech/wavelets/compression/shannon.html
    # Calculates the Shannon entropy of a string
    len = pass.length
    prob = pass.split('').map{|c| pass.count(c).to_f / len }
    -prob.map{|p| p * Math.log(p) / Math.log(2.0) }.sum
  end

  def entropy_ideal(len)
    # Calculates the ideal Shannon entropy of a string with given length
    prob = 1.0 / len
    -1.0 * len * prob * Math.log(prob) / Math.log(2.0)
  end

  def regex_similar(pass = self)
    # Matches any password with a levenshtein distance of 1... in theory
    regex_array = []
    regex_string = ''
    pass_array = pass.split('')
    # start insertion matches
    regex_array << ".#{pass}"
    pass_array.length.times do |i|
      temp_c = pass_array[i]
      # add substitution or deletion matches
      pass_array[i] = "[^#{temp_c}]?"
      regex_array << pass_array.join
      # and insertion matches
      pass_array[i] = "#{temp_c}."
      regex_array << pass_array.join
      pass_array[i] = temp_c
    end
    Regexp.new('^' << regex_array.join('|') << '$')
  end

  QWERTY = [
    '`1234567890-=',
    'qwertyuiop[]\\',
    "asdfghjkl;'",
    'zxcvbnm,./'
  ]
  QWERTY_SHIFT = [
    '`~!@#$%^&*()_+',
    'QWERTYUIOP{}|',
    "ASDFGHJKL:\"",
    'ZXCVBNM<>?'
  ]
  ALPHABET = ["abcdefghijklmnopqrstuvwxyz"]

  def keyboard_coordinate(char = self[0,1], keyboards = [QWERTY, QWERTY_SHIFT])
    row = column = nil
    r = c = 0
    keyboards.each do |keyboard|
      r = 0
      keyboard.each do |row_chars|
#  puts "I am on row #{r} with row_chars #{row_chars} and char #{char}"
        c = (row_chars =~ /#{char}/)
        if c
#  puts "Found #{char} at row #{r}, column #{c}"
          row = r
          column = c
          break
        end
        r += 1
      end
      break if row && column
    end
    if row && column
      Point.new(column, row)
    else
      nil
    end
  end

  def keyboard_travel_distance(pass = self, keyboards = [QWERTY, QWERTY_SHIFT])
    total_dist = pass.split('').inject([pass[0,1],0]) do |last_char_and_dist, c|
      last_coord = keyboard_coordinate(last_char_and_dist[0], keyboards)
      if last_coord
        [c, last_char_and_dist[1] + last_coord.distance(keyboard_coordinate(c, keyboards))]
      else
        last_char_and_dist
      end
    end[1]
  end

  # this should be a high number.
  def keyboard_travel_distance_factor(pass = self, keyboards = [QWERTY, QWERTY_SHIFT])
    if pass.length > 1
      total_dist = keyboard_travel_distance(pass, keyboards)
      total_dist / (pass.length-1)
    else
      1.0
    end
  end

  def dameraulevenshtein(seq1, seq2 = self)
    oneago = nil
    thisrow = (1..seq2.size).to_a + [0]
    seq1.size.times do |x|
      twoago, oneago, thisrow = oneago, thisrow, [0] * seq2.size + [x + 1]
      seq2.size.times do |y|
        delcost = oneago[y] + 1
        addcost = thisrow[y - 1] + 1
        subcost = oneago[y - 1] + ((seq1[x] != seq2[y]) ? 1 : 0)
        thisrow[y] = [delcost, addcost, subcost].min
        if (x > 0 and y > 0 and seq1[x] == seq2[y-1] and seq1[x-1] == seq2[y] and seq1[x] != seq2[y])
          thisrow[y] = [thisrow[y], twoago[y-2] + 1].min
        end
      end
    end
    return thisrow[seq2.size - 1]
  end


  # An attempt to figure out how complex a password is based on things like: key closeness in QUERTY, etc.
  def kolmogorov_complexity_estimation

  end
end

include PasswordEvaluator

# test code
# ["bb","bd","b ","p4ssw0rds","peter","5n3ak3r","    ","l0ser","h1bern4te","Abracadabra","abraCadabra1%","aaaaaaaaBBBBBBBB","abcdefghABCDEFGH","1234567898765432","1337","h4x0r","fA&b@wbP*_a!bYTa",'!@#$%^&}12345qwTYUIsdf^&876',"f29a2e4c1cbf98da0dcb7bd7e502776670d58286"].each do |pass|
#   puts "'#{pass}' => #{valid(pass,20).inspect} with shannon entropy ratio of #{shannon_entropy(pass)/entropy_ideal(pass.length)}"
# end

# puts regex_similar('petermarreck').inspect

# puts regex_similar('petermarreck').match 'peter.marreck'

puts keyboard_travel_distance_factor('password')
puts keyboard_travel_distance_factor('wxyz',[ALPHABET])


# That look about right? The results look meaningful but I'm not 100% sure about the initialization, I based it on the probability that each character would appear in a random string of the expected total character set, because it crashes with zero... do you have any ideas?