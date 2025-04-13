# dnszonefixer
A simple script that takes a DNS zone file with entries in the the format XXX-XXX-XXX-XXX.domain.tld , executes a whois against each IP, gets the current designated owner and replaces the old entry with $owner.domain.tld. (domain and tld remains the same, it just replaces IP octets with the owner).

Usage: ./zonefile3.sh <zonefile>
