# So you want to find out what is messing with your object somewhere deep in your stack...
# Behold, your on-the-fly tracer...

module NotifyWhen
  def notify_when(*meths, &callback)
    class << self; self; end.instance_eval do
      meths.each do |meth|
        alias_method "unnotified_#{meth}".to_sym, meth
        define_method(meth) do |*args, &block|
          callback.yield(*([meth, args, self][0..callback.arity]))
          send("unnotified_#{meth}", *args, &block)
        end
      end
    end
  end
end


h = {} # can be any object
h.extend NotifyWhen
h.notify_when(:[], :[]=){|m, args| puts "#{m} was called with args #{args}"}

h[5] = 'five'
h[5]
h[6]

# []= was called with args [5, "five"]
# [] was called with args [5]
# [] was called with args [6]


# so the idea is we define that somewhere and then do:
# alert whenever params key is set
request.params.extend NotifyWhen
request.params.notify_when(:[]=){|m, args, obj| puts "params key #{args[0]} modified to be #{args[1]} from #{caller[0..2]}" }
# alert whenever params is called off request or set to a new value
request.extend NotifyWhen
request.notify_when(:params, :params=){|m, args, obj| puts "params called from #{caller[0..2].inspect}"}

env.extend NotifyWhen
env.notify_when(:[], :[]=){|m, args, obj| puts "On request.env['rack.request.form_hash'], #{m} called with args #{args.inspect} from #{caller[0..3]}"}

