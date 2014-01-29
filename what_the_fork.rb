# what the fork

# forking/threading/IO playground:

puts RUBY_VERSION

exit_status_success = true
PIDS = []
pid=fork do #Process.spawn("for i in {1..100000}\ndo\necho $i\ndone\necho 'first done'")
  puts `sleep 3; echo "first done"`
  exit_status_success &= $?.success?
  PIDS.delete(pid)
  exit
end
PIDS << pid
pid=fork do #Process.spawn("for i in {1..200000}\ndo\necho $i\ndone\necho 'second done'")
  puts `sleep 6; echo "second done"`
  exit_status_success &= $?.success?
  PIDS.delete(pid)
  exit
end
PIDS << pid
pid=fork do #Process.spawn("for i in {1..300000}\ndo\necho $i\ndone\necho 'third done'; exit 1")
  puts `sleep 9; echo "third done"; exit 1`
  exit_status_success &= $?.success?
  PIDS.delete(pid)
  exit 1
end
PIDS << pid
# else
  # loop { break if PIDS.length == 0 }
p PIDS
  retvals = Process.waitall
  puts "I'm done; exit status: #{exit_status_success}"
  p retvals
# end
