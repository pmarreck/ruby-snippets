# Method to deep_freeze Ruby object collections
# Includes recursion protection

module Enumerable
  def deep_freeze!(oids = {})
    return self if oids.key?(self.object_id)
    oids[self.object_id] = true
    unless self.is_a? String
      frozen = self.each do |key, value|
        if (key.is_a?(Enumerable) && !key.is_a?(String))
          key.deep_freeze!(oids)
        else
          key.freeze
        end
        if (value.is_a?(Enumerable) && !value.is_a?(String))
          value.deep_freeze!(oids)
        else
          value.freeze
        end
      end
      self.replace(frozen)
    end
    self.freeze
  end
end

class Hash
  def deep_freeze!(oids = {})
    return self if oids.key?(self.object_id)
    oids[self.object_id] = true
    frozen = self.each do |key, value|
      if (key.is_a?(Enumerable) && !key.is_a?(String))
        key.deep_freeze!(oids)
      else
        key.freeze
      end
      if (value.is_a?(Enumerable) && !value.is_a?(String))
        value.deep_freeze!(oids)
      else
        value.freeze
      end
    end
    self.replace(frozen)
    self.freeze
  end
end

########## inline tests
if __FILE__==$PROGRAM_NAME

  require 'test/unit'
  class DeepFreezeTest < Test::Unit::TestCase

    def test_nested_hash
      h = {a: {b: 'c', c: [1,2,3]}}
      h.deep_freeze!
      assert_raise(RuntimeError){ h[:a] = {} }
      assert_raise(RuntimeError){ h[:a][:b] << 'd' }
      assert_raise(RuntimeError){ h[:a][:c] << 4 }
    end

    def test_nested_array
      a = [1, :a, {b: '5'}]
      a.deep_freeze!
      assert_raise(RuntimeError){ a[0] = 2 }
      assert_raise(RuntimeError){ a[2][:b] << '2' }
    end

    def test_enumerable_keys
      key = {a: 5}
      h = {key => '7'}
      h.deep_freeze!
      assert_raise(RuntimeError){ key[:a] = 2 }
    end

    def test_recursive_structure_protection
      h = {a: 5}
      h[:b] = h
      assert_nothing_raised{ h.deep_freeze! }
    end

  end
end
