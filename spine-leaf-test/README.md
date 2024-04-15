### Changes

- wait/disable ZTP on spine/leafs before configuring them
- fix Cumulus version to 4.4 for the switches
- fix apt repositories

```bash
### Fix packages for CentOS
cd /etc/yum.repos.d/
sudo sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-*
sudo sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-*
sudo yum update -y
```

- change the ip of the controller before installing DevStack
```bash
vagrant ssh rack-1-host-1 -c "sed -i 's|ip=${!hostname}|ip=99.99.1.1|g' /vagrant/utils/common-functions"
```

- install vagrant scp plugin
```bash
vagrant plugin install vagrant-scp
```

- DevStack installation on controller
```bash
vagrant scp configs/controller.sh rack-1-host-1:.
vagrant ssh rack-1-host-1 -c "chmod +x controller.sh"
vagrant ssh rack-1-host-1 -c ./controller.sh

# set default route
sudo ip route a 0.0.0.0/0 src 99.99.1.1 nexthop via 100.65.1.1 dev eth1 nexthop via 100.64.0.1 dev eth2
```



