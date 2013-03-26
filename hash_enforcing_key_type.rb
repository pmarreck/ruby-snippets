class HashEnforcingKeyType < Hash
  BadKeyClassError = Class.new(StandardError)
  def initialize(*args)
    raise BadKeyClassError, "bad key class: #{args.last}" unless args.last.is_a?(Class)
    @type = args.last
    super(*(args[0..-1]))
  end
  def self.[](*args)
    a = args.flatten
    # note: dependency on expected class being embedded in name of subclasses
    expected_class = const_get(self.to_s.match(/HashEnforcing([A-Z][a-z]+)Keys/)[1])
    raise BadKeyClassError, "bad key class: #{a.first} is a #{a.first.class} and not a #{expected_class}" unless a.first.is_a?(expected_class)
    super
  end
  def [](k, klass = @type)
    if k.is_a?(klass)
      super(k)
    else
      raise BadKeyClassError, "key must be a #{klass}"
    end
  end
  def []=(k, v, klass = @type)
    if k.is_a?(klass)
      super(k, v)
    else
      raise BadKeyClassError, "key must be a #{klass}"
    end
  end
  def merge(*args)
    o = args.first
    o.keys.each{|k| raise(BadKeyClassError, "key '#{k}' must be a #{@type}") unless k.is_a?(@type)}
    super
  end
  alias merge! merge
end


class HashEnforcingSymbolKeys < HashEnforcingKeyType
  def initialize(*args)
    super(*(args << Symbol))
  end
  def [](k)
    super(k, Symbol)
  end
  def []=(k,v)
    super(k, v, Symbol)
  end
end

class HashEnforcingStringKeys < HashEnforcingKeyType
  def initialize(*args)
    super(*(args << String))
  end
  def [](k)
    super(k, String)
  end
  def []=(k, v)
    super(k ,v, String)
  end
end

########## inline tests
if __FILE__==$PROGRAM_NAME
  require 'test/unit'
  class HashEnforcingKeyTypeTest < Test::Unit::TestCase
    def setup
      @h_with_sym = HashEnforcingSymbolKeys.new
      @h_with_str = HashEnforcingStringKeys.new
      @h_with_ary = HashEnforcingKeyType.new(Array)
    end
    def test_symbol_enforcement_getter
      assert_nothing_raised{ @h_with_sym[:a] }
    end
    def test_symbol_enforcement_setter
      assert_nothing_raised{ @h_with_sym[:a] = 5 }
    end
    def test_symbol_enforcement_getter_raises
      assert_raise(HashEnforcingKeyType::BadKeyClassError){ @h_with_sym['a'] }
    end
    def test_symbol_enforcement_setter_raises
      assert_raise(HashEnforcingKeyType::BadKeyClassError){ @h_with_sym['a'] = 5 }
    end
    def test_string_enforcement_getter
      assert_nothing_raised{ @h_with_str['a'] }
    end
    def test_string_enforcement_setter
      assert_nothing_raised{ @h_with_str['a'] = 5 }
    end
    def test_string_enforcement_getter_raises
      assert_raise(HashEnforcingKeyType::BadKeyClassError){ @h_with_str[:a] }
    end
    def test_string_enforcement_setter_raises
      assert_raise(HashEnforcingKeyType::BadKeyClassError){ @h_with_str[:a] = 5 }
    end
    def test_array_enforcement_getter
      assert_nothing_raised{ @h_with_ary[[1]] }
    end
    def test_array_enforcement_setter
      assert_nothing_raised{ @h_with_ary[[1]] = 5 }
    end
    def test_array_enforcement_getter_raises
      assert_raise(HashEnforcingKeyType::BadKeyClassError){ @h_with_ary[:a] }
    end
    def test_array_enforcement_setter_raises
      assert_raise(HashEnforcingKeyType::BadKeyClassError){ @h_with_ary[:a] = 5 }
    end
    def test_symbol_enforcement_merging_symbol_keyed_hash
      assert_nothing_raised{ @h_with_sym.merge(a: 5) }
    end
    def test_symbol_enforcement_raises_merging_nonsymbol_keyed_hash
      assert_raise(HashEnforcingKeyType::BadKeyClassError){ @h_with_sym.merge('a'=>5) }
    end
    def test_symbol_enforcement_raises_merging_mutable_nonsymbol_keyed_hash
      assert_raise(HashEnforcingKeyType::BadKeyClassError){ @h_with_sym.merge!('a'=>5) }
    end
    def test_symbol_enforcement_using_direct_initialization
      assert_nothing_raised{ HashEnforcingSymbolKeys[:a, 5]}
    end
    def test_symbol_enforcement_raises_using_direct_initialization
      assert_raise(HashEnforcingKeyType::BadKeyClassError){ HashEnforcingSymbolKeys['a', 5]}
    end
  end
end
