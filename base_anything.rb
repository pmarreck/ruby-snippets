class BaseN

  PGP_EVEN_WORDS = []
  PGP_ODD_WORDS = []
  PGP_WORDS = [PGP_EVEN_WORDS, PGP_ODD_WORDS]
  %w[ aardvark adroitness absurd adviser accrue aftermath acme aggregate
      adrift alkali adult almighty afflict amulet ahead amusement
      aimless antenna Algol applicant allow Apollo alone armistice
      ammo article ancient asteroid apple Atlantic artist atmosphere
      assume autopsy Athens Babylon atlas backwater Aztec barbecue
      baboon belowground backfield bifocals backward bodyguard banjo bookseller
      beaming borderline bedlamp bottomless beehive Bradbury beeswax bravado
      befriend Brazilian Belfast breakaway berserk Burlington billiard businessman
      bison butterfat blackjack Camelot blockade candidate blowtorch cannonball
      bluebird Capricorn bombast caravan bookshelf caretaker brackish celebrate
      breadline cellulose breakup certify brickyard chambermaid briefcase Cherokee
      Burbank Chicago button clergyman buzzard coherence cement combustion
      chairlift commando chatter company checkup component chisel concurrent
      choking confidence chopper conformist Christmas congregate clamshell consensus
      classic consulting classroom corporate cleanup corrosion clockwork councilman
      cobra crossover commence crucifix concert cumbersome cowbell customer
      crackdown Dakota cranky decadence crowfoot December crucial decimal
      crumpled designing crusade detector cubic detergent dashboard determine
      deadbolt dictator deckhand dinosaur dogsled direction dragnet disable
      drainage disbelief dreadful disruptive drifter distortion dropper document
      drumbeat embezzle drunken enchanting Dupont enrollment dwelling enterprise
      eating equation edict equipment egghead escapade eightball Eskimo
      endorse everyday endow examine enlist existence erase exodus
      escape fascinate exceed filament eyeglass finicky eyetooth forever
      facial fortitude fallout frequency flagpole gadgetry flatfoot Galveston
      flytrap getaway fracture glossary framework gossamer freedom graduate
      frighten gravity gazelle guitarist Geiger hamburger glitter Hamilton
      glucose handiwork goggles hazardous goldfish headwaters gremlin hemisphere
      guidance hesitate hamlet hideaway highchair holiness hockey hurricane
      indoors hydraulic indulge impartial inverse impetus involve inception
      island indigo jawbone inertia keyboard infancy kickoff inferno
      kiwi informant klaxon insincere locale insurgent lockup integrate
      merit intention minnow inventive miser Istanbul Mohawk Jamaica
      mural Jupiter music leprosy necklace letterhead Neptune liberty
      newborn maritime nightbird matchmaker Oakland maverick obtuse Medusa
      offload megaton optic microscope orca microwave payday midsummer
      peachy millionaire pheasant miracle physique misnomer playhouse molasses
      Pluto molecule preclude Montana prefer monument preshrunk mosquito
      printer narrative prowler nebula pupil newsletter puppy Norwegian
      python October quadrant Ohio quiver onlooker quota opulent
      ragtime Orlando ratchet outfielder rebirth Pacific reform pandemic
      regain Pandora reindeer paperweight rematch paragon repay paragraph
      retouch paramount revenge passenger reward pedigree rhythm Pegasus
      ribcage penetrate ringbolt perceptive robust performance rocker pharmacy
      ruffled phonetic sailboat photograph sawdust pioneer scallion pocketful
      scenic politeness scorecard positive Scotland potato seabird processor
      select provincial sentence proximate shadow puberty shamrock publisher
      showgirl pyramid skullcap quantity skydive racketeer slingshot rebellion
      slowdown recipe snapline recover snapshot repellent snowcap replica
      snowslide reproduce solo resistor southward responsive soybean retraction
      spaniel retrieval spearhead retrospect spellbind revenue spheroid revival
      spigot revolver spindle sandalwood spyglass sardonic stagehand Saturday
      stagnate savagery stairway scavenger standard sensation stapler sociable
      steamship souvenir sterling specialist stockman speculate stopwatch stethoscope
      stormy stupendous sugar supportive surmount surrender suspense suspicious
      sweatband sympathy swelter tambourine tactics telephone talon therapist
      tapeworm tobacco tempest tolerance tiger tomorrow tissue torpedo
      tonic tradition topmost travesty tracker trombonist transit truncated
      trauma typewriter treadmill ultimate Trojan undaunted trouble underfoot
      tumor unicorn tunnel unify tycoon universe uncut unravel
      unearth upcoming unwind vacancy uproot vagabond upset vertigo
      upshot Virginia vapor visitor village vocalist virus voyager
      Vulcan warranty waffle Waterloo wallet whimsical watchword Wichita
      wayside Wilmington willow Wyoming woodlark yesteryear Zulu Yucatan
    ].each_slice(2) do |evn, odd|
    PGP_EVEN_WORDS << evn
    PGP_ODD_WORDS << odd
  end

  SYMBOLS = {
    base58: "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz".split(''),
    base58_capitals_last: "123456789abcdefghijkmnopqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ".split(''),
    base64: ('A'..'Z').to_a + ('a'..'z').to_a + ('0'..'9').to_a + "+/".split(''),
    binary: ['0', '1'],
    decimal: ('0'..'9').to_a,
    base16: ('0'..'9').to_a + ('a'..'f').to_a,
    alphanumeric: ('0'..'9').to_a + ('a'..'z').to_a,
    alphanumeric_capitals_first: ('0'..'9').to_a + ('A'..'Z').to_a + ('a'..'z').to_a,
    alphanumeric_capitals_last:  ('0'..'9').to_a + ('a'..'z').to_a + ('A'..'Z').to_a,
    base_typable: '0123456789`-=~!@#$%^&*()_+qwertyuiop[]QWERTYUIOP{}|asdfghjkl;ASDFGHJKL:zxcvbnm,./ZXCVBNM<>? '.split(''),
    base_alphabet: ('a'..'z').to_a,
    pgp_words: PGP_WORDS # http://en.wikipedia.org/wiki/PGP_word_list
  }
  BASES = Hash[SYMBOLS.map{|b,c| [b, Array===c[0] ? c[0].length : c.length]}]

  # Ensures a custom character set has unique values.
  class << self
    def ensure_uniques(charset)
      charset = charset.split('') if String===charset
      if charset.length != charset.uniq.length
        raise "Character set has duplicate characters"
      end
    end
    private :ensure_uniques
  end

  # Converts a baseN string to a base10 integer.
  def self.base_to_int(base, base_v)
    base_val = Array===base_v ? base_v : base_v.split('')
    if SYMBOLS[base]
      base_len = BASES[base]
      base = SYMBOLS[base]
    elsif Symbol===base
      raise "Base #{base} is not a known symbol set"
    elsif base.respond_to?(:length)
      if String===base
        base = base.split('')
      end
      rotating_symbol_map = (Array===base[0])
      if rotating_symbol_map
        base.each{|b| ensure_uniques(b)}
        raise "Rotating sets of symbols need to all be the same length" unless base.map(&:length).uniq.length != 1
        base_len = base[0].length
      else
        ensure_uniques(base)
        base_len = base.length
      end
    elsif !base
      # use an implicit character set
      implicit_base = true
      base = base_val.inject({}){|h, c| h[c]=true; h}.keys
      base_len = base.length
    end
    rotating_symbol_map = (Array===base[0])
    base_val = base_v.split(' ') if String===base_v
    base_val = base_val.first.split('') if base_val.length==1
    return_val = if base_len == 1
      base_val.length
    else
      int_val = 0
      i = 0
      this_base = base
      base_val.reverse.each_with_index do |char,index|
        i = rotating_symbol_map ? index+1 : index # due to endianness issues...
        this_base = rotating_symbol_map ? base[i % base.length] : base
        raise ArgumentError, "Value passed, '#{char}', not in specified symbol set '#{this_base}'#{' which is a rotating symbol map' if rotating_symbol_map}" if (char_index = this_base.index(char)).nil?
        int_val += (char_index*(base_len**index))
      end
      int_val
    end
    return (implicit_base ? [base, return_val] : return_val)
  end

  # Converts a base10 integer to a baseN string.
  def self.int_to_base(base, int_val)
    if SYMBOLS[base]
      base_len = BASES[base]
      base = SYMBOLS[base]
    elsif base.respond_to?(:length)
      rotating_symbol_map = (Array===base[0])
      if rotating_symbol_map
        base.each{|b| ensure_uniques(b)}
        raise "Rotating sets of symbols need to all be the same length" unless base.map(&:length).uniq.length != 1
        base_len = base[0].length
      else
        ensure_uniques(base)
        base_len = base.length
      end
    elsif !base
      # use an implicit character set
      implicit_base = true
      base = int_val.split('').inject({}){|h, c| h[c]=true; h}.keys
      base_len = base.length
    end
    raise ArgumentError, "Value passed, '#{int_val}', is not an Integer." unless int_val.is_a?(Integer)
    rotating_symbol_map = (Array===base[0])
    if base_len == 1
      base[0] * int_val
    else
      base_val = ''
      temp_val = ''
      inc = 0
      begin
        mod = int_val % base_len
        temp_val = (rotating_symbol_map ? base[(inc+1) % base.length][mod] : base[mod])
        base_val = (temp_val.length < 2 ? temp_val : "#{temp_val}#{' ' unless base_val==''}") + base_val
        int_val = (int_val < base_len ? 0 : (int_val - mod)/base_len)
        inc += 1
      end until int_val == 0
      base_val
    end
  end

  class << self
    alias_method :encode, :int_to_base
    alias_method :decode, :base_to_int

    def bin_to_hex(s)
      s.unpack('H*').first
    end

    def hex_to_bin(s)
      [s].pack('H*')
    end
  end

end

class String
  def decode(*args)
    BaseN.decode(*args, self)
  end
end

class Integer
  def encode(*args)
    BaseN.encode(*args, self)
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
    def test_btc_public_key_coding_as_pgp_words
      assert_equal "dwelling pioneer artist sociable concert tobacco stockman existence brickyard visitor flytrap bodyguard accrue travesty Scotland equipment Christmas tradition stopwatch savagery dreadful revenue befriend autopsy",
        BaseN.encode(:pgp_words, BaseN.decode(:base58, '18dYPsghuqxs9eGHosa5V45xqoNtZ6Xktw'))
    end
    def test_btc_public_key_decoding_from_pgp_words
      # the first '1' symbol in bitcoin's base58 public key representation is like a leading zero which is why it is dropped and I have to re-add it for the check. This is actually by design.
      assert_equal '18dYPsghuqxs9eGHosa5V45xqoNtZ6Xktw', '1' + BaseN.encode(:base58, BaseN.decode(:pgp_words, "dwelling pioneer artist sociable concert tobacco stockman existence brickyard visitor flytrap bodyguard accrue travesty Scotland equipment Christmas tradition stopwatch savagery dreadful revenue befriend autopsy".split(' ')))
    end
    def test_btc_private_key_coding_as_pgp_words
      assert_equal "intention highchair dinosaur Mohawk unify blockade Montana bison processor suspense paragraph Christmas pedigree egghead sociable watchword Yucatan assume Chicago scenic Cherokee beehive puberty Mohawk vertigo transit mosquito physique amulet dragnet Pegasus surmount Istanbul ancient cellulose hamlet Brazilian",
        BaseN.encode(:pgp_words, BaseN.decode(:base58, '5JgctoCHLHHKytFjJsrLPcVmbSd4UnDg52Xkm8QczD7npqJt6Pd'))
    end
    def test_btc_private_key_decoding_from_pgp_words
      assert_equal '5JgctoCHLHHKytFjJsrLPcVmbSd4UnDg52Xkm8QczD7npqJt6Pd', BaseN.encode(:base58, BaseN.decode(:pgp_words, "intention highchair dinosaur Mohawk unify blockade Montana bison processor suspense paragraph Christmas pedigree egghead sociable watchword Yucatan assume Chicago scenic Cherokee beehive puberty Mohawk vertigo transit mosquito physique amulet dragnet Pegasus surmount Istanbul ancient cellulose hamlet Brazilian".split(' ')))
    end
    def test_unary_encoding_works_and_doesnt_hang
      assert_nothing_raised do
        Timeout::timeout(1) { assert_equal '11111', BaseN.encode('1', 5) }
        Timeout::timeout(1) { assert_equal '11111', BaseN.encode('1', BaseN.decode('1', '11111')) }
      end
    end
    def test_pgp_words
      pgp = "topmost Istanbul Pluto vagabond treadmill Pacific brackish dictator goldfish Medusa afflict bravado chatter revolver Dupont midsummer stopwatch whimsical cowbell bottomless"
      hex = 0xE58294F2E9A227486E8B061B31CC528FD7FA3F19
      assert_equal pgp, BaseN.encode(:pgp_words, hex)
      assert_equal hex, BaseN.decode(:pgp_words, pgp.split(' '))
    end
    def test_circular_implicit_coding
      assert_equal "PeterMarreck", BaseN.encode(*BaseN.decode(nil, ' PeterMarreck')) # the first symbol is interpreted as "0", so it is dropped, just like 01000 == 1000 in base10
    end
    def test_bin_to_hex_to_bin
      assert_equal '5acf456e9a3d', BaseN.bin_to_hex(BaseN.hex_to_bin('5acf456e9a3d'))
    end
    def test_core_monkeypatch_code_through_various_sets
      pgpwords = "raybeam".decode(' raybem').encode(:pgp_words)
      assert_equal "aftermath hamlet graduate", pgpwords
      num = pgpwords.decode(:pgp_words)
      assert_equal 160103, num
      assert_equal "raybeam", num.encode(' raybem')
    end
    def test_unknown_symbol_set
      assert_raise(RuntimeError){ 'a'.decode(:boguswtf) }
    end
    def test_long_hex_as_pgp
      assert_equal 'puppy processor involve corporate backward molasses concert borderline artist tradition snapline processor quiver photograph indulge detector apple travesty skullcap component', '9bb7773916933e180fe4c1b79eb175450ee5bd32'.decode(:base16).encode(:pgp_words)
    end
  end
end