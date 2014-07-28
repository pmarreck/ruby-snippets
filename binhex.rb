def bin_to_hex(s)
  s.unpack('H*').first
end

def hex_to_bin(s)
  [s].pack('H*')
end

p bin_to_hex(hex_to_bin('5acf456e9a3d')) #.unpack('C*')