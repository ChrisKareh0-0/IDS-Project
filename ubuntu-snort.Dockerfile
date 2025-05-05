# ─────────────────────────────────────────────────────────────
#   Ubuntu 22.04 image with Snort 2, default rule-set & tcpreplay
# ─────────────────────────────────────────────────────────────
FROM ubuntu:22.04

# Enable "universe" repository, then install Snort, rules & helpers
RUN set -e && \
    apt update && \
    apt -y install software-properties-common && \
    add-apt-repository -y universe && \
    apt update && \
    DEBIAN_FRONTEND=noninteractive apt -y install \
        snort \
        snort-rules-default \
        tcpreplay \
        curl

# Run Snort in fast-alert mode on eth0 as PID 1
CMD ["/usr/sbin/snort", "--daq", "afpacket",
     "-i", "eth0", "-A", "fast", "-c", "/etc/snort/snort.conf"]
