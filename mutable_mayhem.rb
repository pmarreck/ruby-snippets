# Observe:

class MyAwesomeToDos
  ALLOWED_THINGS = [:beer, :whiskey, :women, :clean_code]

  def initialize(params)
    @params = params
  end

  def allowed_things
    ALLOWED_THINGS
  end

  def allowed_things_with_extras
    allowed_things.concat([:sailing, :beaches, :biking])
  end

  def are_we_ok?
    allowed_things_with_extras.include?(@params[:what_i_did])
  end
end

td = MyAwesomeToDos.new(what_i_did: :sailing)

puts td.are_we_ok?

me = MyAwesomeToDos.new(what_i_did: :nothing)

puts me.are_we_ok?

she = MyAwesomeToDos.new(what_i_did: :sewing)

puts she.are_we_ok?

# now watch

p MyAwesomeToDos::ALLOWED_THINGS
