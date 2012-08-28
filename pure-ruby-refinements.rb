
require 'active_support/core_ext/module' # for alias_method_chain
require 'active_support/inflector' # for constantize

class CallChain
  def self.caller_name(opts = {}, &block)
    opts[:depth] ||= 1
    parse_caller(opts.merge(at: caller(opts[:depth]+1).first), &block).last
  end

  def self.resolve_classname(opts = {}, &block)
    # try to constantize this class to its full namespace.
    # There is a small chance this will fail so you can pass a "hint" block
    # to further filter the results to the one you expect. That block
    # should take an object which is the class or module in question that was found.
    # NOTE: Maybe try to make use of the following in the future:
    #  Module.constants.map{|m| ((c=m.to_s.constantize).respond_to?(:constants) && c.constants.length>0) ? {c => m.to_s.constantize.constants(false)} : m.to_s.constantize }
    opts={name: opts} if opts.is_a? String
    begin
      o = opts[:name].constantize
    rescue NameError
      # This is kind of expensive. I know.
      os = ObjectSpace.each_object.select{ |o| (o.class==Class || o.class==Module) && o.name =~ /::#{opts[:name]}$/ }
      os = os.select{ |o| yield o } if block_given?
      if os && os.size > 0
        os.first
      else
        raise
      end
    end
  end

  private
  #Stolen from ActionMailer, where this was used but was not made reusable
  def self.parse_caller(opts = {}, &block)
    at = opts[:at]
    if /^(.+?):(\d+)(?::in `(.*)')?/ =~ at
      file   = Regexp.last_match[1]
      line   = Regexp.last_match[2].to_i
      obj    = begin
        where = Regexp.last_match[3]
        if /<([a-z]+):([A-Z][a-zA-Z]*)>/ =~ where
          o = [Regexp.last_match[1].to_sym]
          if opts[:resolve_classname]
            o << self.resolve_classname(Regexp.last_match[2], &block)
          else
            o << Regexp.last_match[2]
          end
          o
        else
          [:method, where.to_sym]
        end
      end
      [file, line, obj]
    end
  end
end

class Binding
  def this
    eval('self')
  end
end

# easy hash traversal
class Hash
  def traverse(*indexes)
    indexes.flatten.inject(self){|v, i| v[i] if v.is_a?(Hash)}
  end
end

module ClassCascadableAttributes
  def self.included(base)
    base.extend ClassMethods
  end
  module ClassMethods
    def class_cascadable_reader(*syms)
      syms.each do |sym|
        define_singleton_method(sym) do
          obj = self.ancestors.detect{|c| c.instance_variable_get("@#{sym}".to_sym) }
# puts "Looked for class method reader #{sym} up the class chain from #{self} and found it in object #{obj.inspect} and its value is #{obj.instance_variable_get("@#{sym}".to_sym).inspect}"
          if obj
            obj.instance_variable_get("@#{sym}".to_sym)
          else
            raise NoMethodError.new("undefined method `#{sym}' for \"#{self}\":#{self.class}")
          end
        end
        define_method(sym) do
# puts "Looked for instance method reader #{sym} up the class chain from #{self}"
          val = self.instance_variable_get("@#{sym}".to_sym) || self.class.send(sym)
# puts "Found a value for #{sym} of #{val.inspect}"
          val
        end
      end
    end
    def class_cascadable_writer(*syms)
      syms.each do |sym|
        define_singleton_method("#{sym}=") do |arg|
# puts "Set class @#{sym} on #{self} = #{arg} via class method"
          self.instance_variable_set("@#{sym}".to_sym, arg)
        end
        define_method("#{sym}=".to_sym) do |arg|
          self.instance_variable_set("@#{sym}".to_sym, ((self.class.send(sym) || []) | arg))
# puts "Set instance @#{sym} on #{self} = #{arg} via instance method and combined it with any class instance values to get #{self.instance_variable_get("@#{sym}".to_sym)}"
        end
      end
    end
    def class_cascadable_accessor(*syms)
      class_cascadable_reader(*syms)
      class_cascadable_writer(*syms)
    end
  end
end
Object.send(:include, ClassCascadableAttributes)


class Refinements

  class << self

    def alias_all_methods_and_store_hashes(base)
      class_meths = []
      base.class_eval do
        self.instance_variable_set(:@_instance_method_hash_hash, {}) unless self.instance_variable_get(:@_instance_method_hash_hash)
        self.instance_methods(false).reject{|m| /^_original_/.match(m.to_s) }.each do |im|
          unless method_defined?("_original_#{im}")
            alias_method "_original_#{im}", im
puts "Aliased instance method #{im} to _original_#{im} inside #{self}"
            self.instance_variable_get(:@_instance_method_hash_hash)[im] = self.instance_method(im).hash
          end
        end
        self.instance_variable_set(:@_class_method_hash_hash, {}) unless self.instance_variable_get(:@_class_method_hash_hash)
# puts "About to go through class (singleton) methods of #{self}: #{self.singleton_methods(false).reject{|m| /^_original_/.match(m.to_s) }}"
        class_meths |= self.singleton_methods(false).reject{|m| /^_original_/.match(m.to_s) }
      end
      class_meths.each do |cm|
        unless base.method_defined?("_original_#{cm}")
# puts "About to try aliasing class method #{cm} on #{base}"
          (class << base; self; end).class_eval do
            alias_method "_original_#{cm}", cm if methods(false).include?(cm)
# puts "Aliased class method #{cm} to _original_#{cm} on #{base}"
            base.instance_variable_get(:@_class_method_hash_hash)[cm] = base.method(cm).hash
          end
        end
      end
# puts "Aliased all methods in #{base}."
# puts "Instance method list: #{base.instance_methods}"
# puts "Class method list: #{base.singleton_methods}"
    end

    def new_instance_methods(base)
# puts "#{base}.instance_variable_get(:@_instance_method_hash_hash) = #{base.instance_variable_get(:@_instance_method_hash_hash)}"
# puts "#{base}.instance_methods(false) = #{base.instance_methods(false)}"
      base.instance_methods(false).reject do |im|
# puts "#{base}.instance_method(#{im}).hash = #{base.instance_method(im).hash} and base.instance_variable_get(:@_instance_method_hash_hash)[#{im}] = #{base.instance_variable_get(:@_instance_method_hash_hash)[im]}"
# puts "base.instance_method(#{im}).hash == base.instance_variable_get(:@_instance_method_hash_hash)[#{im}] || /^_original_/.match(#{im}.to_s) is #{base.instance_method(im).hash == base.instance_variable_get(:@_instance_method_hash_hash)[im] || /^_original_/.match(im.to_s)}"
        base.instance_method(im).hash == base.instance_variable_get(:@_instance_method_hash_hash)[im] ||
          /^_original_/.match(im.to_s)
      end.tap{|m| puts "new instance methods: #{m}"}
    end

    def new_class_methods(base)
# puts "#{base}.instance_variable_get(:@_class_method_hash_hash) = #{base.instance_variable_get(:@_class_method_hash_hash)}"
# puts "#{base}.singleton_methods(false) = #{base.singleton_methods(false)}"
      base.singleton_methods(false).reject do |cm|
        base.method(cm).hash == base.instance_variable_get(:@_class_method_hash_hash)[cm] ||
          /^_original_/.match(cm.to_s)
      end.tap{|m| puts "new class methods: #{m}"}
    end

    def remove_unrefined_instance_aliases(base, new_methods = self.new_instance_methods(base))
      base.instance_methods(false).each do |im|
        if im.to_s =~ /^_original_/
          unless new_methods.include?(im)
# puts "Removing instance method #{im} from #{base}"
            base.send(:remove_method, im)
          end
        end
      end
    end

    def remove_unrefined_class_aliases(base, new_methods = self.new_class_methods(base))
      base.singleton_methods(false).each do |cm|
        if cm.to_s =~ /^_original_/
          unless new_methods.include?(cm)
# puts "Removing class method #{cm} from #{base}"
            (class << base; self; end).send(:remove_method, cm)
          end
        end
      end
    end

  end

end

class Module
  def refine(klass, &block)
    refinement_module = self
    # initialize a class ivar so it inherits... this may need revision at some point
    # class << klass
      # _active_refinements ||= []
    # end
    # execute this block in the context of the klass and see what happened
puts "Refining #{klass} with #{refinement_module}"
    # Yeah this is a little expensive. I welcome better solutions.
    Refinements.alias_all_methods_and_store_hashes(klass)
    # run that bitch and see what it wrought
    klass.class_eval &block
    nu_instance_methods = Refinements.new_instance_methods(klass)
    Refinements.remove_unrefined_instance_aliases(klass, nu_instance_methods)
puts "New instance methods detected on #{klass} are: #{nu_instance_methods}"
    # store any new instance methods in a klass ivar
    nu_instance_methods.each do |im|
      klass.instance_variable_set(:@_im_refs_by_module, {}) unless klass.instance_variable_get(:@_im_refs_by_module)
      klass.instance_variable_get(:@_im_refs_by_module)[refinement_module] ||= {}
      klass.instance_variable_get(:@_im_refs_by_module)[refinement_module][im] = klass.instance_method(im)
      # wire the new method inside the klass, bypassing any existing same-named methods
      klass.send(:define_method, im) do |*args, &block|
puts "I CAN SEE YOU from instance method #{im}, _temporary_refinements, you're #{_temporary_refinements}" if defined?(_temporary_refinements)
puts "Trying to call instance method #{im} on #{self}. self._active_refinements is #{self._active_refinements} and _active_refinements is #{_active_refinements}"
        unless self._active_refinements && !self._active_refinements.empty?
puts "There are no active refinements."
          if self.class.instance_methods(false).include?("_original_#{im}".to_sym)
            send("_original_#{im}".to_sym, *args, &block)
          else
puts "Looked for original instance method #{im} on #{self} and couldn't find it."
            raise NoMethodError.new("undefined method `#{im}' for \"#{self}\":#{self.class}")
          end
        else
puts "There are active refinements!"
          # grab the first matching refinement that implements this method
          if klass.instance_variable_get(:@_im_refs_by_module)
puts "Some of them may be applicable to class #{klass}!"
            meth = nil
            applicable_refinement = self._active_refinements.detect do |ref|
              meth = klass.instance_variable_get(:@_im_refs_by_module).traverse(ref, im)
            end
            if meth
puts "The applicable refinement on #{klass} is #{applicable_refinement} and the method is #{meth.inspect}"
            else
puts "Could not find an applicable method on #{klass} for refinement #{applicable_refinement}"
            end
          else # no refinements
puts "There are no instance method refinements defined on #{klass} yet."
            raise NoMethodError.new("undefined method `#{im}' for \"#{self}\":#{self.class}")
          end
          if meth
            meth.bind(self).call(*args, &block)
          else # no refined methods
            raise NoMethodError.new("undefined method `#{im}' for \"#{self}\":#{self.class}")
          end
        end
      end
puts "#{klass}.instance_variable_get(:@_im_refs_by_module)==#{klass.instance_variable_get(:@_im_refs_by_module).inspect}"
    end

    # store any new class methods in a klass ivar
    nu_class_methods = Refinements.new_class_methods(klass)
    Refinements.remove_unrefined_class_aliases(klass, nu_class_methods)
puts "New class methods detected on #{klass} are: #{nu_class_methods}"
    nu_class_methods.each do |cm|
puts "Trying to call class method #{cm}"
      klass.instance_variable_set(:@_cm_refs_by_module, {}) unless klass.instance_variable_get(:@_cm_refs_by_module)
      klass.instance_variable_get(:@_cm_refs_by_module)[self] ||= {}
      klass.instance_variable_get(:@_cm_refs_by_module)[self][cm] = klass.method(cm)
puts "#{klass}.instance_variable_get(:@_cm_refs_by_module)[#{self}][#{cm}] = #{klass.instance_variable_get(:@_cm_refs_by_module)[self][cm]}"
      # wire the new method inside the klass, bypassing any existing same-named methods
      klass.define_singleton_method(cm) do |*args, &block|
puts "Running class method #{cm}. self._active_refinements is #{self._active_refinements}"
        unless self._active_refinements && !self._active_refinements.empty?
          if singleton_methods(false).include?("_original_#{cm}".to_sym)
            send("_original_#{cm}".to_sym, *args, &block)
          else
            raise NoMethodError.new("undefined method `#{cm}' for \"#{self}\":#{self.class}")
          end
        else
          # grab the first matching refinement that implements this method
          if klass.instance_variable_get(:@_cm_refs_by_module)
            meth = nil
            self._active_refinements.detect do |ref|
              meth = klass.instance_variable_get(:@_cm_refs_by_module).traverse(ref, cm)
            end
          else
            nil
          end
          if meth
            meth.unbind.bind(self).call(*args, &block)
          else # no refined methods
            raise NoMethodError.new("undefined method `#{cm}' for \"#{self}\":#{self.class}")
          end
        end
      end
puts "#{klass}.instance_variable_get(:@_cm_refs_by_module)==#{klass.instance_variable_get(:@_cm_refs_by_module)}"
# puts "#{klass} understands class method #{cm}? #{klass.respond_to? cm}"
# puts "#{klass}.#{cm} == #{klass.send(cm)}"
    end
    # clear the class methods from bucket
    # klass._clear_class_methods

  end
end

class Object
  class_cascadable_accessor :_active_refinements
  @_active_refinements = []
  # Add a passed-in refinement to an ivar.
  # The ivar should naturally go out of scope, removing the refinement (for now)
  # Note that this won't work inside a method definition (YET) without a block
  def using(*refs)
    # self.instance_variable_set("@#{_active_refinements}")
puts "Called USING on #{self} from #{caller.first} with #{refs}, current _active_refinements are #{self._active_refinements.inspect}"
    self._active_refinements = (self._active_refinements || []).dup
puts "In case they weren't already set, they have now been set to #{self._active_refinements.inspect}"
    if block_given?
      original_refinements, self._active_refinements = self._active_refinements.dup, (self._active_refinements | refs)
puts "Block was given. original_refinements==#{original_refinements.inspect}, _active_refinements==#{self._active_refinements.inspect}"
      original_object_refinements, Object._active_refinements = Object._active_refinements.dup, (Object._active_refinements | refs) unless self.is_a?(Class)
puts "I hate doing this but Object._active_refinements are now #{Object._active_refinements}" unless self.is_a?(Class)
      _temporary_refinements = "block given"
      yield
      Object._active_refinements = original_object_refinements unless self.is_a?(Class)
puts "Object._active_refinements set to its original value of #{original_object_refinements} and is now #{Object._active_refinements}"
      raise "Object active refinements not reset properly" unless Object._active_refinements == original_object_refinements
      self._active_refinements = original_refinements
      raise "Active refinements not reset properly" unless self._active_refinements == original_refinements
puts "_active_refinements set to its original value of #{original_refinements.inspect} and is now #{self._active_refinements.inspect}"
    else
puts "No block given, current _active_refinements started out #{_active_refinements.inspect}"
      Object._active_refinements |= refs unless self.is_a?(Class)
      self._active_refinements |= refs
puts "and they are now #{self._active_refinements.inspect}"
puts "and the Object._active_refinements are now #{Object._active_refinements.inspect}"
      _temporary_refinements = "no block given"
    end
puts "So, the current _active_refinements are now #{self._active_refinements.inspect}"
    # fire off any 'used' callbacks
    refs.each do |ref|
      ref.send(:used, self) if ref.respond_to?(:used)
    end
  end
  def not_using(*refs)
    self._active_refinements = (self._active_refinements || []).dup
    if block_given?
      original_refinements, self._active_refinements = self._active_refinements.dup, (self._active_refinements - refs)
      original_object_refinements, Object._active_refinements = Object._active_refinements.dup, (Object._active_refinements - refs) unless self.is_a?(Class)
      yield
      Object._active_refinements = original_object_refinements unless self.is_a?(Class)
      self._active_refinements = original_refinements
    else
      Object._active_refinements -= refs unless self.is_a?(Class)
      self._active_refinements -= refs
    end
    # fire off any 'unused' callbacks
    refs.each do |ref|
      ref.send(:unused, self) if ref.respond_to?(:unused)
    end
  end
end


class CharArray < Array
  def initialize(str)
    @array = str.unpack("C*")  # Unpacks to integers
  end

  def each(&blk)
    @array.each(&blk)
  end

  def print_each
    each { |chr| p chr }
  end
end

p "****BEGIN TEST*****"

test = CharArray.new("abcde")
test.print_each   # Prints a list of integers (expected)

# A refinement which overwrites CharArray#each to return one-char strings
# instead of integers:
module CharArrayStr
  refine CharArray do
    def each
      super { |c| yield c.chr }
    end
  end
end

using CharArrayStr
puts "Calling test.each { |x| p x } "
test.each { |x| p x }  # Prints a list of strings
puts "Calling test.print_each"
test.print_each        # Prints a list of integers?! (or nothing, since refined methods can't take blocks yet!)

not_using CharArrayStr
p "****END TEST*****"
########## inline tests
if __FILE__==$PROGRAM_NAME
  require 'test/unit'
  class PureRubyRefinementsTest < Test::Unit::TestCase

    # test classes
    class TestMethodIntrospect; def whoa; end; def self.whoa_class; end; end

    class TestClassA; end
    class TestClassB < TestClassA; end

    # test setup
    module TimeExtensions
      refine Fixnum do
        def minutes; self * 60; end
      end
    end

    class MyApp
      using TimeExtensions

      def initialize
puts "Called MyApp.new and _active_refinements==#{self._active_refinements}"
        2.minutes
      end
    end

    module JSONGenerator
      refine String do
        def to_json; inspect end
      end

      refine Fixnum do
        def to_json; to_s end
      end

      refine Array do
        def to_json
          # Refinements can see one another, so we can use String#to_json and
          # Fixnum#to_json as part of the definition of Array#to_json.
          "[" + map{ |x| x.to_json }.join(',') + "]"
        end
      end
    end

    module SpaceExtensions
      refine Fixnum do
        def self.feet_per_mile; 5280; end
        def miles
          self.class.feet_per_mile*self
        end
        def minutes; self * -60; end
      end
    end

    def test_ruby_prereq_behavior
      # mainly for reference!
      assert !TestMethodIntrospect.singleton_methods.include?(:whoa)
      assert TestMethodIntrospect.singleton_methods.include?(:whoa_class)
      assert !TestMethodIntrospect.singleton_class.instance_methods.include?(:whoa)
      assert TestMethodIntrospect.singleton_class.instance_methods.include?(:whoa_class)
      assert TestMethodIntrospect.instance_methods.include?(:whoa)
      assert !TestMethodIntrospect.instance_methods.include?(:whoa_class)
      assert !TestMethodIntrospect.methods.include?(:whoa)
      assert TestMethodIntrospect.methods.include?(:whoa_class)
    end

    def test_class_cascadable_accessor
      Object.class_eval do
        class_cascadable_accessor :ref_test_access
      end
      assert Object.respond_to?(:ref_test_access)
      assert Object.new.respond_to?(:ref_test_access)
      Object.ref_test_access = [:this]
      assert_equal [:this], TestClassA.ref_test_access
      assert_equal [:this], TestClassA.new.ref_test_access
      TestClassA.ref_test_access = [:that]
      assert_equal [:that], TestClassA.ref_test_access
      assert_equal [:that], TestClassA.new.ref_test_access
      assert_equal [:this], Object.ref_test_access
      assert_equal [:this], Object.new.ref_test_access
      assert_equal [:that], TestClassB.ref_test_access

    end

    def test_refinements_dont_work_in_global_scope
      assert_equal [], Object._active_refinements
      assert_raise(NoMethodError){ 1.minutes }
    end

    def test_using_refinements_exist_in_a_block
      using TimeExtensions do
        assert_equal [TimeExtensions], self._active_refinements
      end
    end

    def test_refinements_work_in_a_block
      using TimeExtensions do
        assert_nothing_raised(NoMethodError) { 1.minutes }
        assert_equal 60, 1.minutes
      end
    end

    def test_refinements_dont_work_outside_a_block
      using(TimeExtensions){}
      assert_raise(NoMethodError) { 1.minutes }
    end

    def test_refinements_global_scoping
      using SpaceExtensions
      assert_equal 5280, 1.miles
      assert_nothing_raised(NoMethodError){ 4.minutes }
      not_using SpaceExtensions
      assert_raise(NoMethodError){ 1.miles }
    end

    def test_refinements_in_same_scope_see_each_other
      using JSONGenerator       # For the whole file
      assert_equal "[1,\"thing\"]", [1,'thing'].to_json
      not_using JSONGenerator
      assert_raise(NoMethodError){ [1,'thing'].to_json }
    end

    # WHY IS THIS PROBLEM SO HARD TO SOLVE?? argh
    def test_refinements_class_scoping
      assert_equal [], self._active_refinements
      assert_equal 120, MyApp.new
      assert_equal [], self._active_refinements
      assert_raise(NoMethodError){ 2.minutes }
    end

  end
end
