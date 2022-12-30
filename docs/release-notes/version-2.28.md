# Topolograph

## v2.28 (30.12.2022)

## Enhancements
### The shortest path API
It allows to get the shortest path between two OSPF RID, or it also accepts IP address or IP Subnet as source/destination and returns the following: 
* path's cost
* the shortest path 
* unbackuped parts of the shortest path (if these links go down, we will lose a connectivity between the source and destination).

### get the shortest path
`src_node` and `dst_node` accepts OSPF RID as a value.  
```
r_post = requests.post('https://topolograph.com/api/path', auth=('', ''), json={'graph_time': '27Dec2022_22h46m01s_7_hosts_ospfwatcher', 'src_node': '192.168.100.100', 'dst_node': '10.1.123.23'})    
r_post.json()
```
![](https://github.com/Vadims06/topolograph/blob/aaabbef7bcbf5666024702aa1419599e9b9cd617/docs/release-notes/v2.28/api_shortest_path.png)  
A `'192.168.100.100' - '10.1.1.4'` link is shown as nonbackuped  
The visual path  
![](https://github.com/Vadims06/topolograph/blob/aaabbef7bcbf5666024702aa1419599e9b9cd617/docs/release-notes/v2.28/shortest_path_graph.png)  

### get backup path
`removedEdgesAsNodePairsFromSptPath_ll_in_ll` accepts a list of edges which will be treated as down links
```
r_post = requests.post('https://topolograph.com/api/path', auth=('', ''), json={'graph_time': '27Dec2022_22h46m01s_7_hosts_ospfwatcher', 'src_node': '192.168.100.100', 'dst_node': '10.1.123.23', 'removedEdgesAsNodePairsFromSptPath_ll_in_ll': [['10.1.1.4', '10.1.1.2']]})    
r_post.json()
```
![](https://github.com/Vadims06/topolograph/blob/aaabbef7bcbf5666024702aa1419599e9b9cd617/docs/release-notes/v2.28/api_backup_path.png)  
The visual path  
![](https://github.com/Vadims06/topolograph/blob/aaabbef7bcbf5666024702aa1419599e9b9cd617/docs/release-notes/v2.28/backup_path_graph.png)   

### get the shortest path for networks
There is a separate method for getting the shortest path, which accepts IP addresses/IP network as an input.  
Let's build a path between `192.1.113.99` IP and `192.1.213.0/24` network.  
```
r_post = requests.post('https://topolograph.com/api/path/network', auth=('', ''), json={'graph_time': '27Dec2022_22h46m01s_7_hosts_ospfwatcher', 'src_ip_or_network': '192.1.113.99', 'dst_ip_or_network': '192.1.213.0/24'})    
r_post.json()
```
![](https://github.com/Vadims06/topolograph/blob/aaabbef7bcbf5666024702aa1419599e9b9cd617/docs/release-notes/v2.28/api__shortest_path_between_networks.png)  
The visual path  
![](https://github.com/Vadims06/topolograph/blob/921fcf316f63f3ff6fafc1f6c899031952ad0bc4/docs/release-notes/v2.28/shortest_path_between_networks.png)  
