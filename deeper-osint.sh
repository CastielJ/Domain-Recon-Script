#!/bin/bash

read -p "Please write the domain name (example: example.com): " domain
echo -e "\n A full OSINT analisis for $domain\n"

mkdir -p results_$domain && cd results_$domain

# Subdomains
echo -e "\n Subfinder:"
subfinder -d $domain -silent | tee subdomains.txt

echo -e "\n Amass:"
amass enum -passive -d $domain | tee -a subdomains.txt

sort -u subdomains.txt -o subdomains.txt
echo -e "\n Found $(wc -l < subdomains.txt) subdomains"

# DNS and WHOIS
echo -e "\n WHOIS:"
whois $domain | grep -Ei 'Registrar|Registrant|Name Server|Email|Updated|Expiry' | tee whois.txt

echo -e "\n dig:"
dig ANY $domain +short | tee dns.txt

# SSL
echo -e "\n SSL (crt.sh):"
curl -s "https://crt.sh/?q=%25.$domain&output=json" | jq -r '.[].name_value' | sort -u | tee crtsh.txt

echo -e "\n SSL Info (sslscan):"
sslscan $domain | tee sslscan.txt

# IP and PTR
ip=$(dig +short $domain | tail -n1)
echo -e "\n IP-adress: $ip"
host $ip | tee ptr.txt

# Technologies
echo -e "\n WhatWeb:"
whatweb https://$domain | tee whatweb.txt

# Directories
echo -e "\n Gobuster:"
gobuster dir -u https://$domain -w /usr/share/wordlists/dirb/common.txt -t 30 -q | tee gobuster.txt


# ----------------------[ ADVANCED OSINT ]------------------------

# Nuclei (Automatic vulnerability scan)
echo -e "\n Nuclei:"
cat subdomains.txt | httpx -silent | tee live.txt
nuclei -l live.txt -severity low,medium,high,critical -c 50 -o nuclei.txt

# Wayback and GAU (Archived URL)
echo -e "\n Waybackurls:"
cat subdomains.txt | waybackurls | tee wayback.txt

echo -e "\n gau (GetAllURLs):"
cat subdomains.txt | gau | tee gau.txt

# GF (Templates for finding vulnerabilities)
echo -e "\n GF: XSS, RCE, LFI:"
cat gau.txt | gf xss | tee xss.txt
cat gau.txt | gf lfi | tee lfi.txt
cat gau.txt | gf rce | tee rce.txt


# Port Scan (Its taking a hella lot of time, not gonna lie (its safer that way)
echo -e "\n Nmap:"
nmap -sS -sV -T2 -Pn -p- $domain | tee nmap.txt
# ----------------------[ DONE ]------------------------

echo -e "\n Analysis finished! All results in results_$domain folder"
