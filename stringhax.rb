class String
  unless defined?(plus_without_forced_to_s)
    alias :plus_without_forced_to_s :+
    def +(n)
      if n.respond_to? :to_s
        self.plus_without_forced_to_s(n.to_s)
      else
        self.plus_without_forced_to_s(n)
      end
    end
  end
end

class Fixnum
  unless defined?(plus_without_forced_to_i)
    alias :plus_without_forced_to_i :+
    def +(n)
      if n.respond_to? :to_i
        self.plus_without_forced_to_i(n.to_i)
      else
        self.plus_without_forced_to_i n
      end
    end
  end
end

if __FILE__==$0
  require 'test/unit'
  class StringAddForceTos < Test::Unit::TestCase
    def test_addition_with_int
      a = "sandeep"
      b = 1
      assert_equal "sandeep1", a + b
    end

    def test_addition_with_hash
      a = "sandeep"
      b = {a: 2}
      assert_equal "sandeep{:a=>2}", a + b
    end

    def test_add_string_to_fixnum
      a = 1
      b = "6peter"
      assert_equal 7, a + b
    end
  end
end
