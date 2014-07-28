# ruby linked list as array

class LinkedList < Array
  alias_method :next, :last
  alias_method :original_append, :<<
  class << self
    alias_method :new, :[]
  end
  def <<(o)
    if self.next.is_a?(LinkedList)
      # insert in the middle
      original_next = nil
      if o.is_a?(LinkedList)
        if o.length==2
          original_next = self.next
          self[-1] = o
        else
          self.original_append(o)
        end
      else
        if o.length==2
          original_next = self.next
          self[-1]=self.class.new(o)
        else
          self.original_append(self.class.new(o))
        end
      end
      self.next.original_append(original_next) if original_next
    else
      self.original_append(self.class.new(o))
    end
  end

end

class CircularLinkedList < LinkedList
  def join(o)

  end
end

########## inline tests
if __FILE__==$PROGRAM_NAME
  require 'test/unit'
  class LinkedListTest < Test::Unit::TestCase
    def test_linked_list_usage
      ll = LinkedList.new(4)
p ll
      assert_equal LinkedList, ll.class
      ll << 5
p ll
      assert_equal 5, ll.next.first

      ll << LinkedList.new(6)
p ll
      ll.next << ll
p ll
      assert_equal 4, ll.next.next.first
    end

  end
end
