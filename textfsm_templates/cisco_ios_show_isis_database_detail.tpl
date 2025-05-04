Value Required,Filldown LEVEL_NUM (\d)
Value Required,Filldown LSPID (\S+\.[\w\d]{2}-[\w\d]{2})
Value Required,Filldown AREA (\S+)
Value Filldown RID ((\d+\.){3}\d+)
Value Required METRIC (\d+)
Value NARROW_NEIGHBORING_LANID (\S+)
Value EXTENDED_NEIGHBORING_LANID (\S+)

Start
  ^IS-IS\s+.*Level-${LEVEL_NUM}
  ^${LSPID} -> Continue.Record
  ^\s+Area\s+Address:\s+${AREA} -> Continue.Record
  ^\s+Router\s+ID:\s+${RID} -> Continue.Record
  ^\s+Metric:\s+${METRIC}.*IS\s+${NARROW_NEIGHBORING_LANID} -> Continue.Record
  ^\s+Metric:\s+${METRIC}.*IS-Extended\s+${EXTENDED_NEIGHBORING_LANID} -> Continue.Record