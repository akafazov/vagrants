# Changes

## Network
- install vagrant scp plugin
```bash
vagrant plugin install vagrant-scp
```
- fix Cumulus version to 4.4 for the switches
```bash
vagrant up
sleep 60
```
- wait/disable ZTP on spine/leafs before configuring them
```bash
# disable ZTP
vagrant ssh spine-1 -c "sudo ztp -d"
vagrant ssh spine-2 -c "sudo ztp -d"
vagrant ssh rack-1-leaf-1 -c "sudo ztp -d"
vagrant ssh rack-1-leaf-2 -c "sudo ztp -d"
vagrant ssh rack-2-leaf-1 -c "sudo ztp -d"
vagrant ssh rack-2-leaf-2 -c "sudo ztp -d"
sleep 30
```

- configure network

```bash
# configure spines
vagrant scp configs/config-spine-1.sh spine-1:.
vagrant ssh spine-1 -c "chmod +x config-spine-1.sh"
vagrant ssh spine-1 -c ./config-spine-1.sh

vagrant scp configs/config-spine-2.sh spine-2:.
vagrant ssh spine-2 -c "chmod +x config-spine-2.sh"
vagrant ssh spine-2 -c ./config-spine-2.sh

# configure leafs
./create-spine-configs.sh

# configure swp1 and swp2 on rack-X-leaf-1
RACKS=(1 2)
for rack in "${RACKS[@]}"
do
    VM=rack-$rack-leaf-1
    vagrant ssh $VM -c "sudo ip addr add 100.65.$rack.1/30 dev swp1"
    vagrant ssh $VM -c "sudo ip addr add 100.65.$rack.5/30 dev swp2"
done

# configure swp1 and swp2 on rack-X-leaf-2
RACKS=(1 2)
for rack in "${RACKS[@]}"
do
    VM=rack-$rack-leaf-2
    vagrant ssh $VM -c "sudo ip addr add 100.65.0.1/30 dev swp1"
    vagrant ssh $VM -c "sudo ip addr add 100.65.0.5/30 dev swp2"
done

```

























## Hosts

- fix apt repositories (on Hosts)

```bash
### Fix packages for CentOS
LEAFS=(1 2)
RACKS=(1 2)
for rack in "${RACKS[@]}"
do
    for leaf in "${LEAFS[@]}"
    do
        VM=rack-$rack-host-$leaf
        vagrant ssh $VM -c "sudo sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-*"
        vagrant ssh $VM -c "sudo sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-*"
        vagrant ssh $VM -c "sudo yum update -y"
    done
done


# Install FRR
LEAFS=(1 2)
RACKS=(1 2)
for rack in "${RACKS[@]}"
do
    for leaf in "${LEAFS[@]}"
    do
        VM=rack-$rack-host-$leaf
        vagrant ssh $VM -c "sudo yum install -y frr"
        vagrant ssh $VM -c "sudo sed -e '/^\(zebra\|bgpd\)=/s/no/yes/' -i /etc/frr/daemons"
        vagrant ssh $VM -c "sudo sed -e '/^zebra_options/s/-A 127.0.0.1 -s 90000000/-A 127.0.0.1 --vrfwnetns/' -i /etc/frr/daemons"
    done
done


# Configure FRR
RACKS=(1 2)
HOSTS=(1 2)
for rack in "${RACKS[@]}"
do
    for host in "${HOSTS[@]}"
    do
        VM=rack-$rack-host-$host
        cat > configs/frr-rack-$rack-host-$host.conf <<EOF
frr version 7.0
frr defaults traditional
hostname worker1
no ipv6 forwarding
!
router bgp 64999
 bgp router-id 99.99.$rack.$host
 bgp log-neighbor-changes
 neighbor eth1 interface remote-as 64999
 neighbor eth2 interface remote-as 64999
 !
 address-family ipv4 unicast
  redistribute connected
  neighbor eth1 prefix-list only-host-prefixes out
  neighbor eth1 allowas-in origin
  neighbor eth2 prefix-list only-host-prefixes out
  neighbor eth2 allowas-in origin
 exit-address-family
!
ip prefix-list only-default permit 0.0.0.0/0
ip prefix-list only-host-prefixes permit 0.0.0.0/0 ge 32
!
ip protocol bgp route-map out_32_prefixes 
!
route-map out_32_prefixes permit 10
 match ip address prefix-list only-default
 set src 99.99.$rack.$host
!
line vty
!
EOF
        vagrant scp configs/frr-rack-$rack-host-$host.conf $VM:.
        vagrant ssh $VM -c "sudo mv frr-rack-$rack-host-$host.conf /etc/frr/frr.conf"
    done
done

# configure the NICs on hosts
RACKS=(1 2)
HOSTS=(1 2)
for rack in "${RACKS[@]}"
do
    for host in "${HOSTS[@]}"
    do
        VM=rack-$rack-host-$host
        let "Z=2+4*($rack-1)"
        vagrant ssh $VM -c "sudo ip addr add 99.99.$rack.$host/32 dev lo"
        vagrant ssh $VM -c "sudo ip addr add 100.65.$rack.$Z/30 dev eth1"
        vagrant ssh $VM -c "sudo ip addr add 100.64.0.$Z/30 dev eth2"
        vagrant ssh $VM -c "sudo systemctl enable frr"
        vagrant ssh $VM -c "sudo systemctl start frr"
    done
done
```

- change the ip of the controller before installing DevStack
```bash
vagrant ssh rack-1-host-1 -c "sed -i 's|ip=${!hostname}|ip=99.99.1.1|g' /vagrant/utils/common-functions"
```

Devstack requires python3.7 but CentOS comes with python3.6



<!-- 
- DevStack installation on controller
```bash
vagrant scp configs/controller.sh rack-1-host-1:.
vagrant ssh rack-1-host-1 -c "chmod +x controller.sh"
vagrant ssh rack-1-host-1 -c ./controller.sh

# set default route
sudo ip route a 0.0.0.0/0 src 99.99.1.1 nexthop via 100.65.1.1 dev eth1 nexthop via 100.64.0.1 dev eth2
```
 -->


