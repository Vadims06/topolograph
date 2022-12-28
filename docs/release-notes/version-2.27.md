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
![](https://github.com/Vadims06/topolograph/blob/5ddffc78af87d4a6ba04e643442ca50a1bb45e45/docs/release-notes/v2.27/ospf_log_timeline.png)  
  
  
#### Filter any subnet-related events
![](https://github.com/Vadims06/topolograph/blob/5ddffc78af87d4a6ba04e643442ca50a1bb45e45/docs/release-notes/v2.27/ospf_log_timeline_except_subnets.png) 

#### Left only up/down link events
![](https://github.com/Vadims06/topolograph/blob/5ddffc78af87d4a6ba04e643442ca50a1bb45e45/docs/release-notes/v2.27/ospf_log_timeline_only_new_old_links.png)


### Enhancements
A favicon is added. 
