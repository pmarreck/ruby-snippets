
class RandomSentenceBuilder
  @@sentence_parts = [
    ["And so, the", "A", "Nobody knows why a", "Almost daily, a", "Sometimes, the", "However, this particular", "The", "Only one", "A"],
    ["cat","evil potato", "elephant", "monkey", "robot", "ninja", "nerd", "zombie", "teacher", "monster", "butler", "alien", "fox", "demon", "box", "hand", "coffee mug", "programmer"],
    ["regularly", "angrily", "nervously", "quickly", "politely", "quietly", "dramatically"],
    ["destroyed a", "sat on the", "painted a", "captured the", "wrote about a", "kicked the", "screamed at a", "spat on the", "cleaned a", "laughed at the", "ate the"],
    ["green", "deadly", "flaming", "grumpy", "dancing", "electronic", "royal", "screaming", "insane", "secret", "confusing", "cloned", "original"],
    ["cake", "candle", "hair", "police car", "arm", "gardener", "pile of biscuits", "dead body", "printer", "chair", "book", "paper", "mirror", "balloon", "shampoo bottle", "coffin"].map!{|w| "#{w}."},
    ["It's not meant to make sense.", "We're not entirely sure, either.", "I'm sure we can handle it... THIS time.", "Sorry.", "Somehow we still manage to keep our sanity.", "Just don't ask.", "Uhhhh...."] + [""] * 5
  ]
  def self.build_sentence(num = 1)
    sentences = []
    (1..num).each do
      sentences << @@sentence_parts.map {|e| e[rand(e.length)]}.join(" ")
    end
    sentences.join(" ")
  end
end

puts RandomSentenceBuilder.build_sentence
