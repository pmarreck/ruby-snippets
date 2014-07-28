module Enumerable
  def many?
    if block_given?
      self.count{|e| yield e}.to_f/self.size >= 0.8
    else
      self.select{|e| e}.size > 15
    end
  end
  def several?
    es = self.select{|e| e}.size
    es > 3
  end
  def couple?
    es = self.select{|e| e}.size
    es > 1 && es < 6
  end
  alias few? couple?
  alias handful? couple?
end

puts [true, true, true, true, false].many?
puts (1..20).to_a.many?

puts [1, 2, 3, false, false].few?
puts [1,2,3,4].several?
