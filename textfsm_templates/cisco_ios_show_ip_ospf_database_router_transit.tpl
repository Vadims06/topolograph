Value Filldown ROUTER_ID (\d+\.\d+\.\d+\.\d+)
Value Filldown PROCESS_ID (\d+)
Value Filldown AREA (\d+\.\d+\.\d+\.\d+|\d+)
Value Filldown ADV_ROUTER_ID (\d+\.\d+\.\d+\.\d+)
Value Required STUB (Transit Network)
Value Required DR_IP_Addr (\d+\.\d+\.\d+\.\d+)
Value Required METRIC (\d+)

Start
  ^.*\(${ROUTER_ID}\) \(.* ${PROCESS_ID}\)
  ^.*\(Area ${AREA}\)
  ^.*Advertising Router:\s+${ADV_ROUTER_ID}
  ^.*Link connected to: a ${STUB}
  ^.*Designated Router address: ${DR_IP_Addr}
  ^.*TOS\s+0\s+Metric[s]?:\s+${METRIC} -> Record
  ^.*LS age: \d+ -> Tag


Tag
  ^.*LS Type: Router Links -> Next.Clearall
  ^\s -> Start

EOF