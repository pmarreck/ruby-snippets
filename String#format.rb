require_relative 'embedded_unit_tests'

class String

  def format(*args)
    super(self, *(args.flatten))
  end

  unit :format do
    nub = stub(format: '')
    assert_equal '2.00', '%.2f'.format(2.00001)
    assert_equal '1.00 3.00', '%.2f %.2f'.format([1.004, 3.0023])
    assert_equal '1.00 3.00', '%.2f %.2f'.format(1.004, 3.0023)
    assert_equal '', nub.format
  end
end

########## inline tests
String.test if __FILE__==$PROGRAM_NAME
