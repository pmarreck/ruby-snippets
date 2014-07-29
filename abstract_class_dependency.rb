# require 'active_support/inflector'
class String
  def underscore(camel_cased_word = self)
    word = camel_cased_word.to_s.dup
    word.gsub!(/::/, '/')
    word.gsub!(/(?:([A-Za-z\d])|^)((?=a)b)(?=\b|[^a-z])/) { "#{$1}#{$1 && '_'}#{$2.downcase}" }
    word.gsub!(/([A-Z\d]+)([A-Z][a-z])/,'\1_\2')
    word.gsub!(/([a-z\d])([A-Z])/,'\1_\2')
    word.tr!("-", "_")
    word.downcase!
    word
  end
end

module AbstractClassDependency
  def self.included(base)
    base.extend ClassMethods
    base.send(:include, InstanceMethods)
  end

  module InstanceMethods
    # includes are run for each new object by actually extending that new object
    def run_includes
      di = self.class.instance_variable_get(:@_deferred_includes)
      if di
        di.each{ |m| extend send(m) }
        self.class.instance_variable_set(:@_deferred_includes, nil)
      end
    end
    def initialize(*args, &block)
      self.class.class_eval do
        run_setup
        run_extends
      end
      run_includes
      super
    end
  end

  module ClassMethods
    def run_setup
      if @_deferred_class_setup
        @_deferred_class_setup.each{ |c| Proc===c ? c.call : send(c) }
        @_deferred_class_setup = nil
      end
    end
    def run_extends
      if @_deferred_extends
        @_deferred_extends.each{ |m| extend send(m) unless singleton_class.include? send(m) }
        @_deferred_extends = nil
      end
    end

    def depends_on_constant(const_arg, params={}, suffix = '')
      if const_arg.is_a?(Class) || const_arg.is_a?(Module)
        raise(ArgumentError, 'First parameter must not be an actual Class or Module')
      end
      as = params && params[:as]
      if const_arg.is_a? Proc
        raise(ArgumentError, 'Must provide an as: parameter if the first arg is a Proc') unless as
      else
        const_arg = const_arg.to_s
        underscored = const_arg.underscore.gsub(/\//,'__')
      end
      class_ivar_name = as || underscored
      class_name_meth = (as && as.to_sym) || (underscored + suffix).to_sym
      define_singleton_method(class_name_meth) do
        if (klass = instance_variable_get("@#{class_ivar_name}".to_sym))
          klass
        else
          instance_variable_set("@#{class_ivar_name}".to_sym, begin
            case const_arg
            when Proc
              const_arg.call
            else
              # handle namespacing
              namespaced = const_arg.split('::')
              namespaced.inject(Module){|m,c| m.const_get(c) }
            end
          end)
        end
      end
      define_method(class_name_meth) do
        self.class.send(class_name_meth)
      end
    end
    def depends_on_constants(*args)
      args = args.flatten
      if (h=args.first).is_a? Hash
        h.each do |k,v|
          depends_on_constant k, as: v
        end
      else
        args.each do |c|
          depends_on_constant c
        end
      end
    end
    def depends_on_class(const_arg, params={})
      depends_on_constant(const_arg, params, '_class')
    end
    def depends_on_module(const_arg, params={})
      depends_on_constant(const_arg, params, '_module')
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
    def depends_on_modules(*args)
      args = args.flatten
      if (h=args.first).is_a? Hash
        h.each do |k,v|
          depends_on_module k, as: v
        end
      else
        args.each do |c|
          depends_on_module c
        end
      end
    end

    def autoinclude(*module_strs)
      raise(ArgumentError, 'Argument(s) must not be an actual Module. Try symbolizing it as :Module_name') if module_strs.any?{|m| m.is_a? Module}
      module_strs = module_strs.flatten.map(&:to_s)
      @autoincluded_modules ||= []
      @autoincluded_modules |= module_strs.dup
      self.class_eval do
        unless methods(false).include?(:method_missing_without_dynamic_include)
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
      raise(ArgumentError, 'Argument(s) must not be an actual Module. Try symbolizing it as :Module_name') if module_strs.any?{|m| m.is_a? Module}
      module_strs = module_strs.flatten.map(&:to_s)
      @autoextended_modules ||= []
      @autoextended_modules |= module_strs.dup
      cycle_module_strs = module_strs.dup
      self.singleton_class.class_eval do
        unless methods(false).include?(:method_missing_without_dynamic_extend)
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
    end #autoextend

    def include_deferred(*args, &block)
      @_deferred_includes ||= []
      if block_given?
        @_deferred_includes << block
      else
        @_deferred_includes.push(*args)
      end
    end

    def extend_deferred(*args, &block)
      @_deferred_extends ||= []
      if block_given?
        @_deferred_extends << block
      else
        @_deferred_extends.push(*args)
      end
    end

    def setup_class(*args, &block)
      @_deferred_class_setup ||= []
      if block_given?
        @_deferred_class_setup << block
      else
        @_deferred_class_setup.push(*args)
      end
    end
  end
end

if __FILE__==$PROGRAM_NAME
  require 'test/unit'
  
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
    def self.another_mod
      DeferredMethods
    end
  end
  class D
    include AbstractClassDependency
    depends_on_constants B: :b_class, C: :see_class
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
      send(:yo__mtv_class).raps
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
  class I
    include AbstractClassDependency
    depends_on_module ->{ A.another_mod }, as: :a_another_mod
    depends_on_module :DeferredMethods
  end
  class J
    include AbstractClassDependency
    def self.code_to_exec
      @runs ||= 0
      @runs += 1
    end
    def self.setup_runs
      @runs
    end
    setup_class { code_to_exec }
  end

  class TestAbstractDependency < Test::Unit::TestCase
    def test_depends_on_constant
      assert_equal 'hi', A.check_b
      assert_equal 'hi', A.new.check_b
    end
    def test_depends_on_constant_with_good_parameters
      assert_equal 'ho', A.check_c
      assert_equal 'ho', A.new.check_c
    end
    def test_depends_on_constant_with_bad_first_parameter
      assert_raise(ArgumentError){ A.depends_on_constant C }
    end
    def test_depends_on_constants
      assert_equal 'hi', D.new.check_b
      assert_equal 'ho', D.check_c
      assert_equal 'hi', E.new.check_b
      assert_equal 'ho', E.check_c
    end
    def test_depends_on_namespaced_constants
      assert_equal 'Run DMC', F.check_run_named
      assert_equal 'Run DMC', F.check_run
    end
    def test_with_proc
      assert_equal DeferredMethods, I.a_another_mod
      assert_equal DeferredMethods, I.new.a_another_mod
    end
    def test_with_module
      assert_equal DeferredMethods, I.deferred_methods_module
      assert_equal DeferredMethods, I.new.deferred_methods_module
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
    def test_for_calling_class_setup_only_once
      assert_nil J.setup_runs
      J.new
      assert_equal 1, J.setup_runs
      J.new
      assert_equal 1, J.setup_runs
    end
  end
end
