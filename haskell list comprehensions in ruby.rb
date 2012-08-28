
# taken from https://gist.github.com/3356675
ArrayPlaceholder = Array
module ListComprehension

  attr_accessor :stack
  attr_accessor :draws

  def initialize(*args)
    setup
    super(*args)
  end

  def setup
    @stack = []
    @draws = {}
  end

  def method_missing(*args)
    return if args[0][/^to_/]
    @stack << args.map { |a| a or @stack.pop }
    @draws[@stack.pop(2)[0][0]] = args[1] if args[0] == :<
  end

  def +@
    @stack.flatten!
    keys = @draws.keys & @stack
    draws = @draws.values_at *keys

    comp = draws.shift.product(*draws).map do |draw|
      @stack.map { |s| draw[keys.index s] rescue s }.reduce do |val, cur|
        op = Symbol === cur ? [:send, :method][val.method(cur).arity] : :call
        val.send op, cur
      end
    end

    @stack, @draws = [], {}
    Symbol === last ? comp.select(&pop) : comp
  end

  def -@
    case map(&:class).index Range
    when 0 then first.to_a
    when 1 then [first] + last.step(last.min.ord - first.ord).to_a
    else self
    end
  end

  def self.comprehend(&block)
    class << block
    # ListComprehension, Array, ArrayPlaceholder = ArrayPlaceholder, ListComprehension, Array
      def method_missing(*args)
        return if args[0][/^to_/]
        @stack << args.map { |a| a or @stack.pop }
        @draws[@stack.pop(2)[0][0]] = args[1] if args[0] == :<
      end

      class Array
        def +@
          @stack.flatten!
          keys = @draws.keys & @stack
          draws = @draws.values_at *keys

          comp = draws.shift.product(*draws).map do |draw|
            @stack.map { |s| draw[keys.index s] rescue s }.reduce do |val, cur|
              op = Symbol === cur ? [:send, :method][val.method(cur).arity] : :call
              val.send op, cur
            end
          end

          @stack, @draws = [], {}
          Symbol === last ? comp.select(&pop) : comp
        end

        def -@
          case map(&:class).index Range
          when 0 then first.to_a
          when 1 then [first] + last.step(last.min.ord - first.ord).to_a
          else self
          end
        end
      end
    end
    block.call if block_given?
      # ListComprehension, Array, ArrayPlaceholder = Array, ArrayPlaceholder, ListComprehension
  end

end

puts ListComprehension.comprehend { foo  =+ [x * y | x <- [1..3], y <- [4..6]] }
# [4, 5, 6, 8, 10, 12, 12, 15, 18]

# bar  =+ [a + b | a <- ['n','p'..'t'], b <- %w[a i u e o]]
# ["na", "ni", "nu", "ne", "no", "pa", "pi", "pu", "pe", "po", "ra", "ri", "ru", "re", "ro", "ta", "ti", "tu", "te", "to"]

# baz  =+ [i ** 2 / 3 | i <- [3,6..100], :even?]
# [12, 48, 108, 192, 300, 432, 588, 768, 972, 1200, 1452, 1728, 2028, 2352, 2700, 3072]

# quux =+ [s.size.divmod(2) | s <- %w[Please do not actually use this.]]
# [[3, 0], [1, 0], [1, 1], [4, 0], [1, 1], [2, 1]]

