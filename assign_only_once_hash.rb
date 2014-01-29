class AssignValueOnlyOnceHash < Hash
  KeyReassignmentError=Class.new(RuntimeError)
  def []=(key, val)
    raise KeyReassignmentError, "key '#{key}' already assigned" if key? key
    super
  end
end

if __FILE__==$PROGRAM_NAME
  require 'test/unit'
  class AssignValueOnlyOnceHashTest < Test::Unit::TestCase

    def setup
      @h = AssignValueOnlyOnceHash.new
    end

    def test_normal_assignment
      @h[1]=1
      assert_equal 1, @h[1]
    end

    def test_dupe_assignment_raises_error
      @h[1]=1
      assert_raise(AssignValueOnlyOnceHash::KeyReassignmentError){ @h[1]=2 }
    end

  end
end
