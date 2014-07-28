require 'ostruct'
require 'active_support/core_ext'

def booked?(date, events)
    events.any? { |event| (date >= event.booked_from && date <= event.booked_to) }
end

require 'test/unit'
class BookedTest < Test::Unit::TestCase

  def setup
    @events = []

    date1 = OpenStruct.new
    date2 = OpenStruct.new

    date1.booked_from = 1.month.ago
    date1.booked_to = 1.month.ago + 1.hour

    date2.booked_from = 2.weeks.ago
    date2.booked_to = 2.weeks.ago + 1.hour

    @events << date1
    @events << date2
  end

  def test_actually_booked
    setup
    assert booked?(1.month.ago + 30.minutes, @events)
  end

  def test_not_booked
    setup
    assert !booked?(3.months.ago, @events)
  end
end
