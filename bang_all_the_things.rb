# bang_all_the_things

# An opinionated take on mutation readability.
# Drop this into a lib directory, and from now on, use the bang version of the
# methods that mutate the receiver.
# Instantly improved code readability! So simple, so easy. So... Ruby.

# NOTE: Wasn't sure what to do with the []= method, if anything.

module Enumerable
  # it has no mutating methods that don't end in a bang!
end

class Hash
  # alias []= []=
  alias clear!     clear
  alias delete!    delete
  alias delete_if! delete_if
  alias keep_if!   keep_if
  alias rehash!    rehash
  alias replace!   replace
  alias shift!     shift
  alias store!     store
  alias update!    update
end

class Array
  # alias []= []=
  alias append!    <<
  alias clear!     clear
  alias delete!    delete
  alias delete_at! delete_at
  alias delete_if! delete_if
  alias fill!      fill
  alias keep_if!   keep_if
  alias pop!       pop
  alias push!      push
  alias replace!   replace
  alias shift!     shift
  alias unshift!   unshift
end

# This only works if you call it like so:
# a.[]= 0, 5
class ImmutableArray < Array
  def []=(*args)
    orig = dup
    super
    mutated = dup
    replace(orig)
    mutated
  end
end
