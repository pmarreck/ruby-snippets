#---------------------------------------------------------------------
# This is a pure ruby implementation of the Tiny Encryption Algorithm
# (TEA) by David Wheeler and Roger Needham of the Cambridge Computer
# Laboratory.
#
# For more information:
#
#   http://www.simonshepherd.supanet.com/tea.htm
#
# This is an implementation of the 'New Variant' of the cipher.
#
# ====================================================================
# Copyright (c) 2005, 2006 Jeremy Hinegardner <jeremy@hinegardner.org>
#
# This implementation of the TEA New Variant is released under
# the MIT License:
#
#   http://www.opensource.org/licenses/mit-license.html
#
# ====================================================================
#
#---------------------------------------------------------------------
# Ruby 1.8 compatibility
if RUBY_VERSION.include?('1.8')
  class Fixnum; def ord; return self; end; end
end
require 'digest/md5'
class Crypt
  class TEA
    DELTA        = 0x9e3779b9
    ITERATIONS   = 32

    #-------------------------------------------------------------
    # encrypt the given plaintext with the given key, where the key
    # is a text pass phrase
    #-------------------------------------------------------------
    def self.encrypt(plain_text,pass_phrase)
      tea =TEA.new
      tea.encrypt(plain_text,pass_phrase)
    end

    #-------------------------------------------------------------
    # decrypt the given ciphertext with the given key, where the key
    # is a text pass phrase
    #-------------------------------------------------------------
    def self.decrypt(cipher_text,pass_phrase)
      tea = TEA.new
      tea.decrypt(cipher_text,pass_phrase)
    end


    #-------------------------------------------------------------
    def encrypt(plain_text,pass_phrase)

      key = passphrase_to_key(pass_phrase)

      # pad the plaintext to a length modulo 8
      # and preface the string with how many padding characters
      # there where, including itself
      to_pad = 8 - plain_text.length % 8
      plain_text = "#{to_pad}#{plain_text}"

      1.upto(to_pad-1) do |i|
        plain_text = plain_text + rand(0xff).chr
      end

      cipher_text = []

      # for each 8 char's pack them into 2 ints
      range = Range.new(0,plain_text.length,true)
      range.step(8) do |n|

        num1  = plain_text[n].ord.to_i   << 24
        num1 += plain_text[n+1].ord.to_i << 16
        num1 += plain_text[n+2].ord.to_i << 8
        num1 += plain_text[n+3].ord.to_i

        num2  = plain_text[n+4].ord.to_i << 24
        num2 += plain_text[n+5].ord.to_i << 16
        num2 += plain_text[n+6].ord.to_i << 8
        num2 += plain_text[n+7].ord.to_i

        enum1,enum2  = encrypt_chunk(num1,num2,key)

        cipher_text << enum1
        cipher_text << enum2

      end

      cipher_text.collect { |c| sprintf("%.8x",c) }.join('')
    end

    #-------------------------------------------------------------
    def decrypt(cipher_text,pass_phrase)

      key = passphrase_to_key(pass_phrase)

      plain_text = []

      # convert the cipher_text into an array of 2 character
      # strings
      cipher_array = cipher_text.scan(/../)

      # for each 8 char's pack them into 2 ints
      range = Range.new(0,cipher_array.length,true)

      range.step(8) do |n|
        num1  = cipher_array[n].to_i(16)   << 24
        num1 += cipher_array[n+1].to_i(16) << 16
        num1 += cipher_array[n+2].to_i(16) << 8
        num1 += cipher_array[n+3].to_i(16)

        num2  = cipher_array[n+4].to_i(16) << 24
        num2 += cipher_array[n+5].to_i(16) << 16
        num2 += cipher_array[n+6].to_i(16) << 8
        num2 += cipher_array[n+7].to_i(16)

        enum1,enum2  = decrypt_chunk(num1,num2,key)

        plain_text << ((enum1 & 0xFF000000) >> 24)
        plain_text << ((enum1 & 0x00FF0000) >> 16)
        plain_text << ((enum1 & 0x0000FF00) >> 8)
        plain_text << ((enum1 & 0x000000FF))

        plain_text << ((enum2 & 0xFF000000) >> 24)
        plain_text << ((enum2 & 0x00FF0000) >> 16)
        plain_text << ((enum2 & 0x0000FF00) >> 8)
        plain_text << ((enum2 & 0x000000FF))

      end

      pad_count = plain_text.shift.chr.to_i
      (pad_count - 1).times { |i| plain_text.pop }

      plain_text.collect { |c| c.chr }.join("")
    end

    ############
    private
    ############


    #-------------------------------------------------------------
    # convert the given passphrase to and MD5 sum and get the 128
    # bit key as 4 x 32 bit ints
    #-------------------------------------------------------------
    def passphrase_to_key(pass_phrase)
      Digest::MD5.digest(pass_phrase).unpack('L*')
    end


    #-------------------------------------------------------------
    # encrypt 2 of the integers ( 8 characters ) of the input into
    # the cipher text output
    #-------------------------------------------------------------
    def encrypt_chunk(num1,num2,key)
      y,z,sum = num1,num2,0

      ITERATIONS.times do |i|
        y   += ( z << 4 ^ z >> 5) + z ^ sum + key[sum & 3]
        y   = y & 0xFFFFFFFF;

        sum += DELTA
        z   += ( y << 4 ^ y >> 5) + y ^ sum + key[sum >> 11 & 3]
        z   = z & 0xFFFFFFFF;

        # ruby can keep on getting bigger because of Bignum so
        # you have to and with 0xFFFFFFFF to get the Fixnum
        # bytes

      end
      return [y,z]
    end


    #-------------------------------------------------------------
    # decrypt 2 of the integer cipher texts into the plaintext
    #-------------------------------------------------------------
    def decrypt_chunk(num1,num2,key)
      y,z = num1,num2
      sum = DELTA << 5
      ITERATIONS.times do |i|
        z   -= ( y << 4 ^ y >> 5) + y ^ sum + key[sum >> 11 & 3]
        z    = z & 0xFFFFFFFF
        sum -= DELTA
        y   -= ( z << 4 ^ z >> 5) + z ^ sum + key[sum & 3]
        y    = y & 0xFFFFFFFF
      end
      return [y,z]
    end
  end
end


if __FILE__ == $0 then
  require 'test/unit'
  class TEATester < Test::Unit::TestCase

    def test_en_decrypt
      plain_text  = "Just another Ruby Hacker!"
      pass_phrase = "I love ruby"

      puts "encrypting\t[#{plain_text}]"
      cipher_text    = Crypt::TEA.encrypt(plain_text,pass_phrase)

      puts "decrypting\t[#{cipher_text}]"
      decrypted_text = Crypt::TEA.decrypt(cipher_text,pass_phrase)

      puts "decrypted text\t[#{decrypted_text}]"

      assert_equal plain_text, decrypted_text
    end
  end
end
