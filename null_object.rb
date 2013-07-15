class NullObject
  def method_missing(*args)
    self
  end
  def initialize
  	@origin = caller.first
  end
  def nil?; true; end
end

def Maybe(value)
  value.nil? ? NullObject.new : value
end

foo = nil
p Maybe(foo).bar.baz + 5
p NullObject.new || 5
p Maybe(nil).downcase.strip.tr_s('^a-z0-9', '-')