class Hash

  def deepest(opts={}, maxdepth=nil)
    d = opts.delete(:maxdepth)
puts "d = #{d}" if d
    maxdepth ||= d || 25
puts maxdepth
    deeper = self.values.first
    if deeper.is_a? Hash
      deeper.deepest(opts, maxdepth)
    else
      deeper
    end
  end
end

h = {a: {b: {c: {d: 5}}}}

puts h.deepest(maxdepth: 5)
