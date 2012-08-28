module Kernel
  alias original_binding binding
  def binding
    p self
    original_binding
  end
end

class Fixnum
  # def method_missing(meth, *args, &block)
  #   p meth
  #   p eval '@fantastic', binding
  #   p self.inspect
  #   super
  # end
  @context = 'hack'
  # def binding
  #   bnd = super()
  # end

  def minutes_with_context(&block)
    eval block, binding
  end
  def minutes
    eval 'p @context', binding
  end

end

@context = 5
5.minutes
