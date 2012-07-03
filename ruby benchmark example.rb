require 'benchmark'

def permute_array(a)
  1.upto(a.length - 1) do |i|
    j = rand(i + 1)
    a[i], a[j] = a[j], a[i]
  end
  a
end

alphabet = ('a'..'z').to_a #Array
biga = []
(1..10000).each do |x|
  biga << (alphabet[rand*26] + alphabet[rand*26] + alphabet[rand*26] + alphabet[rand*26] + alphabet[rand*26])
end

puts biga

Benchmark.bm(10) do |b|
  b.report("permute_array") { permute_array(biga) }
  b.report("sort_by") { biga.sort_by{rand} }
end
