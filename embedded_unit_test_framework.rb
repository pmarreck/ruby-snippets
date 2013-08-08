require_relative 'embedded_unit_tests'

module TestModule

  defn :new_method do |*args|
  	args.inject(:+)
  end
  unit :new_method do
  	o = self.class.new
  	assert_equal 6, o.new_method(1,2,3)
  end
  mock :new_method, Hash.new{ raise 'wtf' }.merge!([1,2,3] => 6)

  defn :adderdoubler do |*args|
    new_method(*args) * 2
  end
  unit :adderdoubler do
    assert_equal 12, adderdoubler(1,2,3)
  end
  mock :adderdoubler, Hash.new{ raise 'wtf' }.merge!(6 => 12)

end
