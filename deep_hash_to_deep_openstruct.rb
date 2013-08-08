require_relative 'embedded_unit_tests'

require 'ostruct'
module HashToOpenstruct
  def to_ostruct
    o = OpenStruct.new(self)
    each.with_object(o) do |(k,v), o|
      o.send(:"#{k}=", v.to_ostruct) if v.respond_to? :to_ostruct
    end
    o
  end

  unit :to_ostruct do
    Hash.send(:include, HashToOpenstruct)
    @h = {a: {b: {'c' => 5}}}
    # @h.extend HashToOpenstruct
    assert_equal 5, @h.to_ostruct.a.b.c
    os=0; ObjectSpace.each_object(OpenStruct){|o| os+=1 }
    v = @h.to_ostruct.a.b.c
    osa=0; ObjectSpace.each_object(OpenStruct){|o| osa+=1 }
    assert_equal 3, osa - os
  end

end

########## inline tests
HashToOpenstruct.test if __FILE__==$PROGRAM_NAME

########## inline tests
# if __FILE__==$PROGRAM_NAME
#   require 'test/unit'
#   Hash.send(:include, HashToOpenstruct)
#   class HashToOpenstructTest < Test::Unit::TestCase
#     def setup
#       @h = {a: {b: {'c' => 5}}}
#     end
#     def test_to_openstruct
#       assert_equal 5, @h.to_ostruct.a.b.c
#     end
#     def test_object_generation_profile
#       os=0; ObjectSpace.each_object(OpenStruct){|o| os+=1 }
#       v = @h.to_ostruct.a.b.c
#       osa=0; ObjectSpace.each_object(OpenStruct){|o| osa+=1 }
#       assert_equal 3, osa - os
#     end
#   end
# end
