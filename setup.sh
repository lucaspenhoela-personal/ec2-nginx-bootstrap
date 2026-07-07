#!/bin/bash
# ====================================================================
# setup.sh - Provisiona servidor web Nginx no Ubuntu
# Autor: Lucas Ribeiro Penhoela
# Uso: sudo bash setup.sh
# ====================================================================

set -e  # para o script se qualquer comando falhar

LOG_FILE="/var/log/setup.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "=== Iniciando setup do servidor web ==="

# 1. Atualizar sistema
log "Atualizando lista de pacotes..."
apt update -y >> "$LOG_FILE" 2>&1

log "Atualizando pacotes instalados..."
apt upgrade -y >> "$LOG_FILE" 2>&1

# 2. Instalar Nginx
log "Instalando Nginx..."
apt install -y nginx >> "$LOG_FILE" 2>&1

# 3. Garantir que Nginx está habilitado e rodando
log "Habilitando Nginx pra iniciar no boot..."
systemctl enable nginx >> "$LOG_FILE" 2>&1
systemctl start nginx >> "$LOG_FILE" 2>&1

log "Configurando auto-restart via systemd override..."
mkdir -p /etc/systemd/system/nginx.service.d
cat > /etc/systemd/system/nginx.service.d/override.conf << 'OVERRIDE'
[Service]
Restart=on-failure
RestartSec=5s
OVERRIDE
systemctl daemon-reload

# 4. Criar página customizada
log "Criando página HTML customizada..."
cat > /var/www/html/index.html << 'HTML'
<!DOCTYPE html>
<html lang="pt-BR">
<head>
    <meta charset="UTF-8">
    <title>Servidor Provisionado Automaticamente</title>
    <style>
        body { font-family: sans-serif; padding: 40px; background: #232f3e; color: white; }
        h1 { color: #ff9900; }
        code { background: #444; padding: 4px 8px; border-radius: 4px; }
    </style>
</head>
<body>
    <h1>Servidor provisionado automaticamente!</h1>
    <p>Este servidor foi configurado por um script bash.</p>
    <p>Instância: <code id="hostname"></code></p>
    <script>
        document.getElementById('hostname').textContent = window.location.hostname;
    </script>
</body>
</html>
HTML

log "=== Setup concluído com sucesso ==="
TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" \
    -H "X-aws-ec2-metadata-token-ttl-seconds: 60")
PUBLIC_IP=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" \
    http://169.254.169.254/latest/meta-data/public-ipv4)
log "Acesse: http://$PUBLIC_IP"