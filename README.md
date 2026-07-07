 Projeto 2 — Servidor Linux na Nuvem com Automação

> Provisionamento de servidor web em menos de 3 minutos via script bash, sem cliques manuais no console após o launch.

**Status:** Concluído · **Cloud:** AWS · **Custo:** $0 · **Automação:** Bash

## Arquitetura

```
[Internet]
    ↓ porta 80 (HTTP) - aberta
    ↓ porta 22 (SSH)  - só meu IP
[Security Group]
    ↓
[EC2 Ubuntu 24.04 - t2.micro]
    ├── Nginx (servidor web)
    ├── HTML customizada
    └── systemd override (auto-restart on-failure)
```

## Tecnologias

- **AWS EC2** — instância Ubuntu 24.04 t2.micro/t3.micro
- **Nginx** — servidor web
- **Bash** — script de automação (`setup.sh`)
- **systemd** — gerenciamento de serviços e auto-restart via override (`Restart=on-failure`)

## O que o script faz

- Atualiza pacotes do sistema (`apt update && apt upgrade`)
- Instala Nginx
- Habilita serviço pra iniciar no boot (`systemctl enable nginx`)
- Cria página HTML customizada em `/var/www/html/`
- Configura auto-restart do Nginx via systemd override (`Restart=on-failure`, `RestartSec=5s`)
- Loga todas as operações em `/var/log/setup.log`

### Decisão: cron vs systemd

A primeira versão usava um cron job de healthcheck a cada 5 minutos. O cron reage em até 5 minutos e religa o serviço mesmo quando foi parado de propósito (um `systemctl stop nginx` intencional era desfeito no ciclo seguinte). O systemd override com `Restart=on-failure` reage em segundos e respeita o stop intencional: só religa quando o processo termina com falha. Por isso a troca.

## Como reproduzir

**Passos no console AWS:**

1. Criar key pair `key-projeto-2` no console EC2
2. Lançar instância Ubuntu 24.04 com Security Group:
   - SSH (22) — apenas meu IP
   - HTTP (80) — `0.0.0.0/0`

**Passos no terminal:**

```bash
# Copiar script pra dentro da instância
scp -i ~/.ssh/key-projeto-2.pem setup.sh ubuntu@IP:~/

# Conectar via SSH
ssh -i ~/.ssh/key-projeto-2.pem ubuntu@IP

# Executar (já dentro da instância)
sudo bash setup.sh
```

**Validar:** acessar `http://IP-publico` no navegador.

## Problemas que enfrentei

**Tentei rodar o script no Windows local.** O `setup.sh` usa comandos Linux (`apt`, `systemctl`) que não existem no Git Bash. Solução: copiar pra dentro da instância via `scp` e executar com `sudo bash` lá. Aprendi a diferença entre scripts de infra (rodam no meu PC, gerenciam recursos da nuvem) e scripts de configuração de servidor (rodam dentro da máquina, configuram o sistema).

**Site não abria pelo navegador apesar do Nginx rodando.** Erro `ERR_CONNECTION_TIMED_OUT`. Causa: Security Group sem porta 80 aberta. Solução: adicionar regra Inbound HTTP com source `0.0.0.0/0`. Lição: em cloud, serviço rodando não significa serviço acessível — sempre verificar a rede primeiro.

## Custo

**$0,00 na execução original** — t2.micro dentro do Free Tier (750h/mês). Importante: stop/terminate da instância quando não em uso pra não consumir horas desnecessariamente.

Nota: a elegibilidade de free tier de EC2/RDS desta conta expirou (reestruturação do Free Tier da AWS pós julho/2025). Hoje, a mesma instância gera custo por hora — o valor $0 vale apenas para o contexto da execução original.

## Próximas iterações

- Reescrever toda a infra em Terraform (Projeto 3 do portfólio) — concluído: [aws-vpc-3tier-terraform](https://github.com/lucaspenhoela-personal/aws-vpc-3tier-terraform)
- Adicionar HTTPS via Let's Encrypt + Certbot
- Configurar fail2ban pra proteção SSH
- Migrar pra User Data (script rodando no boot, sem `scp`+`ssh`)

---

**Lucas Ribeiro Penhoela** · [LinkedIn](https://www.linkedin.com/in/lucas-ribeiro-penhoela-a4b429258) · [GitHub](https://github.com/lucaspenhoela-personal)
