# A futile attempt to do "math" via the cleverest regex I could come up with.

class String
  def prev
    (ord-1).chr
  end
  def carry!
puts "called carry! with #{self}"
    return self unless self =~ /2/
# p match(/(.?)(2)/)
    gsub!(/(.?)(2)/, "#{$1 ? $1.succ : '1'}#{$2 ? $2.prev : 'wtf'}")
    carry!
  end

  def add_1_binary
    succ!
    carry!
  end
end

ADD_1 = /[01]$/
CARRY = /(.?)(2)/

p '0'.gsub(ADD_1){|c| c.succ }
p '1'.gsub(ADD_1){|c| c.succ }

p '02'.gsub(CARRY){|c| $1.succ + '0' }
p '12'.gsub(CARRY){|c| $1.succ + $2.prev }

p '011'.add_1_binary
