net add interface swp1,swp2,swp3,swp4
net commit  # (wait for it to complete, it will take several minutes)
sleep 3
net add bgp autonomous-system 65000
net add bgp router-id 99.97.1.1 # (where X is the spine number, 1 or 2)
net add loopback lo ip address 99.97.1.1/32
net add bgp neighbor swp1 interface remote-as 64999
net add bgp neighbor swp2 interface remote-as 64999
net add bgp neighbor swp3 interface remote-as 64999
net add bgp neighbor swp4 interface remote-as 64999
net add bgp redistribute connected
net commit