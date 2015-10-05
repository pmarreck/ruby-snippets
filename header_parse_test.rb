require 'mail'

# String monkeypatch
# This is one of many possible "encoding problem" solutions. It's actually an intractable problem
# but you'd have to read "Gödel, Escher, Bach" to understand why...
class String
  def clean_utf8
    # self.force_encoding("UTF-8").encode("UTF-16BE", :invalid=>:replace, :replace=>"?").encode("UTF-8")
    unpack('C*').pack('U*') if !valid_encoding?
  end
end

module Parsing
  module Email
    class Header
      EMAIL_HEADER_PARSER_REGEX = /
        ([A-Za-z-]+):\s       # Find a header key, which ends in a colon and a space. Capture the hyphenated word portion.
        (                     # Now start capturing the value.
          [^\r\n]+            # First, match everything that is not a line ending char.
          (?:                 # Then start a non-capturing repeating match which first consists of...
            \r?\n             # A line ending combo...
            (?![A-Za-z-]+:\s) # But first, do a negative lookahead to make sure the next line does not start with another header-key-looking string
            [^\r\n]+          # Then match all text that is not a line ending char.
          )*                  # Repeat this non-capturing group match 0 or more times.
        )                     # End capturing the value.
      /mx                     # Allow matches to cross line endings (m) and allow whitespace and comments in this regex (x).
      EMAIL_MULTILINE_HEADER_VALUE_REGEX = /\r?\n\s*/m

      attr_reader :headers
      def initialize(opts = {})
        @headers = (Hash === opts ? opts[:headers] : opts)
      end

      def call
        return {} unless @headers
        clean_header_values_hash(headers_hash)
      end
      alias to_h call

      private

      def headers_hash
        h = {}
        @headers.scan(EMAIL_HEADER_PARSER_REGEX).map do |k,v|
          if k && v
            if h[k]
              # if this key already has a value, wrap it in an array and append the new value, otherwise just set the key value
              h[k] = [h[k]] unless Array === h[k]
              h[k] << v
            else
              h[k] = v
            end
          end
        end
        h
      end

      # Clean up runs of a newline followed by whitespace in header values by replacing with a space
      def clean_header_values_hash(h)
        h.each do |k,v|
          if Array === v
            v.map! do |val|
              val =~ EMAIL_MULTILINE_HEADER_VALUE_REGEX ? val.gsub!(EMAIL_MULTILINE_HEADER_VALUE_REGEX,' ') : val
            end
          else
            v.gsub!(EMAIL_MULTILINE_HEADER_VALUE_REGEX, ' ') if v =~ EMAIL_MULTILINE_HEADER_VALUE_REGEX
          end
        end
        h
      end

    end
  end
end


headers = <<-HEADERS
Delivered-To: jtest01@assistly.com
Return-Path: <noreply@comixology.com>
Received: from smtp36.gate.dfw1a (gate36.gate.dfw.mlsrvr.com [172.20.100.36])
       by mail138a.mail.dfw.mlsrvr.com (SMTP Server) with ESMTP id 107434FCCD
       for <info@comixology.com>; Wed, 29 Dec 2010 05:46:02 -0500 (EST)
X-Spam-Threshold: 95
X-Spam-Score: 0
X-Spam-Flag: NO
X-Virus-Scanned: OK
X-MessageSniffer-Scan-Result: 0
X-MessageSniffer-Rules: 0-0-0-32767-c
X-CMAE-Scan-Result: 0
X-CNFS-Analysis: v=1.0 c=1 a=410GYZBmXEQA:10 a=8nJEP1OIZ-IA:10 a=jrTSQGAaAAAA:8 a=zr8WG4425YMt8zt5NHsA:9 a=9yu0GlTtA_AyZ2ttE_-TzX-Oml0A:4 a=wPNLvfGTeEIA:10 a=vUvjSO8KtUCdM2_P:21 a=bi41oqnuo1lMp9yW:21
X-Orig-To: info@comixology.com
X-Originating-Ip: [173.203.22.3]
Received: from [173.203.22.3] ([173.203.22.3:54314] helo=287315-web1.comixology.com)
       by smtp36.gate.dfw1a.rsapps.net (envelope-from <noreply@comixology.com>)
       (ecelerity 2.2.3.46 r(37554)) with ESMTP
       id 4A/C8-28011-8611B1D4; Wed, 29 Dec 2010 05:46:01 -0500
Received: from comixology.com (localhost [127.0.0.1])
       by 287315-web1.comixology.com (Postfix) with ESMTP id E41991188DCD;
       Wed, 29 Dec 2010 05:45:59 -0500 (EST)
Date: Wed, 29 Dec 2010 05:45:59 -0500
To: info@comixology.com
From: comiXology <noreply@comixology.com>
Reply-to: carta.mesquita@bol.com.br
Subject: Feedback from the Marvel Mobile Comics App
Message-ID: <843e0dc47783da9c4ff408f8cb9a8c79@comixology.com>
X-Priority: 3
X-Mailer: PHPMailer 5.0.2 (phpmailer.codeworxtech.com)
MIME-Version: 1.0
Content-Transfer-Encoding: 8bit
Content-Type: text/plain; charset="ISO-8859-1"
HEADERS

t = Time.now
500.times do
  begin
    email = Parsing::Email::Header.new(headers)
    email.call
  rescue ArgumentError
    email = Parsing::Email::Header.new(headers.clean_utf8)
    email.call
  end
end
puts "Time with my regex: #{mine = (Time.now - t)} seconds"

t = Time.now
500.times do
  email = Mail.new(headers)
  email.received
end
puts "Time with Mail gem: #{mailgem = (Time.now - t)} seconds"

puts "Factor of improvement: #{(mailgem/mine*10000).to_i.to_f/100}%"