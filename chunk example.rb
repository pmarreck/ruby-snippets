open("/usr/share/dict/words", "r:iso-8859-1") do |f|
  f.chunk do |line|
    line.capitalize.ord
  end.each do |ch, lines|
    p [ch.chr, lines.length]
  end
end
