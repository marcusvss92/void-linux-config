# /usr/local/bin/laptop-power-setup.sh
#!/bin/bash

# Configurações adicionais de economia para laptop gaming

# CPU governor
echo 'GOVERNOR="powersave"' | doas tee /etc/default/cpufrequtils

# TLP para power management avançado
doas xbps-install -S tlp
echo 'START_CHARGE_THRESH_BAT0=40' | doas tee -a /etc/tlp.conf
echo 'STOP_CHARGE_THRESH_BAT0=80' | doas tee -a /etc/tlp.conf

# Auto-suspend após 30min sem uso
doas tee /etc/systemd/logind.conf.d/power.conf << 'EOF'
[Login]
IdleAction=suspend
IdleActionSec=30min
EOF

echo "✅ Configuração de economia de energia aplicada"
