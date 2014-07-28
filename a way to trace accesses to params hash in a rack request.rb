module NotifyWhen
  def notify_when(*meths, &callback)
    self.singleton_class.instance_eval do
      meths.each do |meth|
        alias_method "unnotified_#{meth}".to_sym, meth
        define_method(meth) do |*args, &block|
          callback.yield(*([meth, args, self][0..callback.arity]))
          send("unnotified_#{meth}", *args, &block)
        end
      end
    end
  end
  INTERESTING_RACK_KEYS = %w[ CONTENT_TYPE REQUEST_METHOD rack.methodoverride.original_method rack.request.query_string ]
  RACK_ENV_TRACING = lambda do |m, args, obj|
    if INTERESTING_RACK_KEYS.include? args[0]
      puts
      puts INTERESTING_RACK_KEYS.map{|k| "env[#{k}]==#{obj.send('unnotified_[]',k).inspect}"}.join("\n")
      puts "rack.request.form_input.eql? rack.input == #{obj.send('unnotified_[]','rack.request.form_input').eql? obj.send('unnotified_[]','rack.input')}"
      puts "On request.env, #{m} called with args #{args.inspect} from #{caller[2..3]}"
    end
  end
end

module Rack
  class Request
    alias untraced_params params
    def params
      puts "calling params from #{caller[0..2]}"
      untraced_params
    end
  end
end



# def call(env)

#   unless env.singleton_class.ancestors.include?(NotifyWhen)
#     puts "extending env with NotifyWhen"
#     env.extend NotifyWhen
#     env.notify_when(:[], :[]=, &NotifyWhen::RACK_ENV_TRACING)
#   end