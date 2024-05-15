# Deploying FRR with BGP configuration on Cloud-1 on Plusserver

## Prequisites
# Created VM on plusserver
# Security group of VM to allow connections on port 179

## Deploying the FRR
sudo apt-get update
sudo apt-get install -y frr frr-doc
sudo sed -e '/^\(bgpd\)=/s/no/yes/' -i /etc/frr/daemons

## Configuring FRR
# Change the IP of the neighbors (dc1-gw & cloud-2) in lines starting with "neighbor" and IP

sudo tee /etc/frr/frr.conf <<EOF
frr version 8.1
frr defaults traditional
hostname dc2-gw
log file /var/log/frr/frr.log debugging
log timestamp precision 3
service integrated-vtysh-config
line vty
debug bgp neighbor-events
debug bgp updates in
debug bgp updates out

router bgp 65000
  bgp router-id 172.32.1.1
  bgp log-neighbor-changes
  bgp graceful-shutdown
  no bgp default ipv4-unicast
  no bgp ebgp-requires-policy
  bgp disable-ebgp-connected-route-check

  neighbor downlink peer-group
  neighbor downlink remote-as internal
  neighbor 213.131.230.39 peer-group downlink
  neighbor 213.131.230.19 remote-as 64999
  neighbor 213.131.230.19 ebgp-multihop 20

  address-family ipv4 unicast
    #redistribute connected
    neighbor downlink activate
    neighbor downlink soft-reconfiguration inbound
    neighbor downlink route-map ALLOW_ALL in
    neighbor downlink route-map ALLOW_ALL out
    neighbor 213.131.230.19 activate
    neighbor 213.131.230.19 soft-reconfiguration inbound
    neighbor 213.131.230.19 route-map ALLOW_ALL in
    neighbor 213.131.230.19 route-map ALLOW_ALL in
  exit-address-family

  address-family ipv6 unicast
    #redistribute connected
    neighbor downlink activate
    neighbor downlink soft-reconfiguration inbound
    neighbor downlink route-map ALLOW_ALL in
    neighbor downlink route-map ALLOW_ALL out
    neighbor 213.131.230.19 activate
    neighbor 213.131.230.19 soft-reconfiguration inbound
    neighbor 213.131.230.19 route-map ALLOW_ALL in
    neighbor 213.131.230.19 route-map ALLOW_ALL in
  exit-address-family

route-map ALLOW_ALL permit 10

ip nht resolve-via-default

EOF

## Enable FRR
sudo systemctl enable frr
sudo systemctl start frr
