#!/bin/bash

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root."
    exit 1
fi

# Function to display usage
usage() {
    echo "Usage: $0 -p <root_password> -i <ipv4_address> -v <vmid> -s <storage> [-h <hostname>]"
    echo
    echo "Options:"
    echo "  -p  Root password for the LXC container"
    echo "  -i  IPv4 address (e.g., 192.168.1.100/24)"
    echo "  -v  VMID for the new container"
    echo "  -s  Proxmox storage name (e.g., 'local-lvm' or 'local')"
    echo "  -h  Hostname for the container (default: 'pihole-lxc')"
    echo
    exit 1
}

# Default values
HOSTNAME="pihole"
STORAGE="local-lvm"

# Parse command-line arguments
while getopts "p:i:v:s:h:" opt; do
    case "${opt}" in
        p) ROOT_PASS="${OPTARG}" ;;
        i) IPV4_ADDR="${OPTARG}" ;;
        v) VMID="${OPTARG}" ;;
        s) STORAGE="${OPTARG}" ;;
        h) HOSTNAME="${OPTARG}" ;;
        *) usage ;;
    esac
done

# Validate required arguments
if [[ -z "$ROOT_PASS" || -z "$IPV4_ADDR" || -z "$VMID" ]]; then
    usage
fi

# Extract IP and subnet mask from provided IPV4 address (e.g., 192.168.1.100/24)
IP_ADDR_NO_CIDR=$(echo "$IPV4_ADDR" | cut -d'/' -f1)
SUBNET_MASK=$(echo "$IPV4_ADDR" | cut -d'/' -f2)

# Calculate gateway IP (default behavior assumes it's .1 of the subnet)
IFS='.' read -r -a IP_ARRAY <<< "$IP_ADDR_NO_CIDR"
GATEWAY="${IP_ARRAY[0]}.${IP_ARRAY[1]}.${IP_ARRAY[2]}.1"

# Create Debian 12 LXC container
pct create $VMID local:vztmpl/debian-12-standard_12.7-1_amd64.tar.zst \
    -features nesting=1 \
    -hostname $HOSTNAME \
    -password $ROOT_PASS \
    -net0 name=eth0,bridge=vmbr0,ip=$IPV4_ADDR,gw=$GATEWAY \
    -storage $STORAGE \
    -cores 2 \
    -memory 512 \
    -swap 512 \
    -unprivileged 1

# Set the container to start automatically on boot
pct set $VMID -onboot 1

# Start the container
pct start $VMID

# Wait for network to come up
sleep 10

# Install dependencies and create setupVars.conf for unattended install
pct exec $VMID -- bash -c "
    apt update && apt install -y curl
    mkdir -p /etc/pihole
    cat <<EOF > /etc/pihole/setupVars.conf
PIHOLE_INTERFACE=eth0
IPV4_ADDRESS=$IP_ADDR_NO_CIDR
PIHOLE_DNS_1=8.8.8.8
PIHOLE_DNS_2=8.8.4.4
QUERY_LOGGING=true
INSTALL_WEB_SERVER=true
INSTALL_WEB_INTERFACE=true
LIGHTTPD_ENABLED=true
EOF
    curl -sSL https://install.pi-hole.net | bash /dev/stdin --unattended
    /usr/local/bin/pihole setpassword $ROOT_PASS
"

# Display completion message
echo "Pi-hole LXC setup complete! Access it at http://$IP_ADDR_NO_CIDR/admin/ with the web password: $ROOT_PASS"
