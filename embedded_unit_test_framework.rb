require_relative 'embedded_unit_tests'

module TestModule

  def new_method(*args)
  	args.inject(:+)
  end
  unit :new_method, 'assert new_method adds its args' do |instance|
  	assert_equal 6, instance.new_method(1,2,3)
  end
  mock :new_method, [1,2,3] => 6, [1,2,3,-4] => 2

  def adderdoubler(*args)
    new_method(*args) * 2
  end
  unit :adderdoubler, 'assert adderdoubler method works with 3 args' do |instance|
    assert_equal 12, instance.adderdoubler(1,2,3)
  end
  unit :adderdoubler, 'assert ad works with negative args' do |instance|
    assert_equal 4, instance.adderdoubler(1,2,3,-4)
  end
  mock :adderdoubler, 6 => 12

  def adderquadrupler(*args)
    adderdoubler(*args) + adderdoubler(*args)
  end
  unit :adderquadrupler, 'assert adderquadrupler works' do |instance|
    assert_equal 24, instance.adderquadrupler(6)
  end

end

########## inline integrity check
TestModule.test if __FILE__==$PROGRAM_NAME