module RailsCompatibleDelegator
  attr_reader :delegate
  def self.included(base)
    base.class_eval do
      undef_method :class, :is_a?, :instance_of?, :to_s, :inspect, :method # for Rails compatibility
    end
  end
  def initialize(*args)
    @delegate = args.first
  end
  def method_missing(*args, &block)
    return @delegate.send(*args, &block) if @delegate.respond_to?(args.first)
    super
  end

  def respond_to_missing?(method_name, include_private = false)
    [:equal?, :__id__, :__send__, :respond_to?].include?(args.first.to_sym) || super
  end

  def initialize_dup(obj)
    obj.instance_variable_set(:@delegate, delegate.dup)
    super
  end

  def initialize_clone(obj)
    obj.instance_variable_set(:@delegate, delegate.clone)
    super
  end
end


########## inline tests
if __FILE__==$PROGRAM_NAME

  require 'test/unit'
  class RailsCompatibleDelegatorTest < Test::Unit::TestCase

    attr_reader :subject, :klass

    def setup
      @klass ||= Class.new do
        include RailsCompatibleDelegator
        def [](k)
          if k==:test
            :override
          else
            delegate[k]
          end
        end
        def whack
          :job
        end
      end
      @delegated = Hash.new(0)
      @subject = @klass.new(@delegated)
    end

    def test_overridden_behavior
      assert_equal :override, subject[:test]
    end

    def test_delegate
      assert_equal @delegated, subject.delegate
    end

    def test_class
      assert_equal Hash, subject.class
      assert subject.is_a?(Hash)
    end

    def test_delegate_not_overridden_behavior
      assert_equal 0, subject[5]
      assert_equal 0, subject.size
    end

    def test_object_ids_do_differ
      assert_not_equal subject.object_id, subject.delegate.object_id
    end

    def test_not_equal?
      assert !subject.equal?(subject.delegate), "the subject should not be 'equal?' to its delegate"
    end

    def test_nonequality
      assert_not_equal subject, subject.delegate, "the subject should != its delegate"
    end

    def test_respond_to
      assert subject.respond_to?(:whack)
      assert !subject.delegate.respond_to?(:whack)
    end

    def test_dup
      dup = subject.dup
      assert_not_equal subject, dup
      assert dup.respond_to?(:delegate), "dup of delegator lost delegation"
      assert !dup.delegate.respond_to?(:delegate)
      assert_not_equal subject.object_id, dup.object_id
      assert_not_equal subject.delegate.object_id, dup.delegate.object_id
    end

    def test_method_on_delegate
      assert_equal '{}', subject.to_s
    end

    def test_double_wrapping
      meat = Class.new do
        include RailsCompatibleDelegator
        def value
          3
        end
      end
      cheese = Class.new do
        include RailsCompatibleDelegator
        def value
          2 + super
        end
      end
      bun = Class.new do
        include RailsCompatibleDelegator
        def value
          1 + super
        end
      end
      assert_equal 6, bun.new(cheese.new(meat.new)).value
    end

  end

end
