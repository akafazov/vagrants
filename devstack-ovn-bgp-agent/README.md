# Deploying OVN BGP Agent with DevStack

## Prequisites

* Vagrant
* VirtualBox

## Steps to deploy

### Start and provision the vagrant environment

```sh
vagrant up --provider=virtualbox
```

### Access the ovn-bgp container

```sh
vagrant ssh vm1
```

### Install devstack with ovn-bgp agent enabled

Execute the following commands to prepare the Virtual Machine for DevStack installation.

```sh
sudo sysctl -w net.ipv6.conf.all.disable_ipv6=0
sudo apt-get install -y git vim tmux

sudo mkdir /opt/stack
sudo chown vagrant:root /opt/stack
cd /opt/stack/
git clone https://opendev.org/openstack/ovn-bgp-agent

cd
git clone https://opendev.org/openstack/devstack

cd devstack
```

### Create ./local.conf file with the following configuration:

```ini
[[local|localrc]]

HOST_IP=192.168.57.101

DATABASE_PASSWORD=password
RABBIT_PASSWORD=password
SERVICE_PASSWORD=password
SERVICE_TOKEN=password
ADMIN_PASSWORD=password

Q_AGENT=ovn
Q_ML2_PLUGIN_MECHANISM_DRIVERS=ovn,logger
Q_ML2_PLUGIN_TYPE_DRIVERS=local,flat,vlan,geneve
Q_ML2_TENANT_NETWORK_TYPE="geneve"

# Enable devstack spawn logging
LOGFILE=$DEST/logs/stack.sh.log

enable_service ovn-northd
enable_service ovn-controller
enable_service q-ovn-metadata-agent

# Use Neutron
enable_service q-svc

# Disable Neutron agents not used with OVN.
disable_service q-agt
disable_service q-l3
disable_service q-dhcp
disable_service q-meta

# Enable services, these services depend on neutron plugin.
enable_plugin neutron https://opendev.org/openstack/neutron
enable_service q-trunk
enable_service q-dns
enable_service q-port-forwarding
enable_service q-qos
enable_service neutron-segments
enable_service q-log

enable_plugin networking-bgpvpn https://git.openstack.org/openstack/networking-bgpvpn.git

# Horizon (the web UI) is enabled by default. You may want to disable
# it here to speed up DevStack a bit.
enable_service horizon
# disable_service horizon

# Cinder (OpenStack Block Storage) is disabled by default to speed up
# DevStack a bit. You may enable it here if you would like to use it.
disable_service cinder c-sch c-api c-vol
#enable_service cinder c-sch c-api c-vol

# Enable SSL/TLS
ENABLE_TLS=True
enable_service tls-proxy

# Enable ovn-bgp-agent
enable_plugin ovn-bgp-agent https://opendev.org/openstack/ovn-bgp-agent


# Whether or not to build custom openvswitch kernel modules from the ovs git
# tree. This is disabled by default.  This is required unless your distro kernel
# includes ovs+conntrack support.  This support was first released in Linux 4.3,
# and will likely be backported by some distros.
# NOTE(mjozefcz): We need to compile the module for Ubuntu Bionic, because default
# shipped kernel module doesn't openflow meter action support.
OVN_BUILD_MODULES=True
OVN_BUILD_FROM_SOURCE=true
OVN_BRANCH=main
OVS_BRANCH=branch-3.3


# If the admin wants to enable this chassis to host gateway routers for
# external connectivity, then set ENABLE_CHASSIS_AS_GW to True.
# Then devstack will set ovn-cms-options with enable-chassis-as-gw
# in Open_vSwitch table's external_ids column.
# If this option is not set on any chassis, all the of them with bridge
# mappings configured will be eligible to host a gateway.
ENABLE_CHASSIS_AS_GW=True

[[post-config|$NOVA_CONF]]
[scheduler]
discover_hosts_in_cells_interval = 2
```

### Install devstack

```sh
./stack.sh
```

> **Note:** This step will take around 15-30 minutes to complete.

### Change the driver to EVPN

Open /etc/ovn-bgp-agent/bgp-agent.conf and change the driver to ovn_evpn_driver

```
driver = ovn_evpn_driver
```

Restart the devstack service

```sh
sudo systemctl restart devstack@ovn-bgp-agent.service
```

## Create the OpenStack resources

### Export environment variables for OpenStack client

Export the necessary environment variables to connect to the OpenStack API.

```sh
export OS_IDENTITY_API_VERSION=3
export OS_AUTH_URL=https://192.168.57.101/identity/
export OS_DEFAULT_DOMAIN=default
export OS_USERNAME=admin
export OS_PASSWORD=password
export OS_PROJECT_NAME=admin
```

### Create network

Create a new network in OpenStack.

```sh
openstack network create demo-net
```

### Create subnet

Create a new subnet in the previously created network.

```sh
openstack subnet create --network demo-net \
  --subnet-range 192.168.0.0/24 \
  --gateway 192.168.0.1 \
  demo-subnet
```

### Create a router

Create a new router and connect it to the subnet.

```sh
openstack router create demo-router
openstack router add subnet demo-router demo-subnet
openstack router set demo-router --external-gateway public
```

### Create a floating IP address

Create a new floating IP address.

```sh
$(openstack floating ip create public -c id -f value)
```

### Create a keypair for the VM

Create a new keypair for the virtual machine.

```sh
openstack keypair create test-key > test.pem
chmod 600 test.pem
```

### Create VM

Create a new virtual machine using the previously created resources.

```sh
openstack server create --flavor m1.small --image $(openstack image show cirros-0.6.2-x86_64-disk -f value -c id) --nic net-id=$(openstack network show demo-net -f value -c id) --security-group $(openstack security group list -f value -c ID -c Name --project $(openstack project show admin -f value -c id) | grep default | awk '{print $1}' ) --key-name test-key demo-vm1
```

### Assign the floating IP address to the VM

Assign the floating IP address to the virtual machine.

```sh
openstack floating ip set --port $(openstack port list --device-id $(openstack server show demo-vm1 -c id -f value) --fixed-ip subnet=$(openstack subnet show demo-subnet -f value -c id) -f value -c ID) $(openstack floating ip list --project $(openstack project show admin -f value -c id)  --status DOWN -c ID -f value | head -1)
```

### Allow SSH traffic in the security group

Allow incoming SSH traffic in the security group.

```sh
openstack security group rule create --protocol tcp --dst-port 22 $(openstack security group list -f value -c ID -c Name --project $(openstack project show admin -f value -c id) | grep default | awk '{print $1}' )
```

### Access the VM via SSH

Access the virtual machine via SSH.

```sh
ssh -i test.pem cirros@$(openstack floating ip list --project $(openstack project show admin -f value -c id) --port $(openstack port list --device-id $(openstack server show demo-vm1 -c id -f value) --fixed-ip subnet=$(openstack subnet show demo-subnet -f value -c id) -f value -c ID)   --status ACTIVE -c 'Floating IP Address' -f value | head -1)
```

## Access the OpenStack dashboard

### Forward port 80 from vagrant vm to port 8080 to your local machine

Forward port 80 from the vagrant vm to port 8080 on your local machine.

> **Note:** The password for the vagrant user is `vagrant`.

```sh
ssh vagrant@192.168.57.101 -L 8080:192.168.57.101:80
```

Open a web browser and access the OpenStack dashboard at http://localhost:8080/dashboard.

> **Note:** The default username is `admin`, password is `password`.