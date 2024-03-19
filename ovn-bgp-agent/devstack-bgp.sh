set -v

sudo sysctl -w  net.ipv6.conf.all.disable_ipv6=0
sudo apt-get install -y git vim tmux


sudo mkdir /opt/stack
sudo chown vagrant:root /opt/stack
cd /opt/stack/
git clone https://opendev.org/openstack/ovn-bgp-agent

cd
git clone https://opendev.org/openstack/devstack
cp /opt/stack/ovn-bgp-agent/devstack/local.conf.sample devstack/local.conf
cd devstack
./stack.sh

