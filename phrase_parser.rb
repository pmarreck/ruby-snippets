# ruby common phrase finder

require 'net/http'
require 'uri'
require 'active_support/all'
require 'action_view/helpers/sanitize_helper'

include ActionView::Helpers::SanitizeHelper

class Phrases

  attr_accessor :stats
  attr_accessor :visited_links

  WORD_SPLITTER = /[\s\-\_\"\.\,\!\?\&\(\)\[\]\/]+/

  WORD_FILTER = /\A[\w%#]+\z/i

  PRUNE_LIMIT = 10000000

  DEPTH_LIMIT = 2

  PHRASE_LENGTH_LIMIT = 3

  LINK_LIMIT = 500

  def initialize
    self.stats = Hash.new(0)
    self.visited_links = []
  end

  def parse(text)
    text_ary = text.split(WORD_SPLITTER).select{|w| w =~ WORD_FILTER}.map(&:downcase).map(&:to_sym)
    tot_size = text_ary.size
    puts "Parsing text of #{tot_size} words..."
    (0..tot_size).each do |i|
      (0..PHRASE_LENGTH_LIMIT).each do |phrase_len|
        next if i + phrase_len > tot_size
        candidate = text_ary[i..(i+phrase_len)]
        self.stats[candidate] += 1
      end
    end
    prune if self.stats.size > PRUNE_LIMIT
  end

  def recursive_parse(url, depth=0)
    return if depth > DEPTH_LIMIT || self.visited_links.include?(url) || self.visited_links.length > LINK_LIMIT
    self.visited_links << url
    puts "Getting URL #{url} at depth #{depth}..."
    text = get(url)
    links = URI.extract(text).select{|u| u =~ /^https?\:\/\//}.reject{|u| u =~ /\.(gif|jpg|jpeg|js|png|css|ico|pdf|img|doubleclick|feedburner)\b/}
    text = strip_tags(text)
    self.parse(text)
    links.each do |link|
      begin
        recursive_parse(link, depth+1)
      rescue StandardError => e
        puts "Error: #{e}"
      end
    end
  end

  def get(url)
    Net::HTTP.get(URI.parse(url))
  end

  def sort
    self.stats = self.stats.sort_by{|k,v| v}
    self.stats
  end

  def prune
    puts "Pruning stats..."
    self.stats.delete_if{|k,v| v < 2}
  end

end

p = Phrases.new
p.recursive_parse('http://slashdot.org')

puts p.stats.size
p p.stats.sort
