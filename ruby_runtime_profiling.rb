class HashList < Hash
  def add(k)
    self[k] = true
  end
  alias include? key?
end

module ResourceConsumptionProfiler
  extend self
  def profile_resource_consumption(params = {})
    require 'benchmark' unless defined?(Benchmark) if params[:benchmark]
    # First thing to do is track the observer effect so we don't trip on ourselves when measuring.
    # This is trickier than you think- always run the test after ANY code change to make sure
    # you didn't inadvertently create more objects!
    heisenbergs = HashList.new
    heisenbergs.add heisenbergs.object_id
    object_snapshot = {}
    object_snapshot_post = {}
    # heisenbergs.add object_snapshot.object_id
    # heisenbergs.add object_snapshot_post.object_id
    # symbols aren't returned by ObjectSpace#each_object so have to do them manually
    object_snapshot[Symbol] = Symbol.all_symbols.map{|s| s.object_id}
    heisenbergs.add object_snapshot[Symbol].object_id
    if params[:active_record]
      require 'active_support/notifications'
      db_operation_counts = {}
      db_times = {}
      db_time = 0.0
      heisenbergs.add db_operation_counts.object_id
      heisenbergs.add db_times.object_id
      heisenbergs.add db_time.object_id
      sql_subscriber_string = 'sql.active_record'
      heisenbergs.add sql_subscriber_string.object_id
      ar_subscriber = ActiveSupport::Notifications.subscribe(sql_subscriber_string) do |*args|
        name, start, finish, id, payload = *args
        duration = finish - start
        sql_command = payload[:sql]
        op = table = nil
        case sql_command
        when /^insert +into +`?([a-z_]+)`?/io
          op = :C
          table = $1
          heisenbergs.add $~.object_id
          heisenbergs.add $1.object_id
        when /^select /i
          op = :R
          heisenbergs.add $~.object_id
          table = sql_command.match(/ from +`?([a-z_]+)`?/io)[1]
          heisenbergs.add $~.object_id
        when /^update +`?([a-z_]+)`?/io
          op = :U
          table = $1
          heisenbergs.add $~.object_id
          heisenbergs.add $1.object_id
        when /^delete /io
          op = :D
          heisenbergs.add $~.object_id
          table = sql_command.match(/ from +`?([a-z_]+)`?/io)[1]
          heisenbergs.add $~.object_id
        end
        if op && table
          k = table.to_sym
          heisenbergs.add k.object_id
          heisenbergs.add table.object_id
          db_operation_counts[k] ||= begin
            h = Hash.new(0)
            heisenbergs.add h.object_id
            h
          end
          db_operation_counts[k][op] += 1
          db_times[table] ||= 0.0
          db_times[table] += duration
          db_time += duration
        elsif op || table
          puts "WARNING: could not extract full sql params for logging from: #{sql_command}"
        end
      end
    end

    ObjectSpace.each_object do |o|
      object_snapshot[o.class] ||= begin
        a = []
        heisenbergs.add a.object_id
        a
      end
      object_snapshot[o.class] << o.object_id unless (Array===o || Hash===o) && heisenbergs.include?(o.object_id)
    end

    osco_pre = {}
    heisenbergs.add osco_pre.object_id
    gc_free = ObjectSpace.count_objects(osco_pre)[:FREE]
    params[:stress] ? GC.stress=true : GC.disable
    start_time = Time.now
    heisenbergs.add start_time.object_id
    out = {}
    heisenbergs.add out.object_id
    size_extra = {}
    heisenbergs.add size_extra.object_id


    if params[:benchmark]
      bmt = Benchmark.measure{ yield }
    else
      yield
    end

    end_time = Time.now
    heisenbergs.add end_time.object_id

    params[:stress] ? GC.stress=false : GC.enable
    osco = {}
    heisenbergs.add osco.object_id
    free_loss = gc_free - ObjectSpace.count_objects(osco)[:FREE]
    GC.start

    object_snapshot_post[Symbol] = (sym_ary = Symbol.all_symbols).map{|s| s.object_id}
    heisenbergs.add object_snapshot_post[Symbol].object_id
    heisenbergs.add sym_ary.object_id
    ObjectSpace.each_object do |o|
      klass = o.class
      heisenbergs.add klass.object_id
      object_snapshot_post[klass] ||= begin
        a = []
        heisenbergs.add a.object_id
        a
      end
      object_snapshot_post[klass] << o.object_id unless (Time===o || Array===o || Hash===o) && heisenbergs.include?(o.object_id)
    end

    if params[:benchmark]
      heisenbergs.add bmt.object_id
      bmiv = bmt.instance_variables
      heisenbergs.add bmiv.object_id
      bmiv.each{|iv| heisenbergs.add bmt.instance_variable_get(iv).object_id }
    end

    if params[:active_record]
      ActiveSupport::Notifications.unsubscribe(ar_subscriber)
    end

    osp_symbol = 0
    first_obj = nil
    object_snapshot_post.each do |klass, oids|
      klass_diff = oids - (object_snapshot[klass] || [])
      out[klass] = klass_diff.length
      if params[:output_objects] && out[klass] > 0
        if TrueClass===params[:output_objects] ||
          (Array===params[:output_objects] && params[:output_objects].include?(klass)) ||
          (Class===params[:output_objects] && params[:output_objects] == klass)
          puts "New objects of class #{klass}:"
          klass_diff.each do |oid|
            begin
              puts "  #{ObjectSpace._id2ref(oid).inspect}"
            rescue RangeError # it's been recycled
            end
          end
        end
      end
      out.select!{|k,v| v > 0}
      first_obj = begin
        klass_diff.first && ObjectSpace._id2ref(klass_diff.first)
      rescue RangeError # it's been recycled
        nil
      end
      if klass_diff.size > 0 && first_obj && first_obj.respond_to?(:size)
        size_extra[klass] = klass_diff.map do |oid|
            begin
              ObjectSpace._id2ref(oid)
            rescue RangeError # it's been recycled
              nil
            end
          end.compact.inject(0) do |s, o|
          begin
            # Sometimes, certain objects of this class still won't respond_to size, weirdly...
            o.respond_to?(:size) ? (s + o.size) : s
          rescue IOError # sigh, enumerables respond to .size but IO enumerables raise if closed
            o.closed? ? s : raise
          end
        end
      end
    end
    object_snapshot.clear
    object_snapshot_post.clear
    out = {new_object_counts: out, object_sizes: size_extra, mem_bytes_consumed: free_loss, wall_time: end_time - start_time}
    out[:user_cpu_time] = bmt.utime if params[:benchmark]
    if params[:active_record]
      out[:db_operation_counts] = db_operation_counts
      out[:db_times] = db_times
      out[:total_db_time] = db_time
    end
    out
  end
  alias wtf profile_resource_consumption
end

########## inline tests
if __FILE__==$PROGRAM_NAME
  class Object
    include ResourceConsumptionProfiler
  end

  require 'test/unit'
  class RuntimeProfilingTest < Test::Unit::TestCase

    def test_expected_measurements_for_empty_block
      out = profile_resource_consumption {}
      assert_equal({}, out[:new_object_counts])
      assert_equal(5, out[:mem_bytes_consumed])
    end

    def test_expected_measurements
      a = []
      out = profile_resource_consumption do
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
      assert_equal({Symbol=>1, String=>3, Array=>1, Time=>1, Hash=>1}, out[:new_object_counts])
      assert_equal({Symbol=>5, String=>14, Array=>1, Hash=>1}, out[:object_sizes])
      assert_equal(23, out[:mem_bytes_consumed])
      assert out[:wall_time] > 0
      assert out[:wall_time] < 1
    end

    def test_expected_with_benchmark_empty_block
      out = profile_resource_consumption(benchmark: true) {}
      # Note that benchmarking adds a few extra objects. It is too much of a pain to tease them out at this time.
      assert_equal({String=>1, Float=>6, Benchmark::Tms=>1}, out[:new_object_counts])
      assert_equal({String=>0}, out[:object_sizes])
      assert_equal(37, out[:mem_bytes_consumed])
      assert_equal(0.0, out[:user_cpu_time])
    end

    # just to demonstrate...
    p profile_resource_consumption { require 'active_support' }
  end
end
