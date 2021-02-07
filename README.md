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
| Bird    | show ospf state all                            | show ospf state all                             | show ospf state all                              | No            |
| Nokia   | show router ospf database type router detail   | show router ospf database type network detail   | show router ospf database type external detail   | No            |

  
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
P.S. Picture of topology was static, right now it dynamic! =)
![](https://github.com/Vadims06/topolograph/blob/master/upload_graph_demo.gif)

## Building the shortest paths
Choose the node  
Set it as a source or destination from right-clicked menu or from dropdown menu above  
Beside colored edges on the graph, the shortest path's cost and nodes list is printed above the topology  

![](https://github.com/Vadims06/topolograph/blob/master/build-spt.gif)
## Network reaction on the link failure. Backup paths
Pressing on edge we simulate the link outage and can see backup paths  
![pressing on edge we simulate the link outage and can see backup paths](https://github.com/Vadims06/topolograph/blob/master/backup_SPT.png)
and we can see backup of backup paths as well  


### OSPF cost changes on the fly. OSPF cost planning.
It feasible to change OSPF cost on any edge and get network reaction on the fly!  
Build the shortest path under General View and set new OSPF cost in new pop-up-ed form - new path will be repainted  
This pop-uped form is available under NetworkReactionOnFailure and shows network traffic pattern changes!  
On the demo below we changed OSPF cost from 1 to 22 and OSPF rebuilt the shortest path via bottom link.  
![](https://github.com/Vadims06/topolograph/blob/master/ospf-cost-change-on-the-fly.gif)

Sum it up, available features under GeneralView Tab:  

* **Build the shortest path**, right click on a node and set it as a source or destination.
* **Find backup paths**, just press on a colored SPT edge and you will simulate link outage. The network reaction will be showed with using different colors.
* **OSPF edge cost planning** right click on an edge and you can change edge's OSPF cost you see new path of your SPT.
* **Find termination node of a network** start typing a network in Focus/Source tab and you get a dropdown list with all nodes with this network. Once you choose it - you will be focused on the node.  

NetworkReactionOnFailure is covered in ![how-to](https://topolograph.com/how-to)

## Vendor support
* Cisco
* Juniper
* Quagga
* Bird
* others (see below)
if you would like to see support of other vendors - just create an issue on this page or contact using Slack chat. You can create textfsm template for scrapping LSDB output of your vendor and create merge request, or we can do it by themselves - please send your outputs to us.

# Online Resources. Contacts
* Slack chat: https://topolograph.slack.com
* Main site: https://topolograph.com
* Docker version of site: https://github.com/Vadims06/topolograph-docker

## Known issues
If you just upload LSDB and press Delete -> topology will be deleted and added again. Just press Upload LSDB Tab again and then deleting of topology works fine.

# Contribution. New textfsm templates creation for different vendors
In order to project supports different vendors you can help us by creating five separate textfsm files for different LSA types for one vendor. Check ![Wiki](https://github.com/Vadims06/topolograph/wiki/How-to-add-new-vendor-support) for this.

## Used RFC
RFC 2328
