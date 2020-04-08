# Requirements
- docker
- docker-compose

# Install
- `docker-compose build`
- `docker-compose up`
- set device DNS server to your machines IP address

# Usage

## OSX
- `IPADDRESS=$(ifconfig | grep 192 | awk '{print $2}') docker-compose up`