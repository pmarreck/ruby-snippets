# to_proc fun

# inspired by http://rbjl.net/29-become-a-proc-star

class Array
  def to_proc
    ->(obj){ obj.send *self }
  end
end

class Regexp
  def to_proc
    ->(e){ e.to_s[self] }
  end
end

class Class
  def to_proc
    ->(*args){ self.new *args }
  end
end

class Hash
  def to_proc
    ->(obj){ self.key?(obj) ? self[obj].to_proc.call(obj) : obj }
  end
end

p [1,2,3].select(&[:>, 1])

p [1,2,3,4,5].map &{ 1 => :to_s, 3 => [:to_s, 2] } # if you use Array#to_proc

