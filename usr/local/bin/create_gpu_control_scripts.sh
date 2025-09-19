#!/bin/bash
# Função para criar scripts de controle

create_gpu_control_scripts() {
    echo "Criando scripts de controle da GPU..."
    
    # Script para LIGAR GPU (para hashcat, etc.)
    doas tee /usr/local/bin/gpu-on.sh << 'EOF'
#!/bin/bash
# Ativar GPU NVIDIA para pentesting

echo "🔥 Ativando GPU NVIDIA..."

# Remover do runtime PM
echo on > /sys/bus/pci/devices/0000:01:00.0/power/control 2>/dev/null

# Definir performance mode
nvidia-smi -pm 1 2>/dev/null
nvidia-smi -pl 115 2>/dev/null  # RTX 2050 power limit padrão

# Verificar se ativou
if nvidia-smi &>/dev/null; then
    echo "✅ GPU NVIDIA ativa"
    nvidia-smi --query-gpu=name,power.draw,temperature.gpu --format=csv,noheader
else
    echo "❌ Falha ao ativar GPU"
fi
EOF

    # Script para DESLIGAR GPU (economia de energia)
    doas tee /usr/local/bin/gpu-off.sh << 'EOF'
#!/bin/bash
# Desativar GPU NVIDIA para economia de energia

echo "💤 Colocando GPU NVIDIA em modo economia..."

# Definir power save mode
nvidia-smi -pm 0 2>/dev/null

# Colocar em runtime PM
echo auto > /sys/bus/pci/devices/0000:01:00.0/power/control 2>/dev/null

echo "✅ GPU em modo economia de energia"
echo "Para reativar: gpu-on"
EOF

    # Script de status
    doas tee /usr/local/bin/gpu-status.sh << 'EOF'
#!/bin/bash
# Status da GPU

echo "=== Status GPU NVIDIA ==="

# Power state
GPU_POWER=$(cat /sys/bus/pci/devices/0000:01:00.0/power/control 2>/dev/null)
echo "Power Control: $GPU_POWER"

# NVIDIA info (se ativa)
if nvidia-smi &>/dev/null; then
    echo "Status: ATIVA"
    nvidia-smi --query-gpu=name,power.draw,temperature.gpu,utilization.gpu --format=csv,noheader
else
    echo "Status: INATIVA/ECONOMIA"
fi

# Processos usando GPU
echo ""
echo "Processos usando GPU:"
nvidia-smi pmon -c 1 2>/dev/null || echo "Nenhum processo detectado"
EOF

    # Tornar executáveis
    doas chmod +x /usr/local/bin/gpu-{on,off,status}.sh
}
