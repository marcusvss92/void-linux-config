#!/bin/bash
# /usr/local/bin/get-resume-offset.sh

SWAPFILE_PATH="/swapfile"  # Ajuste conforme seu swapfile

# Método 1: Para ext4/xfs
get_resume_offset_ext4() {
    local swapfile="$1"
    
    # Usar filefrag para obter offset físico
    local offset=$(filefrag -v "$swapfile" | awk 'NR==4{print $4}' | sed 's/\.//')
    echo "$offset"
}

# Método 2: Para Btrfs (mais complexo)
get_resume_offset_btrfs() {
    local swapfile="$1"
    
    echo "⚠️  Btrfs swapfile requer ferramenta especial..."
    
    # Verificar se btrfs_map_physical está disponível
    if ! command -v btrfs_map_physical &>/dev/null; then
        echo "❌ btrfs_map_physical não encontrado!"
        echo "Instale via: https://github.com/osandov/osandov-linux/tree/master/scripts"
        return 1
    fi
    
    # Calcular offset para Btrfs
    local pagesize=$(getconf PAGESIZE)
    local offset_bytes=$(btrfs_map_physical "$swapfile" | head -2 | tail -1 | awk '{print $9}')
    local offset_pages=$((offset_bytes / pagesize))
    
    echo "$offset_pages"
}

# Detectar filesystem
FILESYSTEM=$(df --output=fstype "$SWAPFILE_PATH" | tail -1)

echo "=== Calculando RESUME_OFFSET ==="
echo "Swapfile: $SWAPFILE_PATH"
echo "Filesystem: $FILESYSTEM"

case "$FILESYSTEM" in
    "ext4"|"xfs")
        OFFSET=$(get_resume_offset_ext4 "$SWAPFILE_PATH")
        ;;
    "btrfs")
        OFFSET=$(get_resume_offset_btrfs "$SWAPFILE_PATH")
        ;;
    *)
        echo "❌ Filesystem não suportado: $FILESYSTEM"
        exit 1
        ;;
esac

echo "RESUME_OFFSET: $OFFSET"

# Salvar para uso posterior
echo "RESUME_OFFSET=$OFFSET" > /etc/resume-offset.conf
echo "✅ Offset salvo em /etc/resume-offset.conf"
