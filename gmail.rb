class Gmail
  require 'net/imap'
  def initialize(email,password)
    @imap = Net::IMAP.new("imap.gmail.com",993,true)
    @imap.login(email, password)
    @imap.examine('INBOX')
    self
  end
  
  def search(search_arr)
    @imap.search(search_arr)
  end
end

# 172800 = 2 days
date = (Time.now - 172800).strftime("%d-%b-%Y")

g = Gmail.new("boxes@thredup.com","5C5376")
results = g.search(["BODY","2726 SW BUCKHART ST","BODY","34953","TO","boxes+16589@thredup.com","NOT","BEFORE",date])
puts results.count > 0

results = g.search(["BODY","2726 SW BUCKHART ST","BODY","34XXXX953","TO","boxes+16589@thredup.com","NOT","BEFORE",date])
puts results.count > 0