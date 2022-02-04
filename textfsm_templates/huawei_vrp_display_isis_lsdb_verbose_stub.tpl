Value Required,Filldown LSPID (\S+)
Value Filldown Hostname (\S+)
Value Filldown AREA (\S+)
Value Required METRIC (\d+)
Value Required SUBNET (\d+\.\d+\.\d+\.\d+)
Value Required SUBNET_MASK (\d+\.\d+\.\d+\.\d+)
Value Fillup RID ((\d+\.){3}\d+)

Start
  ^\s+SOURCE\s+${LSPID} -> Continue.Record
  ^\s+HOST\s+NAME\s+${Hostname} -> Continue.Record
  ^\s+AREA\s+ADDR\s+${AREA} -> Continue.Record
  ^\S+IP-Internal\s+${SUBNET}\s+${SUBNET_MASK}\s+COST:\s+${METRIC} -> Continue.Record
  ^\s+Router\s+ID\s+${RID} -> Continue.Record
