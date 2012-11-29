# encoding: utf-8

# Ruby Corner Cases
# A test suite/education tool to peer into the interesting nooks of Ruby
# and document them for myself.
# (as well as a way to prove they still work on future Rubies)

require 'test/unit'
class RubyInterestingFeaturesTest < Test::Unit::TestCase

  def test_splat_operator_usefulness
    assert_equal [1], [*1]
    assert_equal [1], [*[1]]
    a = *[1]
    assert_equal [1], a
    a = *1
    assert_equal [1], a
  end

  def test_case_whens_take_lambdas
    z = 0
    result = case z
      when lambda(&:odd?) then 'odd one'
      when lambda(&:zero?) then 'mark it zero dude'
    end
    assert_equal 'mark it zero dude', result
  end

  def test the case of the mysterious space
    assert_equal %w[ test the case of the mysterious space ], __method__.to_s.split(/ /)
    # it's a utf8 nonbreaking space, i.e. option-space on Macs.
    # And apparently, a legal character for Ruby names. Now go mess with people.
  end

end
