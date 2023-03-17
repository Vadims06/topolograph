# Topolograph

## v2.30 (17.03.2023)

## Enhancements

### OSPF/IS-IS cost on edge labels

* LabelFrom, LabelTo is available now on topolograph. Meanwhile it is possible to switch this view off.

![](https://github.com/Vadims06/topolograph/blob/77a5100b56ff5ab0e180cefc98e504067ace17c5/docs/release-notes/v2.30/edge_labels_on_graph.PNG)

* OSPF/IS-IS cost on the shortest path

![](https://github.com/Vadims06/topolograph/blob/77a5100b56ff5ab0e180cefc98e504067ace17c5/docs/release-notes/v2.30/edge_labels_on_the_path.PNG)

### API reply code
* In case of pushing bad OSPF/IS-IS LSDB - reply is Bad Request, 400. Linked to [watcher api ValueError: UNAUTHORIZED](https://github.com/Vadims06/ospfwatcher/issues/3)
