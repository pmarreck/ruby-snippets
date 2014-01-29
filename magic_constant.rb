# Method calls to self.CapitalizedMethod which are not defined will first try to get a constant named that from the current
# scope or the class scope, allowing you to stub it easily

module FindAConstantMethod
  def method_missing(m, *args, &block)
    if m.to_s =~ /^[A-Z]/
      parts = m.to_s.split('__')
      start_scope = Module.constants.include?(parts.first.to_sym) ? Module : (Class===self ? self : self.class)
      parts.inject(start_scope){ |ns, c| ns.constants.include?(c.to_sym) ? ns.const_get(c.to_sym) : super }
    else
      super
    end
  end
end

module Namespaced
  class Lass
  end
end

class MagicClass
  class AnotherLocalConst; end
  include FindAConstantMethod
  extend FindAConstantMethod

  def here?
    self.Namespaced__Lass
  end
  def there?
    self.Abbacadabra
  end
  def another?
    self.AnotherLocalConst
  end
  def self.class_level?
    self.Namespaced__Lass
  end
end

puts MagicClass.new.here?

begin
  puts MagicClass.new.there?
rescue => e
  puts "Undefined constants still raise properly" if ((e.message =~ /undefined method `Abbacadabra'/) != nil)
end

puts MagicClass.new.another?

puts MagicClass.class_level?
