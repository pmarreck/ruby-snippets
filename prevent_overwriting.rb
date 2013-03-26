class Module
  # Check for an existing method in the current class before extending.  IF
  # the method already exists, then a warning is printed and the extension is
  # not added.  Otherwise the block is yielded and any definitions in the
  # block will take effect.
  #
  # Usage:
  #
  #   class String
  #     prevent_overwriting("xyz") do
  #       def xyz
  #         ...
  #       end
  #     end
  #   end
  #
  def prevent_overwriting(method)
    if method_defined?(method)
      raise RuntimeError, "WARNING: Possible conflict with #{self}##{method} which already exists"
    else
      yield
    end
  end
end

########## inline tests
if __FILE__==$PROGRAM_NAME
  require 'test/unit'
  class PreventMethodOverwritingTest < Test::Unit::TestCase
    def setup
      @klass = Class.new
      @klass.class_eval do
        def test; end
      end
    end
    def test_raise_if_overwriting
      assert_raise(RuntimeError) do
        @klass.class_eval do
          prevent_overwriting(:test) do
            def test; end
          end
        end
      end
    end
  end
end
