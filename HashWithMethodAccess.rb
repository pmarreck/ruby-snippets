# HashWithMethodAccess


# Sort of a failed experiment/learning experience, but...

#                            user     system      total        real
# OpenStruct init        8.120000   0.090000   8.210000 (  8.212957)
# OpenStruct access      0.170000   0.000000   0.170000 (  0.170700)
# Struct init            0.150000   0.000000   0.150000 (  0.151335)
# Struct access          0.060000   0.000000   0.060000 (  0.065066)
# HWMA init              0.870000   0.020000   0.890000 (  0.889556)
# HWMA access            0.780000   0.010000   0.790000 (  0.779100)


module HashUtils
	# recursively makes this nested hash method-accessible,
	# so you can access keys with method calls.
	# Requires the keys to be symbols, FYI
	def to_method_accessible
	  HashWithMethodAccess[self].map_deep do |k,v|
	    [(k.to_sym || k rescue k), (v.class==Hash ? HashWithMethodAccess[v] : v)]
	  end
	end
end

# Allows you to access hash keys via method calls.
# If you pass in an object to .new(), that object
# will be returned for missing keys. If that object
# is a HashWithMethodAccess object it will repeat that
# configuration so you can basically chain arbitrary keys on the fly,
# like a free-form dictionary object.
class HashWithMethodAccess < Hash
  def initialize(*args)
    @_missing_value = args.first
    super
  end
  def method_missing(*args)
    m, val = args
    is_setter = m[-1]=='='
    key = is_setter ? m.to_s.chomp('=').to_sym : m.to_sym
    if is_setter
      self[key] = val
    elsif key?(key)
      self[key]
    else
      # if we were initialized with a value to return on missing keys, add magic
      if @_missing_value
        self[key] = @_missing_value.dup
        if @_missing_value.is_a? HashWithMethodAccess
          self[key].instance_variable_set(:@_missing_value, @_missing_value.dup)
        end
        self[key]
      else
        super
      end
    end
  end
  # So... you have to implement respond_to? if you implement method_missing.
  def respond_to?(m)
    key? m
  end

  def self.[](*args)
    # HashWithMethodAccess requires symbol keys on initialize with hash shortcut
    unsymbolized = super
    unsymbolized.deep_symbolize_keys!
  end
end unless defined? HashWithMethodAccess

########## inline test running
if __FILE__==$PROGRAM_NAME
  require_relative '../../test/unit/lib/desk/hash_utils_test'
end

class HashUtilsTest < Test::Unit::TestCase
  def setup
    @deep_hash = {a: {b: {c: Test::Unit, d: 5}}}
  end

  def test_hash_method_access
    hma = HashWithMethodAccess.new
    hma[:something] = 'what'
    hma.other = 'other'
    assert_equal 'what', hma.something
    assert_equal 'other', hma.other
    assert_equal 'other', hma[:other]
    assert_nil hma['other']
    assert_raise(NoMethodError) {hma.unknown}
    hmad = HashWithMethodAccess.new(HashWithMethodAccess.new)
    hmad.some.arbitrary.deep.path = 'thing'
    assert_equal 'thing', hmad.some.arbitrary.deep.path
  end

  def test_hash_to_method_accessible_via_index
    h = HashWithMethodAccess[{'a' => {'b' => 5}}]
    assert_equal({a: {b: 5}}, h)
    h = h.to_method_accessible
    assert_equal 5, h.a.b
  end

  def test_hash_to_method_accessible
    h = {a: {b: {c: 5}}}
    h = h.to_method_accessible
    assert_equal 5, h.a.b.c
  end
end




