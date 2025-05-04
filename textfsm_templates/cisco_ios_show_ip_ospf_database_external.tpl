Value Filldown ROUTER_ID (\d+\.\d+\.\d+\.\d+)
Value Filldown PROCESS_ID (\d+)
Value Filldown ADV_ROUTER_ID (\d+\.\d+\.\d+\.\d+)
Value Required SUBNET (\d+\.\d+\.\d+\.\d+)
Value Required SUBNET_MASK (\/\d+)
Value Filldown METRIC_TYPE (\d+)
Value Filldown METRIC (\d+)
Value Filldown FORWARDING_IP_ADDR (\d+\.\d+\.\d+\.\d+)


Start
  ^.*\(${ROUTER_ID}\) \(.* ${PROCESS_ID}\)
  ^.*Link State ID: ${SUBNET}
  ^.*Advertising Router:\s+${ADV_ROUTER_ID}
  ^.*Network Mask: ${SUBNET_MASK}
  ^.*Metric Type: ${METRIC_TYPE} 
  ^.*Metric: ${METRIC}
  ^.*Forward Address: ${FORWARDING_IP_ADDR}
  ^.*External Route Tag: .* -> Record
  ^.*LS -> Start

EOF