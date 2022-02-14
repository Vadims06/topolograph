Value Required,Filldown LSPID (\S+)
Value Filldown Hostname (\S+)
Value Filldown AREA (\S+)
Value Required NEIGHBORING_LSPID (\S+)
Value Required METRIC (\d+)
Value Fillup RID ((\d+\.){3}\d+)

Start
  ^\s+SOURCE\s+${LSPID} -> Continue.Record
  ^\s+HOST\s+NAME\s+${Hostname} -> Continue.Record
  ^\s+AREA\s+ADDR\s+${AREA} -> Continue.Record
  ^\S+NBR\s+ID\s+${NEIGHBORING_LSPID}\s+COST:\s+${METRIC} -> Continue.Record
  ^\s+Router\s+ID\s+${RID} -> Continue.Record