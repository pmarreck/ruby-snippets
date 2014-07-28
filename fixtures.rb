module RaiseOnMutation
  MutationError = Class.new(StandardError)
  def save(*args);                raise MutationError.new "#{__method__} not allowed with this object"; end
  def save!(*args);               raise MutationError.new "#{__method__} not allowed with this object"; end
  def update_attribute(*args);    raise MutationError.new "#{__method__} not allowed with this object"; end
  def update_attributes(*args);   raise MutationError.new "#{__method__} not allowed with this object"; end
  def update_attributes!(*args);  raise MutationError.new "#{__method__} not allowed with this object"; end
  def update_column(*args);       raise MutationError.new "#{__method__} not allowed with this object"; end
  def []=(*args);                 raise MutationError.new "#{__method__} not allowed with this object"; end
  def reload(*args);              raise MutationError.new "#{__method__} not allowed with this object"; end
  def increment(*args);           raise MutationError.new "#{__method__} not allowed with this object"; end
  def increment!(*args);          raise MutationError.new "#{__method__} not allowed with this object"; end
  def decrement(*args);           raise MutationError.new "#{__method__} not allowed with this object"; end
  def decrement!(*args);          raise MutationError.new "#{__method__} not allowed with this object"; end
  def delete(*args);              raise MutationError.new "#{__method__} not allowed with this object"; end
  def destroy(*args);             raise MutationError.new "#{__method__} not allowed with this object"; end
  def toggle(*args);              raise MutationError.new "#{__method__} not allowed with this object"; end
  def toggle!(*args);             raise MutationError.new "#{__method__} not allowed with this object"; end
  def touch(*args);               raise MutationError.new "#{__method__} not allowed with this object"; end
end

require "factory_girl_rails"
class FROZEN_FACTORIES
  def self.cache
    @cache ||= {}
  end
  def self.[](k)
    self.cache[k] ||= FactoryGirl.create(k).tap{|fg| fg.extend(RaiseOnMutation)}.freeze
  end
end
