# The point of this class is to create a largely future-proof universal (at least within a system) identifier with the following properties:

# Versionable
# Orderable (ideally)
# Includes enough context
# Deterministic (can extract information from it to retrieve the original record in the event we aren’t yet ready to denormalize this ID in the database)
# Collision-resistant with other systems in the same domain

# In theory, this ID system has pulled those off.

# It is inspired by Twitter's Snowflake code. Differences are that this achieves collision avoidance without requiring running as a service.

class StarId

  attr_reader :datacenter_id, :worker_id, :reporter, :logger, :version
  attr_accessor :sequence, :class_id

  VERSION_ID_BITS = 3
  VERSIONS = {}

  CURRENT_FORMAT_VERSION = 0

  VERSIONS[0] = {
    datacenter_id_bits:    (datacenter_id_bits = 4),
    worker_id_bits:        (worker_id_bits = 5),
    class_id_bits:         (class_id_bits = 8),
    timestamp_bits:        (timestamp_bits = 32),
    sequence_bits:         (sequence_bits = 11),
    version_id_bits:       (version_id_bits = VERSION_ID_BITS), # should probably never change
    max_class_id:          (1 << class_id_bits) - 1,
    max_worker_id:         (1 << worker_id_bits) - 1,
    max_datacenter_id:     (1 << datacenter_id_bits) - 1,
    max_version_id:        (1 << version_id_bits) - 1,
    version_id_shift:      (version_id_shift = 0),
    sequence_shift:        (sequence_shift = (version_id_shift + version_id_bits)),
    timestamp_shift:       (timestamp_shift = (sequence_shift + sequence_bits)),
    class_id_shift:        (class_id_shift = (timestamp_shift + timestamp_bits)),
    worker_id_shift:       (worker_id_shift = (class_id_shift + class_id_bits)),
    datacenter_id_shift:   (datacenter_id_shift = (worker_id_shift + worker_id_bits)),
    version_id_mask:       (((1 << version_id_bits) - 1) << version_id_shift),
    sequence_base_mask:    (sequence_base_mask = (1 << sequence_bits) - 1),
    sequence_mask:         sequence_base_mask << sequence_shift,
    timestamp_mask:        (((1 << timestamp_bits) - 1) << timestamp_shift),
    class_id_mask:         (((1 << class_id_bits) - 1) << class_id_shift),
    worker_id_mask:        (((1 << worker_id_bits) - 1) << worker_id_shift),
    datacenter_id_mask:    (((1 << datacenter_id_bits) - 1) << datacenter_id_shift),
    datacenter_id_default: 0,
    worker_id_default:     0,
    version_id_default:    0
  }.freeze


  DATACENTER_ID_BITS = 4
  WORKER_ID_BITS = 5
  CLASS_ID_BITS = 8
  TIMESTAMP_BITS = 32
  SEQUENCE_BITS = 11


  MAX_CLASS_ID = (1 << CLASS_ID_BITS) - 1
  MAX_WORKER_ID = (1 << WORKER_ID_BITS) - 1
  MAX_DATACENTER_ID = (1 << DATACENTER_ID_BITS) - 1
  MAX_VERSION_ID = (1 << VERSION_ID_BITS) - 1

  VERSION_ID_SHIFT    = 0
  SEQUENCE_SHIFT      = VERSION_ID_SHIFT + VERSION_ID_BITS
  TIMESTAMP_SHIFT     = SEQUENCE_SHIFT   + SEQUENCE_BITS
  CLASS_ID_SHIFT      = TIMESTAMP_SHIFT  + TIMESTAMP_BITS
  WORKER_ID_SHIFT     = CLASS_ID_SHIFT   + CLASS_ID_BITS
  DATACENTER_ID_SHIFT = WORKER_ID_SHIFT  + WORKER_ID_BITS

  VERSION_ID_MASK = ((1 << VERSION_ID_BITS) - 1) << VERSION_ID_SHIFT
  SEQUENCE_BASE_MASK = (1 << SEQUENCE_BITS) - 1
  SEQUENCE_MASK = SEQUENCE_BASE_MASK << SEQUENCE_SHIFT
  TIMESTAMP_MASK = ((1 << TIMESTAMP_BITS) - 1) << TIMESTAMP_SHIFT
  CLASS_ID_MASK = ((1 << CLASS_ID_BITS) - 1) << CLASS_ID_SHIFT
  WORKER_ID_MASK = ((1 << WORKER_ID_BITS) - 1) << WORKER_ID_SHIFT
  DATACENTER_ID_MASK = ((1 << DATACENTER_ID_BITS) - 1) << DATACENTER_ID_SHIFT

  DATACENTER_ID_DEFAULT = 0
  WORKER_ID_DEFAULT = 0
  VERSION_ID_DEFAULT = 0

  def initialize(params = {})
    @datacenter_id = (params[:datacenter_id] || DATACENTER_ID_DEFAULT).to_i
    @worker_id = (params[:worker_id] || WORKER_ID_DEFAULT).to_i
    raise "Datacenter ID set to #{@datacenter_id} which is invalid" if @datacenter_id > MAX_DATACENTER_ID || @datacenter_id < 0
    raise "Worker ID set to #{@worker_id} which is invalid" if @worker_id > MAX_WORKER_ID || @worker_id < 0
    @version = (params[:version] || VERSION_ID_DEFAULT).to_i
    raise "Version ID set to #{@version} which is invalid" if @version > MAX_VERSION_ID || @version < 0
    @sequence = params[:sequence].to_i & SEQUENCE_BASE_MASK if params[:sequence]
    @class_id = params[:class_id].to_i if params[:class_id]
    @reporter = params[:reporter] || lambda{ |r| puts r }
    @logger = params[:logger] || lambda{ |r| puts r }
  end

  def id
    raise "Sequence number (usually an incrementing database identifier) has not been provided" unless @sequence
    raise "Class ID has not been provided and is necessary" unless @class_id
    raise "Class ID is set to #{@class_id} which is invalid" if @class_id > MAX_CLASS_ID || @class_id < 0
    @timestamp = current_time.to_i
    @star_id = (
      (@version << VERSION_ID_SHIFT)          |
      (@sequence << SEQUENCE_SHIFT)           |
      (@timestamp << TIMESTAMP_SHIFT)         |
      (@class_id << CLASS_ID_SHIFT)           |
      (@worker_id << WORKER_ID_SHIFT)         |
      (@datacenter_id << DATACENTER_ID_SHIFT)
    )
  end
  alias call id

  def decode(star_id = @star_id)
    @star_id       = star_id
    @version       = (@star_id & VERSION_ID_MASK)    >> VERSION_ID_SHIFT
    @sequence      = (@star_id & SEQUENCE_MASK)      >> SEQUENCE_SHIFT
    @timestamp     = (@star_id & TIMESTAMP_MASK)     >> TIMESTAMP_SHIFT
    @class_id      = (@star_id & CLASS_ID_MASK)      >> CLASS_ID_SHIFT
    @worker_id     = (@star_id & WORKER_ID_MASK)     >> WORKER_ID_SHIFT
    @datacenter_id = (@star_id & DATACENTER_ID_MASK) >> DATACENTER_ID_SHIFT
    {
      version:       @version,
      sequence:      @sequence,
      timestamp:     @timestamp,
      class_id:      @class_id,
      worker_id:     @worker_id,
      datacenter_id: @datacenter_id
    }
  end

  private

  def current_time
    Time.now.utc.to_f
  end

  def current_time_millis
    (Time.now.utc.to_f * 1000).to_i
  end

  def till_next_millis(last_timestamp = @last_timestamp)
    timestamp = nil
    # the scala version didn't have the sleep. Not sure if sleeping releases the mutex lock, more research required
    while (timestamp = current_time_millis) < last_timestamp; sleep 0.0001; end
    timestamp
  end

end

# this is my version of an inline test with no other dependencies...
if __FILE__==$PROGRAM_NAME
  require 'test/unit'

  class StarIdTest < Test::Unit::TestCase

    def test_id_sequentiality
      sid = StarId.new(sequence: 1, class_id: 0)
      id = sid.id
      id2 = StarId.new(sequence: 2, class_id: 0).id
      id3 = StarId.new(sequence: 3, class_id: 0).id
      assert id > 0, "StarId isn't returning a valid ID"
      assert id2 > id, "StarId isn't forcing sequential IDs"
      assert id3 > id2, "StarId isn't forcing sequential IDs"
    end

    def test_star_id_decoding
      h = StarId.new.decode(1844528256869679145)
      assert_equal 1, h[:version], "decoded version is wrong"
      assert_equal 5, h[:sequence], "decoded sequence is wrong"
      assert_equal 1387602829, h[:timestamp], "decoded timestamp is #{h[:timestamp]} which is wrong"
      assert_equal 100, h[:class_id], "decoded class_id is wrong"
      assert_equal 6, h[:worker_id], "decoded worker_id is wrong"
      assert_equal 3, h[:datacenter_id], "decoded datacenter_id is wrong"
    end

  end

end
