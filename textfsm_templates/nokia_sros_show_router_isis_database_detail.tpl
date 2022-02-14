Value Required,Filldown LSPID (\S+)
Value Required,Filldown Level (\S+)
Value Required,Filldown AREA (\d+\.\d+)
Value Required,Filldown RID ((\d+\.){3}\d+)
Value Required NEIGHBORING_LSPID (\S+)
Value METRIC (\d+)
Value NbrIP ((\d+\.){3}\d+)


Start
  ^LSP\s+ID\s+:\s+${LSPID}-00\s+Level\s+:\s+${Level} -> Continue.Record
  ^\s+Area\s+Address\s+:\s+\(\d+\)\s+${AREA}.* -> Continue.Record
  ^\s+Router\s+ID\s+:\s+${RID} -> Continue.Record
  ^\s+Nbr\s+:\s+${NEIGHBORING_LSPID} -> Continue
  ^\s+Default\s+Metric\s+:\s+${METRIC} -> Continue
  ^\s+Nbr\s+IP\s+:\s+${NbrIP} -> Continue.Record