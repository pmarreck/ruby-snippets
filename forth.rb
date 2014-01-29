#!/usr/bin/env ruby

# Modified from https://gist.github.com/perimosocordiae/300705

class ForthInterpreter

  def initialize
    # the stack
    @stack = []
    # the dictionary of Forth words (String => Proc)
    @dict = {
      '+'     => mkBinary{ |a,b| a+b },
      '-'     => mkBinary{ |a,b| a-b },
      '*'     => mkBinary{ |a,b| a*b },
      '/'     => mkBinary{ |a,b| a/b },
      '%'     => mkBinary{ |a,b| a%b },
      '='     => mkBool2 { |a,b| a==b },
      '<'     => mkBool2 { |a,b| a<b },
      '>'     => mkBool2 { |a,b| a>b },
      '&'     => mkBool2 { |a,b| a&b },
      '|'     => mkBool2 { |a,b| a|b },
      'not'   => mkBool1 { |a| a==0 },
      'neg'   => mkUnary { |a| -a },
      '.'     => lambda  { puts pop },
      '..'    => lambda  { p @stack },
      ':'     => lambda  { @word=[] },
      ';'     => lambda  { makeword },
      'pop'   => lambda  { pop },
      'fi'    => lambda  { @skip=nil },
      'words' => lambda  { p @dict.keys.sort },
      'if'    => lambda  { @skip=true if pop==0 },
      'dup'   => lambda  { push @stack[-1] || ufe },
      'over'  => lambda  { push @stack[-2] || ufe },
      'swap'  => lambda  { begin swap rescue ufe end },
    }
  end

  def pop() @stack.pop || ufe end

  def push(f) @stack<<f end

  # poor man's Exception class
  def ufe() raise("Stack underflow") end

  # lambda constructor helpers
  def mkUnary(&fn)  lambda{push(fn.call(pop))} end
  def mkBinary(&fn) lambda{push(fn.call(pop,pop))} end
  def mkBool1(&b)   lambda{push(b.call(pop)?1:0)} end
  def mkBool2(&b)   lambda{push(b.call(pop,pop)?1:0)} end

  def swap
    @stack[-2,2] = @stack[-2,2].reverse
  end

  # adds user-defined word to the @dictionary
  def makeword
    (@word=nil;raise("Empty word definition"))  unless @word && @word.size > 1
    (@word=nil;raise("Nested word definition")) if @word.include? ':'
    name, code = @word.shift, @word.join(' ')
    @dict[name] = lambda{parse(code)}
    @word = nil
  end

  # meat and potatoes
  def parse(str)
    begin
    str.split.each do |w|
      if @skip and w != 'fi'
        next        # skipping over conditional
      elsif @word and w != ';'
        @word << w      # reading word definition
      elsif @dict.has_key? w
        @dict[w].call     # calling pre-defined word
      else
        push w.to_i     # pushing int literal
      end
    end
    rescue
      puts "Error: #{$!}"
    end
  end

end

puts "Ruby Forth interpreter: enter commands at the prompt"

Parser = ForthInterpreter.new
# read definitions files
while ARGV.size > 0
  File.open(ARGV.shift).each{|line| Parser.parse(line)}
end
# REPL
loop do
  ">> ".display
  break unless gets
  Parser.parse($_)
end
