Value Required,Filldown LSPID (\S+\.\d{2})
Value Required,Filldown AREA (\S+)
Value Filldown RID ((\d+\.){3}\d+)
Value Required,Filldown Hostname (\S+)
Value Required SUBNET (\d+\.\d+\.\d+\.\d+)
Value Required SUBNET_MASK (\d+)
Value Required METRIC (\d+)

Start
  ^${LSPID}-\d+\s+Sequence:.* -> Continue.Record
  ^\s*IP prefix: ${SUBNET}/{SUBNET_MASK} metric ${METRIC} -> Continue.Record
  ^\s+Area\s+address:\s+${AREA}.* -> Continue.Record
  ^\s+IP\s+router\s+id:\s+${RID} -> Continue.Record
  ^\s+Hostname:\s+${Hostname} -> Continue.Record
  ^.*IP extended prefix: ${SUBNET}/${SUBNET_MASK} metric ${METRIC}.* -> Continue.Record