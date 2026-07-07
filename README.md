# Bootstrap automatizado de servidor Nginx em EC2

> Provisionamento de servidor web em menos de 3 minutos via script bash, sem cliques manuais no console após o launch.

**Status:** Concluído · **Cloud:** AWS · **Automação:** Bash

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
- **Bash** — scripts de automação (`setup.sh` e `user-data.sh`)
- **systemd** — gerenciamento de serviço e auto-restart

## O que o script faz

- Atualiza pacotes do sistema (`apt-get`, modo não interativo)
- Instala Nginx e habilita pra iniciar no boot (`systemctl enable nginx`)
- Configura auto-restart via systemd override (`Restart=on-failure`)
- Cria página HTML customizada em `/var/www/html/`
- Descobre o IP público via IMDSv2 (metadata com token, sem serviço externo)
- Loga todas as operações em `/var/log/setup.log`

O script é idempotente: rodar duas vezes não quebra nada — apt, systemctl e a
sobrescrita dos arquivos de configuração são seguros pra reexecução.

## Decisão: cron vs systemd pro healthcheck

A primeira versão usava um cron job checando o Nginx a cada 5 minutos e
religando se tivesse caído. Troquei por um override do systemd
(`Restart=on-failure`, `RestartSec=5s`). O trade-off: o cron reage em até 5
minutos e religa até um serviço parado de propósito com `systemctl stop`; o
systemd reage em segundos a um crash e respeita a parada intencional do
operador. Menos peça móvel: sem script extra, sem crontab.

## Como reproduzir

### Opção A — script via SSH

**Passos no console AWS:**

1. Criar key pair no console EC2
2. Lançar instância Ubuntu 24.04 com Security Group:
   - SSH (22) — apenas meu IP
   - HTTP (80) — `0.0.0.0/0`

**Passos no terminal:**

```bash
scp -i ~/.ssh/sua-chave.pem setup.sh ubuntu@IP:~/
ssh -i ~/.ssh/sua-chave.pem ubuntu@IP
sudo bash setup.sh
```

### Opção B — zero-touch via User Data

Colar o conteúdo de `user-data.sh` no campo User Data ao lançar a instância.
O script roda como root no primeiro boot, sem `scp` nem `ssh`. A saída
completa fica em `/var/log/cloud-init-output.log`.

Atenção: subir instância fora do free tier gera custo. Nesta conta a
elegibilidade expirou, então a opção fica documentada, não executada.

**Validar:** acessar `http://IP-publico` no navegador.

## Problemas que enfrentei

**Tentei rodar o script no Windows local.** O `setup.sh` usa comandos Linux
(`apt`, `systemctl`) que não existem no Git Bash. Solução: copiar pra dentro
da instância via `scp` e executar com `sudo bash` lá. Aprendi a diferença
entre scripts de infra (rodam no meu PC, gerenciam recursos da nuvem) e
scripts de configuração de servidor (rodam dentro da máquina, configuram o
sistema).

**Site não abria pelo navegador apesar do Nginx rodando.** Erro
`ERR_CONNECTION_TIMED_OUT`. Causa: Security Group sem porta 80 aberta.
Solução: adicionar regra Inbound HTTP com source `0.0.0.0/0`. Lição: em
cloud, serviço rodando não significa serviço acessível — sempre verificar a
rede primeiro.

## Custo

**$0,00 na execução original** — t2.micro dentro do Free Tier vigente à
época (750h/mês). A elegibilidade de free tier de EC2/RDS desta conta
expirou na reestruturação pós julho/2025: hoje a mesma instância gera custo.
Por isso a infraestrutura é tratada como descartável.

## Descarte da infraestrutura

Nada deste projeto permanece rodando. Ao final da validação:

1. Terminate da instância EC2
2. Delete do Security Group criado pro teste
3. Delete do key pair no EC2 e do `.pem` local

Custo recorrente: zero.

## Próximas iterações

- Reescrever toda a infra em Terraform — concluído em
  [aws-vpc-3tier-terraform](https://github.com/lucaspenhoela-personal/aws-vpc-3tier-terraform)
- Migrar pra User Data (script rodando no boot, sem `scp`+`ssh`) — concluído
  (`user-data.sh`)
- Adicionar HTTPS via Let's Encrypt + Certbot
- Configurar fail2ban pra proteção SSH

---

**Lucas Ribeiro Penhoela** · [LinkedIn](https://www.linkedin.com/in/lucas-ribeiro-penhoela-a4b429258) · [GitHub](https://github.com/lucaspenhoela-personal)
