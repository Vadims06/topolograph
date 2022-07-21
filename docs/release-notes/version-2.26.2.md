# Topolograph

## v2.26.2 (21.07.2022)

### Enhancements
* Topolograph builds a topology based on OSPF adjacency and physical connectivity is hidden. But in some cases, we can assume that neighbors share the same media, in some cases - not. For example, if neighbors have a common DR - we assume that they are connected via shared physical media and then we emulate one of the edge failures between such neighbors - we emulate all edges down.  
##### Mark all shared media links (which have common DR) is enabled  ![shared media mode](https://github.com/Vadims06/topolograph/blob/0c30e982a65dba273e9eaa2d5f0bf5ecc12bd060/docs/release-notes/v2.26.2/networkReactionOnFailure_dr_is_enabled.png "save layout")
* Network reaction if a link/s goes down on dedicated media.  
If neighbors do not have DR or they have, but they are only two neighbors on the link, and when we emulate edge failure - we remove the only a single link between two particular neighbors.  
##### Mark all shared media links (which have common DR) is disabled  ![dedicated media mode](https://github.com/Vadims06/topolograph/blob/0c30e982a65dba273e9eaa2d5f0bf5ecc12bd060/docs/release-notes/v2.26.2/networkReactionOnFailure_dr_is_not_enabled.png "save layout")

## v2.26.1 (14.06.2022)

### Enhancements
* Asymmetric links counter is added in `Unidirectional and Asymmetric links` report
