# Topolograph
Topolograph.com is a Python-based tool, which is aimed at visualizing OSPF topology and working with the OSPF network offline! No any logins and passwords!
The Topolograph visualizes OSPF network topology based on OSPF's LinkState DataBase scrapped from a single network device ( thanks OSPF =). You can upload a txt file or boot up docker's version of Topolograph on your PC and the Topolograph takes OSPF via NAPALM's methods by itself. Then you can build the shortest path from a source to a destination, get backup paths, emulate link outage along the path or change OSPF link cost on the fly! Additionally, you can simulate a device outage and see appropriate network reaction. Build reports about the network.  
Once you upload your OSPF to Topolograph - you save the state of your network. After any changes on a network (i.e. redistribution from BGP to OSPF via route-maps with prefix-lists) - upload the network once again and compare them between each other.

## Available option
* Do not require any logins and passwords - accept LSDB from txt file
* Docker version is available. Launch local copy of Topolograph site on your PC
* Once you get your network graph - build the shortests paths
* Simulate a link outage and discover backup paths or backup of backup paths...
* Simulate a router shutdown. Look at traffic flow around the failed router
* Browse your network with `Focus on the Node` option
* Compare the network state at different times
* Discover backuped/not-backuped networks in Analytics/Network heatmap
* Discover asymmetric paths

| Vendor  | LSA1                                           | LSA2                                            | LSA5                                             | NAPALM support |
|---------|------------------------------------------------|-------------------------------------------------|--------------------------------------------------|----------------|
| Cisco   | show ip ospf database router                   | show ip ospf database network                   | show ip ospf database external                   | YES            |
| Quagga  | show ip ospf database router                   | show ip ospf database network                   | show ip ospf database external                   | YES            |
| Juniper | show ospf database router extensive \| no-more | show ospf database network extensive \| no-more | show ospf database external extensive \| no-more | YES            |
| Bird    | show ospf state all                            | show ospf state all                             | show ospf state all                              | No            |
| Nokia   | show router ospf database type router detail   | show router ospf database type network detail   | show router ospf database type external detail   | Yes           |
| Mikrotik| /routing ospf lsa print detail file=lsa.txt    | /routing ospf lsa print detail file=lsa.txt     | /routing ospf lsa print detail file=lsa.txt      | No            |
| Huawei  | display ospf lsdb router                       | display ospf lsdb network                       | display ospf lsdb ase                            | No            |

  
LSA 1 and LSA 2 is mandatory and have to exist in the same file. LSA 5 is optional.  
So the output from all commands should be placed in a single file and then be uploaded to Topolograph.
### Expected file's extension
- .txt
- .log
# Upload LSDB to the Topolograph
This demo shows how to save OSPF LSDB from your devices and upload it to Topolograph. 
1. Redirect an output from your terminal to a file. 
2. Execute commands from the table above. 
3. Upload the file to Topolograph.

## Building the shortest paths
Choose the node  
Set it as a source or destination from right-clicked menu or from dropdown menu above  
Beside colored edges on the graph, the shortest path's cost and nodes list is printed above the topology  

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

## Vendor support
* Cisco
* Juniper
* Quagga
* Bird
* Nokia
* Mikrotik
* Huawei
* Paloalto
* others (see below)
if you would like to see support of other vendors - just create an issue on this page or contact using Slack chat. You can create textfsm template for scrapping LSDB output of your vendor and create merge request, or we can do it by themselves - please send your outputs to us.

## API
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
                          json={'lsdb_output': lsdb_output, 'vendor_device': 'Cisco'})
  pp(r_post.json())
```

# Online Resources. Contacts
* Slack chat: https://topolograph.slack.com
* Main site: https://topolograph.com
* Docker version of site: https://github.com/Vadims06/topolograph-docker

## Known issues
If you just upload LSDB and press Delete -> topology will be deleted and added again. Just press Upload LSDB Tab again and then deleting of topology works fine.

# Contribution. 
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
