net add interface swp1,swp2,swp49,swp50 
net commit
sleep 3
net add bgp autonomous-system 64999
net add bgp router-id 99.98.1.1
net add loopback lo ip address 99.98.1.1/32
net commit
sleep 3
# defining peers
net add bgp neighbor swp49 interface remote-as 65000  # to spine
net add bgp neighbor swp50 interface remote-as 65000  # to spine
net add bgp neighbor swp49 allowas-in origin
net add bgp neighbor swp50 allowas-in origin
net add bgp neighbor swp1 interface remote-as 64999  # to hosts
net add bgp neighbor swp2 interface remote-as 64999  # to hosts
net add bgp neighbor swp1 route-reflector-client
net add bgp neighbor swp2 route-reflector-client
net add bgp neighbor swp1 next-hop-self force
net add bgp neighbor swp2 next-hop-self force
net add bgp neighbor swp1 default-originate
net add bgp neighbor swp2 default-originate
net add bgp redistribute connected
net commit
