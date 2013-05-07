module ResourceConsumptionProfiler
  extend self
  def profile_resource_consumption(params = {})
    require 'benchmark' unless defined?(Benchmark) if params[:benchmark]
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

    gc_free = ObjectSpace.count_objects[:FREE]
    params[:stress] ? GC.stress=true : GC.disable
    start_time = Time.now
    heisenbergs << start_time.object_id
    out = {}
    heisenbergs << out.object_id
    size_extra = {}
    heisenbergs << size_extra.object_id


    if params[:benchmark]
      bmt = Benchmark.measure{ yield }
    else
      yield
    end

    if params[:benchmark]
      heisenbergs << bmt.object_id
      bmiv = bmt.instance_variables
      heisenbergs << bmiv.object_id
      bmiv.each{|iv| heisenbergs << bmt.instance_variable_get(iv).object_id }
    end

    end_time = Time.now
    heisenbergs << end_time.object_id
    params[:stress] ? GC.stress=false : GC.enable
    osco = {}
    heisenbergs << osco.object_id
    free_loss = gc_free - ObjectSpace.count_objects(osco)[:FREE]
    GC.start

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

    osp_symbol = 0
    object_snapshot_post.each do |klass, oids|
      klass_diff = oids - (object_snapshot[klass] || [])
      out[klass] = klass_diff.length
      if params[:output_objects] && out[klass] > 0
        if TrueClass===params[:output_objects] ||
          (Array===params[:output_objects] && params[:output_objects].include?(klass)) ||
          (Class===params[:output_objects] && params[:output_objects] == klass)
          puts "New objects of class #{klass}:"
          klass_diff.each do |oid|
            puts "  #{ObjectSpace._id2ref(oid).inspect}"
          end
        end
      end
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
    size_extra[:free_mem_bytes_consumed] = free_loss
    size_extra[:user_cpu_time] = bmt.utime if params[:benchmark]
    object_snapshot.clear
    object_snapshot_post.clear
    [out, size_extra, end_time - start_time]
  end
end

########## inline tests
if __FILE__==$PROGRAM_NAME
  class Object
    include ResourceConsumptionProfiler
  end

  require 'test/unit'
  class RuntimeProfilingTest < Test::Unit::TestCase

    def test_expected_measurements_for_empty_block
      num_objects, sizes, time = profile_resource_consumption {}
      assert_equal({}, num_objects)
      assert_equal({:free_mem_bytes_consumed=>6}, sizes)
    end

    def test_expected_measurements
      a = []
      num_objects, sizes, time = profile_resource_consumption do
        s = "hi there"
        n = "nope"
        ar = []
        ar << s
        a << ar
        b = "crazy"
        h = {a: 'b'}
        a << h
        t = Time.now
        a << t
        s = :hellotherebaby
        g = b.to_sym # note that this is the only one that counts as "new"
        10.times { "unbelievable" }
      end
      assert_equal({Symbol=>1, String=>3, Array=>1, Time=>1, Hash=>1}, num_objects)
      assert_equal({Symbol=>5, String=>14, Array=>1, Hash=>1, :free_mem_bytes_consumed=>24}, sizes)
      assert time > 0
      assert time < 1
    end

    def test_expected_with_benchmark_empty_block
      num_objects, sizes, time = profile_resource_consumption(benchmark: true) {}
      # Note that benchmarking adds a few extra objects. It is too much of a pain to tease them out at this time.
      assert_equal({String=>1, Float=>6, Benchmark::Tms=>1}, num_objects)
      assert_equal({String=>0, :free_mem_bytes_consumed=>39, :user_cpu_time=>0.0}, sizes)
    end

    # just to demonstrate...
    p profile_resource_consumption { require 'active_support' }
  end
end

