module ArrayUtils

  def self.included(base)
    base.send(:alias_method, :_orig_bracket, :[])
    base.send(:include, InstanceMethods)
    base.send(:alias_method, :[], :_new_bracket)
  end
  module InstanceMethods
    unless respond_to? :_new_bracket
      def _new_bracket(*args, &block)
        if block_given? && args.empty?
          select(&block)
        elsif block_given?
          _orig_bracket(*args).select(&block)
        else
          _orig_bracket(*args)
        end
      end
    end
  end
end

class Array
  include ArrayUtils
end

if __FILE__==$0
  require 'test/unit'
  class IndexByBlockTest < Test::Unit::TestCase
    def test_working
      a = [1,2,3,4,5,6]
      assert_respond_to [], :_orig_bracket
      assert_equal 1, a._orig_bracket(0)
      # assert_equal 0, [].method(:[]).arity
      assert_equal [2,4,6], a[&:even?]
      assert_equal [2], a[0..2,&:even?]
    end
  end
end
