# Proxmox-based Homelab

## Overview
This repository contains a self-hosted homelab setup using **Proxmox**.  
Each service runs in its own **LXC container**, with separate configurations for easier management and deployment.

## Services Included
- **Pi-hole**: Network-wide ad blocker to improve privacy and block ads at the DNS level.

## Setup
1. Clone this repository:
   ```sh
   git clone https://github.com/sourabh-pisal/homelab.git
   cd homelab
   ```
1. Deploy pihole:
   ```sh
   ./create_pihole.sh -p "your_root_password" -i "192.168.0.2/24" -v "1001"
   ```
