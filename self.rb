class Ziffy
  def hihi
    p self.inspect
    -> { p self.inspect }
  end

  def hoho(block)
    yield block if block_given?
  end
end

x = Ziffy.new

x.hoho x.hihi
