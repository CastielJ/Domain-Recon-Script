# Deeper OSINT

**Deeper OSINT** is an advanced Bash script for **comprehensive reconnaissance** of a target domain.  
It automates subdomain enumeration, live host detection, technology fingerprinting, vulnerability scanning, and more — leveraging multiple powerful OSINT tools.

> ⚠️ For **authorized security testing only**. Do not use against targets without explicit permission.

---

## 📌 Features

- **Subdomain enumeration** via:
  - [Subfinder](https://github.com/projectdiscovery/subfinder)
  - [Amass](https://github.com/owasp-amass/amass)
  - crt.sh certificate transparency logs

- **DNS information**: WHOIS, DIG

- **SSL/TLS scanning**: [sslscan](https://github.com/rbsec/sslscan)

- **Live host detection**: [httpx](https://github.com/projectdiscovery/httpx)

- **Web technology fingerprinting**: [WhatWeb](https://github.com/urbanadventurer/WhatWeb)

- **Directory brute-forcing**: [Gobuster](https://github.com/OJ/gobuster)

- **Vulnerability scanning**: [Nuclei](https://github.com/projectdiscovery/nuclei)

- **Historical URL gathering**:
  - [waybackurls](https://github.com/tomnomnom/waybackurls)
  - [gau](https://github.com/lc/gau)

- **Parameter discovery**: [gf](https://github.com/tomnomnom/gf) patterns

- **Port scanning**: [Nmap](https://nmap.org/)

---

## 🚀 Installation

Clone this repository:
```bash
git clone https://github.com/<your-username>/deeper-osint.git
cd deeper-osint
chmod +x deeper-osint.sh
```

Install dependencies

On Kali Linux:

sudo apt update && sudo apt install -y golang subfinder amass whois dnsutils curl jq sslscan whatweb gobuster nmap git

# Install Go-based tools
go install github.com/projectdiscovery/httpx/cmd/httpx@latest
go install github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest
go install github.com/tomnomnom/waybackurls@latest
go install github.com/lc/gau/v2/cmd/gau@latest
go install github.com/tomnomnom/gf@latest

# Install GF patterns
mkdir -p ~/.gf
git clone https://github.com/1ndianl33t/Gf-Patterns ~/.gf

# Make sure Go bin is in PATH
echo 'export PATH=$PATH:$(go env GOPATH)/bin' >> ~/.zshrc && source ~/.zshrc

🛠 Usage

./deeper-osint.sh <domain>
./deeper-osint.sh example.com

Results will be saved into the current directory:

subdomains.txt
live.txt
whois.txt
dig.txt
sslscan.txt
whatweb.txt
gobuster.txt
nuclei.txt
wayback.txt
gau.txt
gf_results/
nmap.txt

📂 Output Example

[+] Gathering subdomains...
[*] Found 124 subdomains

[+] Checking live hosts...
[*] 37 live hosts found

[+] Running nuclei...
[INF] Nuclei Engine Version: v3.4.6
[INF] Templates loaded: 6,400+
[INF] Scan completed in 1m43s


⚠️ Disclaimer

This tool is for authorized security testing and educational purposes only.
The author is not responsible for any misuse or damage caused.
