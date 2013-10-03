# Based on ideas in http://en.wikipedia.org/wiki/Consistent_hashing

require 'digest'

class ConsistentHash

  DEFAULT_REPLICAS = 80

  DEFAULT_HASHER = ->(o){ Digest::MD5.hexdigest(o).to_i(16) }

  DEFAULT_SERIALIZER = ->(o){ o.respond_to?(:as_json) ? o.as_json : Marshal.dump(o) }

  attr_accessor :pool, :circle, :replicas

  def initialize(pool = [], opts = {})
    @circle = {}
    @pool = []
    @replicas   = opts[:replicas]      || DEFAULT_REPLICAS
    @hasher     = opts[:hash_function] || DEFAULT_HASHER
    @serializer = opts[:serializer]    || DEFAULT_SERIALIZER
    pool.each do |slot|
      add(slot, false)
    end
    sort
  end

  def remove(slot)
    @pool.delete_if{ |e| e == slot }
    @circle.delete_if{ |k,v| v == slot }
  end

  def add(slot, sorted = true)
    @pool << slot
    self.replicas.times do |i|
      @circle[get_hash(serialize(slot)+i.to_s)] = slot
    end
    sort if sorted
  end

  def fetch(element)
    h = get_hash(element)
    @circle.find(->{ @circle.first }){ |k,v| k > h }[1]
  end

  private

  def sort
    @circle = Hash[@circle.sort]
  end

  def serialize(o)
    @serializer.(o)
  end

  def get_hash(o)
    @hasher.(serialize(o))
  end

end

# note: this test will currently fail sometimes, depending on the # of replicas you select

if __FILE__==$PROGRAM_NAME
  require 'test/unit'
  class TestConsistentHash < Test::Unit::TestCase
    def distribution(ary)
      counts = Hash.new(0)
      ary.each do |k|
        counts[k] += 1
      end
      counts
    end
    def setup
      @elements = ['A', Object, {e: 'f'}, 55, 23, 'peter', 'weeblos', Fixnum, {d: 'e'}, 'b', 'c', 'd', 'e', 'f', 'g', 'hh', 'ab', 'bc', 'cd', 'wtf', :something, 'arbitrary']
      @pool = %w[ A B C D ]
      @ch = ConsistentHash.new(@pool)
    end
    def test_consistency_after_add
      mapped = @elements.map{|e| @ch.fetch(e) }
      @ch.add('E')
      new_mapped = @elements.map{|e| @ch.fetch(e) }
      assert new_mapped.any?{|e| e == 'E' }, "The new slot 'E' is missing from the results"
      @ch.pool.each do |slot|
        assert new_mapped.any?{|e| e == slot}, "Slot '#{slot}' is missing from the mappings #{new_mapped}. This may be a false positive. The circle distribution looks like: #{distribution(@ch.circle.values)} and the mappings distribution looks like: #{distribution(new_mapped)}"
      end
    end
    def test_consistency_after_remove
      mapped = @elements.map{|e| @ch.fetch(e) }
      @ch.remove('D')
      new_mapped = @elements.map{|e| @ch.fetch(e) }
      assert new_mapped.none?{|e| e == 'D'}, "The removed slot 'D' is appearing in the results"
      @ch.pool.each do |slot|
        assert new_mapped.any?{|e| e == slot}, "Slot '#{slot}' is missing from the mappings #{new_mapped}. This may be a false positive. The circle distribution looks like: #{distribution(@ch.circle.values)} and the mappings distribution looks like: #{distribution(new_mapped)}"
      end
    end
    def test_fetch
      mock_hash = {
        'A0' => 1,
        'B0' => 2,
        'C0' => 3,
        'D0' => 4,
        thing: 1.5,
        last: 4.5
      }
      @ch = ConsistentHash.new(@pool, replicas: 1, hash_function: ->(o){ mock_hash[o] }, serializer: ->(o){ o })
      assert_equal 'B', @ch.fetch(:thing)
      assert_equal 'A', @ch.fetch(:last)
    end
  end
end