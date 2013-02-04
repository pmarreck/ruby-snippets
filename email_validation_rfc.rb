# RFC 5322 Email Validation Regex in Ruby

EMAIL = /
    (?<addr_spec> (?> \g<local_part> @ \g<domain> ) ){0}
    (?<local_part> (?> \g<dot_atom> | \g<quoted_string> | \g<obs_local_part> ) ){0}
    (?<domain> (?> \g<dot_atom> | \g<domain_literal> | \g<obs_domain> ) ){0}
    (?<domain_literal> (?> \g<CFWS>? \[ (?: \g<FWS>? \g<dtext> )* \g<FWS>? \] \g<CFWS>? ) ){0}
    (?<dtext> (?> [\x21-\x5a] | [\x5e-\x7e] | \g<obs_dtext> ) ){0}
    (?<quoted_pair> (?> \\ (?: \g<VCHAR> | \g<WSP> ) | \g<obs_qp> ) ){0}
    (?<dot_atom> (?> \g<CFWS>? \g<dot_atom_text> \g<CFWS>? ) ){0}
    (?<dot_atom_text> (?> \g<atext> (?: \. \g<atext> )* ) ){0}
    (?<atext> (?> [a-zA-Z0-9!\#\$%&'*\+\/\=\?\^_`{\|}~\-]+ ) ){0}
    (?<atom> (?> \g<CFWS>? \g<atext> \g<CFWS>? ) ){0}
    (?<word> (?> \g<atom> | \g<quoted_string> ) ){0}
    (?<quoted_string> (?> \g<CFWS>? " (?: \g<FWS>? \g<qcontent> )* \g<FWS>? " \g<CFWS>? ) ){0}
    (?<qcontent> (?> \g<qtext> | \g<quoted_pair> ) ){0}
    (?<qtext> (?> \x21 | [\x23-\x5b] | [\x5d-\x7e] | \g<obs_qtext> ) ){0}

    # comments and whitespace
    (?<FWS> (?> (?: \g<WSP>* \r\n )? \g<WSP>+ | \g<obs_FWS> ) ){0}
    (?<CFWS> (?> (?: \g<FWS>? \g<comment> )+ \g<FWS>? | \g<FWS> ) ){0}
    (?<comment> (?> \( (?: \g<FWS>? \g<ccontent> )* \g<FWS>? \) ) ){0}
    (?<ccontent> (?>\g<ctext> | \g<quoted_pair> | \g<comment> ) ){0}
    (?<ctext> (?> [\x21-\x27] | [\x2a-\x5b] | [\x5d-\x7e] | \g<obs_ctext> ) ){0}

    # obsolete tokens
    (?<obs_domain> (?> \g<atom> (?: \. \g<atom> )* ) ){0}
    (?<obs_local_part> (?> \g<word> (?: \. \g<word> )* ) ){0}
    (?<obs_dtext> (?> \g<obs_NO_WS_CTL> | \g<quoted_pair> ) ){0}
    (?<obs_qp> (?> \\ (?: \x00 | \g<obs_NO_WS_CTL> | \n | \r ) ) ){0}
    (?<obs_FWS> (?> \g<WSP>+ (?: \r\n \g<WSP>+ )* ) ){0}
    (?<obs_ctext> (?> \g<obs_NO_WS_CTL> ) ){0}
    (?<obs_qtext> (?> \g<obs_NO_WS_CTL> ) ){0}
    (?<obs_NO_WS_CTL> (?> [\x01-\x08] | \x0b | \x0c | [\x0e-\x1f] | \x7f ) ){0}

    # character class definitions
    (?<VCHAR> (?> [\x21-\x7E] ) ){0}
    (?<WSP> [ \t] ){0}
  \g<addr_spec>
/uix

p "peter@desk.com".scan(EMAIL)
p EMAIL =~ "peter@desk.com"
p EMAIL.match("peter@desk.com")
p EMAIL.match('"peter@nodomain.com" <peter@desk.com>')
p '"peter@nodomain.com" <peter@desk.com>'.scan EMAIL
