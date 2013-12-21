require 'monitor'

class IdWorker

  attr_reader :worker_id, :datacenter_id, :reporter, :logger, :sequence, :last_timestamp

  TWEPOCH = 1288834974657
  WORKER_ID_BITS = 5
  DATACENTER_ID_BITS = 5
  MAX_WORKER_ID = (1 << WORKER_ID_BITS) - 1
  MAX_DATACENTER_ID = (1 << DATACENTER_ID_BITS) - 1
  SEQUENCE_BITS = 12
  WORKER_ID_SHIFT = SEQUENCE_BITS
  DATACENTER_ID_SHIFT = SEQUENCE_BITS + WORKER_ID_BITS
  TIMESTAMP_LEFT_SHIFT = SEQUENCE_BITS + WORKER_ID_BITS + DATACENTER_ID_BITS
  SEQUENCE_MASK = (1 << SEQUENCE_BITS) - 1

  # note: this is a class-level (global) lock.
  # May want to change to an instance-level lock if this is reworked to some kind of singleton or worker daemon.
  MUTEX_LOCK = Monitor.new

  def initialize(worker_id = 0, datacenter_id = 0, sequence = 0, reporter = nil, logger = nil)
    raise "Worker ID set to #{worker_id} which is invalid" if worker_id > MAX_WORKER_ID || worker_id < 0
    raise "Datacenter ID set to #{datacenter_id} which is invalid" if datacenter_id > MAX_DATACENTER_ID || datacenter_id < 0
    @worker_id = worker_id
    @datacenter_id = datacenter_id
    @sequence = sequence
    @reporter = reporter || lambda{ |r| puts r }
    @logger = logger || lambda{ |r| puts r }
    @last_timestamp = -1
    @logger.call("IdWorker starting. timestamp left shift %d, datacenter id bits %d, worker id bits %d, sequence bits %d, workerid %d" % [TIMESTAMP_LEFT_SHIFT, DATACENTER_ID_BITS, WORKER_ID_BITS, SEQUENCE_BITS, worker_id])
  end

  def get_id(*)
    # log stuff here, theoretically
    next_id
  end
  alias call get_id

  protected

  def next_id
    MUTEX_LOCK.synchronize do
      timestamp = current_time_millis
      if timestamp < @last_timestamp
        @logger.call("clock is moving backwards.  Rejecting requests until %d." % @last_timestamp)
      end
      if @last_timestamp == timestamp
        @sequence = (@sequence + 1) & SEQUENCE_MASK
        if @sequence == 0
          timestamp = till_next_millis(@last_timestamp)
        end
      else
        @sequence = 0
      end
      @last_timestamp = timestamp
      ((timestamp - TWEPOCH) << TIMESTAMP_LEFT_SHIFT) |
        (@datacenter_id << DATACENTER_ID_SHIFT) |
        (@worker_id << WORKER_ID_SHIFT) |
        @sequence
    end
  end

  private

  def current_time_millis
    (Time.now.to_f * 1000).to_i
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

  class IdWorkerTest

    AssertionError = Class.new(StandardError)

    def assert(bool, msg = 'Assertion False')
      raise AssertionError.new(msg) unless bool
    end

    def initialize
      idw = IdWorker.new
      id = idw.call
      id2 = idw.call
      id3 = idw.call
      puts id
      puts id2
      puts id3
      assert id > 0, "IdWorker isn't returning a valid ID"
      assert id2 > id, "IdWorker isn't forcing sequential IDs"
      assert id3 > id2, "IdWorker isn't forcing sequential IDs"
    end

    self
  end.new

end
