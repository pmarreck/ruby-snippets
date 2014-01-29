# encoding: utf8

class MénageÀUn
  @fap={}
  def self.fap; @fap; end
  def self.fap=(o); @fap=o; end
  def self.inherited(c); raise StandardError, "class #{self} can't be inherited from"; end
  def self.new(*args); raise StandardError, "class #{self} can't be instantiated"; end
end unless defined? MénageÀUn
