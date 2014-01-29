require 'test/unit'
require 'mocha/setup'
require 'ostruct'

def time
  t = Time.now
  yield
  Time.now - t
end

class TestStubbing < Test::Unit::TestCase

  def setup
    @api_obj = nil
  end

  def test_openstruct
    puts "OpenStruct:"
    puts time { 10000.times{ @api_obj = OpenStruct.new(post_id: 4321)}}
  end

  def test_stub
    puts "stub:"
    puts time { 10000.times{ @api_obj = stub(post_id: 4321) }}
  end
end

# OpenStruct:
# 0.14541
# stub:
# 0.619781