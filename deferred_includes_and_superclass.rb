# Problem: You want to be able to load a class without also having to load all its
# dependencies as a prerequisite, such as in a unit test

# test module

module BucketOMethods
  def hi
    puts 'hi'; 'hi'
  end
end

# Loading this class won't require its dependencies to load

# First trick is to (re)open inherited parent class on the fly
# If class D is later loaded from a file, C will still get its methods (later)
# If you need D's methods in a test upfront, then you will of course have to actually require it first
# but at least this gives you the opp to stub them out, if you don't

class C < (class D; self; end)

  # Second trick is to extend new instances with a module instead of including it here
  # so that it won't need to be required ahead of time just to load this class definition
  def include_modules
    extend BucketOMethods
  end

  def initialize(*args, &block)
    include_modules
    super
  end
end

C.new.hi
