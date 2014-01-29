
NAME_SPLITTER_REGEX = /^
  (?<name>[^\s,]+){0}
  (?<name_spaced>\g<name>(?:\s\g<name>)*){0}
  \s*
  (?:
    (?<first_name>\g<name>)
  |
    (?<first_name>\g<name>)\s*(?<last_name>\g<name_spaced>)
  |
    (?<last_name>\g<name_spaced>)\s*,\s*(?<first_name>\g<name_spaced>)
  )
  \s*
$/uix

########## inline tests
if __FILE__==$PROGRAM_NAME
  require 'test/unit'
  class NameMatcherTest < Test::Unit::TestCase
    def test_name_matching
      regex = NAME_SPLITTER_REGEX
      examples = [
        [" Peter ", "Peter", nil],
        [" Peter Marreck ", "Peter", "Marreck"],
        [" Marreck, Peter ", "Peter", "Marreck"],
        [" Marreck, Peter Robert ", "Peter Robert", "Marreck"],
        ["  Peter Robert Marreck ", "Peter", "Robert Marreck"],
        [" Robert Marreck, Peter ", "Peter", "Robert Marreck"]
      ]

      matches = nil
      examples.each do |example, expected_first, expected_last|
        matches = regex.match(example)
        assert_equal expected_first, matches[:first_name]
        assert_equal expected_last, matches[:last_name]
      end

    end
  end
end