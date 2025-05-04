Value Required,Filldown LEVEL_NUM (\d)
Value Required,Filldown LSPID (\S+\.[\w\d]{2}-[\w\d]{2})
Value Required,Filldown AREA (\S+)
Value Filldown RID ((\d+\.){3}\d+)
Value NARROW_SUBNET (\d+\.\d+\.\d+\.\d+||[.:\dabcdefABCDEF]+)
Value EXTENDED_SUBNET (\d+\.\d+\.\d+\.\d+||[.:\dabcdefABCDEF]+)
Value Required SUBNET_MASK (\d+\.\d+\.\d+\.\d+|\d+)
Value Required METRIC (\d+)

Start
  ^IS-IS\s+.*Level-${LEVEL_NUM}
  ^${LSPID} -> Continue.Record
  ^\s+Area\s+Address:\s+${AREA} -> Continue.Record
  ^\s+Router\s+ID:\s+${RID} -> Continue.Record
  ^\s+Metric:\s+${METRIC}\s+IP\s+${NARROW_SUBNET}[/\s*]?${SUBNET_MASK} -> Continue.Record
  ^\s+Metric:\s+${METRIC}\s+(\s*MT\s*)?(\(\s*IPv6 Unicast\s*\))?\s*IP(v6)?(\-Extended|\-External)?\s+${EXTENDED_SUBNET}/${SUBNET_MASK} -> Continue.Record