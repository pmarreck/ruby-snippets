class ImmutableHash < Hash
  def []=(k, v)
    puts "k is #{k}"
    puts "v being set to #{v}"
    super
  end
  def [](k)
    super.dup rescue super
  end
end

h = ImmutableHash.new

h[:a] = "hello"
puts h[:a].tap{|o| puts o.object_id }
puts h[:a].tap{|o| puts o.object_id }

h[:a] = ImmutableHash.new
oida = nil
oidb = nil
h[:a][:b] = "whoa"

p h

s = h[:a]
old_h = h
h[:a] = "bye"

puts "s is #{s}"
p h[:a]
p old_h
