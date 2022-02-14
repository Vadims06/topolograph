Value Filldown LSPID (\S+\.\d{2})
Value Filldown AREA (\S+)
Value Filldown RID ((\d+\.){3}\d+)
Value Required,Filldown Hostname (\S+)
Value Required NEIGHBORING_LSPID (\S+)
Value Required METRIC (\d+)

Start
  ^${LSPID}-\d+\s+Sequence:.* -> Continue.Record
  ^\s+Area\s+address:\s+${AREA}.* -> Continue.Record
  ^\s+IP\s+router\s+id:\s+${RID} -> Continue.Record
  ^\s+Hostname:\s+${Hostname} -> Continue.Record
  ^\s+IS\s+extended\s+neighbor:\s+${NEIGHBORING_LSPID},.*\s+Metric:\s+\S+\s+${METRIC} -> Continue.Record