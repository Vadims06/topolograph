# Topolograph
Topolograph.com is a Python-based tool, which is aimed at working with the OSPF network offline! No any logins and passwords!
The Topolograph can visualize network topology based on OSPF's LinkState DataBase scrapped from a single network device ( thanks OSPF =). You can upload a txt file or boot up docker's version of Topolograph on your PC and the Topolograph takes OSPF via NAPALM's methods by itself. Then you can build the shortest path from source to destination, get backup paths, emulate link outage along the path or change OSPF link cost on the fly! Additionally, you can simulate a device outage and see appropriate network reaction. Once you upload your OSPF to Topolograph - you save the state of your network. After any changes on a network (i.e. redistribution from BGP to OSPF via route-maps with prefix-lists) - upload the network once again and compare them between each other.

## Available option
* Do not require any logins and passwords - accept LSDB from txt file
* Docker version is available. Launch local copy of Topolograph site on your PC
* Once you get your network graph - build the shortests paths
* Simulate a link outage and discover backup paths or backup of backup paths...
* Simulate a router shutdown. Look at traffic flow around the failed router
* Browse your network with `Focus on the Node` option
* Compare the network state at different times
* Discover backuped/not-backuped networks in Analytics/Network heatmap
* Discover unsymmetric paths

| Vendor  | LSA1                                           | LSA2                                            | LSA5                                             | NAPALM support |
|---------|------------------------------------------------|-------------------------------------------------|--------------------------------------------------|----------------|
| Cisco   | show ip ospf database router                   | show ip ospf database network                   | show ip ospf database external                   | YES            |
| Quagga  | show ip ospf database router                   | show ip ospf database network                   | show ip ospf database external                   | YES            |
| Juniper | show ospf database router extensive \| no-more | show ospf database network extensive \| no-more | show ospf database external extensive \| no-more | YES            |
### Expected file's extension
- .txt
- .log
### Upload LSDB to the Topolograph
This demo shows how to save OSPF LSDB from your devices and upload it to Topolograph. Picture of topology was static, right now it dynamic!
![](https://github.com/Vadims06/topolograph/blob/master/upload_graph_demo.gif)

### Network reaction on the link failure
Pressing on edge we simulate the link outage and can see backup paths
![pressing on edge we simulate the link outage and can see backup paths](https://github.com/Vadims06/topolograph/blob/master/backup_SPT.png)
and we can see backup of backup paths...
![](https://github.com/Vadims06/topolograph/blob/master/build-spt.gif)

### OSPF cost changes on the fly. OSPF cost planning.
You get network reaction as soon as you set new edge cost.
![](https://github.com/Vadims06/topolograph/blob/master/ospf-edge-change.gif)

Once you upload LSDB - topology appears under GeneralView Tab. Here you are able to use the folowing features:

* **Build the shortest path**, right click on a node and set it as a source or destination.
* **Find backup paths**, just press on a colored SPT edge and you will simulate link outage. The network reaction will be showed with using different colors.
* **OSPF edge cost planning** right click on an edge and you can change edge's OSPF cost you see new path of your SPT.
* **Find termination node of a network** start typing a network in Focus/Source tab and you get a dropdown list with all nodes with this network. Once you choose it - you will be focused on the node.


## Vendor support
* Cisco
* Juniper
* Quagga
* others (see below)
if you would like to see support of other vendors - just create an issue on this page or contact using Slack chat. You can create textfsm template for scrapping LSDB output of your vendor and create merge request, or we can do it by themselves - please send your outputs to us.

# Online Resources. Contacts
* Slack chat: https://topolograph.slack.com
* Main site: https://topolograph.com
* Docker version of site: https://github.com/Vadims06/topolograph-docker

## Known issues
Sometimes there are double-colored lines over the same edge or edge selection is not working - just clear browser cache using CTRL + F5.

# Contribution. New textfsm templates creation for different vendors
In order to project supports different vendors you can help us by creating five separate textfsm files for different LSA types for one vendor.

| TextFSM name | Purpose |
| ------ | ------ |
| <vendor_name>\_<os_name>\_<command>\_router\_p2p | LSA describes adjacency through p2p links |
| <vendor_name>\_<os_name>\_<command>\_router\_transit | LSA describes adjacency through broadcast media |
| <vendor_name>\_<os_name>\_<command>\_router\_stub | LSA describes included in OSPF subnets  |
| <vendor_name>\_<os_name>\_<command>\_router\_network | For describe adj in broadcast media |
| <vendor_name>\_<os_name>\_<command>\_router\_external | LSA describes external subnets |

## Topology
Source: RFC 2328
```
             ...........................
             .   +                     .
             .   | 3+---+              .      N12      N14
             . N1|--|RT1|\ 1           .        \ N13 /
             .   |  +---+ \            .        8\ |8/8
             .   +         \ ____      .          \|/
             .              /    \   1+---+8    8+---+6
             .             *  N3  *---|RT4|------|RT5|--------+
             .              \____/    +---+      +---+        |
             .    +         /      \   .           |7         |
             .    | 3+---+ /        \  .           |          |
             .  N2|--|RT2|/1        1\ .           |6         |
             .    |  +---+            +---+8    6+---+        |
             .    +                   |RT3|------|RT6|        |
             .                        +---+      +---+        |
             .                      2/ .         Ia|7         |
             .                      /  .           |          |
             .             +---------+ .           |          |
             .Area 1           N4      .           |          |
             ...........................           |          |
          ..........................               |          |
          .            N11         .               |          |
          .        +---------+     .               |          |
          .             |          .               |          |    N12
          .             |3         .             Ib|5         |6 2/
          .           +---+        .             +----+     +---+/
          .           |RT9|        .    .........|RT10|.....|RT7|---N15.
          .           +---+        .    .        +----+     +---+ 9    .
          .             |1         .    .    +  /3    1\      |1       .
          .            _|__        .    .    | /        \   __|_       .
          .           /    \      1+----+2   |/          \ /    \      .
          .          *  N9  *------|RT11|----|            *  N6  *     .
          .           \____/       +----+    |             \____/      .
          .             |          .    .    |                |        .
          .             |1         .    .    +                |1       .
          .  +--+   10+----+       .    .   N8              +---+      .
          .  |H1|-----|RT12|       .    .                   |RT8|      .
          .  +--+SLIP +----+       .    .                   +---+      .
          .             |2         .    .                     |4       .
          .             |          .    .                     |        .
          .        +---------+     .    .                 +--------+   .
          .            N10         .    .                     N7       .
          .                        .    .Area 2                        .
          .Area 3                  .    ................................
          ..........................
Figure 6: A sample OSPF area configuration 
```
#### LINK ID definitions for different network types (p2p, stub, transit)

```
                   Link type   Description       Link ID
                   __________________________________________________
                   1           Point-to-point    Neighbor Router ID
                               link
                   2           Link to transit   Interface address of
                               network           Designated Router
                   3           Link to stub      IP network number
                               network
                   4           Virtual link      Neighbor Router ID
```

## LSA Router p2p
| Variable | Example Values |
| ------ | ------ |
| ROUTER_ID |  |
| PROCESS_ID |  |
| AREA |
| ADV_ROUTER_ID | 192.1.1.3 from `Advertising Router` |
| STUB | `another Router` word |
| NEIGHBORING_ROUTER_ID | 18.10.0.6 from `Link ID` |
| ROUTER_INTERFACE_IP | 0.0.0.3 but generally it's ipaddress of our neighbor |
| METRIC | 8 |
```
Next RT3's router-LSA for the backbone is shown.  It
indicates that RT3 has a single attachment to the
backbone.  This attachment is via an unnumbered
point-to-point link to Router RT6.  RT3 has again
indicated that it is an area border router.

        ; RT3's router-LSA for the backbone

        LS age = 0                     ;always true on origination
        Options = (E-bit)              ;
        LS type = 1                    ;indicates router-LSA
        Link State ID = 192.1.1.3      ;RT3's router ID
        Advertising Router = 192.1.1.3 ;RT3's router ID
        bit E = 0                      ;not an AS boundary router
        bit B = 1                      ;area border router
        #links = 1
               Link ID = 18.10.0.6     ;Neighbor's Router ID
               Link Data = 0.0.0.3     ;MIB-II ifIndex of P-P link
               Type = 1                ;connects to router
               # TOS metrics = 0
               metric = 8
```

## LSA Router Type transit
| Variable | Example Values |
| ------ | ------ |
| ROUTER_ID |  |
| PROCESS_ID |  |
| AREA |
| ADV_ROUTER_ID | 192.1.1.3 from `Advertising Router` |
| STUB | `transit` word |
| DR_IP_Addr | 192.1.1.4 from `Link ID` |
| ROUTER_INTERFACE_IP | 192.1.1.3 from `Link Data` |
| METRIC | 1 |
```
; RT3's router-LSA for Area 1

        LS age = 0                     ;always true on origination
        Options = (E-bit)              ;
        LS type = 1                    ;indicates router-LSA
        Link State ID = 192.1.1.3      ;RT3's Router ID
        Advertising Router = 192.1.1.3 ;RT3's Router ID
        bit E = 0                      ;not an AS boundary router
bit B = 1                      ;area border router
        #links = 2
               Link ID = 192.1.1.4     ;IP address of Desig. Rtr.
               Link Data = 192.1.1.3   ;RT3's IP interface to net
               Type = 2                ;connects to transit network
               # TOS metrics = 0
               metric = 1
```

## LSA Router Type stub
| Variable | Example Values |
| ------ | ------ |
| ROUTER_ID |  |
| PROCESS_ID |  |
| AREA |
| ADV_ROUTER_ID | 192.1.1.3 from `Advertising Router` |
| STUB | `stub` word |
| SUBNET | 192.1.4.0 from `Link ID` |
| SUBNET_MASK | 0xffffff00 from `Link Data` but generally it's in DEC format|
| METRIC | 2 |

```
; RT3's router-LSA for Area 1

        LS age = 0                     ;always true on origination
        Options = (E-bit)              ;
        LS type = 1                    ;indicates router-LSA
        Link State ID = 192.1.1.3      ;RT3's Router ID
        Advertising Router = 192.1.1.3 ;RT3's Router ID
        bit E = 0                      ;not an AS boundary router
bit B = 1                      ;area border router
        #links = 2

               Link ID = 192.1.4.0     ;IP Network number
               Link Data = 0xffffff00  ;Network mask
               Type = 3                ;connects to stub network
               # TOS metrics = 0
               metric = 2
```


## LSA Network
| Variable | Example Values |
| ------ | ------ |
| AREA |  |
| NETMASK | 0xffffff00 but generally it's in DEC format |
| ADV_ROUTER_ID | 192.1.1.4 from `Advertising Router` |
| DR_IP_Add | 192.1.1.4 from `Link State ID` |
| NEIGHBORING_ROUTER_ID | [192.1.1.4, 192.1.1.1, 192.1.1.2, 192.1.1.3] DR also includes itself in this list!|

```
Network-LSAs are originated for Network N3 in Area 1,
Networks N6 and N8 in Area 2, and Network N9 in Area 3.
Assuming that Router RT4 has been selected as the
Designated Router for Network N3, the following
network-LSA is generated by RT4 on behalf of Network N3
(see Figure 15 for the address assignments):
; Network-LSA for Network N3
 LS age = 0                     ;always true on origination
        Options = (E-bit)              ;
        LS type = 2                    ;indicates network-LSA
        Link State ID = 192.1.1.4      ;IP address of Desig. Rtr.
        Advertising Router = 192.1.1.4 ;RT4's Router ID
        Network Mask = 0xffffff00
               Attached Router = 192.1.1.4    ;Router ID
               Attached Router = 192.1.1.1    ;Router ID
               Attached Router = 192.1.1.2    ;Router ID
               Attached Router = 192.1.1.3    ;Router ID
```

## LSA External
| Variable | Example Values |
| ------ | ------ |
| ROUTER_ID |  |
| PROCESS_ID |  |
| ADV_ROUTER_ID | Router RT7's ID |
| SUBNET | N12's IP network number |
| SUBNET_MASK |
| METRIC_TYPE | 1 |
| METRIC | 2 |
| FORWARDING_IP_ADDR | 0.0.0.0 |

```
Consider once again the AS pictured in Figure 6.  There
are two AS boundary routers: RT5 and RT7.  Router RT5
originates three AS-external-LSAs, for networks N12-N14.
Router RT7 originates two AS-external-LSAs, for networks
N12 and N15.  Assume that RT7 has learned its route to
N12 via BGP, and that it wishes to advertise a Type 2
metric to the AS.  RT7 would then originate the
following LSA for N12:

        ; AS-external-LSA for Network N12,
        ; originated by Router RT7

        LS age = 0                  ;always true on origination
        Options = (E-bit)           ;
        LS type = 5                 ;AS-external-LSA
        Link State ID = N12's IP network number
        Advertising Router = Router RT7's ID
        bit E = 1                   ;Type 2 metric
        metric = 2
        Forwarding address = 0.0.0.0
```
