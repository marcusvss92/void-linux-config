#!/bin/bash
# /usr/local/bin/setup-firewall.sh
# Configuração de firewall com nftables para pentesting

MODE="$1"

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

setup_secure_firewall() {
    echo -e "${GREEN}Configurando firewall seguro com nftables...${NC}"
    
    # Limpar regras existentes
    nft flush ruleset
    
    # Criar tabela principal
    nft add table inet filter
    
    # Criar chains
    nft add chain inet filter input { type filter hook input priority 0 \; policy drop \; }
    nft add chain inet filter forward { type filter hook forward priority 0 \; policy drop \; }
    nft add chain inet filter output { type filter hook output priority 0 \; policy accept \; }
    
    # Regras básicas de segurança
    nft add rule inet filter input ct state related,established accept
    nft add rule inet filter input iifname lo accept
    
    # SSH (ajuste a porta conforme necessário)
    nft add rule inet filter input tcp dport 22 ct state new accept
    
    # Bloquear tráfego IPv6 desnecessário
    nft add rule inet filter input meta l4proto ipv6-icmp icmpv6 type { destination-unreachable, packet-too-big, time-exceeded, parameter-problem, echo-request } accept
    nft add rule inet filter input ip6 nexthdr icmpv6 accept
    
    # Log e drop para debugging
    nft add rule inet filter input limit rate 5/minute log prefix \"DROP INPUT: \"
    
    echo -e "${GREEN}Firewall seguro configurado${NC}"
}

setup_pentest_firewall() {
    echo -e "${YELLOW}Configurando firewall para pentesting...${NC}"
    
    # Limpar regras existentes
    nft flush ruleset
    
    # Criar tabela principal
    nft add table inet filter
    
    # Criar chains com políticas mais permissivas para output
    nft add chain inet filter input { type filter hook input priority 0 \; policy drop \; }
    nft add chain inet filter forward { type filter hook forward priority 0 \; policy accept \; }
    nft add chain inet filter output { type filter hook output priority 0 \; policy accept \; }
    
    # Regras básicas
    nft add rule inet filter input ct state related,established accept
    nft add rule inet filter input iifname lo accept
    
    # SSH
    nft add rule inet filter input tcp dport 22 ct state new accept
    
    # Portas comuns para reverse shells e listeners
    nft add rule inet filter input tcp dport 4444 accept
    nft add rule inet filter input tcp dport 4443 accept
    nft add rule inet filter input tcp dport 8080 accept
    nft add rule inet filter input tcp dport 8443 accept
    nft add rule inet filter input tcp dport 9999 accept
    nft add rule inet filter input tcp dport 1234 accept
    
    # Portas para web shells e ferramentas web
    nft add rule inet filter input tcp dport 80 accept
    nft add rule inet filter input tcp dport 443 accept
    nft add rule inet filter input tcp dport 8000 accept
    nft add rule inet filter input tcp dport 3000 accept
    
    # Portas para SMB e compartilhamento (se necessário)
    nft add rule inet filter input tcp dport { 139, 445 } accept
    nft add rule inet filter input udp dport { 137, 138 } accept
    
    # FTP passivo (se necessário)
    nft add rule inet filter input tcp dport 21 accept
    nft add rule inet filter input tcp dport 20000-21000 accept
    
    # ICMP necessário para algumas ferramentas
    nft add rule inet filter input icmp type { echo-request, destination-unreachable, time-exceeded } accept
    nft add rule inet filter input meta l4proto ipv6-icmp icmpv6 type { destination-unreachable, packet-too-big, time-exceeded, parameter-problem, echo-request } accept
    
    # Permitir tráfego para interfaces de tunneling comuns
    nft add rule inet filter input iifname { tun+, tap+, wg+ } accept
    nft add rule inet filter forward iifname { tun+, tap+, wg+ } accept
    nft add rule inet filter forward oifname { tun+, tap+, wg+ } accept
    
    echo -e "${YELLOW}Firewall configurado para pentesting${NC}"
    echo -e "${RED}ATENÇÃO: Múltiplas portas abertas para testes${NC}"
}

save_rules() {
    echo -e "${GREEN}Salvando regras do nftables...${NC}"
    nft list ruleset > /etc/nftables.conf
}

show_status() {
    echo -e "${GREEN}Status atual do firewall:${NC}"
    nft list ruleset
}

case "$MODE" in
    "secure")
        setup_secure_firewall
        save_rules
        ;;
    "pentest")
        setup_pentest_firewall
        save_rules
        ;;
    "status")
        show_status
        ;;
    "")
        # Modo padrão - seguro
        setup_secure_firewall
        save_rules
        ;;
    *)
        echo "Uso: $0 [secure|pentest|status]"
        exit 1
        ;;
esac