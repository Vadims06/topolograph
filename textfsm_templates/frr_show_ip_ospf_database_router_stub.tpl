Value Filldown ROUTER_ID (\d+\.\d+\.\d+\.\d+)
Value Filldown PROCESS_ID (\d+)
Value Filldown AREA (\d+\.\d+\.\d+\.\d+|\d+)
Value Filldown ADV_ROUTER_ID (\d+\.\d+\.\d+\.\d+)
Value Required STUB (Stub Network)
Value SUBNET (\d+\.\d+\.\d+\.\d+)
Value SUBNET_MASK (\d+\.\d+\.\d+\.\d+)
Value METRIC (\d+)

Start
  ^.*OSPF Router with ID \(${ROUTER_ID}\)
  ^.*\(Area ${AREA}\)
  ^.*Advertising Router:\s+${ADV_ROUTER_ID}
  ^.*Link connected to: ${STUB}
  ^.*Net: ${SUBNET}
  ^.*Network Mask: ${SUBNET_MASK}
  ^.*TOS 0 Metric:\s+${METRIC} -> Record
  ^.*LS age: \d+ -> Tag


Tag
  ^.*LS Type: Router Links -> Next.Clearall
  ^\s -> Start

EOF