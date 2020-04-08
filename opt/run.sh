#!/usr/bin/env bash

if [[ -z "$IPADDRESS" ]]; then
  >&2 echo "Please provide your IP address"
  >&2 echo "eg: IPADDRESS=192.168.1.42 docker-compose up"
  exit 1
fi

echo "Your IP (DNS server): $IPADDRESS"

zones=""

IFS=';' read -ra entries <<< "$HOSTS"
for zone in "${entries[@]}"; do
  zone="${zone#"${zone%%[![:space:]]*}"}"
  zone="${zone%"${zone##*[![:space:]]}"}"
  echo "Routing $zone to $IPADDRESS";
  zones="$zones
  $(cat << !
zone "$zone" IN {
  type master;
  file "$zone.zone";
};
!
)

"
  cat << ! > /var/bind/$zone.zone
\$TTL    3600
@       IN      SOA     ns1 root (
                              1         ; Serial
                         3600         ; Refresh
                          300         ; Retry
                         3600         ; Expire
                         300 )        ; Negative Cache TTL


        IN      NS      ns1
        IN      NS      ns2
        IN      A       $IPADDRESS


ns1     IN      A       127.0.0.1
ns2     IN      A       127.0.0.1

* IN A  $IPADDRESS
!
  done

cat << ! > /etc/bind/named.conf
options {
  directory "/var/bind";
  pid-file "/var/run/named/named.pid";
  listen-on { any; };
  recursion yes;
  dnssec-enable no;

  allow-recursion { any; };
  allow-query { any; };
  allow-query-cache { any; };
  forwarders {
    127.0.0.11;
  };
};

$zones
!

if named-checkconf; then
  named -f
fi