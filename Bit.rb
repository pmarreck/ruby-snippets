#!/usr/bin/env ruby
# Bit: A class to assist with doing fixed-bit operations

require 'rubygems'
require 'inline'

class Bit
  # first param is the total size in bits, nth params set the nth bits to true to start (if you want)
  def initialize(size=16, *bits)
    @bitarray = []
    @number = 0
    @size = size
    @bitarray[size-1] ||= nil
    set bits if bits # note: this puts the bits array into another array (see below)
  end

  # sets a bunch of bits
  def set(*bits)
    #this hack is needed if you're passing in an array already from initialize, since it's wrapped in an array too
    bits = bits[0] if bits[0].class == Array
    bits.each do |n|
      n = n % (@size-1) if n > (@size-1)
      unless @bitarray.at(n-1)
        @bitarray[n-1]=1
        recalcnumber(n-1,true)
      else
        return nil if bits.size==1
      end
    end
  end
  
  def unset(*bits)
    #this hack is needed if you're passing in an array already from initialize, since it's wrapped in an array too
    bits = bits[0] if bits[0].class == Array
    bits.each do |n|
      n = n % (@size-1) if n>(@size-1)
      if @bitarray.at(n-1)
        @bitarray[n-1]=nil
        recalcnumber(n-1,false)
      else
        return nil if bits.size==1
      end
    end
  end
  
  def get(n)
    if @bitarray.at(n-1)
      true
    else
      false
    end
  end
  
  def number
    @number
  end
  
  def number=(num)
    if num<2**@size
      @number = num
    else
      @number = num & ((2**@size)-1) 
    end
    recalcbitarray
  end
  
  def bitstring
    str=""
    0.upto(@size-1) do |b|
      @bitarray.at(b) ? str << "1" : str << "0"
    end
    str.reverse
  end
  
  def bitarray
    ary = []
    0.upto(@size-1) do |b|
      @bitarray.at(b) ? ary << 1 : ary << 0
    end
    ary.reverse.inspect
  end
  
  def to_s
    bitarray
  end

  # counts the true bits. if you pass in false, counts the false bits
  def count_bits(typ=true)
    if typ
      @bitarray.nitems
    else
      @bitarray.clone.delete_if {|b| b==1}.length
    end
  end
  
  # rotates bits. wraps around
  def <<(places)
    places.downto(1) do
      @bitarray.unshift(@bitarray.at(@size-1))
      @bitarray[@size]=nil
      @number*=2
      @number+=(1-2**@size) if @bitarray.at(0)
    end
    #recalcwholenumber
  end

  # rotates bits. wraps around
  def >>(places)
    places.downto(1) do
      @bitarray[@size-1] = @bitarray.shift
      @number/=2
      @number+=2**(@size-1) if @bitarray.at(@size-1)
    end
    #recalcwholenumber
  end
  
  # between you and me, the following is classic cool as hell Ruby
  def | bit
    oper :|, bit
  end
  
  def & bit
    oper :&, bit
  end
  
  def ^ bit
    oper :^, bit
  end

private

  #the following method handles the |, &, and ^ operations in one shot (see above)
  def oper(op,bit)
    out = Bit.new(@size)
    case bit
    when Fixnum,Bignum
      out.number = @number.send(op,bit)
    when Bit
      out.number = @number.send(op,bit.number)
    else
      raise "Wrong type passed to #{op} for Bit, got " + bit.class.to_s
    end
    out
  end
  
  def recalcnumber(n,set)
    if set
      @number += 2**n
    else
      @number -= 2**n
    end
  end
  
  #not used currently
  def recalcwholenumber
    @number = 0
    0.upto(@size-1) do |i|
      @number += 2**i if @bitarray.at(i)
    end
  end
  
  def recalcbitarray
    place = 0
    @number.to_s(2).reverse.each_byte do |b|
      b==49 ? @bitarray[place]=1 : @bitarray[place]=nil
      place+=1
    end
    place.upto(@size-1) {|b| @bitarray[b]=nil}
  end
  
  inline(:Ruby) do |builder|
      (self.methods - Object.methods).each {|meth| builder.optimize meth.to_sym }
  end
end

b = Bit.new(8,5)
puts b
puts b.number
b.set(7)
puts b.number
b.number=81
puts b
bits = Bit.new(16,16)
bits.set(8)
puts bits.get(17)
puts bits.set(8)
puts bits.number
puts bits
c = Bit.new()
c.number = b.number + bits.number
puts "c = " + c.to_s
c.set(255)
c >> 2
puts "c = " + c.to_s
puts c.number
puts c.count_bits
puts c.count_bits(false)
d = Bit.new(5)
d.set(1)
puts d.number
d << 1
puts d.number
d >> 2
puts d.number
puts d
e = Bit.new(8)
e.set(1)
puts e
puts e.number
e >> 2
puts e
puts e.number
e << 4
puts e
puts e.number
e.number=42
puts e.bitstring
puts e.class
puts d
puts e
puts d & e 
e.number = 1125
e << 1
puts e
a=Bit.new(16)
a.number="0xFF".to_i(16)
puts a
g = Bit.new(16)
h = Bit.new(16)
g.set(1,2,3)
puts g
h.set(2,3,6)
puts h
puts g ^ h

test = Bit.new(256)
1.upto(4000) do |iter|
 test = test ^ (2**(rand(256)))
 puts "#{iter}   #{test.count_bits}  #{test.bitstring}"
end