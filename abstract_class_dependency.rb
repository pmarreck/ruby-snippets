require 'active_support/inflector'

module AbstractClassDependency
  def self.included(base)
    base.extend ClassMethods
  end

  module ClassMethods
    def depends_on_class(class_str, params={})
      raise(ArgumentError, 'First parameter must not be an actual Class') if class_str.is_a? Class
      class_str = class_str.to_s
      class_name_meth = (params && params[:as] && params[:as].to_s) || (class_str.underscore << '_class')
      class_ivar_name = class_name_meth.gsub(/\//,'__')
      class_name_meth = class_name_meth.to_sym
      define_singleton_method(class_name_meth) do
        if (klass = instance_variable_get("@#{class_ivar_name}".to_sym))
          klass
        else
          instance_variable_set("@#{class_ivar_name}".to_sym, begin
            # handle namespacing
            namespaced = class_str.split('::')
            namespaced.inject(Module){|m,c| m.const_get(c) }
          end)
        end
      end
      define_method(class_name_meth) do
        self.class.send(class_name_meth)
      end
    end
    def depends_on_classes(*args)
      args = args.flatten
      if (h=args.first).is_a? Hash
        h.each do |k,v|
          depends_on_class k, as: v
        end
      else
        args.each do |c|
          depends_on_class c
        end
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
  module Yo
    class MTV
      def self.raps
        'Run DMC'
      end
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
  class D
    include AbstractClassDependency
    depends_on_classes B: :b_class, C: :see_class
    def check_b
      b_class.hi
    end
    def self.check_c
      see_class.ho
    end
  end
  class E
    include AbstractClassDependency
    depends_on_classes :B, :C
    def check_b
      b_class.hi
    end
    def self.check_c
      c_class.ho
    end
  end
  class F
    include AbstractClassDependency
    depends_on_class :'Yo::MTV', as: :yo_mtv
    depends_on_class :'Yo::MTV'
    def self.check_run_named
      yo_mtv.raps
    end
    def self.check_run
      send('yo/mtv_class').raps
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
    def test_depends_on_classes
      assert_equal 'hi', D.new.check_b
      assert_equal 'ho', D.check_c
      assert_equal 'hi', E.new.check_b
      assert_equal 'ho', E.check_c
    end
    def test_depends_on_namespaced_classes
      assert_equal 'Run DMC', F.check_run_named
      assert_equal 'Run DMC', F.check_run
    end
  end
end
