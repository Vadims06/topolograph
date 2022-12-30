# Topolograph

## v2.27 (28.12.2022)

## OSPF Watcher is integrated into Topolograph
### OSPF Monitoring page
The solution is available only on docker-based Topolograph. It requires launching [topolograph-docker](https://github.com/Vadims06/topolograph-docker) and [ospfwatcher](https://github.com/Vadims06/ospfwatcher) on your on-premise host. Right after it OSPF topology changes will be logged into Topolograph's DB and ELK. Topolograph's OSPFWatcher page provides the following options:  
* filter logs by start and end time
* filter network event by new/old subnets, up/down links, cost changes events

### Demo logs
OSPF Monitoring page is prefilled by demo logs.
Event on timeline dashboard is clickable - the historical event is shown on the graph too. For example if we choose the link down event between 10.1.1.2 and 10.1.1.4 on the timeline dashboard, we see an appropriate link on the graph. It means that this link went down at 8:26 AM UTC.
All logs are grouped by the detected device.   
#### New subnet event shows where the subnet appeared  
![](https://github.com/Vadims06/topolograph/blob/56861d2d72399c92a6858346cd42171cbd6da4c7/docs/release-notes/v2.27/ospf_monitoring_new_subnet.PNG)  
  
  
#### Filter any subnet-related events, select Change metric event
new and old metric is shown
![](https://github.com/Vadims06/topolograph/blob/56861d2d72399c92a6858346cd42171cbd6da4c7/docs/release-notes/v2.27/ospf_monitoring_change_metric.PNG) 

#### up/down link events
Red timelines show link (~adjacency) down events, green one - up link (~adjacency).  
Timeline `10.1.1.2-10.1.1.3` has been selected.
![](https://github.com/Vadims06/topolograph/blob/56861d2d72399c92a6858346cd42171cbd6da4c7/docs/release-notes/v2.27/ospf_monitoring_down_link.PNG)


### Enhancements
A favicon is added. 
