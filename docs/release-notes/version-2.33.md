# Topolograph

## v2.33 (11.07.2023)

## New features
Basic graph analytic's algorithm were added:
* Find central node/s in the network
* Find the most N loaded/critical nodes in the network
* Find the most N loaded/critical edges in the network
* Find "single point of failure" nodes. If they fail, the network will lose the connection between nodes (become disjointed)
* Find fault tolerant nodes. If they fail, the network will keep connected.

### New features
#### Central nodes
![](https://github.com/Vadims06/topolograph/blob/b0ec1488b202e94604aec541d3eeac554243f8dc/docs/release-notes/v2.33/central_nodes_v2_33.PNG)

#### The most 3 loaded/critical nodes
![](https://github.com/Vadims06/topolograph/blob/b0ec1488b202e94604aec541d3eeac554243f8dc/docs/release-notes/v2.33/_3_most_loaded_nodes.PNG)

#### The most 3 loaded/critical edges
![](https://github.com/Vadims06/topolograph/blob/b0ec1488b202e94604aec541d3eeac554243f8dc/docs/release-notes/v2.33/_3_most_loaded_edges.PNG)

#### Single point of failure
![](https://github.com/Vadims06/topolograph/blob/b0ec1488b202e94604aec541d3eeac554243f8dc/docs/release-notes/v2.33/single_point_of_failure.PNG)

#### Fault tolerant nodes
![](https://github.com/Vadims06/topolograph/blob/b0ec1488b202e94604aec541d3eeac554243f8dc/docs/release-notes/v2.33/fault_tolerant_nodes.PNG)

## Enhancements

* "-" Yaml syntax clashed with "zoom in" keyword hotkey of graph
* Documentation. Cisco NX-OS commands for getting OSPF LSDB were added.
