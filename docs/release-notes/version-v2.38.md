# Topolograph

## v2.38 (21.01.2024)

## Fixes
* IS-IS templates improvements to avoid missing links between the same nodes.

## Improvements
* IS-IS Watcher is released and integrated into Topolograph!  
IS-IS Watcher is a monitoring tool of IS-IS topology changes for network engineers. It works via passively listening to IS-IS control plane messages through a specially established IS-IS adjacency between IS-IS Watcher and one of the network device. The tool logs IS-IS events and/or export by Logstash to **Elastic Stack (ELK)**, **Zabbix**, **WebHooks** and **Topolograph** monitoring dashboard for keeping the history of events, alerting, instant notification. By encapsulating the solution's elements in containers, it becomes exceptionally quick to start. The only thing is needed to configure manually is GRE tunnel setup on the Linux host.  
## IS-IS Watcher detects the following network events:
* IS-IS neighbor adjacency Up/Down
* IS-IS link cost changes
* IS-IS networks appearance/disappearance from the topology

![](https://github.com/Vadims06/topolograph/blob/bafd52acf8b832eae34db84cf97e629e4dbab45e/docs/release-notes/v2.38/topolograph_dashboard_with_l1_l2_events.png)

Gathered attributes 
| TLV name                         | TLV |
|----------------------------------|-----|
| IS Reachability                  | 2   |
| Extended IS Reachability   (new) | 22  |
| IPv4 Internal Reachability (old) | 128 |
| IPv4 External Reachability (old) | 130 |
| Extended IPv4 Reachability (new) | 135 |
| IPv6 Reachability                | 236 |

Here is a small demo https://github.com/Vadims06/topolograph/blob/bafd52acf8b832eae34db84cf97e629e4dbab45e/docs/release-notes/v2.38/is_is_watcher_demo.mp4

* Thanks to [Duplicate IPs Issue#6](https://github.com/Vadims06/topolograph-docker/issues/6) the **new report to find duplicated networks** (networks're terminated on multiple not-direct connected hosts). For example, consider the following linear topology: router A connects to router B using the IP x.x.x.x/30, router B connects to router C using the IP y.y.y.y/30, and router C connects to router D using the IP z.z.z.z/30. The correct topology should be A<x.x.x.x/30>B<y.y.y.y/30>C<z.z.z.z/30>D, but in fact it has the following topology: A<x.x.x.x/30>B<y.y.y.y/30>C<x.x.x.x/30>D


| Network | Number of terminated nodes | Node names |
|-----------|-------------------------------|-------------|
| x.x.x.x/30|           4             | [172.16.1.2, 172.26.1.2], [172.30.2.1, 178.20.3.1] |

The report shows a group of nodes, where the network is terminated. Additional groupping via `[]` shows if hosts are direct neighbors.
