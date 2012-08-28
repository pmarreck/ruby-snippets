require 'delegate'

class Fixnum
  attr_accessor :meta
end

class Meta < SimpleDelegator
  def __getobj__
    super.call
  end
end

5.meta = Meta.new( lambda{ Time.now } )

puts 5.meta

puts ObjectSpace._id2ref(11).inspect

# puts 5.methods

OldFixnum = Fixnum

class NewFixnum < SimpleDelegator
  def __getobj__
    puts "You just accessed the number: #{self}"
    super
  end
end
Fixnum = NewFixnum

puts 5

