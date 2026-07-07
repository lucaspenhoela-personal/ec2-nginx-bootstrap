#!/bin/bash
# ====================================================================
# setup.sh - Provisiona servidor web Nginx no Ubuntu
# Autor: Lucas Ribeiro Penhoela
# Uso: sudo bash setup.sh
# ====================================================================

set -euo pipefail  # para em erro, variavel indefinida ou falha em pipe
export DEBIAN_FRONTEND=noninteractive  # evita prompts interativos do apt

LOG_FILE="/var/log/setup.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "=== Iniciando setup do servidor web ==="

# 1. Atualizar sistema
log "Atualizando lista de pacotes..."
apt-get update -y >> "$LOG_FILE" 2>&1

log "Atualizando pacotes instalados..."
apt-get upgrade -y >> "$LOG_FILE" 2>&1

# 2. Instalar Nginx
log "Instalando Nginx..."
apt-get install -y nginx >> "$LOG_FILE" 2>&1

# 3. Garantir que Nginx esta habilitado e rodando
log "Habilitando Nginx pra iniciar no boot..."
systemctl enable nginx >> "$LOG_FILE" 2>&1
systemctl start nginx >> "$LOG_FILE" 2>&1

# 4. Auto-restart via systemd (substitui o healthcheck por cron)
# Restart=on-failure reage em segundos a crash do processo e respeita
# um "systemctl stop" intencional do operador.
log "Configurando auto-restart do Nginx via systemd override..."
mkdir -p /etc/systemd/system/nginx.service.d
cat > /etc/systemd/system/nginx.service.d/override.conf << 'OVERRIDE'
[Service]
Restart=on-failure
RestartSec=5s
OVERRIDE
systemctl daemon-reload

# 5. Criar pagina customizada
log "Criando pagina HTML customizada..."
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
    <p>Instancia: <code id="hostname"></code></p>
    <script>
        document.getElementById('hostname').textContent = window.location.hostname;
    </script>
</body>
</html>
HTML

# 6. Obter IP publico via IMDSv2 (sem dependencia de servico externo)
log "Consultando IP publico via IMDSv2..."
TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" \
    -H "X-aws-ec2-metadata-token-ttl-seconds: 60")
PUBLIC_IP=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" \
    http://169.254.169.254/latest/meta-data/public-ipv4)

log "=== Setup concluido com sucesso ==="
log "Acesse: http://$PUBLIC_IP"
