# topolograph
Topolograph.com is an online project which can visualize network topology based on single OSPF LinkState DataBase scrapping from one network device ( thanks OSPF =). Then you can not only see (and check) the shortest path from source to destination, but also see the outcome from link or node failure along the path to the destination. The existing algorithms depict SPT, backup or even backup of backup paths and print out how many segments along the path are backuped and how many are not. Additionally, if you are planning device maintenance and would like to know how shutdowning some particular device will affect on routing in your topology - just choose this node in `Node shutdown Pred` and you get your answer: will be topology stay connected or not, how many subnets will become unavailable.

Available algorithms:

* link failure algorithm, it goes successively along the shortest path and removes the connection between devices. Then, searching for the shortest path is repeating. 
* node failure algorithm, the principle of operation is the same, but it removes devices. 

#### Other functionality
* subnet inventory
* painting and grouping network devices by some criteria ( i.e office name )
* device shutdown outcome prediction

Topology sample
![](https://github.com/Vadims06/topolograph/blob/master/graph%20description%20sample.png)

# New textfsm templates creation for different vendors
Please create five separate textfsms for different LSA types.

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
