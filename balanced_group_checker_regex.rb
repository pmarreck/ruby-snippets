require 'test/unit'

module RubyRegexMeister
  BALANCED_GROUP_CHECKER = /(
    (?<non_grouping_char>
      [^\(\{\[\<\)\}\]\>\"]
    ){0}
    (?<double_quoted_group>
      \" \g<content> \"
    ){0}
    (?<single_quoted_group>
      \' \g<content> \'
    ){0}
    (?<parens_group>
      \( \g<content> \)
    ){0}
    (?<brackets_group>
      \[ \g<content> \]
    ){0}
    (?<chevrons_group>
      \< \g<content> \>
    ){0}
    (?<braces_group>
      \{ \g<content> \}
    ){0}
    (?<balanced_group>
      (?>
        \g<parens_group>   |
        \g<brackets_group> |
        \g<chevrons_group> |
        \g<double_quoted_group> |
        \g<single_quoted_group> |
        \g<braces_group>
      )
    ){0}
    (?<content>
      (?> \g<balanced_group> | \g<non_grouping_char> )*
    ){0}
    \A \g<content> \Z
  )/uix
end

class YouSayImpossibleISayBullshitTest < Test::Unit::TestCase
  include RubyRegexMeister

  def test_simple_match
    assert BALANCED_GROUP_CHECKER.match('(things) or not'), "simple parens did not match. you really broke it bad"
  end

  def test_nested_different_groups
    assert BALANCED_GROUP_CHECKER.match('some (things that [are grouped] sometimes) or not'), "different nested groups failed"
  end

  def test_unbalanced_group
    assert_nil BALANCED_GROUP_CHECKER.match('this( is unbalanced'), "stop matching unbalanced shit man"
  end

  def test_wrong_matching_close_group
    assert_nil BALANCED_GROUP_CHECKER.match('this( is matched] wrong'), "matching on wrong characters"
  end

  def test_sequential_groups
    assert BALANCED_GROUP_CHECKER.match('here (is one group) and (here is another) and (watch this), [you\'re gonna love] {my nuts}')
  end

  def test_very_tight_groups
    assert BALANCED_GROUP_CHECKER.match('({}) so tight'), "loosen this up, man"
  end

  def test_intersecting_groups_no_match
    assert_nil BALANCED_GROUP_CHECKER.match('(So I started [ and then I jizzed) my pants]'), "Matching on intersecting groups, you kinky bastard"
  end

  def test_quoted_groups
    assert BALANCED_GROUP_CHECKER.match('"some email" <some@email.com>'), "Quoted strings match"
  end

  def test_many_nests_bitches_many_nests
    ridiculous_test_string = 'this( [shit] is (matched(well[({moof})]),) whoa,{} right?)'
    assert BALANCED_GROUP_CHECKER.match(ridiculous_test_string), "admittedly, that was pretty hard to pull off"
  end

end
