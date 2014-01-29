#!/usr/bin/env ruby

require 'digest/sha2'

shared_secret = "yabbadabbadoo"
provider_salt = "peter"
seconds_since_epoch = Time.now.to_i
minutes_since_epoch = seconds_since_epoch / 60
cleartext = shared_secret + provider_salt + minutes_since_epoch.to_s
hash = Digest::SHA2.new << cleartext
p hash.hexdigest.to_i(16).to_s[0..7]
