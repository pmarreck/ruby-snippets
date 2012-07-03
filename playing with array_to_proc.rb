
class Array
	def to_proc
	  lambda do |m, *args|
	    self.map do |e| # self is the left-hand array, e is the element of it
        if Array===m
          if e.respond_to?(m.first)
            e.send(m, *args)
          end
        else
          m.send(e,*args)
        end
      end
	  end
	end
end

########## inline test running
if __FILE__==$PROGRAM_NAME
  require 'test/unit'
  class ArrayToProcTest < Test::Unit::TestCase

    def setup

    end

    def test_simple_method_mapping

    end

  end
end

puts ['12','23','34'].map(&[:to_i, :reverse]).inspect
puts [1,2,3].map(&[:to_s, [:+,5]])


