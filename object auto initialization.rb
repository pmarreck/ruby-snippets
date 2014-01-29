
# Some code that lets you quickly erect objects and their attributes with a params hash

# Most people just call this Struct, but this was written before I knew about it. lol

class InvalidAutoInitializeParamError < StandardError; end

class Object
  class << self
    alias new_without_auto_initialize new
    def new_with_auto_initialize(*args,&block)
      a1 = args.first
      o = new_without_auto_initialize
      if a1.class==Hash
        if o.respond_to?(:initialize_with_hash)
          a1.keys.each do |k|
            setter = (k.to_s << '=').to_sym
            if o.respond_to? k || o.respond_to?(setter) # for now, only allow keys that have accessors
              if o.respond_to?(setter)
                o.send(setter, a1[k])
              else
                o.instance_variable_set("@#{k}".to_sym, a1[k])
              end
            else # don't allow it
              raise InvalidAutoInitializeParamError, "The auto initialize parameter '#{k}' is not allowed for this object"
            end
          end
          if o.method(:initialize_with_hash).arity >= 1
            o.initialize_with_hash(*args, &block)
          else
            o.initialize_with_hash(&block)
            yield o if block_given?
          end
        end
      end
      o
    end
    alias new new_with_auto_initialize
  end
end

class Class
  def initialize_with_hash
    self.send(:define_method, :initialize_with_hash){}
  end
end

class A
  attr_reader :this, :that
  def initialize_with_hash
    p instance_variables
  end
end

class B
  attr_accessor :whoa_dude
  initialize_with_hash
end

a = A.new({this: 5, that: 10}){ |a| p a }

b = B.new(whoa_dude: 'yeah')

p b

#=> [:@this, :@that]
#=> #<A:0x007ff6c2884698 @this=5, @that=10>
#=> #<B:0x007ff6c2884288 @whoa_dude="yeah">



a = A.new({this: 5, that: 10, those: 7})
#=> The auto initialize parameter 'those' is not allowed for this object (InvalidAutoInitializeParamError)
