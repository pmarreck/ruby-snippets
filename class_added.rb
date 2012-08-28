class Stack
  @max_stack_size = 25
  @current = nil
  def self.stack
    @stack ||= []
  end
  def self.max_stack_size
    @max_stack_size ||= 25
  end
  def self.max_stack_size=(s)
    @max_stack_size = s.to_i
  end
  def self.push(o)
    stack.push(o)
    @current = o
    truncate_stack_if_necessary
    stack
  end
  def self.pop(num=nil)
    @current = (num ? stack[-(1+num)] : stack[-2])
    # have to do this wackiness since [].pop(1)==[] but [].pop==nil
    num ? stack.pop(num) : stack.pop
  end
  def self.peek(num=nil)
    num ? stack.last(num) : @current
  end
  def self.include?(e)
    stack.include? e
  end
  class << self
    alias current peek
    def truncate_stack_if_necessary
      if stack.length > max_stack_size
        @stack = stack.last(max_stack_size)
      end
    end
  end
end

class ClassDefinitionStack < Stack
end

class TraceFunctionStack < Stack
  def self.pop(*args)
    super(*args)
    set_trace_func_without_stack current
  end
  def self.push(*args)
    super(*args)
    set_trace_func_without_stack current
  end
end

# make set_trace_func work with a stack when there's a block given
module Kernel
  unless instance_methods.include?(:set_trace_func_with_stack)
    alias set_trace_func_without_stack set_trace_func
    def set_trace_func_with_stack(pr = nil)
      if block_given?
        TraceFunctionStack.push(pr)
        yield
        TraceFunctionStack.pop
      else
        if pr == nil
          TraceFunctionStack.pop
        else
          TraceFunctionStack.push(pr)
        end
      end
    end
    alias set_trace_func set_trace_func_with_stack
  end
end

# provide a callback when a class is opened or closed

# provides 'started' and 'ended' event callbacks for class definitions
# (Sorta. The 'ended' event is kind of a hack. Suggestions to better it, welcome.)
class ::Class

  TRACE_NEXT_END_PROC = ->(*args) do
    if args[0]=="end"
      if (c=ClassDefinitionStack.pop) && c.respond_to?(:ended)
        c.ended
      end
      set_trace_func nil
    end
  end
  TRACE_NEXT_RETURN_PROC = ->(*args) do
p args
    if args[0]=="return" # && args[3]==__method__.to_sym
p __method__.to_sym
      set_trace_func nil
    end
  end
  alias inherited_without_callbacks inherited
  def inherited_with_callbacks(klass)
    klass.started if klass.respond_to?(:started)
    ClassDefinitionStack.push(klass)
    inherited_without_callbacks(klass)
    set_trace_func(TRACE_NEXT_END_PROC)
  end
  alias inherited inherited_with_callbacks

  def started
    puts "started #{self}"
  end

  def ended
    puts "ended #{self}"
  end

  def instance_created(o)
    puts "Creating a new #{self}"
  end

  alias new_without_instance_created_callback new
  def new_with_instance_created_callback(*args,&block)
    n = new_without_instance_created_callback(*args,&block)
    self.instance_created(n) if self.respond_to?(:instance_created)
    n
  end
  alias new new_with_instance_created_callback
end

# class Module
#   alias method_added_without_callbacks method_added
#   def method_added_with_callbacks(name)
#     method_added_without_callbacks(name)
# puts "Added method #{name}"
#     set_trace_func(Class::TRACE_NEXT_RETURN_PROC)
#   end
#   alias method_added method_added_with_callbacks
# end


module MyModule
  class Whoa
    class Inner
      def self.ended
        puts "HEY I ENDED THE #{self} CLASS!"
      end
      puts "inside MyModule::Whoa::Inner"
    end
    puts "inside MyModule::Whoa"
  end
  class Hey; end
end

module Namespace
  class Thing
  end
end

a = 5
class Thing
  def self.closed
    p "closed #{self} (inside Thing)"
  end
  puts "about to define messymeth"
  def messymeth
    set_trace_func(Class::TRACE_NEXT_RETURN_PROC)
    puts "inside messymeth"
  end
  puts "just defined messymeth"
end

Thing.new.messymeth

class Ding; end

module Bing

end

class Wing; end

boing = Class.new

w = Wing.new


########## inline tests
if __FILE__==$PROGRAM_NAME
  # give Class started and ended methods so the events always fire
  class ::Class
    def started; end
    def ended; end
    def instance_created(o); end
  end
  require 'test/unit'
  require 'mocha'
  class ClassAddedTest < Test::Unit::TestCase
    def test_class_creation_callback_started_and_ended
      # Tricky to put an expectation on a class that doesn't exist yet...
      Class.any_instance.expects(:started)
      Class.any_instance.expects(:ended)
      eval <<-BREAKIN_THE_LAW
        class ::Testes
        end
      BREAKIN_THE_LAW
    end
    def test_instance_creation_callback
      String.expects(:instance_created)
      String.new
    end

    def method_started_callback

    end
  end
end