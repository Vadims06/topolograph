# Topolograph
Topolograph.com is a Web Python-based tool, which is aimed at visualizing OSPF/ISIS topology and working with the OSPF/ISIS network offline! No any logins and passwords!
The Topolograph visualizes OSPF/ISIS network topology based on LinkState DataBase scrapped from a single network device ( thanks OSPF/ISIS =). You can upload a txt file or boot up docker's version of Topolograph on your PC and the Topolograph takes OSPF via NAPALM's methods by itself. Then you can build the shortest path from a source to a destination, get backup paths, emulate link outage along the path or change OSPF/ISIS link cost on the fly! Additionally, you can simulate a device outage and see appropriate network reaction. Build reports about the network.  
Once you upload your OSPF/ISIS to Topolograph - you save the state of your network. After any changes on a network (i.e. redistribution from BGP to OSPF via route-maps with prefix-lists) - upload the network once again and compare them between each other.  
![](https://github.com/Vadims06/topolograph/blob/5bd6912d90260da6c412cae7b78e5b1024e61131/functional-topolograph-role.png)  
[OSPF Watcher repo](https://github.com/Vadims06/ospfwatcher)
## Available option
* Do not require any logins and passwords - accept LSDB from txt file or via Rest API
* Docker version is available. Launch local copy of Topolograph site on your PC
* Once you get your network graph - build the shortests paths
* Simulate a link outage and discover backup paths or backup of backup paths...
* Simulate a router shutdown. Look at traffic flow around the failed router
* Find the most loaded nodes and edges, fault tolerant nodes.
* Check network reaction to IGP cost change on a link
* Compare the network state at different times
* Discover backuped/not-backuped networks in Analytics/Network heatmap
* Discover asymmetric paths
* Build arbitrary topologies based on YAML. Yaml file topology visualisation.

# Supported vendors for OSPF visualisation
| Vendor  | LSA1                                           | LSA2                                            | LSA5                                             | NAPALM support |
|---------|------------------------------------------------|-------------------------------------------------|--------------------------------------------------|----------------|
| Cisco   | show ip ospf database router                   | show ip ospf database network                   | show ip ospf database external                   | YES            |
| Cisco NX-OS| show ip ospf database router detail         | show ip ospf database network detail            | show ip ospf database external detail            | No            |
| Quagga  | show ip ospf database router                   | show ip ospf database network                   | show ip ospf database external                   | YES            |
| Juniper | show ospf database router extensive \| no-more | show ospf database network extensive \| no-more | show ospf database external extensive \| no-more | YES            |
| Bird    | show ospf state all                            | show ospf state all                             | show ospf state all                              | No            |
| Nokia   | show router ospf database type router detail   | show router ospf database type network detail   | show router ospf database type external detail   | Yes           |
| Mikrotik| /routing ospf lsa print detail file=lsa.txt    | /routing ospf lsa print detail file=lsa.txt     | /routing ospf lsa print detail file=lsa.txt      | No            |
| Huawei  | display ospf lsdb router                       | display ospf lsdb network                       | display ospf lsdb ase                            | No            |
| Paloalto  | show routing protocol ospf dumplsdb         | show routing protocol ospf dumplsdb                | show routing protocol ospf dumplsdb            | No            |
| Ubiquiti  | show ip ospf database router          | show ip ospf database network      | show ip ospf database external          | No            |
| Allied Telesis  | show ip ospf database router  | show ip ospf database network	      | show ip ospf database external	          | No            |
| Extreme  | show ospf lsdb detail lstype router  | show ospf lsdb detail lstype network	      | show ospf lsdb detail lstype as-external	          | No            |
| Ericsson  | show ospf database router detail  | show ospf database network detail	      | show ospf database external detail	          | No            |

  
LSA 1 and LSA 2 is mandatory and have to exist in the same file. LSA 5 is optional. The output from all commands should be placed in a single file and then be uploaded to Topolograph.  

# Supported vendors for ISIS visualisation
| Vendor  | Command                                     | Stub network included                       | External (redistributed) network          | 
|---------|---------------------------------------------|---------------------------------------------|--------------------------------------------------|
| Cisco   | show isis database detail                   | YES                     | No, (need tested LSDB for adding it)                   |
| Juniper  | show isis database extensive               | YES, but need tested LSDB for checking it    | No, (need tested LSDB for adding it)                   |
| Nokia   | show router isis database detail            | YES, but need tested LSDB for checking it    | No, (need tested LSDB for adding it)                   |
| Huawei   | display isis lsdb verbose                  | YES, but need tested LSDB for checking it    | No, (need tested LSDB for adding it)                   |
| ZTE     | show isis database verbose                  | YES, but need tested LSDB for checking it    | No, (need tested LSDB for adding it)                   |
  

### How to start
- run commands specifically to your vendor (from Supported vendors table) on single device ( if you have multiple areas - do it on ABR)
- save all commands output in a single file with .txt or .log extension
- upload the file to Topolograph

- or do it programmatically via Rest API. Multi devices LSDBs are supported via API only (v2.34). 

### Expected file's extension
- .txt
- .log

# Demo
## Upload OSPF LSDB to the Topolograph and Building the shortest paths
This demo shows how to get OSPF topology visual and interact with it.
1. Upload the file to Topolograph from exicuted commands previously.
2. Build the shortest paths
3. Emulate a link outage and see backup paths

![](https://github.com/Vadims06/topolograph/blob/master/short_demo_text_file_and_short_paths.gif)
## Network reaction on the link failure. Backup paths
Pressing on edge we simulate the link outage and can see backup paths  
![pressing on edge we simulate the link outage and can see backup paths](https://github.com/Vadims06/topolograph/blob/master/backup_SPT.png)
and we can see backup of backup paths as well  


### OSPF cost changes on the fly. OSPF cost planning.
It's feasible to change OSPF cost on any edge and get network reaction on the fly!  
Build the shortest path under General View and set new OSPF cost in new pop-up-ed form - new path will be repainted  
This pop-uped form is available under NetworkReactionOnFailure and shows network traffic pattern changes!  
On the demo below we changed OSPF cost from 1 to 22 and OSPF rebuilt the shortest path via bottom link.  
![](https://github.com/Vadims06/topolograph/blob/master/ospf-cost-change-on-the-fly.gif)

Sum it up, available features under GeneralView Tab:  

* **Build the shortest path**, right click on a node and set it as a source or destination.
* **Find backup paths**, just press on a colored SPT edge and you will simulate link outage. The network reaction will be showed with using different colors.
* **OSPF edge cost planning** right click on an edge and you can change edge's OSPF cost you see new path of your SPT.
* **Find termination node of a network** start typing a network in Focus/Source tab and you get a dropdown list with all nodes with this network. Once you choose it - you will be focused on the node.  

### NetworkReactionOnFailure is covered in [how-to](https://topolograph.com/how-to)
It's possible to simulate a link or router shutdown/outage. The topology will be re-pained with expected changed traffic flow avoiding failed link or router.
![](https://github.com/Vadims06/topolograph/blob/master/network_reaction_rem_edge1.png)
* Blue lines show traffic increasing over the link
* Grey lines show traffic decreasing over the link

Try to shutdown backup router and see the graph reaction. If this is a true backup router - there shoudn't be network rebuilding too much
![](https://github.com/Vadims06/topolograph/blob/master/network_reaction_shut_node.png)

## Reports
### Asymmetric paths
When different costs are configured on different links - asymmetric paths could be in the network. The incoming path from W to F is going via C-D, but the outgoing path is via B-A. Paths can go via different ISPs and come with different delays and, probably, losses. The report is aimed at discovering such cases in order to eliminate it.  
![](https://github.com/Vadims06/topolograph/blob/master/asymmetric_horizontal_2x.png)

### Network heatmap
The topolograph knows what networks are advertised by nodes. When the network is terminated on both routers, using VRRP, both nodes advertise the network. The node is marked by red if it has a lot of unbackuped networks, and vise versa.
![](https://github.com/Vadims06/topolograph/blob/master/heatmap.png)

### ECMP backup paths
* We suggest that if we have multiple links bounded to ECMP and if the main link in ECMP goes down, the backup path should go via the second link in ECMP.  passed report  
![passed report](https://github.com/Vadims06/topolograph/blob/471b545720378598d550b448ff6c7e82fa7c677c/ospf_ecmp_backup_path_via_ecmp.png "passed report")
* If backup path goes not via ECMP and chooses completely different path - the report will be treated as failed.  failed report  
![passed report](https://github.com/Vadims06/topolograph/blob/471b545720378598d550b448ff6c7e82fa7c677c/ospf_ecmp_backup_path_not_via_ecmp.png "failed report")

## Private
Keep your network inside your organization.
Run your local copy of Topolograph inside your on-premises network using the docker image.  
![](https://github.com/Vadims06/topolograph/blob/master/topolograph_docker.png)

## API
### Schema
Full schema description is [here](https://topolograph.com/api/ui/)   
### Default credentials
Default credentials are available via environment variables in case of using docker-based version. How to set it described in this [case](https://github.com/Vadims06/topolograph/issues/26).
### Details
Started from v2.19. Scrab your LSDB using your favourite tools like Ansible, netmiko, Nornir, etc and upload your OSPF network graph to Topolograph via a POST request. The response returns:
* diff comparison with previously uploaded graphs
* link to get all networks
* status about passed checks (are there are asymmetric links in the network, etc)

```
{'diff': {'compared_with_graph_time': '08Jun2021_20h15m26s_13_hosts',
          'graphs_diff': {'all_edges_stats_ll': [{'dst_node': '123.123.110.110',
                                                  'link_cost': 10,
                                                  'link_status': 'old',
                                                  'src_node': '123.123.100.100'],
                          'new_nodes': [],
                          'old_nodes': []},
          'networks_diff': {'new_subnets_attr_dd_ll': [{'rid': '123.30.30.30',
                                                        'subnet': '30.30.30.30/32'}],
                            'old_subnets_attr_dd_ll': []}},
 'graph_time': '08Jun2021_20h15m51s_13_hosts',
 'hosts': {'count': 13},
 'networks': {'backuped': 17,
              'count': 39,
              'notbackuped': 22,
              'url_link': 'https://topolograph.com/api/network/08Jun2021_20h15m51s_13_hosts'},
 'reports': {'ansym_edges_pass_status': False},
 'timestamp': '2021-06-08T20:15:51.724000'}
```
### API graph upload
Upload you OSPF network via python. Supposed that you saved commands output into cisco_lsdb_output.txt.
```
import requests
from pprint import pprint as pp
with open('cisco_lsdb_output.txt') as f:
  lsdb_output = f.read()
  r_post = requests.post('https://topolograph.com/api/graph', auth=('youraccount@domain.com', 'your-pass'), 
                          json={'lsdb_output': lsdb_output, 'vendor_device': 'Cisco', 'igp_protocol': 'ospf'})
  pp(r_post.json())
```  
`igp_protocol` may include `ospf` or `isis`  

### Get the shortest path
It allows to get the shortest path between two OSPF RID, or it also accepts IP address or IP Subnet as source/destination and returns the following: 
* path's cost
* the shortest path 
* unbackuped parts of the shortest path (if these links go down, we will lose a connectivity between the source and destination).

`src_node` and `dst_node` accepts OSPF RID as a value.  
```
r_post = requests.post('https://topolograph.com/api/path', auth=('', ''), 
json={'graph_time': '27Dec2022_22h46m01s_7_hosts_ospfwatcher', 'src_node': '192.168.100.100', 'dst_node': '10.1.123.23'})  
```
Reply
```
r_post.json()
{'cost': 30, 
'spt_path_nodes_name_as_ll_in_ll': [['192.168.100.100', '10.1.1.4', '10.1.1.2', '10.1.123.23']], 
'unbackup_paths_nodes_name_as_ll_in_ll': [['192.168.100.100', '10.1.1.4']]}
```
A `'192.168.100.100' - '10.1.1.4'` link is shown as nonbackuped  
The visual path  
![](https://github.com/Vadims06/topolograph/blob/aaabbef7bcbf5666024702aa1419599e9b9cd617/docs/release-notes/v2.28/shortest_path_graph.png)  

### Get backup path
`removedEdgesAsNodePairsFromSptPath_ll_in_ll` accepts a list of edges which will be treated as down links
```
r_post = requests.post('https://topolograph.com/api/path', auth=('', ''), 
json={'graph_time': '27Dec2022_22h46m01s_7_hosts_ospfwatcher', 'src_node': '192.168.100.100', 'dst_node': '10.1.123.23', 
'removedEdgesAsNodePairsFromSptPath_ll_in_ll': [['10.1.1.4', '10.1.1.2']]})    
```
```
r_post.json()
{'cost': 40, 
'spt_path_nodes_name_as_ll_in_ll': [['192.168.100.100', '10.1.1.4', '10.1.1.3', '10.1.1.2', '10.1.123.23']], 
'unbackup_paths_nodes_name_as_ll_in_ll': [['192.168.100.100', '10.1.1.4']]}
```
The visual path  
![](https://github.com/Vadims06/topolograph/blob/aaabbef7bcbf5666024702aa1419599e9b9cd617/docs/release-notes/v2.28/backup_path_graph.png)   

### get the shortest path for networks
There is a separate method for getting the shortest path, which accepts IP addresses/IP network as an input.  
Let's build a path between `192.1.113.99` IP and `192.1.213.0/24` network.  
```
r_post = requests.post('https://topolograph.com/api/path/network', auth=('', ''), 
json={'graph_time': '27Dec2022_22h46m01s_7_hosts_ospfwatcher', 'src_ip_or_network': '192.1.113.99', 'dst_ip_or_network': '192.1.213.0/24'})    
``` 
Reply
``` 
r_post.json()
{'cost': 20, 
'spt_path_nodes_name_as_ll_in_ll': [['10.1.1.1', '10.1.1.4', '10.1.1.2'], ['10.1.1.1', '10.1.1.3', '10.1.1.2']], 
'unbackup_paths_nodes_name_as_ll_in_ll': []}
``` 
The visual path  
![](https://github.com/Vadims06/topolograph/blob/921fcf316f63f3ff6fafc1f6c899031952ad0bc4/docs/release-notes/v2.28/shortest_path_between_networks.png)  

### Network reaction on a failure
We have the following topology  
![image](https://user-images.githubusercontent.com/20796986/144145217-454c1442-ba6c-4337-a6f2-8dde5d337f1e.png)  
#### Test case
Emulate powering off nodes 10.1.1.2 and 10.1.1.4.
#### What we would like to test
* Link over utilisation will occurs?
* Network reachability will be broken? Some nodes will be isolated?  
Test request:
```
import requests
from pprint import pprint as pp
r_post = requests.post('http://<topolograph-host>/api/network_reaction/node_failure/', auth=('   ', '    '), 
                          json={"graph_time": "25Nov2021_08h20m45s_7_hosts", "failed_nodes_list": ["10.1.1.2", "10.1.1.4"]})
pp(r_post.json())
```
Reply
```
{'affectedLinks': {'sptPathsDecreasedInPercent': {},
                   'sptPathsIncreasedInPercent': {'from': '10.1.1.1',
                                                  'to': '10.1.1.3',
                                                  'value': 60}},
 'disjointedNodes': [['10.1.123.23', '10.1.123.24'],
                     ['192.168.100.100'],
                     ['10.1.1.1', '10.1.1.3']],
 'isGraphStillConnected': False}
 ```
# Yaml based topology
Topolograph visualizes topologies based on OSPF/IS-IS LSDB files, but starting from v2.32 it accepts YAML to build a graph. It can be used for building arbitrary topologies (not exactly IGP domains), but moreover it can keep the topology updated via Rest API. It's the first version of Network Diagram as a Service (NDAS)!  
OSPF/IS-IS LSDB <-> YAML is interchangeable now in both ways, so it allows to make a design of IGP domain from the scratch or based on uploaded a LSDB, add new links/edges between nodes or change igp's cost and then check network reaction based on our changes.
### Basic YAML based topology.
Build a graph with defined `nodes` and `edges`. 
![https://user-images.githubusercontent.com/20796986/144145217-454c1442-ba6c-4337-a6f2-8dde5d337f1e.png](https://github.com/Vadims06/topolograph/blob/6f042dd08cba67c7c5191e16c87ff8679fb179eb/docs/release-notes/v2.32/basic_yaml_diagram.PNG)  

### Node attributes
* `node's name` is mandatory. Should be in IP-address format. To change it to any other value - use `label`
* Tags of node are optional. Any key (type string): value (str, int, float, dictionary, list) pairs.
![image](https://github.com/Vadims06/topolograph/blob/6f042dd08cba67c7c5191e16c87ff8679fb179eb/docs/release-notes/v2.32/node_attributes_yaml_file_and_api_request.png)   
There is a graph with 6 nodes. Select all primary nodes (`ha_role`: `primary`) in the first DC (`dc1`)
```
import requests
from pprint import pprint as pp
query_params = {'location': 'dc1', 'ha_role': 'primary'}                                  
r_get = requests.get(f'http://{TOPOLOGRAPH_HOST}:{TOPOLOGRAPH_PORT}/api/diagram/{graph_time}/nodes', auth=('   ', '    '), params=query_params, timeout=(5, 30))
```
Reply
```
pp(r_get.json())
[{'ha_role': 'primary',
  'id': 1,
  'label': '10.10.10.2',
  'location': 'dc1',
  'name': '10.10.10.2',
  'size': 15}]
```
### Edge attributes
* `src`, `dst` is mandatory. 
* `cost` is optional. Default is 1. Equal to OSPF/IS-IS cost.
* `directed` is optional. Default is false.
* Tags of edge are optional. Any key (type string): value (str, int, float, dictionary, list) pairs.
![image](https://github.com/Vadims06/topolograph/blob/6f042dd08cba67c7c5191e16c87ff8679fb179eb/docs/release-notes/v2.32/edge_attributes_yaml_file_and_api_request.PNG)   
Select all edges over verizon ISP between `10.10.10.2` and `10.10.10.4`  
```
query_params = {'src_node': '10.10.10.2', 'dst_node': '10.10.10.4', 'isp': 'verizon'}
r_get = requests.get(f'http://{TOPOLOGRAPH_HOST}:{TOPOLOGRAPH_PORT}/api/diagram/{graph_time}/edges', auth=('   ', '    '), params=query_params, timeout=(5, 30))
```
Reply
```
pp(r_get.json())                                                                          
[{'bw': 1000,
  'cost': 1,
  'dst': '10.10.10.4',
  'id': 3,
  'isp': 'verizon',
  'media': 'fiber',
```
### Network reaction on adding new link between devices.
Let's add a new link with `cost` 1 between R3 (10.10.10.3) and R4 (10.10.10.4) device and see how network will react on it.
![image](https://github.com/Vadims06/topolograph/blob/6f042dd08cba67c7c5191e16c87ff8679fb179eb/docs/release-notes/v2.32/yaml_diagram_network_reaction_on_adding_r3_r4.PNG)
Obviously, we see traffic increase on direct link R3<->R4 and traffic decrease to R2 (10.10.10.2) and R5 (10.10.10.5).

# Online Resources. Contacts
* Slack chat: https://topolograph.slack.com
* Main site: https://topolograph.com
* Docker version of site: https://github.com/Vadims06/topolograph-docker
* Online doc: https://topolograph.com/how-to

## Known issues
If you just upload LSDB and press Delete -> topology will be deleted and added again. Just press Upload LSDB Tab again and then deleting of topology works fine.

# Contribution.  
## Adding new feature into core of Topolograph  
Email me admin at topolograph.com and can open the access to the repository.  
## adding new vendor
In order to project supports different vendors you can help us by creating five separate textfsm files for different LSA types for one vendor. Check [Wiki](https://github.com/Vadims06/topolograph/wiki/How-to-add-new-vendor-support) for this.

## adding NAPALM support
For adding scrapping OSPF by NAPALM - please create three additional methods and ping me to add it to topolograph. The example based on Cisco IOS NAPALM
```
    def get_ospf_router_lsa_raw_output(self):
        command_router = 'show ip ospf database router'

        show_ospf_lsdb_router_lsa_output = self._send_command(command_router).strip()
        return show_ospf_lsdb_router_lsa_output

    def get_ospf_network_lsa_raw_output(self):
        command_network = 'show ip ospf database network'

        show_ospf_lsdb_network_lsa_output = self._send_command(command_network).strip()
        return show_ospf_lsdb_network_lsa_output


    def get_ospf_external_lsa_raw_output(self):
        command_external = 'show ip ospf database external'

        show_ospf_lsdb_external_lsa_output = self._send_command(command_external).strip()
        return show_ospf_lsdb_external_lsa_output
```

## Used RFC
RFC 2328
