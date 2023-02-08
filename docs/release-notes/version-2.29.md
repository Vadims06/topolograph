# Topolograph

## v2.29 (04.02.2023)

## Enhancements

### VRF (ospf vrf instances) support

* A single node might have several OSPF instances in different VRFs and in order to remove duplicated nodes on the graph - it possible to create VRF, associate OSPF VRF instances with VRF and master node (the node which will be on the graph)
VRF names can be imported via CSV file

![](https://github.com/Vadims06/topolograph/blob/cbf02ed75f519c765014b87391672c9d82a0af6b/docs/release-notes/v2.29/vrf_schema.png)
