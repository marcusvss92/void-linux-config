#!/bin/bash
# /usr/local/bin/setup-security.sh
# Script de configuração automática de segurança para pentesting no Void Linux

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}Este script precisa ser executado como root${NC}"
        exit 1
    fi
}

install_packages() {
    echo -e "${GREEN}Instalando pacotes necessários...${NC}"
    
    # Atualizar repositórios
    xbps-install -S
    
    # Pacotes básicos de segurança
    xbps-install -y nftables fail2ban aide audit osquery htop btop sysstat
    
    # Ferramentas de rede e monitoramento
    xbps-install -y tcpdump wireshark-qt ntopng
    
    # Criptografia e proteção
    xbps-install -y encfs gocryptfs pass gnupg2
    
    # Sandbox
    xbps-install -y firejail
    
    echo -e "${GREEN}Pacotes instalados com sucesso${NC}"
}

setup_services() {
    echo -e "${GREEN}Configurando serviços...${NC}"
    
    # Criar diretórios dos serviços se não existirem
    mkdir -p /etc/sv/nftables
    mkdir -p /etc/sv/fail2ban
    
    # Tornar scripts executáveis
    chmod +x /etc/sv/nftables/run
    chmod +x /etc/sv/nftables/finish
    chmod +x /etc/sv/fail2ban/run
    
    # Habilitar serviços
    ln -sf /etc/sv/nftables /var/service/ 2>/dev/null || true
    ln -sf /etc/sv/fail2ban /var/service/ 2>/dev/null || true
    
    echo -e "${GREEN}Serviços configurados${NC}"
}

setup_directories() {
    echo -e "${GREEN}Criando estrutura de diretórios...${NC}"
    
    # Diretórios para logs de segurança
    mkdir -p /var/log/security-monitor
    mkdir -p /var/log/aide
    mkdir -p /var/log/network
    
    # Diretórios para backup
    mkdir -p /etc/sysctl.d/backups
    
    # Diretório para projetos de pentesting
    mkdir -p /home/projects
    mkdir -p /home/projects/evidence
    mkdir -p /home/projects/reports
    
    # Diretórios para AIDE
    mkdir -p /var/lib/aide
    
    # Permissões adequadas
    chmod 700 /var/log/security-monitor
    chmod 700 /var/log/aide
    chmod 750 /var/log/network
    chmod 700 /home/projects
    
    echo -e "${GREEN}Estrutura de diretórios criada${NC}"
}

setup_cron() {
    echo -e "${GREEN}Configurando tarefas automáticas...${NC}"
    
    # Criar crontab para root se não existir
    mkdir -p /var/spool/cron/crontabs
    
    # Backup do crontab atual se existir
    if [ -f /var/spool/cron/crontabs/root ]; then
        cp /var/spool/cron/crontabs/root /var/spool/cron/crontabs/root.backup
    fi
    
    # Configurar cron para monitoramento
    cat > /var/spool/cron/crontabs/root << 'EOF'
# Verificação de segurança a cada 15 minutos
*/15 * * * * /usr/local/bin/security-monitor.sh >/dev/null 2>&1

# BTRFS scrub semanal (domingo às 3h)
0 3 * * 0 btrfs scrub start / >/dev/null 2>&1

# AIDE check diário (às 4h)
0 4 * * * aide --check >/var/log/aide/daily-check.log 2>&1

# Rotação de logs diária
0 5 * * * find /var/log/security-monitor -name "*.log" -mtime +7 -delete
0 5 * * * find /var/log/network -name "*.pcap" -mtime +3 -delete

# Backup de configurações semanal
0 6 * * 1 /usr/local/bin/backup-configs.sh >/dev/null 2>&1
EOF
    
    # Definir permissões corretas
    chmod 600 /var/spool/cron/crontabs/root
    chown root:root /var/spool/cron/crontabs/root
    
    # Reiniciar crond
    sv restart cron 2>/dev/null || true
    
    echo -e "${GREEN}Tarefas automáticas configuradas${NC}"
}

initialize_aide() {
    echo -e "${GREEN}Inicializando AIDE...${NC}"
    
    if [ -f /etc/aide.conf ]; then
        echo "Criando base de dados inicial do AIDE..."
        aide --init
        
        if [ -f /var/lib/aide/aide.db.new ]; then
            mv /var/lib/aide/aide.db.new /var/lib/aide/aide.db
            echo -e "${GREEN}Base de dados AIDE criada com sucesso${NC}"
        else
            echo -e "${YELLOW}Aviso: Não foi possível criar base de dados AIDE${NC}"
        fi
    else
        echo -e "${YELLOW}Arquivo /etc/aide.conf não encontrado${NC}"
    fi
}

create_backup_script() {
    echo -e "${GREEN}Criando script de backup...${NC}"
    
    cat > /usr/local/bin/backup-configs.sh << 'EOF'
#!/bin/bash
# Script de backup de configurações importantes

BACKUP_DIR="/backup/configs"
DATE=$(date +%Y%m%d-%H%M%S)

mkdir -p "$BACKUP_DIR"

# Backup de arquivos críticos
tar -czf "$BACKUP_DIR/system-configs-$DATE.tar.gz" \
    /etc/aide.conf \
    /etc/sysctl.d/ \
    /etc/nftables.conf \
    /etc/fail2ban/ \
    /etc/ssh/ \
    /etc/doas.conf \
    /usr/local/bin/security-monitor.sh \
    /usr/local/bin/pentest-mode.sh \
    /usr/local/bin/setup-firewall.sh \
    2>/dev/null

# Criptografar backup
gpg --cipher-algo AES256 --compress-algo 1 --symmetric \
    --output "$BACKUP_DIR/system-configs-$DATE.tar.gz.gpg" \
    "$BACKUP_DIR/system-configs-$DATE.tar.gz"

# Remover backup não criptografado
rm -f "$BACKUP_DIR/system-configs-$DATE.tar.gz"

# Manter apenas os últimos 10 backups
find "$BACKUP_DIR" -name "system-configs-*.tar.gz.gpg" -mtime +30 -delete

echo "Backup concluído: $BACKUP_DIR/system-configs-$DATE.tar.gz.gpg"
EOF

    chmod +x /usr/local/bin/backup-configs.sh
    
    echo -e "${GREEN}Script de backup criado${NC}"
}

make_scripts_executable() {
    echo -e "${GREEN}Tornando scripts executáveis...${NC}"
    
    chmod +x /usr/local/bin/setup-firewall.sh
    chmod +x /usr/local/bin/pentest-mode.sh
    chmod +x /usr/local/bin/security-monitor.sh
    chmod +x /usr/local/bin/backup-configs.sh
    
    echo -e "${GREEN}Scripts configurados${NC}"
}

final_steps() {
    echo -e "${GREEN}Executando passos finais...${NC}"
    
    # Aplicar configurações sysctl
    sysctl -p /etc/sysctl.d/99-security.conf
    
    # Configurar firewall inicial
    /usr/local/bin/setup-firewall.sh secure
    
    # Aguardar serviços subirem
    sleep 5
    
    echo -e "${GREEN}==================================${NC}"
    echo -e "${GREEN}CONFIGURAÇÃO CONCLUÍDA COM SUCESSO${NC}"
    echo -e "${GREEN}==================================${NC}"
    echo
    echo -e "${YELLOW}Comandos úteis:${NC}"
    echo -e "  pentest-mode.sh pentest  - Ativar modo pentesting"
    echo -e "  pentest-mode.sh secure   - Ativar modo seguro"
    echo -e "  pentest-mode.sh status   - Ver status atual"
    echo -e "  security-monitor.sh      - Executar verificação manual"
    echo
    echo -e "${YELLOW}Serviços ativos:${NC}"
    sv status nftables fail2ban
    echo
    echo -e "${RED}IMPORTANTE:${NC}"
    echo -e "- Configure uma senha forte para criptografia GPG"
    echo -e "- Initialize o pass: pass init sua-chave-gpg"
    echo -e "- Configure VPN antes de atividades de pentesting"
    echo -e "- Execute 'aide --check' regularmente"
}

# Script principal
echo -e "${GREEN}=== CONFIGURAÇÃO DE SEGURANÇA PARA PENTESTING ===${NC}"
echo -e "${GREEN}Void Linux + BTRFS + nftables + runit${NC}"
echo

check_root

echo "Este script irá:"
echo "- Instalar pacotes de segurança necessários"
echo "- Configurar nftables e fail2ban"
echo "- Criar scripts de monitoramento"
echo "- Configurar AIDE para monitoramento de integridade"
echo "- Estabelecer rotinas automáticas de backup"
echo

read -p "Continuar? (s/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Ss]$ ]]; then
    echo "Instalação cancelada."
    exit 1
fi

# Executar todas as funções
install_packages
setup_directories
setup_services
setup_cron
make_scripts_executable
create_backup_script
initialize_aide
final_steps

exit 0