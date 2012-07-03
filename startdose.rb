require 'active_support'

class Halflife
  def initialize(params = {})
    params = {
      half_life_in_hours: 12,
      dosage_every: 24,
      days_later: 14
    }.merge(params)
    start_dose = 1.0
    how_much_left = 0.0
    params[:days_later].times do |day|
      start_dose = how_much_left + 1.0
      puts "Starting day #{day} with #{start_dose} dose."
      how_much_left = start_dose/(2**(params[:dosage_every] / params[:half_life_in_hours]))
      puts "After day #{day} there is #{how_much_left} left."
    end
  end
end

Halflife.new
