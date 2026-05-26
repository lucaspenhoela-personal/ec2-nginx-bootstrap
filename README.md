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
    └── Cron job (healthcheck a cada 5min)
```

## Tecnologias

- **AWS EC2** — instância Ubuntu 24.04 t2.micro/t3.micro
- **Nginx** — servidor web
- **Bash** — script de automação (`setup.sh`)
- **Cron + systemd** — healthcheck e gerenciamento de serviços

## O que o script faz

- Atualiza pacotes do sistema (`apt update && apt upgrade`)
- Instala Nginx
- Habilita serviço pra iniciar no boot (`systemctl enable nginx`)
- Cria página HTML customizada em `/var/www/html/`
- Configura cron de healthcheck (verifica Nginx a cada 5 min, reinicia se cair)
- Loga todas as operações em `/var/log/setup.log`

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

**$0,00** — t2.micro dentro do Free Tier (750h/mês). Importante: stop/terminate da instância quando não em uso pra não consumir horas desnecessariamente.

## Próximas iterações

- Reescrever toda a infra em Terraform (Projeto 3 do portfólio)
- Adicionar HTTPS via Let's Encrypt + Certbot
- Configurar fail2ban pra proteção SSH
- Migrar pra User Data (script rodando no boot, sem `scp`+`ssh`)

---

**Lucas Ribeiro Penhoela** · [LinkedIn](https://www.linkedin.com/in/lucas-ribeiro-penhoela-a4b429258) · [GitHub](https://github.com/lucaspenhoela-personal)
