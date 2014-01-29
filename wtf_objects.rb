
class A
  def hi
    puts 'original method'
    'original method'
  end
end

module B
  def hi
    puts 'module method'
    'module method'
  end
  def bye
    puts 'module method bye'
    'module method bye'
  end
end

A.new.hi

class A
  include B
end

A.new.hi

A.new.bye

module C
  def self.included(base)
    base.instance_eval do
      old_hi = instance_method(:hi)

      define_method(:hi) do
        h = old_hi.bind(self).() + ' + New Behavior'
        puts h
        h
      end
    end
  end
end

A.send(:include,C)

A.new.hi

module Redef
  def self.included(base)
    base.instance_eval do
      def self.redef(meth,&redefine_block)
        self.instance_eval do
          eval("_old_#{meth} = instance_method(:#{meth})")
          define_method(meth) do
            eval("yield _old_#{meth}.bind(self).()")
          end
        end
      end
    end
  end
end


A.new.bye

class A
  include Redef
  redef :bye do |orig_bye|
    o = orig_bye + ' plus fancy redef'
    puts o
    o
  end
end

A.new.bye

