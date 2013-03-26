module Kernel

  def profile_memory
    # First thing to do is track the observer effect so we don't trip on ourselves when measuring.
    # This is trickier than you think- always run the test after ANY code change to make sure
    # you didn't inadvertently create more objects!
    heisenbergs = []
    heisenbergs << heisenbergs.object_id
    object_snapshot = {}
    object_snapshot_post = {}
    heisenbergs << object_snapshot.object_id
    heisenbergs << object_snapshot_post.object_id
    # symbols aren't returned by ObjectSpace#each_object so have to do them manually
    object_snapshot[Symbol] = Symbol.all_symbols.map{|s| s.object_id}
    heisenbergs << object_snapshot[Symbol].object_id
    ObjectSpace.each_object do |o|
      object_snapshot[o.class] ||= begin
        a = []
        heisenbergs << a.object_id
        a
      end
      object_snapshot[o.class] << o.object_id unless (Array===o || Hash===o) && heisenbergs.include?(o.object_id)
    end

    start_time = Time.now
    heisenbergs << start_time.object_id

    yield

    end_time = Time.now
    heisenbergs << end_time.object_id

    object_snapshot_post[Symbol] = (sym_ary = Symbol.all_symbols).map{|s| s.object_id}
    heisenbergs << object_snapshot_post[Symbol].object_id
    heisenbergs << sym_ary.object_id
    ObjectSpace.each_object do |o|
      object_snapshot_post[o.class] ||= begin
        a = []
        heisenbergs << a.object_id
        a
      end
      object_snapshot_post[o.class] << o.object_id unless (Time===o || Array===o || Hash===o) && heisenbergs.include?(o.object_id)
    end

    out = {}
    size_extra = {}
    osp_symbol = 0
    object_snapshot_post.each do |klass, oids|
      klass_diff = oids - (object_snapshot[klass] || [])
      out[klass] = klass_diff.length
      out.select!{|k,v| v > 0}
      if klass_diff.size > 0 && ObjectSpace._id2ref(klass_diff.first).respond_to?(:size)
        size_extra[klass] = klass_diff.map{|oid| ObjectSpace._id2ref(oid)}.inject(0) do |s, o|
          begin
            s + o.size
          rescue IOError # sigh, enumerables respond to .size but IO enumerables raise if closed
            o.closed? ? s : raise
          end
        end
      end
    end
    object_snapshot.clear
    object_snapshot_post.clear
    [out, size_extra, end_time - start_time]
  end
end

########## inline tests
if __FILE__==$PROGRAM_NAME
  require 'test/unit'
  class RuntimeProfilingTest < Test::Unit::TestCase
    def test_expected_measurements
      num_objects, sizes, time = profile_memory do
        [] << "hi there"
        b = "crazy"
        h = {a: 'b'}
        t = Time.now
        s = :hellotherebaby
        g = b.to_sym # note that this is the only one that counts as "new"
        10.times { "unbelievable" }
      end
      assert_equal({Symbol=>1, String=>14, Array=>1, Time=>1, Hash=>1}, num_objects)
      assert_equal({Symbol=>5, String=>139, Array=>1, Hash=>1}, sizes)
      assert time > 0
      assert time < 1
    end
    # just to demonstrate...
    p profile_memory { require 'active_support' }
  end
end

