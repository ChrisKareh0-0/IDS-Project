## Abstract

This research paper provides a comprehensive walkthrough and technical explanation of constructing an Intrusion Detection System (IDS) lab using Docker containers and Snort. It includes the rationale, structure, tooling, dataset usage, and traffic simulation with step-by-step annotations of every command and configuration. This work enables reproducible experimentation with network traffic inspection using Snort and replay-based detection using PCAP datasets.

---

## 1. Introduction

Intrusion Detection Systems (IDS) are fundamental in monitoring, detecting, and alerting administrators of potentially malicious activities within networks. This paper presents a practical and replicable method to deploy a full IDS lab using Docker containers, featuring a Snort-based IDS, a Kali-based attacker node, and a Metasploitable vulnerable target.

---

## 2. Project Structure

The following structure defines our project workspace:

```
ids-lab/
├── docker-compose.yml             # Defines container relationships and networking
├── kali.Dockerfile                # Optional: Extend Kali tools setup
├── ubuntu-snort.Dockerfile        # Builds a container with Snort and utilities
├── dataset/                       # Stores PCAP files used for traffic replay
│   └── Friday-WorkingHours.pcap   # Example PCAP from CICIDS2017 dataset
```

---

## 3. Environment Setup

### 3.1 Create Project Directory

```bash
mkdir -p ~/Documents/freelance/ids-lab && cd ~/Documents/freelance/ids-lab
mkdir dataset
```

- `mkdir -p`: Creates nested directories if they do not exist.
    
- `cd`: Changes into the new directory to perform all operations in this workspace.
    

### 3.2 Define Containers with docker-compose.yml

This file defines 3 services and a bridge network:

```yaml
version: "3.9"  # Compose file format version

networks:
  pentest-net:
    driver: bridge
    ipam:
      config:
        - subnet: 192.168.56.0/24
```

- `bridge`: Simulates a LAN-like environment between containers.
    
- `subnet`: Assigns a static subnet for predictable IPs.
    

Each service block defines a container:

#### Kali Linux (Attacker)

```yaml
  kali:
    image: kalilinux/kali-rolling
    container_name: kali_ct
    networks:
      pentest-net:
        ipv4_address: 192.168.56.10
    cap_add: [NET_RAW, NET_ADMIN]
    tty: true
    command: >
      sh -c "apt update && \
             apt -y install nmap metasploit-framework python3-scapy tcpdump tcpreplay iputils-ping && \
             bash"
```

- `cap_add`: Grants low-level network access (e.g., raw sockets).
    
- `command`: Installs necessary tools like `nmap`, `metasploit`, `tcpreplay`, and opens a Bash shell.
    

#### Metasploitable (Target)

```yaml
  metasploitable:
    image: peakkk/metasploitable:latest
    container_name: metasploitable_ct
    networks:
      pentest-net:
        ipv4_address: 192.168.56.20
    tty: true
```

- This image simulates an exploitable Linux machine with insecure services enabled.
    

#### Ubuntu Snort (IDS)

```yaml
  ubuntu_snort:
    build:
      context: .
      dockerfile: ubuntu-snort.Dockerfile
    container_name: ubuntu_snort_ct
    networks:
      pentest-net:
        ipv4_address: 192.168.56.30
    cap_add: [NET_ADMIN]
    volumes:
      - ./dataset:/pcaps
```

- `cap_add`: Allows packet sniffing.
    
- `volumes`: Mounts the dataset folder for Snort to access PCAPs.
    

---

## 4. Dockerfile – Snort Installation

### ubuntu-snort.Dockerfile

```Dockerfile
FROM ubuntu:22.04
RUN apt update && \
    DEBIAN_FRONTEND=noninteractive apt install -y snort tcpreplay curl iputils-ping && \
    mkdir -p /var/log/snort && \
    touch /var/log/snort/alert
CMD ["snort", "--daq", "afpacket", "-i", "eth0", "-A", "fast", "-c", "/etc/snort/snort.conf"]
```

- `tcpreplay`: Used for sending `.pcap` files over the network.
    
- `--daq afpacket`: Specifies data acquisition method compatible with Linux.
    
- `-A fast`: Logs alerts in a human-readable format.
    

---

## 5. Obtaining Datasets

Example command:

```bash
curl -L -o dataset/Friday-WorkingHours.pcap \
  https://huggingface.co/datasets/cicids2017/resolve/main/pcap/Friday-WorkingHours.pcap
```

- `-L`: Follows redirections.
    
- `-o`: Outputs to a specific file.
    

---

## 6. Starting the Lab

```bash
docker compose up -d --build
docker compose ps
```

- `-d`: Runs in detached mode.
    
- `--build`: Rebuilds images if necessary.
    
- `ps`: Confirms containers are running.
    

---

## 7. Replaying Network Traffic

To simulate network activity:

```bash
docker compose exec ubuntu_snort \
  tcpreplay --intf1=eth0 /pcaps/Friday-WorkingHours.pcap
```

- `exec`: Runs a command inside the container.
    
- `tcpreplay`: Sends packets over `eth0` interface.
    

---

## 8. Verifying Snort Output

```bash
docker compose exec ubuntu_snort tail -f /var/log/snort/alert
```

- `tail -f`: Streams Snort alert log in real time.
    

Sample output:

```
[**] [1:1000001:0] Example Rule Match [**]
[Priority: 1]
```

---

## 9. Custom Snort Rules

To test detection customization:

1. Edit `snort.conf` to include:
    

```
include $RULE_PATH/local.rules
```

2. Add a rule to `local.rules`:
    

```
alert tcp any any -> any 80 (msg:"HTTP traffic detected"; sid:1000001; rev:1;)
```

3. Restart Snort:
    

```bash
docker compose restart ubuntu_snort
```

---

## 10. Conclusion

This setup provides a controlled, repeatable, and easily modifiable lab to study intrusion detection using real network captures. The combination of Docker, Snort, and PCAP replay enables students, researchers, and professionals to analyze attack patterns, validate rules, and build familiarity with IDS architecture.

Future work can extend this setup to include:

- Suricata for comparative IDS testing
    
- Bro/Zeek for advanced traffic analysis
    
- Log aggregation and dashboarding (e.g., ELK stack)
    

This lab is a foundational framework for cybersecurity education and IDS rule development.