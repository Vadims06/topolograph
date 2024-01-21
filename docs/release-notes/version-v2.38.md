# Topolograph

## v2.38 (21.01.2024)

## Fixes
* IS-IS templates improvements to avoid missing links between the same nodes.

## Improvements
* Thanks to [Duplicate IPs Issue#6](https://github.com/Vadims06/topolograph-docker/issues/6) the **new report to find duplicated networks** (networks're terminated on multiple not-direct connected hosts). For example, consider the following linear topology: router A connects to router B using the IP x.x.x.x/30, router B connects to router C using the IP y.y.y.y/30, and router C connects to router D using the IP z.z.z.z/30. The correct topology should be A<x.x.x.x/30>B<y.y.y.y/30>C<z.z.z.z/30>D, but in fact it has the following topology: A<x.x.x.x/30>B<y.y.y.y/30>C<x.x.x.x/30>D


| Network | Number of terminated nodes | Node names |
|-----------|-------------------------------|-------------|
| x.x.x.x/30|           4             | [172.16.1.2, 172.26.1.2], [172.30.2.1, 178.20.3.1] |

The report shows a group of nodes, where the network is terminated. Additional groupping via `[]` shows if hosts are direct neighbors.
