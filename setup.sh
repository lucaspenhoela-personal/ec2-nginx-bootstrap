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

# 5. Configurar healthcheck via cron
log "Configurando healthcheck do Nginx via cron..."
cat > /usr/local/bin/nginx-healthcheck.sh << 'CRON'
#!/bin/bash
if ! systemctl is-active --quiet nginx; then
    systemctl start nginx
    echo "[$(date)] Nginx estava parado. Reiniciado." >> /var/log/nginx-healthcheck.log
fi
CRON
chmod +x /usr/local/bin/nginx-healthcheck.sh

# Adiciona cron job (a cada 5 minutos) se ainda não existir
(crontab -l 2>/dev/null | grep -q nginx-healthcheck.sh) || \
    (crontab -l 2>/dev/null; echo "*/5 * * * * /usr/local/bin/nginx-healthcheck.sh") | crontab -

log "=== Setup concluído com sucesso ==="
log "Acesse: http://$(curl -s ifconfig.me)"