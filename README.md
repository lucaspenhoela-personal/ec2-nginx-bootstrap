# Projeto 2 — Servidor Linux na Nuvem com Automação

Servidor Nginx provisionado automaticamente em EC2 via script bash.

![Status](https://img.shields.io/badge/status-conclu%C3%ADdo-success)
![Cloud](https://img.shields.io/badge/cloud-AWS-orange)
![Cost](https://img.shields.io/badge/custo-%240-blue)

## Arquitetura

## Tecnologias

- **AWS EC2** — instância Ubuntu 24.04 t2.micro/t3.micro
- **Nginx** — servidor web
- **Bash** — script de automação (`setup.sh`)
- **Cron + systemd** — healthcheck e gerenciamento de serviços

## Como reproduzir

1. Criar key pair `key-projeto-2` no console EC2
2. Lançar instância Ubuntu 24.04 com Security Group:
   - SSH (22) — apenas meu IP
   - HTTP (80) — `0.0.0.0/0`
3. Copiar e executar o script:
```bash
   scp -i ~/.ssh/key-projeto-2.pem setup.sh ubuntu@IP:~/
   ssh -i ~/.ssh/key-projeto-2.pem ubuntu@IP
   sudo bash setup.sh
```
4. Acessar `http://IP-publico` no navegador

## O script faz

- Atualiza pacotes do sistema (`apt update && apt upgrade`)
- Instala Nginx
- Habilita serviço no boot (`systemctl enable nginx`)
- Cria página HTML customizada
- Configura cron de healthcheck (verifica Nginx a cada 5 min)
- Loga operações em `/var/log/setup.log`

## Problemas que enfrentei

**Tentei rodar o script no Windows local.** O `setup.sh` usa comandos Linux (`apt`, `systemctl`) que não existem no Git Bash. Solução: copiar pra dentro da instância via `scp` e executar com `sudo bash` lá. Aprendi a diferença entre scripts de infra (rodam no PC) e scripts de configuração de servidor (rodam dentro da máquina).

**Site não abria pelo navegador apesar do Nginx rodando.** Erro `ERR_CONNECTION_TIMED_OUT`. Causa: Security Group sem porta 80 aberta. Solução: adicionar regra Inbound HTTP com source `0.0.0.0/0`. Lição: em cloud, serviço rodando não significa serviço acessível — sempre verificar firewall.

## Custo

**$0,00** — t2.micro dentro do Free Tier (750h/mês). Importante: stop/terminate da instância quando não em uso.

## Próximas iterações

- Reescrever toda a infra em Terraform (Projeto 3)
- Adicionar HTTPS via Let's Encrypt + Certbot
- Configurar fail2ban pra proteção SSH

---

**Lucas Ribeiro Penhoela** · [LinkedIn](https://www.linkedin.com/in/lucas-ribeiro-penhoela-a4b429258) · [GitHub](https://github.com/lucaspenhoela-personal)
