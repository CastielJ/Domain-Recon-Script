#!/bin/bash
# deeper-osint.sh
# Full OSINT scan for a domain
# Improved & error-tolerant version (V 2.1)
# Made by github.com/CastielJ

if [ -z "$1" ]; then
    echo "Usage: $0 <domain>"
    exit 1
fi

domain="$1"
echo "=== Deeper OSINT for $domain ==="

# ===== 1. Dependency check =====
required=(
    subfinder amass whois dig curl jq sslscan host whatweb gobuster
    httpx nuclei waybackurls gau gf nmap
)
missing=()
for cmd in "${required[@]}"; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        missing+=("$cmd")
    fi
done
if [ ${#missing[@]} -gt 0 ]; then
    echo "[!] WARNING: Missing tools: ${missing[*]}"
    echo "Install them before running for full results."
fi

# ===== 2. Subdomain enumeration =====
echo -e "\n[+] Gathering subdomains..."
{
    command -v subfinder >/dev/null 2>&1 && subfinder -d "$domain" -silent
    command -v amass >/dev/null 2>&1 && amass enum -passive -d "$domain"
} | sort -u > subdomains.txt
echo "[*] Found $(wc -l < subdomains.txt) subdomains"

# ===== 3. crt.sh SSL certificates =====
echo -e "\n[+] Querying crt.sh..."
resp=$(curl -sL -H "User-Agent: Mozilla/5.0" "https://crt.sh/?q=%25.$domain&output=json")
if echo "$resp" | jq -e '.[0]' >/dev/null 2>&1; then
    echo "$resp" | jq -r '.[].name_value' | sed 's/\*\.//g' | sort -u >> subdomains.txt
else
    echo "[!] crt.sh returned invalid JSON — saved raw to crtsh_raw.txt"
    printf '%s\n' "$resp" > crtsh_raw.txt
fi
sort -u subdomains.txt -o subdomains.txt

# ===== 4. DNS info =====
echo -e "\n[+] DNS Info..."
command -v whois >/dev/null 2>&1 && whois "$domain" > whois.txt
command -v dig >/dev/null 2>&1 && dig "$domain" ANY +noall +answer > dig.txt

# ===== 5. SSL scan =====
echo -e "\n[+] SSL Scan..."
command -v sslscan >/dev/null 2>&1 && sslscan "$domain" > sslscan.txt

# ===== 6. Live hosts via HTTPX =====
echo -e "\n[+] Checking live hosts..."
if command -v httpx >/dev/null 2>&1 && httpx -h 2>&1 | grep -qi "projectdiscovery"; then
    cat subdomains.txt | httpx -silent -threads 50 -timeout 5 > live.txt
    echo "[*] $(wc -l < live.txt) live hosts found"
else
    echo "[!] ProjectDiscovery httpx not found or wrong version"
fi

# ===== 7. Web technology fingerprinting =====
echo -e "\n[+] Fingerprinting..."
if command -v whatweb >/dev/null 2>&1 && [ -s live.txt ]; then
    whatweb -i live.txt --log-verbose=whatweb.txt
fi

# ===== 8. Directory brute-forcing =====
echo -e "\n[+] Directory brute-force..."
if command -v gobuster >/dev/null 2>&1 && [ -s live.txt ]; then
    while read -r url; do
        gobuster dir -u "$url" -w /usr/share/seclists/Discovery/Web-Content/common.txt -q | tee -a gobuster.txt
    done < live.txt
fi

# ===== 9. Nuclei vulnerability scan =====
echo -e "\n[+] Running nuclei..."
if command -v nuclei >/dev/null 2>&1 && [ -s live.txt ]; then
    nuclei -l live.txt -severity low,medium,high,critical -c 50 -o nuclei.txt
else
    echo "[!] nuclei not installed or live.txt empty"
fi

# ===== 10. Historical URLs (Wayback/Gau) =====
echo -e "\n[+] Gathering historical URLs..."
if [ -s subdomains.txt ]; then
    [ -x "$(command -v waybackurls)" ] && cat subdomains.txt | waybackurls > wayback.txt
    [ -x "$(command -v gau)" ] && cat subdomains.txt | gau > gau.txt
fi

# ===== 11. GF filters =====
echo -e "\n[+] Filtering URLs with gf..."
if command -v gf >/dev/null 2>&1; then
    mkdir -p gf_results
    for pattern in xss sqli lfi rce; do
        [ -s gau.txt ] && gf "$pattern" gau.txt > "gf_results/${pattern}.txt"
    done
fi

# ===== 12. Nmap scan =====
echo -e "\n[+] Running Nmap scan..."
if command -v nmap >/dev/null 2>&1; then
    nmap -iL live.txt -T4 -oN nmap.txt
fi

echo -e "\n=== OSINT complete. All results saved in current directory ==="
