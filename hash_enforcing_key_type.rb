class HashEnforcingKeyType < Hash
  BadKeyClassError = Class.new(StandardError)
  KEY_CLASS_EXTRACTOR = /^HashEnforcing([A-Z][A-Za-z]+)Keys$/
  def initialize(*args)
    if args.last.is_a?(Class)
      @type = args.pop
    else
      begin
        expected_classname = self.class.to_s.match(KEY_CLASS_EXTRACTOR)[1]
        @type = self.class.const_get(expected_classname)
      rescue => e
        e.message << "\n(It's possible that '#{expected_classname}' is not actually an available class here.)"
        raise e
      end
    end
    # raise BadKeyClassError, "bad key class: #{args.last}" unless args.last.is_a?(Class)
    super(*args)
  end
  def self.[](*args)
    a = args.flatten
    expected_class = const_get(self.to_s.match(KEY_CLASS_EXTRACTOR)[1])
    a = a.first if Hash===a.first && a.length=1
    valid = case a
      when Array
        a.each_with_index.all?{ |k, i| i.odd? || expected_class===k }
      when Hash
        a.each_pair.all?{ |k, v| expected_class===k }
      end
    raise BadKeyClassError, "bad key class: #{a} contains keys that are not a #{expected_class}" unless valid
    super
  end
  def [](k, klass = @type)
    if klass===k
      super(k)
    else
      raise BadKeyClassError, "requested key '#{k}' must be a #{klass}"
    end
  end
  def []=(k, v, klass = @type)
    if klass===k
      super(k, v)
    else
      raise BadKeyClassError, "key '#{k}' must be a #{klass}"
    end
  end
  alias store []=
  def merge(*args)
    o = args.first
    o.keys.each{|k| raise(BadKeyClassError, "key '#{k}' must be a #{@type}") unless k.is_a?(@type)}
    super
  end
  alias merge! merge
  def to_h
    Hash[self]
  end
end


class HashEnforcingSymbolKeys < HashEnforcingKeyType
end

class HashEnforcingStringKeys < HashEnforcingKeyType
end

class HashEnforcingBogusKeys < HashEnforcingKeyType
end

# i like to get tricky...
class HashEnforcingHashEnforcingSymbolKeysKeys < HashEnforcingKeyType
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
    def test_to_h
      assert_equal Hash, @h_with_sym.to_h.class
    end
    def test_store
      h = HashEnforcingSymbolKeys.new
      h.store(:a, 5)
      assert_equal 5, h[:a]
      assert_raise(HashEnforcingKeyType::BadKeyClassError){ h.store('b', 5) }
    end
    def test_arbitrary_class_enforcement_with_nonexistent_class
      assert_raise(NameError){ HashEnforcingBogusKeys.new }
    end
    def test_arbitrary_class_enforcement
      h = HashEnforcingHashEnforcingSymbolKeysKeys.new
      j = HashEnforcingSymbolKeys.new
      j[:a]=5
      assert_nothing_raised{ h[j]=6 }
    end
  end
end
