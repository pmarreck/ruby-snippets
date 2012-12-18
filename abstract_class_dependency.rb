require 'active_support/inflector'

module AbstractClassDependency
  def self.included(base)
    base.extend ClassMethods
  end

  module ClassMethods
    def depends_on_class(class_str, params={})
      raise(ArgumentError, 'First parameter must not be an actual Class') if class_str.is_a? Class
      class_str = (class_sym = class_str.to_sym).to_s
      class_name_meth = params && params[:as]
      class_name_meth ||= (class_str.underscore << '_class').to_sym
      define_singleton_method(class_name_meth) do
        if (klass = instance_variable_get("@#{class_name_meth}".to_sym))
          klass
        else
          instance_variable_set("@#{class_name_meth}".to_sym, const_get(class_sym))
        end
      end
      define_method(class_name_meth) do
        self.class.send(class_name_meth)
      end
    end
  end

end
if __FILE__==$PROGRAM_NAME
  class B
    def self.hi
      'hi'
    end
  end
  class C
    def self.ho
      'ho'
    end
  end
  class A
    include AbstractClassDependency
    depends_on_class :B # :b_class should now be defined
    depends_on_class 'C', as: :see_klass
    def check_b
      b_class.hi
    end
    def self.check_b
      b_class.hi
    end
    def check_c
      see_klass.ho
    end
    def self.check_c
      see_klass.ho
    end
  end

  require 'test/unit'
  class TestAbstractDependency < Test::Unit::TestCase
    def test_depends_on_class
      assert_equal 'hi', A.check_b
      assert_equal 'hi', A.new.check_b
    end
    def test_depends_on_class_with_good_parameters
      assert_equal 'ho', A.check_c
      assert_equal 'ho', A.new.check_c
    end
    def test_depends_on_class_with_bad_first_parameter
      assert_raise(ArgumentError){ A.depends_on_class C }
    end
  end
end