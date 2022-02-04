Value Required,Filldown LSPID (\S+\.\d{2})
Value Required,Filldown AREA (\S+)
Value Filldown RID ((\d+\.){3}\d+)
Value Required SUBNET (\d+\.\d+\.\d+\.\d+)
Value Required SUBNET_MASK (\d+\.\d+\.\d+\.\d+)
Value Required METRIC (\d+)

Start
  ^${LSPID}-.* -> Continue.Record
  ^\s+Area\s+Address:\s+${AREA} -> Continue.Record
  ^\s+Router\s+ID:\s+${RID} -> Continue.Record
  ^\s+Metric:\s+${METRIC}\s+IP\s+${SUBNET}\s+${SUBNET_MASK} -> Continue.Record
