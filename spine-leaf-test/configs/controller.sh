#!/usr/bin/env bash
set -x
source /vagrant/utils/common-functions
install_devstack master

sleep 60

# br-ex configuration
sudo ovs-vsctl del-br br-ex
sudo ovs-vsctl add-br br-ex
sudo ip l s dev br-ex up
sudo ip a a 1.1.1.1/32 dev br-ex

# set the kernel flags
sudo sysctl -w net.ipv4.conf.all.rp_filter=0
sudo sysctl -w net.ipv4.conf.br-ex.proxy_arp=1
sudo sysctl -w net.ipv4.ip_forward=1
# for ipv6 the next are needed
# sudo sysctl -w net.ipv6.conf.br-ex.proxy_ndp=1
# sudo sysctl -w net.ipv6.all.forwarding=1

# configure node as gateway node
sudo ovs-vsctl set open . external-ids:ovn-bridge-mappings="public:br-ex"
sudo ovs-vsctl set open . external-ids:ovn-cms-options="enable-chassis-as-gw"
