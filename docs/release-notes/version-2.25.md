# Topolograph

## v2.25 (09.12.2021)

## OSPF Watcher is added
## Architecture
![](https://github.com/Vadims06/ospfwatcher/blob/f218b754ac7b543ffe46f9bb7df9cba0caf7b5cb/docs/Architecture.png)  
The Quagga container has `network_mode=host` so it sees the GRE tunnel, which is configured by Admin on the Linux Host.  
### Functional Role
![](https://github.com/Vadims06/ospfwatcher/blob/247bb4d330de762cfc4c3fd67135e5740ba8403c/docs/functional-watcher-role.png)
## Demo
Click on the image in order zoom it.  
![](https://github.com/Vadims06/ospfwatcher/blob/ada2ca86df171ec5f1b550da821f0a8ca1cb1df4/docs/ospf-watcher-demo.gif)

## Discovering OSPF logs in Kibana. Examples
OSPF cost changes on links  
![](https://github.com/Vadims06/ospfwatcher/blob/774ffe06131e932bd0d87b430010523d942a2342/docs/cost-changes-raw-logs.png)

Logs if OSPF adjacency was Up/Down or any networks appeared/disappeared.  
![](https://github.com/Vadims06/ospfwatcher/blob/774ffe06131e932bd0d87b430010523d942a2342/docs/host-updown-raw-logs.png)

### Enhancements
[Network reaction API](https://github.com/Vadims06/topolograph/issues/24)
