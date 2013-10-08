require 'matrix'

class PolynomialRegression

  attr_accessor :x, :y, :deg

  def initialize x, y, degree
    @x, @y, @deg = x, y, degree
  end

  def regress
    x_data = @x.map { |xi| (0..@deg).map { |pow| (xi**pow).to_f } }

    mx = Matrix[*x_data]
    my = Matrix.column_vector(@y)

    ((mx.t * mx).inv * mx.t * my).transpose.to_a[0]
  end

end

########## inline tests
if __FILE__==$PROGRAM_NAME
  require 'test/unit'
  class PolynomialRegressionTest < Test::Unit::TestCase
    def setup
      @x = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
      @y = [1, 6, 17, 34, 57, 86, 121, 162, 209, 262, 321]
      @deg = 2
    end
    def test_basic_2_degree_regression
      assert_equal [1, 2, 3], PolynomialRegression.new(@x, @y, @deg).regress.map(&:to_i)
    end
    def test_5_degree_regression
      @deg = 5
      assert_equal [1, 1, 3, 0, 0, 0], PolynomialRegression.new(@x, @y, @deg).regress.map(&:to_i)
    end
  end
end
