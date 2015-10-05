module Enumerable
  def recursive?(oids = {})
    if oids.key?(self.object_id)
      return true
    else
      oids[self.object_id] = 1
      return any?{ |v| v.recursive?(oids) if v.respond_to?(:recursive?) }
    end
    return false
  end
end

p [1,2,3,{a: 'b'}].recursive?

h = {}
h[0] = h
p h.recursive?

a = []
a << a
p a.recursive?
