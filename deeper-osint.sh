#!/bin/bash
# deeper-osint.sh — full OSINT analysis tool with SSL certificate details

read -p "Please write the domain name (example: example.com): " domain
echo -e "\n=== Starting full OSINT analysis for $domain ===\n"

results_dir="results_$domain"
mkdir -p "$results_dir/gf_results" "$results_dir/screenshots"
cd "$results_dir" || exit 1

# Initialize full report
report="full_report.txt"
echo "=== OSINT Report for $domain ===" > "$report"

# ===== Dependency check =====
required=(subfinder amass whois dig curl jq sslscan host whatweb gobuster httpx nuclei waybackurls gau gf nmap openssl)
missing=()
for cmd in "${required[@]}"; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        missing+=("$cmd")
    fi
done
if [ ${#missing[@]} -gt 0 ]; then
    echo "[!] Missing tools: ${missing[*]}" | tee -a "$report"
    echo "Install them before running for full results." | tee -a "$report"
fi

# ===== Subdomain enumeration =====
echo "\n===== Subdomain Enumeration =====" >> "$report"
subfinder -d "$domain" -silent > subdomains.txt 2>/dev/null
amass enum -passive -d "$domain" >> subdomains.txt 2>/dev/null

resp=$(curl -sL -H "User-Agent: Mozilla/5.0" "https://crt.sh/?q=%25.$domain&output=json")
if echo "$resp" | jq -e '.[0]' >/dev/null 2>&1; then
    echo "$resp" | jq -r '.[].name_value' | sed 's/\*\.//g' >> subdomains.txt
else
    echo "[!] crt.sh returned invalid JSON — saved raw to crtsh_raw.txt" | tee -a "$report"
    printf '%s\n' "$resp" > crtsh_raw.txt
fi

sort -u subdomains.txt -o subdomains.txt
echo "[*] Found $(wc -l < subdomains.txt) subdomains" | tee -a "$report"
cat subdomains.txt >> "$report"

# ===== DNS and WHOIS =====
echo "\n===== DNS and WHOIS =====" >> "$report"
whois "$domain" | grep -Ei 'Registrar|Registrant|Name Server|Email|Updated|Expiry' > whois.txt 2>/dev/null
dig ANY "$domain" +short > dns.txt 2>/dev/null
cat whois.txt dns.txt >> "$report"

# ===== SSL scan =====
echo "\n===== SSL Scan =====" >> "$report"
sslscan "$domain" > sslscan.txt 2>/dev/null
cat sslscan.txt >> "$report"

# ===== Live SSL Certificate extraction =====
echo "\n===== Live SSL Certificate =====" >> "$report"
if command -v openssl >/dev/null 2>&1; then
    echo | openssl s_client -connect "$domain:443" -servername "$domain" 2>/dev/null | \
    openssl x509 -noout -text > live_cert.txt

    {
        echo "Issuer: $(openssl x509 -in live_cert.txt -noout -issuer)"
        echo "Subject: $(openssl x509 -in live_cert.txt -noout -subject)"
        echo "Valid From: $(openssl x509 -in live_cert.txt -noout -startdate)"
        echo "Valid To: $(openssl x509 -in live_cert.txt -noout -enddate)"
        echo "SHA1 Fingerprint: $(openssl x509 -in live_cert.txt -noout -fingerprint -sha1)"
        echo "SHA256 Fingerprint: $(openssl x509 -in live_cert.txt -noout -fingerprint -sha256)"
    } > ssl_summary.txt

    cat ssl_summary.txt >> "$report"

    expiry_date=$(openssl x509 -in live_cert.txt -noout -enddate | cut -d= -f2)
    expiry_seconds=$(date -d "$expiry_date" +%s)
    now_seconds=$(date +%s)
    days_left=$(( (expiry_seconds - now_seconds) / 86400 ))
    echo "Days until expiration: $days_left" | tee -a ssl_summary.txt >> "$report"
    if [ $days_left -le 30 ]; then
        echo "[!] SSL certificate expires in $days_left days!" | tee -a "$report"
    fi
fi

# ===== IP and PTR =====
echo "\n===== IP and PTR =====" >> "$report"
ip=$(dig +short "$domain" | tail -n1)
echo "[*] IP address: $ip" | tee -a summary.txt >> "$report"
host "$ip" > ptr.txt 2>/dev/null
cat ptr.txt >> "$report"

# ===== Technology fingerprint =====
echo "\n===== Technology Fingerprinting =====" >> "$report"
whatweb "https://$domain" --log-verbose=whatweb.txt >/dev/null 2>&1
cat whatweb.txt >> "$report"

# ===== Live host check =====
echo "\n===== Live Hosts =====" >> "$report"
if command -v httpx >/dev/null 2>&1 && httpx -h 2>&1 | grep -qi "projectdiscovery"; then
    cat subdomains.txt | httpx -silent -threads 50 -timeout 5 > live.txt
    cat live.txt >> "$report"
else
    echo "[!] ProjectDiscovery httpx not found or wrong version" | tee -a "$report"
fi

# ===== Folder brute-force =====
echo "\n===== Folder Brute Force =====" >> "$report"
if command -v gobuster >/dev/null 2>&1 && [ -s live.txt ]; then
    while read -r url; do
        gobuster dir -u "$url" -w /usr/share/seclists/Discovery/Web-Content/common.txt -q >> gobuster.txt
    done < live.txt
    cat gobuster.txt >> "$report"
fi

# ===== Vulnerability scan =====
echo "\n===== Vulnerability Scan =====" >> "$report"
if command -v nuclei >/dev/null 2>&1 && [ -s live.txt ]; then
    nuclei -l live.txt -severity low,medium,high,critical -c 50 -o nuclei.txt >/dev/null 2>&1
    cat nuclei.txt >> "$report"
fi

# ===== Historical URLs =====
echo "\n===== Historical URLs =====" >> "$report"
[ -x "$(command -v waybackurls)" ] && cat subdomains.txt | waybackurls > wayback.txt && cat wayback.txt >> "$report"
[ -x "$(command -v gau)" ] && cat subdomains.txt | gau > gau.txt && cat gau.txt >> "$report"

# ===== GF patterns =====
echo "\n===== GF Patterns =====" >> "$report"
if command -v gf >/dev/null 2>&1; then
    for pattern in xss sqli lfi rce; do
        [ -s gau.txt ] && gf "$pattern" gau.txt > "gf_results/${pattern}.txt" && {
            echo "--- $pattern ---" >> "$report"
            cat "gf_results/${pattern}.txt" >> "$report"
        }
    done
fi

# ===== OPTIONAL: Screenshot capture =====
echo "\n===== Screenshots =====" >> "$report"
if command -v gowitness >/dev/null 2>&1 && [ -s live.txt ]; then
    gowitness file -f live.txt --disable-logging --destination screenshots >/dev/null 2>&1
    echo "[+] Screenshots saved in screenshots/ folder" >> "$report"
fi

# ===== OPTIONAL: ASN scanning =====
echo "\n===== ASN Scanning =====" >> "$report"
if command -v amass >/dev/null 2>&1; then
    asn=$(whois "$domain" | grep -i "origin" | awk '{print $2}' | sort -u | head -n1)
    if [ -n "$asn" ] && command -v naabu >/dev/null 2>&1; then
        amass intel -asn "$asn" > asn_ranges.txt
        naabu -list asn_ranges.txt -p- -o asn_ports.txt >/dev/null 2>&1
        cat asn_ports.txt >> "$report"
    fi
fi

echo -e "\n=== Scan complete. Results saved in $results_dir/ ==="
