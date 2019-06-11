Value Filldown AREA (\d+\.\d+\.\d+\.\d+|\d+)
Value Filldown NETMASK (\/\d+)
Value Filldown ADV_ROUTER_ID (\d+\.\d+\.\d+\.\d+)
Value Filldown DR_IP_Add (\d+\.\d+\.\d+\.\d+)
Value List NEIGHBORING_ROUTER_ID (\d+\.\d+\.\d+\.\d+)

Start
  ^.*\(Area ${AREA}\)
  ^.*LS Type: -> Continue.Record
  ^.*Link State ID:\s+${DR_IP_Add}
  ^.*Advertising Router:\s+${ADV_ROUTER_ID}
  ^.*Network Mask: ${NETMASK}
  ^.*Attached Router: ${NEIGHBORING_ROUTER_ID}
  ^.*LS -> Start

Tag
  ^\s -> Start