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

### Install devstack

```sh
bash ./devstack-bgp.sh
cd devstack
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
export OS_AUTH_URL=https://$(hostname -I | awk '{print $2}')/identity/
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

### Allow SSH traffic in the security group

Allow incoming SSH traffic in the security group.

```sh
openstack security group rule create --protocol tcp --dst-port 22 $(openstack security group list -f value -c ID -c Name --project $(openstack project show admin -f value -c id) | grep default | awk '{print $1}' )
```

## Access the OpenStack dashboard

### Forward port 80 from vagrant vm to port 8080 to your local machine

Forward port 80 from the vagrant vm to port 8080 on your local machine.

> **Note:** The password for the vagrant user is `vagrant`.

```sh
ssh vagrant@192.168.56.10 -L 8080:192.168.56.10:80
```

Open a web browser and access the OpenStack dashboard at http://localhost:8080/dashboard.

> **Note:** The default username is `admin`, password is `password`.