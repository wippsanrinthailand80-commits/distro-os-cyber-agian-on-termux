# PhantomSec OS — Usage Guide

## Getting Started

### 1. Install
```bash
git clone https://github.com/wippsanrinthailand80-commits/distro-os-cyber-agian-on-termux
cd distro-os-cyber-agian-on-termux
bash install.sh
```

### 2. Launch
```bash
phantomsec
# or
bash phantomsec.sh
```

---

## Menu Navigation

- Type the number and press **ENTER** to select
- Type `0` to go back to the previous menu
- Press `Ctrl+C` to force-quit at any time

---

## Example Workflows

### CTF Recon Flow
1. Main Menu → `01` Information Gathering
2. → `1` Nmap (scan all ports)
3. → `2` Whois (gather domain info)
4. → `3` DNS Enumeration
5. Reports saved in `~/.phantomsec/reports/`

### Web App Pentest Flow
1. Main Menu → `02` Vulnerability Scanning → `5` Nmap Vuln Script
2. Main Menu → `03` Web Exploitation → `1` SQLMap
3. Main Menu → `03` Web Exploitation → `3` Directory Bruteforce
4. Main Menu → `03` Web Exploitation → `5` CORS Check

### Password Attack Flow
1. Main Menu → `04` Password Attacks → `5` Download wordlist
2. → `1` Hydra with SSH/FTP target
3. → `2` Hash Identifier on found hashes
4. → `3` Online hash crack attempt

---

## Tips

- **Reports** are auto-saved to `~/.phantomsec/reports/` for every scan
- **Logs** are saved to `~/.phantomsec/logs/`
- Run `bash modules/recon.sh example.com` for a quick recon without the menu
- Set your Shodan API key in Settings (option 12) for more powerful searches
- Use the **Matrix theme** (`bash themes/matrix.sh`) for style 😄

---

## Troubleshooting

| Issue | Fix |
|---|---|
| `nmap: command not found` | Run Tool Manager → Install Missing Tools |
| `sqlmap: command not found` | `pkg install sqlmap` |
| Permission denied on phantomsec | `chmod +x $PREFIX/bin/phantomsec` |
| Slow internet speeds | Use a VPN or check your connection |
| `hydra` fails immediately | Check target is reachable: `ping target` |
