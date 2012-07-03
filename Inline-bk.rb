module Inline
  require 'rubygems'
  require 'inline'
  class Ruby < Inline::C
    def initialize(mod)
      super
    end

    def optimize(meth)
      src = RubyToC.translate(@mod, meth)
      @mod.class_eval "alias :#{meth}_slow :#{meth}"
      @mod.class_eval "remove_method :#{meth}"
      c src
    end
  end
end