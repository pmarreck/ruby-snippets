class Eggtimer
  attr_accessor :minutes
  attr_accessor :message
  attr_accessor :beeps
  def initialize(mins = 5, msg="Time's up!", beeps=5)
    @minutes = mins
    @message = msg
    @beeps = beeps
  end
  def run
    sleep @minutes*60
    puts @message
    puts "\a"*@beeps # beeps
  end
end

et = Eggtimer.new(1)
et.run
