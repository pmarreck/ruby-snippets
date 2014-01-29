require 'ap'
require 'rails'
module QueueUtils
  def push_uniq!(*args)
    args.each do |e|
      self.push(e) unless self.include?(e)
    end
  end
  def unshift_uniq!(*args)
    args.each do |e|
      self.unshift(e) unless self.include?(e)
    end
  end
  def delete_first!(*args)
    args.each do |e|
      loc = self.index(e)
      self.delete_at(loc) if loc
    end
  end
  def delete_last!(*args)
    self.reverse!
    self.delete_first(*args)
    self.reverse!
  end
end

$LOAD_PATH.extend QueueUtils

ap $LOAD_PATH
