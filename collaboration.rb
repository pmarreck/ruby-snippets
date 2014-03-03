require 'test/unit'

def f1(a=0)
  1 + a
end

def f2(a=0)
  2 + a
end

def f3(a=0)
  3 + a
end

def f(input)
  8 + f1(f2(f3(input)))
end

########## inline tests
if __FILE__==$PROGRAM_NAME
  require 'test/unit'
  require 'mocha/setup'
  class CollaborationTest < Test::Unit::TestCase
    # FULL INTEGRATION TEST
    def test_integration_of_all_3
      assert_equal 14, f(0)
      assert_equal 17, f(3)
    end

    # basically, I want to find a redefinition of f2 above which WILL break the above test but which WON'T break any of the below tests:

    # UNIT TESTS

    def test_f
      stubs(:f1).returns(6)
      # stubs(:f2).returns(2)
      # stubs(:f3).returns(3)
      assert_equal 14, f(0)
    end

    def test_f1
      stubs(:f2).returns(2)
      stubs(:f3).returns(3)
      assert_equal 1, f1
      assert_equal 5, f1(4)
    end

    def test_f2
      stubs(:f1).returns(1)
      stubs(:f3).returns(3)
      assert_equal 2, f2
      assert_equal 16, f2(14)
    end

    def test_f3
      stubs(:f1).returns(1)
      stubs(:f2).returns(2)
      assert_equal 3, f3
      assert_equal 10, f3(7)
    end

    # now we test immediate pairs of collaborators

    def test_f_f1
      stubs(:f2).returns(2)
      stubs(:f3).returns(3)
      assert_equal 11, f(3)
    end

    # It is unnecessary to test collaboration of f and f2 because f is only immediately dependent on the output of f1

    #... no?

  end
end
