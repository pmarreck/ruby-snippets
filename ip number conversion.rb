class Integer
  def to_ip_ary
    [self].pack("N").unpack("C*")
  end
  def to_ip
    to_ip_ary.join(".")
  end
end

class Array
  def to_ip_num
    #(0..3).inject(0){|acc,i| acc + (self[i] << (24 - (8 * i)))}
    self.pack("C*").unpack("N")[0]
  end
end

class String
  def to_ip_num
    self.split(".").map!{|v| v.to_i}.to_ip_num
  end
end

n = "127.0.0.1".to_ip_num
puts n

puts n.to_ip_ary.inspect

puts n.to_ip
