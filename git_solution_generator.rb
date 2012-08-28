#!/usr/bin/env ruby
#
#  File: git_solution_generator.rb
#  Created by Peter Marreck on 2012-08-03.

class GitSolutionGenerator

  def solutions(n=1, sep=" ")
   (1..n).inject(""){|total,x| total+"#{solution}#{sep}"}
  end

  def solution
   "#{thats_easy} #{you_have_to} #{to} #{in_order_to}." + (rand < 0.5 ? " Then, #{you_have_to} #{to} #{in_order_to}." : '')
  end

  def thats_easy
    ["That's easy,", "Just", "I see the problem,", "Easy,"].sample
  end

  def you_have_to
    ["git rebase #{'-i ' if rand<0.5}to", "check your reflog on", "git stash unstaged changes on", "forward-port", "merge the latest commits with", "pull#{' --ff-only' if rand<0.5} from", "push to"].sample
  end

  def to
    ["the most recent common commit with #{branch}", "the latest commits from #{branch}", branch].sample
  end

  def branch(the=true)
    [head, "#{headprefix}master", "#{'the ' if the}#{headprefix}original branch", "#{'the ' if the}current branch", "#{'the ' if the}index pointer"].sample
  end

  def head
    "#{headprefix}HEAD#{headsuffix}"
  end

  def headsuffix
    ['^'*rand(6), "~#{rand(10)+1}", "", ""].sample
  end

  def headprefix
    ["detached ", "upstream ", "remote ", "", ""].sample
  end

  def in_order_to
    "to make sure the #{object} " << ["is on the correct", "is in sync with the", "is not detached from the", "is not missing commits from the", "is rebased to the", "is merged with the"].sample << ' ' << branch(false)
  end

  def object
    ["index pointer", "reflog", "most recent commit", head, "local merge commit"].sample
  end

end

gsg = GitSolutionGenerator.new
puts gsg.solutions(10,"\n\n")
