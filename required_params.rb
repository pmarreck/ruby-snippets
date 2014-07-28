class Hash
  def require_keys(*args)
    args.flatten.each do |arg|
      raise "Attribute #{arg.inspect} is required" unless self.key?(arg)
    end
  end
end

require 'active_support/core_ext'
class A
  def whoa(params) #params.require_keys([:one, :two])
    params.require_keys(:one, :two)
  end
end

a = A.new
a.whoa(one: 'a', two: 'b')
a.whoa(one: 'a')

# a.whoa