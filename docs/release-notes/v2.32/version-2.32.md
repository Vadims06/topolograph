# Topolograph

## v2.32 (24.06.2023)

## New features
* Extreme OSPF support is added
* Ericsson OSPF support is added
* Yaml based topology. Network design mode.

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
