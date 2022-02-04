Value Required,Filldown LSPID (\S+\.\d{2})
Value Required,Filldown AREA (\S+)
Value Filldown RID ((\d+\.){3}\d+)
Value Required METRIC (\d+)
Value Required NEIGHBORING_LSPID (\S+)

Start
  ^${LSPID}-.* -> Continue.Record
  ^\s+Area\s+Address:\s+${AREA} -> Continue.Record
  ^\s+Router\s+ID:\s+${RID} -> Continue.Record
  ^\s+Metric:\s+${METRIC}\s+IS\s+${NEIGHBORING_LSPID} -> Continue.Record
