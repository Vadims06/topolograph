Value Required,Filldown LSPID (\S+)
Value Required,Filldown Level (\S+)
Value Required,Filldown AREA (\d+\.\d+)
Value Required,Filldown RID ((\d+\.){3}\d+)
Value Required SUBNET (\d+\.\d+\.\d+\.\d+)
Value Required SUBNET_MASK (\d+)
Value Required METRIC (\d+)


Start
  ^LSP\s+ID\s+:\s+${LSPID}-00\s+Level\s+:\s+${Level}
  ^\s+Area\s+Address\s+:\s+\(\d+\)\s+${AREA}.*
  ^\s+Router\s+ID\s+:\s+${RID}
  ^\s+Default\s+Metric\s+:\s+${METRIC}
  ^\s+Control\s+Info:\s+,\s+prefLen\s+${SUBNET_MASK}
  ^\s+Prefix\s+:\s+${SUBNET} -> Record