#!/bin/bash
################################################################################
## Developer: Caio Fratelli
## Email: caio@razel.com.br
## Script Version: 0.0.1
## Description: A simple script that takes a DNS zone file with entries in the
## format XXX-XXX-XXX-XXX.domain.tld, executes a whois against each IP,
## gets the current designated owner and replaces the old entry with
## $owner.domain.tld.
## (domain and tld remains the same, it just replaces IP octets with the owner).
##
## Usage: ./zonefile3.sh <zonefile>
################################################################################

# Check if input file is provided
if [ $# -ne 1 ]; then
    echo "Usage: $0 <zonefile>"
    exit 1
fi

zonefile="$1"

# Process each line of the zone file
while IFS= read -r line; do
    # Check if the line is a PTR record (second field)
    if echo "$line" | awk '$2 == "PTR" { exit 0 }'; then
        # Extract the hostname (third field), remove trailing dot (temporarily)
        hostname=$(echo "$line" | awk '{print $4}' | sed 's/\.$//')
        # Split each hyphenated IP part
        hyphenated_ip=$(echo "$hostname" | cut -d. -f1)
        remaining_host=$(echo "$hostname" | cut -d. -f2-)
        subdomain=$(echo "$remaining_host" | cut -d. -f1)
        domain_tld=$(echo "$remaining_host" | cut -d. -f2-)
        # Convert hyphenated IP to regular IP
        ip=$(echo "$hyphenated_ip" | tr '-' '.')
        # Perform WHOIS lookup and extract owner (first occurrence)
        owner=$(whois -h whois.registro.br "$ip" | grep -i -m 1 'owner:' | awk '{print $2,$3}')
        # Do analysis of DNS-compatible name with the requirements:
        # Lowercase.
        # Replace accents with their unaccented counterparts.
        # Replace spaces with hyphens.
        # Remove any remaining characters that are not a-z, 0-9, or hyphen.
        # Remove leading and trailing hyphens.
        customer=$(echo "$owner" | \
            awk '{print tolower($0)}' | \
            sed -e 's/[ãáâ]/a/g' \
                -e 's/[ẽéê]/e/g' \
                -e 's/[ĩíî]/i/g' \
                -e 's/[õóô]/o/g' \
                -e 's/[ũúû]/u/g' \
                -e 's/ç/c/g' \
                -e 's/ /-/g' \
                -e 's/[^a-z0-9-]//g' \
                -e 's/^-*//' \
                -e 's/-*$//')

        # New hostname
        if [ -z "$customer" ]; then
            # If customer is empty (owner not found), keep original hostname
            new_hostname="$hostname."
        else
            new_hostname="$customer.$domain_tld."
        fi

        # Preserving the original spacing.
        # This regex captures:
	# The start of the line following a very specific structure (please modify it to suit your particular needs)
        new_line=$(echo "$line" | sed -E "s/^(([^[:space:]]+[[:space:]]+){3})[^[:space:]]+/\1$new_hostname/")
        echo "$new_line"
    else
        # Not a PTR line, output as-is
        echo "$line"
    fi
done < "$zonefile"
