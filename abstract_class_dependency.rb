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

    def autoinclude(*module_strs)
      raise(ArgumentError, 'Argument(s) must not be an actual Module') if module_strs.any?{|m| m.is_a? Module}
      module_strs = module_strs.flatten.map(&:to_s)
      @autoincluded_modules ||= []
      @autoincluded_modules |= module_strs.dup
      self.class_eval do
        unless methods.include?(:method_missing_without_dynamic_include)
          alias method_missing_without_dynamic_include method_missing
          def method_missing_with_dynamic_include(*args)
            klass = self.class
            cycle_module_strs = klass.instance_variable_get(:@autoincluded_modules).dup
            begin
              mod = eval(cycle_module_strs.shift)
              klass.send(:include, mod) unless klass.include? mod
              send(*args)
            rescue NameError
              if cycle_module_strs.size > 0
                retry
              else
                method_missing_without_dynamic_include(*args)
              end
            end
          end
          alias method_missing method_missing_with_dynamic_include
        end
      end
    end

    def autoextend(*module_strs)
      raise(ArgumentError, 'Argument(s) must not be an actual Module') if module_strs.any?{|m| m.is_a? Module}
      module_strs = module_strs.flatten.map(&:to_s)
      @autoextended_modules ||= []
      @autoextended_modules |= module_strs.dup
      cycle_module_strs = module_strs.dup
      self.singleton_class.class_eval do
        unless methods.include?(:method_missing_without_dynamic_extend)
          alias method_missing_without_dynamic_extend method_missing
          def method_missing_with_dynamic_extend(*args)
            klass = self
            cycle_module_strs = klass.instance_variable_get(:@autoextended_modules).dup
            begin
              mod = eval(cycle_module_strs.shift)
              klass.send(:extend, mod) unless klass.singleton_class.include? mod
              send(*args)
            rescue NameError
              if cycle_module_strs.size > 0
                retry
              else
                method_missing_without_dynamic_extend(*args)
              end
            end
          end
          alias method_missing method_missing_with_dynamic_extend
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
  module DeferredMethods
    def git
      'some'
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
  class G
    include AbstractClassDependency
    autoinclude :DeferredMethods
  end
  class H
    include AbstractClassDependency
    autoextend :DeferredMethods
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
    def test_autoinclude
      assert_nothing_raised { G.new.git }
      assert_equal 'some', G.new.git
      assert_raise(NoMethodError){ G.git }
    end
    def test_autoextend
      assert_nothing_raised { H.git }
      assert_equal 'some', H.git
      assert_raise(NoMethodError){ H.new.git }
    end
  end
end
