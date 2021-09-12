# Topolograph

## v2.21 (21.08.2021)

### Enhancements
* HP (limited) support is added. 

The limitation is due to HP doesn't follow rfc2328 specification, I mean Router LSA has to provide subnet and subnet mask in Link ID and Link Data respectively, but HP includes subnet, but doesn't include the network mask.
```
LSA Age                         : 167
LSA Type                        : 0x1 (Router LSA)
Advertising Router              : 192.168.255.154

Number of links                 : 13
 
    Interface Type              : 3 (Connected to Stub Network)
    LSA Metric                  : 1
    Link Data                   : 192.168.48.0
    Link ID                     : 192.168.255.154 <- subnet? it has to contain mask
``` 
The same situation with external networks. HP forgot to include the network mask in the LSA5)
```
LSA Age                         : 3
LSA Type                        : 0x5 (AS External LSA)
Advertising Router              : 10.10.0.6
Link State ID                   : 192.168.245.0 <- ok, but where is the mask??
LSA Sequence                    : 0x80000517
LSA Checksum                    : 0x7fb1
LSA Option Bits                 : E=0 MC=0 N/P=0 EA=0 DC=0
LSA Metric                      : 10
Bit E                           : 1 (External Metric Type2)
Forwarding Address              : 0.0.0.0
External Route Tag              : 0
```
From this message I know that there is some 192.168.245.0 subnet in a network, but don't know what the mask of this subnet =)
