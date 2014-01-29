# trying to log object allocation

class Class
  alias new_without_log new
  def new_with_log(*args, &block)
    x = new_without_log(*args, &block)
    x.after_init if x.respond_to?(:after_init)
  end
  alias new new_with_log

  alias allocate_without_log allocate
  def allocate_with_log
    x = allocate_without_log
    p x
  end
  alias allocate allocate_with_log
end

class Object
  def after_init
    puts "Hey! You just made a new #{self.class} with object ID #{self.object_id} !"
  end
end
