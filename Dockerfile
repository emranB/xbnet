FROM rust:latest

# Install necessary packages
RUN apt-get update && apt-get install -y \
    libudev-dev \
    iproute2 \
    iputils-ping \
    net-tools \
    bridge-utils \
    iptables \
    traceroute \
    nmap \
    tcpdump \ 
    util-linux \
    bsdmainutils \
    vim \
    openssh-server \
    && rm -rf /var/lib/apt/lists/*

# Create necessary directories for SSH
RUN mkdir /var/run/sshd

# Create the user 'spiri' and set passwords for both 'root' and 'spiri'
RUN useradd -m spiri && \
    echo 'root:spiri-friend' | chpasswd && \
    echo 'spiri:spiri-friend' | chpasswd && \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config

# Expose SSH port
EXPOSE 22

# Clone the xbnet repository
RUN git clone https://github.com/jgoerzen/xbnet.git /usr/src/xbnet

# Build xbnet
WORKDIR /usr/src/xbnet
RUN cargo build --release

# Copy the built binary to /usr/local/bin
RUN cp target/release/xbnet /usr/local/bin/xbnet

# Copy the entrypoint script
COPY ./scripts/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Copy the set-env-vars.sh script to set env vars
COPY ./scripts/set-env-vars.sh /set-env-vars.sh
RUN chmod +x /set-env-vars.sh

# Copy the health check script
COPY ./scripts/health-check.sh /health-check.sh
RUN chmod +x /health-check.sh

# TEST
COPY ./scripts/debug/host-setup-docker.sh /host-setup-docker.sh
RUN chmod +x /host-setup-docker.sh

# Add healthcheck
HEALTHCHECK CMD /health-check.sh || exit 1
