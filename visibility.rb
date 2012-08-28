require 'active_support/inflector'

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

class Fixnum
  def test
    p CallChain.caller_name(resolve_classname: true)
    # eval 'p @how_can_i_see_this', b.binding
    # p b.binding.this
  end
end

module A
  class MyClass
    @how_can_i_see_this = 'hey'
    1.test
    def this_meth
      1.test
    end
  end
end

A::MyClass.new.this_meth

