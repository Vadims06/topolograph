# Topolograph

## v2.21 (27.07.2021)

### Enhancements
* Backup paths via 3d party locations.  
This report checks that if two locations are directly connected, backup paths should be only between two locations and do not go via third location as transit. Before running this report - it's needed to create groups (~site names/locations) and assign devices to groups. For example, there are two locations in France: the main site (EU_FRA) and the remote site (EU_FRA1). The same schema with offices in Italy. The main offices in France and Italy are connected to each other and have main (OSPF cost 10) and backup (OSPF cost 20) link.
network scheme ![network scheme](https://github.com/Vadims06/topolograph/blob/8361ce52894f90885a828982080353f8b0737966/docs/release-notes/v2.20/ospf_backup_path_via_third_locations.png "network scheme")  
Remote offices have the main link (OSPF cost 1) to their main offices and backup link (OSPF cost 10) to the foreign office.  
If the main link between main offices goes down - the backup path goes via remote offices in different locations!  
![failed report](https://github.com/Vadims06/topolograph/blob/8361ce52894f90885a828982080353f8b0737966/docs/release-notes/v2.20/ospf_intergroup_backup_path_via_third_group.png "failed report")
* fixes in ECMP backup paths report in v2.20
