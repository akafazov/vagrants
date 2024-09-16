# Deploying FRR with BGP configuration on Cloud-1 on Plusserver

## Prequisites
# Created VM on plusserver
# Security group of VM to allow connections on port 179

## Deploying the FRR
sudo apt-get update
sudo apt-get install -y frr frr-doc
sudo sed -e '/^\(bgpd\)=/s/no/yes/' -i /etc/frr/daemons

## Configuring FRR
# Change the IP of the neighbor in line "neighbor 213.131.230.183 peer-group uplink"

sudo tee /etc/frr/frr.conf <<EOF
frr version 8.1
frr defaults traditional
hostname cloud-2
log file /var/log/frr/frr.log debugging
log timestamp precision 3
service integrated-vtysh-config
line vty
debug bgp neighbor-events
debug bgp updates in
debug bgp updates out

interface lo
  ip address 172.33.1.1/32
exit

router bgp 65000
  bgp router-id 172.33.1.1
  bgp log-neighbor-changes
  bgp graceful-shutdown
  no bgp default ipv4-unicast
  no bgp ebgp-requires-policy

  neighbor uplink peer-group
  neighbor uplink remote-as internal
  neighbor 213.131.230.183 peer-group uplink

  address-family ipv4 unicast
    redistribute connected
    neighbor uplink activate
    neighbor uplink allowas-in origin
    neighbor uplink prefix-list only-host-prefixes out
  exit-address-family

  address-family ipv6 unicast
    redistribute connected
    neighbor uplink activate
    neighbor uplink allowas-in origin
    neighbor uplink prefix-list only-host-prefixes out
  exit-address-family

ip prefix-list only-default permit 0.0.0.0/0
ip prefix-list only-host-prefixes permit 0.0.0.0/0 ge 32

route-map rm-only-default permit 10
  match ip address prefix-list only-default
  set src 172.33.1.1

ip protocol bgp route-map rm-only-default

ipv6 prefix-list only-default permit ::/0
ipv6 prefix-list only-host-prefixes permit ::/0 ge 128

route-map rm-only-default permit 11
  match ipv6 address prefix-list only-default
  set src f00d:f00d:f00d:f00d:f00d:f00d:f00d:0030

ipv6 protocol bgp route-map rm-only-default

ip nht resolve-via-default

EOF

## Enable FRR
sudo systemctl enable frr
sudo systemctl start frr
