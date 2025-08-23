---

# deeper-osint.sh

A **comprehensive OSINT & recon automation script** for penetration testers, bug bounty hunters, and security researchers.
It gathers information about a target domain and stores results both as **organized output files** and in a **single combined report**.

---

## Features

* **Subdomain Enumeration**: `subfinder`, `amass`, `crt.sh`
* **DNS & WHOIS Lookup**
* **SSL/TLS Analysis**: `sslscan` + live certificate extraction (issuer, subject, validity, fingerprints, expiry check)
* **IP & Reverse PTR Lookup**
* **Technology Fingerprinting**: `whatweb`
* **Live Host Detection**: `httpx`
* **Directory Brute Force**: `gobuster` with Seclists wordlists
* **Vulnerability Scanning**: `nuclei`
* **Historical URLs**: `waybackurls`, `gau`
* **Parameter Discovery**: `gf` patterns (XSS, SQLi, LFI, RCE)
* **Screenshots** *(optional)*: `gowitness`
* **ASN Discovery & Scanning** *(optional)*: `amass`, `naabu`
* **Port Scanning**: `nmap` (placed at the very end)
* **Unified Report**: all results combined in `full_report.txt`
* **Organized Outputs**: structured into `results_<domain>/`

---

## 📂 Output Structure

When scanning `example.com`, results are saved in:

```
results_example.com/
├── asn_ports.txt
├── crtsh_raw.txt
├── dns.txt
├── full_report.txt       # combined report with all results
├── gobuster.txt
├── gau.txt
├── gf_results/
│   ├── lfi.txt
│   ├── rce.txt
│   ├── sqli.txt
│   └── xss.txt
├── live.txt
├── live_cert.txt
├── nmap.txt
├── nuclei.txt
├── ptr.txt
├── screenshots/
├── ssl_summary.txt
├── sslscan.txt
├── subdomains.txt
├── summary.txt
├── wayback.txt
├── whatweb.txt
└── whois.txt
```

## Dependencies

This script relies on several tools. Install them on **Kali Linux** (or Debian-based systems):

```bash
sudo apt update && sudo apt install -y \
    subfinder amass whois dnsutils curl jq sslscan host whatweb gobuster nmap openssl
```

Additional tools via Go:

```bash
go install github.com/projectdiscovery/httpx/cmd/httpx@latest
go install github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest
go install github.com/tomnomnom/waybackurls@latest
go install github.com/lc/gau/v2/cmd/gau@latest
go install github.com/tomnomnom/gf@latest
```

Optional:

```bash
go install github.com/sensepost/gowitness@latest
go install github.com/projectdiscovery/naabu/v2/cmd/naabu@latest
```

Make sure Go binaries are in your PATH:

```bash
echo 'export PATH=$PATH:~/go/bin' >> ~/.bashrc
source ~/.bashrc
```

---

## Usage

```bash
./deeper-osint.sh
```

When prompted, enter the target domain (e.g., `example.com`).
Results will be saved in `results_example.com/`.

---

## ⚠️ Disclaimer

This script is for **educational and security research purposes only**.
Use it **only on domains you own or have explicit permission to test**.
The author is not responsible for misuse or damage caused by this tool.

---

Happy hunting & stay ethical!

---
