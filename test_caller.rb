require 'ap'

class Thisthing
  def hey(&block)
    if block_given?
      y = yield
      if (y.is_a? Symbol) || (y.is_a? String) || (y.is_a? Class)
        c = y
      elsif y
        c = y.class
      else
        c = (eval 'self', block.binding).class
      end
      ap c
    else
      ap caller.first
    end
  end
end

class Tryit
  def go
    t = Thisthing.new
    t.hey {}
  end
end
a = Tryit.new

a.go
