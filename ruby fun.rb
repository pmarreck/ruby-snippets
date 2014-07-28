# fun ruby stdobj hacks


class Array
  def ~
    self.sort_by{rand}
  end
end

class String
  def to_a
    self.split(//)
  end
end


p ~('peter'.to_a)

