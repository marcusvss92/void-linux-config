setup_sleep_hooks() {
    echo "Configurando hooks de suspend/resume..."
    
    # Hook para suspend (desligar GPU)
    doas tee /usr/lib/systemd/system-sleep/nvidia-power << 'EOF'
#!/bin/bash
# Hook de suspend/resume para NVIDIA

case $1 in
    pre)
        # Antes de suspend - desativar GPU
        echo "Desativando GPU para suspend..."
        nvidia-smi -pm 0 2>/dev/null
        echo auto > /sys/bus/pci/devices/0000:01:00.0/power/control 2>/dev/null
        ;;
    post)
        # Após resume - manter GPU desligada (usuário ativa manualmente)
        echo "Resume - GPU permanece em economia de energia"
        echo "Use 'gpu-on' se precisar ativar"
        ;;
esac
EOF
    
    doas chmod +x /usr/lib/systemd/system-sleep/nvidia-power
}
