(1..100).map{|n| [f=(n%3).zero?,b=(n%5).zero?].any? ? "#{'Fizz' if f}#{'Buzz' if b}" : n}
