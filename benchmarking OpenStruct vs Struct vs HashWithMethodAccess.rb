require 'ostruct'
require 'benchmark'

rep = 400000

user_struct = Struct.new(:name, :age)

user_hwma = HashWithMethodAccess.new(HashWithMethodAccess.new)

user = "User".freeze
age = 21
hash = {:name => user, :age => age}.freeze

Benchmark.bm 20 do |x|

  x.report 'OpenStruct init' do
    rep.times do |index|
       OpenStruct.new(hash)
    end
  end
  x.report 'OpenStruct access' do
    o = OpenStruct.new(hash)
    rep.times do |index|
       o.name
       o.age
    end
  end
  x.report 'Struct init' do
    rep.times do |index|
       user_struct.new(user, age)
    end
  end
  x.report 'Struct access' do
    o = user_struct.new(user, age)
    rep.times do |index|
       o.name
       o.age
    end
  end
  x.report 'HWMA init' do
    rep.times do |index|
       HashWithMethodAccess.new(hash)
    end
  end

  x.report 'HWMA access' do
    o = HashWithMethodAccess.new(hash)
    rep.times do |index|
      o.name
      o.age
    end
  end

end
