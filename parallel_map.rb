module Enumerable
  def pmap(method = :thread)
    case method
    when :thread
      threads = map do |elem|
        Thread.new { yield elem }
      end
      threads.map { |thread| thread.join.value }
    when :fork
      map do |elem|
        read, write = IO.pipe
        pid = fork do
          read.close
          result = yield elem
          Marshal.dump(result, write)
          exit!(0) # skips exit handlers.
        end
        write.close
        result = read.read
        Process.wait(pid)
        raise "child failed" if result.empty?
        Marshal.load(result)
      end
    end
  end
end

class Fixnum
  def factorial
    return 1 if self.zero?
    1.upto(self).inject(:*)
  end
end

# not sure if fork method works correctly yet...
p [123451, 232423, 113129, 104010, 195853, 186569, 157629].pmap(:fork){ |n| n.factorial }
