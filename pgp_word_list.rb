class PGPWordList
  PGP_WORDLIST = {}
  PGP_EVEN_WORDS = {}
  PGP_ODD_WORDS = {}
  PGP_WORDS = [PGP_EVEN_WORDS, PGP_ODD_WORDS]
  %w[
    aardvark adroitness
    absurd adviser
    accrue aftermath
    acme aggregate
    adrift alkali
    adult almighty
    afflict amulet
    ahead amusement
    aimless antenna
    Algol applicant
    allow Apollo
    alone armistice
    ammo article
    ancient asteroid
    apple Atlantic
    artist atmosphere
    assume autopsy
    Athens Babylon
    atlas backwater
    Aztec barbecue
    baboon belowground
    backfield bifocals
    backward bodyguard
    banjo bookseller
    beaming borderline
    bedlamp bottomless
    beehive Bradbury
    beeswax bravado
    befriend Brazilian
    Belfast breakaway
    berserk Burlington
    billiard businessman
    bison butterfat
    blackjack Camelot
    blockade candidate
    blowtorch cannonball
    bluebird Capricorn
    bombast caravan
    bookshelf caretaker
    brackish celebrate
    breadline cellulose
    breakup certify
    brickyard chambermaid
    briefcase Cherokee
    Burbank Chicago
    button clergyman
    buzzard coherence
    cement combustion
    chairlift commando
    chatter company
    checkup component
    chisel concurrent
    choking confidence
    chopper conformist
    Christmas congregate
    clamshell consensus
    classic consulting
    classroom corporate
    cleanup corrosion
    clockwork councilman
    cobra crossover
    commence crucifix
    concert cumbersome
    cowbell customer
    crackdown Dakota
    cranky decadence
    crowfoot December
    crucial decimal
    crumpled designing
    crusade detector
    cubic detergent
    dashboard determine
    deadbolt dictator
    deckhand dinosaur
    dogsled direction
    dragnet disable
    drainage disbelief
    dreadful disruptive
    drifter distortion
    dropper document
    drumbeat embezzle
    drunken enchanting
    Dupont enrollment
    dwelling enterprise
    eating equation
    edict equipment
    egghead escapade
    eightball Eskimo
    endorse everyday
    endow examine
    enlist existence
    erase exodus
    escape fascinate
    exceed filament
    eyeglass finicky
    eyetooth forever
    facial fortitude
    fallout frequency
    flagpole gadgetry
    flatfoot Galveston
    flytrap getaway
    fracture glossary
    framework gossamer
    freedom graduate
    frighten gravity
    gazelle guitarist
    Geiger hamburger
    glitter Hamilton
    glucose handiwork
    goggles hazardous
    goldfish headwaters
    gremlin hemisphere
    guidance hesitate
    hamlet hideaway
    highchair holiness
    hockey hurricane
    indoors hydraulic
    indulge impartial
    inverse impetus
    involve inception
    island indigo
    jawbone inertia
    keyboard infancy
    kickoff inferno
    kiwi informant
    klaxon insincere
    locale insurgent
    lockup integrate
    merit intention
    minnow inventive
    miser Istanbul
    Mohawk Jamaica
    mural Jupiter
    music leprosy
    necklace letterhead
    Neptune liberty
    newborn maritime
    nightbird matchmaker
    Oakland maverick
    obtuse Medusa
    offload megaton
    optic microscope
    orca microwave
    payday midsummer
    peachy millionaire
    pheasant miracle
    physique misnomer
    playhouse molasses
    Pluto molecule
    preclude Montana
    prefer monument
    preshrunk mosquito
    printer narrative
    prowler nebula
    pupil newsletter
    puppy Norwegian
    python October
    quadrant Ohio
    quiver onlooker
    quota opulent
    ragtime Orlando
    ratchet outfielder
    rebirth Pacific
    reform pandemic
    regain Pandora
    reindeer paperweight
    rematch paragon
    repay paragraph
    retouch paramount
    revenge passenger
    reward pedigree
    rhythm Pegasus
    ribcage penetrate
    ringbolt perceptive
    robust performance
    rocker pharmacy
    ruffled phonetic
    sailboat photograph
    sawdust pioneer
    scallion pocketful
    scenic politeness
    scorecard positive
    Scotland potato
    seabird processor
    select provincial
    sentence proximate
    shadow puberty
    shamrock publisher
    showgirl pyramid
    skullcap quantity
    skydive racketeer
    slingshot rebellion
    slowdown recipe
    snapline recover
    snapshot repellent
    snowcap replica
    snowslide reproduce
    solo resistor
    southward responsive
    soybean retraction
    spaniel retrieval
    spearhead retrospect
    spellbind revenue
    spheroid revival
    spigot revolver
    spindle sandalwood
    spyglass sardonic
    stagehand Saturday
    stagnate savagery
    stairway scavenger
    standard sensation
    stapler sociable
    steamship souvenir
    sterling specialist
    stockman speculate
    stopwatch stethoscope
    stormy stupendous
    sugar supportive
    surmount surrender
    suspense suspicious
    sweatband sympathy
    swelter tambourine
    tactics telephone
    talon therapist
    tapeworm tobacco
    tempest tolerance
    tiger tomorrow
    tissue torpedo
    tonic tradition
    topmost travesty
    tracker trombonist
    transit truncated
    trauma typewriter
    treadmill ultimate
    Trojan undaunted
    trouble underfoot
    tumor unicorn
    tunnel unify
    tycoon universe
    uncut unravel
    unearth upcoming
    unwind vacancy
    uproot vagabond
    upset vertigo
    upshot Virginia
    vapor visitor
    village vocalist
    virus voyager
    Vulcan warranty
    waffle Waterloo
    wallet whimsical
    watchword Wichita
    wayside Wilmington
    willow Wyoming
    woodlark yesteryear
    Zulu Yucatan
  ].each_slice(2).with_index do |(evn, odd), i|
    hex = i.to_s(16).downcase.rjust(2,'0')
    PGP_WORDLIST[hex] = [evn, odd]
    PGP_EVEN_WORDS[evn.downcase] = hex
    PGP_ODD_WORDS[odd.downcase] = hex
  end

  attr_accessor :input

  def convert_to_pgp_words(hex_string = self.input)
    pairs = hex_string.scan(/[0-9a-f]{2}/i).map(&:downcase)
    pairs.map.with_index{ |hex, i| PGP_WORDLIST[hex][i % 2] }
  end

  def convert_from_pgp_words(pgp_words = self.input)
    words = (Array===pgp_words ? pgp_words : pgp_words.split(/\s+/))
    to_hex = words.map(&:downcase).map.with_index{ |word, i| PGP_WORDS[i % 2][word] }
    if (loc=to_hex.index(nil))
      raise StandardError, "Decoding error: missing a word after '#{words[loc-1]}'"
    end
    to_hex.join
  end

  def initialize(arg)
    @input = arg
  end

  def is_hex?
    @input =~ /\A(?:[0-9a-f]{2})+\Z/i
  end

  def convert
    if is_hex?
      convert_to_pgp_words
    else
      convert_from_pgp_words
    end
  end

  def self.convert(arg)
    new(arg).convert
  end
end

# example from Wikipedia page at http://en.wikipedia.org/wiki/PGP_word_list to prove it works...

# PGPWordList.convert('E58294F2E9A227486E8B061B31CC528FD7FA3F19').each_slice(4) do |words|
#   puts words.join(' ')
# end

# inline test

if __FILE__==$PROGRAM_NAME
  require 'test/unit'
  class TestPHPWordlist < Test::Unit::TestCase
    def test_pgp_wordlist_encoding
      assert_equal 'topmost Istanbul Pluto vagabond', PGPWordList.convert('E58294f2').join(' ')
    end

    def test_pgp_wordlist_decoding
      assert_equal 'e58294f2', PGPWordList.convert('topmost istanbul  pluto Vagabond')
    end

    def test_pgp_wordlist_decoding_omission_error
      assert_raise(StandardError){ PGPWordList.convert('topmost istanbul vagabond') }
    end

    def test_pgp_wordlist_circular_calls
      assert_equal 'abcde12345', PGPWordList.convert(PGPWordList.convert('abcde12345'))
      assert_equal %w[ stopwatch whimsical cowbell bottomless ], PGPWordList.convert(PGPWordList.convert('stopwatch whimsical cowbell bottomless'))
      assert_equal %w[ stopwatch whimsical cowbell bottomless ], PGPWordList.convert(PGPWordList.convert(%w[ stopwatch whimsical cowbell bottomless ]))
    end
  end
end

# PGPWordList.convert("44f4614c7007a737c5bd68a293d8954274b11e8cea25e2e8").each_slice(4) do |words|
#   puts words.join(' ')
# end
p 0x0100
p PGPWordList.convert('0100')