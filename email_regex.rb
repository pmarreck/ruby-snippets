  EMAIL_REGEX = /(
    (?<non_grouping_char>
      [^\(\<\)\>\"]
    ){0}
    (?<text_char>
      [\x20-\x5B\x5D-\x7E]
    ){0}
    (?<text_char_without_closing_paren>
      [\x20-\x28\x2A-\x5B\x5D-\x7E]
    ){0}
    (?<text_char_without_doublequote>
      [\x20\x21\x23-\x5B\x5D-\x7E]
    ){0}
    (?<text_char_without_closing_chevron_or_space>
      [\x21-\x3D\x3F-\x5B\x5D-\x7E]
    ){0}
    (?<text_char_without_comma_or_at>
      [\x20-\x2B\x2D-\x3F\x41-\x5B\x5D-\x7E]
    ){0}
    (?<text_char_without_comma>
      [\x20-\x2B\x2D-\x3F\x41-\x5B\x5D-\x7E\@]
    ){0}
    (?<local_part_without_period>
      [\x21\x23-\x27\x2A\x2B\x2D-\x39\x3D\x41-\x5B\x5D-\x7A\x7C\x7E]
    ){0}
    (?<local_part>
      (?: \g<local_part_without_period>+[.]\g<local_part_without_period>+ | \g<local_part_without_period>+ )
    ){0}
    (?<double_quoted_group>
      \" \g<text_char_without_doublequote>+ \"
    ){0}
    (?<parens_group>
      \( \g<text_char_without_closing_paren>+ \)
    ){0}
    (?<chevrons_group>
      \< \g<text_char_without_closing_chevron_or_space>+ \>
    ){0}
    (?<chevrons_email>
      \< \g<email> \>
    ){0}
    (?<balanced_group>
      (?>
        \g<parens_group>   |
        \g<double_quoted_group>
      )
    ){0}
    (?<tld>
    \b
      (?> COM | ORG | EDU | GOV | UK | NET | CA | DE | JP | FR | AERO | ARPA | ASIA | A[UCDEFGILMNOQRSTWXZ] | US | RU | CH | IT | NL | SE | NO | ES | MIL | BIZ | B[ABDEFGHIJMNORSTVWYZ] | CAT | COOP | C[CDFGIKLMNORUVWXYZ] | D[JKMOZ] | E[CEGRTU] | F[IJKMO] | G[ABDEFGHILMNPQRSTUWY] | H[KMNRTU] | INFO | INT | I[DELMNOQRS] | JOBS | J[EMO] | K[EGHIMNPRWYZ] | L[ABCIKRSTUVY] | MOBI | MUSEUM | M[ACDEGHKLMNOPQRSTUVWXYZ] | NAME | N[ACEFGIPRUZ] | OM | PRO | P[AEFGHKLMNRSTWY] | QA | R[EOSW] | S[ABCDGHIJKLMNORTUVXYZ] | TRAVEL | TEL | TLD | T[CDFGHJKLMNOPRTVWZ] | U[AGYZ] | VET | V[ACEGINU] | WIKI | W[FS] | XN\-\- (?> 0ZWM56D | 11B5BS3A9AJ6G | 3E0B707E | 45BRJ9C | 80AKHBYKNJ4F | 80AO21A | 90A3AC | 9T4B11YI5A | CLCHC0EA0B2G2A9GCD | DEBA0AD | FIQS8S | FIQZ9S | FPCRJ9C3D | FZC2C9E2C | G6W251D | GECRJ9C | H2BRJ9C | HGBK6AJ7F53BBA | HLCJ6AYA9ESC7A | J6W193G | JXALPDLP | KGBECHTV | KPRW13D | KPRY57D | LGBBAT1AD8J | MGBAAM7A8H | MGBAYH7GPA | MGBBH1A71E | MGBC0A9AZCG | MGBERP4A5D4AR | O3CW4H | OGBPF8FL | P1AI | PGBS0DH | S9BRJ9C | WGBH1C | WGBL6A | XKC2AL3HYE2A | XKC2DL3A5EE0H | YFRO4I67O | YGBI2AMMX | ZCKZAH ) | XXX | Y[ET] | Z[AMW] )
    \b
    ){0}
    (?<ccsld>
      \g<tld>(?= [.]\g<tld>)
    ){0}
    (?<tlds>
      (?: [.]\g<ccsld>)? [.]\g<tld>
    ){0}
    (?<allowed_name>
      \b(?<!\-)[a-z0-9\-]{1,40}(?!\-)\b
    ){0}
    (?<subdomain>
      \g<allowed_name>
      (?! \g<tlds> )
    ){0}
    (?<subdomains>
      \g<subdomain>(?: [.]\g<subdomain>){0,3}[.]
    ){0}
    (?<domain>
      \g<allowed_name>
      (?= \g<tlds> )
    ){0}
    (?<hostname>
      \g<subdomains>? \g<domain> \g<tlds>
    ){0}
    (?<email>
      (\g<local_part>@\g<hostname>)
    ){0}
    (?<content>
      (?> \s+ | \g<balanced_group> | \g<text_char_without_comma_or_at>+\g<chevrons_email> | \g<email> | \, )*
    ){0}
    (?<test>
      (?> (?> \s+ | \g<balanced_group> | \g<email> | \g<text_char_without_comma>+\g<chevrons_email> ) \,? )*
    ){0}
    \g<test>
  )/uix

p '"someones name" <aaa@bbb.com>, hello <someone@ccc.com>, "dont@pickme.com" <abc@de.com>, another@email.com'.scan(EMAIL_REGEX).map{|ma| ma[-3]}.compact

# not capturing b@b.com or e@e.com at this time...
p '"a <b@b.com>" <c@com>, "artie" <d@d.com>, e@e.com, f@f.com<g@g.com>, another@email.com'.scan(EMAIL_REGEX).map{|ma| ma[-3]}.compact
