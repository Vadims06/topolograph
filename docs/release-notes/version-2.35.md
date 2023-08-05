# Topolograph

## v2.35 (05.08.2023)

## New features

OSPFv3 support is added for Arista.

| Vendor  | Command                                     | Stub network included                       | External (redistributed) network          | 
|---------|---------------------------------------------|---------------------------------------------|--------------------------------------------------|
| Arista  | show ipv6 ospf database detail              | YES                     | YES                   |

## Enhancements
Subnets from transit interfaces (interfaces with ospf type `broadcast`) are included into graph properties. Networks are available via RestAPI `/network/{graph_time}`, take into account in graph diff.  

![](https://github.com/Vadims06/topolograph/blob/db815f1200ba2c3a2c406916718a202c95456f69/docs/release-notes/v2.35/broadcast_subnets_of_10_0_0_1_node.PNG)
Broadcast subnets of `10.0.0.1` node.
