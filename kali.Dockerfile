# ─────────────────────────────────────────────────────────────
#   Kali (Attacker) image with all required pentest tools
# ─────────────────────────────────────────────────────────────
FROM kalilinux/kali-rolling

# Core toolset: nmap, metasploit, scapy, packet capture & replay, ping
RUN apt update && \
    DEBIAN_FRONTEND=noninteractive apt -y install \
        nmap \
        metasploit-framework \
        python3-scapy \
        tcpdump \
        tcpreplay \
        iputils-ping

# Start in an interactive shell by default
CMD ["bash"]
