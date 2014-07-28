module KlassMocks
  def a
    puts "mock of a"
  end
  def b(*args)
    puts "mock of b, args: #{args}"
  end
  def c
    puts "mock of c"
    a
  end
end

class Klass
  def a
    puts 5
  end
  def b(*args)
    args.inject(:+)
  end
  def c
    puts "original c"
    a
  end
end

class Klass
  alias a_backup a
end
k = Klass.new
k.instance_eval do
  alias c_original c
end
k.extend KlassMocks
k.instance_eval do
  # alias c c_original
end
class << k
  alias c c_original
  remove_method :c_original
end

k.c
# k.c_original # this will raise, expectedly