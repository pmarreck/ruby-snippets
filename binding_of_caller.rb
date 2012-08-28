require 'continuation'

def Continuation.create(*args, &block)
  cc = nil
  result = callcc { |c|
    cc = c
    block.call(cc) if block and args.empty?
  }
  result ||= args
  return *[cc, *result]
end

def Binding.of_caller(&block)
  # old_critical = Thread.critical
  # Thread.critical = true
  count = 0
  cc, result, error = Continuation.create(nil, nil)
  error.call if error

  tracer = lambda do |*args|
    type, context = args[0], args[4]
    if type == "return"
      count += 1
      # First this method and then calling one will return --
      # the trace event of the second event gets the context
      # of the method which called the method that called this
      # method.
      if count == 2
        # It would be nice if we could restore the trace_func
        # that was set before we swapped in our own one, but
        # this is impossible without overloading set_trace_func
        # in current Ruby.
        set_trace_func(nil)
        cc.call(eval("binding", context), nil)
      end
#     elsif type != "line"
# p type
#       set_trace_func(nil)
#       error_msg = "Binding.of_caller used in non-method context or " +
#         "trailing statements of method using it aren't in the block."
#       cc.call(nil, lambda { raise(Exception, error_msg ) })
    end
  end

  unless result
    set_trace_func(tracer)
    return nil
  else
    # Thread.critical = old_critical
    yield result
  end
end

# def the_value_of_x
#   Binding.of_caller do |b|
#     eval "x", b
#   end
# end

# def main
#   x = 1
#   print "The value of x is ", the_value_of_x, "\n"
# end

# main

def inc_counter
  Binding.of_caller do |b|
    eval("counter += 1", b)
  end
  #              <--- line (A)
end
counter = 0
inc_counter
inc_counter
counter           # -> 2
