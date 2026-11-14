# Laboratório 19: Segurança, Auditoria e Administração

## Objetivo
Implementar princípios de *Least Privilege* (Menor Privilégio), isolar perfis de usuários e aprender mecanismos de backup/restore para salvar a sua empresa no dia de um ataque cibernético.

## Conceitos
- Autenticação e Autorização (GRANT / REVOKE)
- Row-Level Security (RLS) no PostgreSQL
- Backups Lógicos (pg_dump / mongodump) vs Físicos
- SQL Injection

## Procedimento (Nível 1 - Execução)

Vamos criar um usuário de Apenas Leitura (Read-Only) para a equipe de Ciência de Dados no PostgreSQL.

No terminal do Postgres (`psql -U adv_user -d adv_recruitment`):
```sql
CREATE ROLE cientista_dados WITH LOGIN PASSWORD 'senha_forte';
GRANT CONNECT ON DATABASE adv_recruitment TO cientista_dados;
GRANT USAGE ON SCHEMA public TO cientista_dados;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO cientista_dados;
```

Teste a segurança, abrindo um novo psql com esse usuário:
```bash
docker exec -it adv_db_postgres psql -U cientista_dados -d adv_recruitment
```
Tente deletar uma vaga. O Postgres deve cuspir um erro de "Permission Denied".

## Investigação (Nível 2)
Cibercriminosos atacaram o sistema à 1:00 da manhã. Por sorte, às 00:00 um job do Cron executou o seguinte comando no servidor:
```bash
docker exec -t adv_db_postgres pg_dump -U adv_user -F c -d adv_recruitment > /var/backups/adv_recruitment_bkp.dump
```
Pesquise e descreva a diferença brutal de velocidade (e interrupção do sistema) entre um Backup Lógico (como o comando acima) e um Backup Físico (Filesystem Snapshots / WAL Archiving / pg_basebackup) para bancos gigantescos de 5 Terabytes.

## Desafio (Nível 3) - Row Level Security (RLS)
Sua plataforma possui dezenas de empresas conectadas simultaneamente.
O desenvolvedor backend esqueceu de colocar `WHERE empresa_id = X` na tela de relatórios financeiros. 
A "Empresa A" conseguiu visualizar os salários confidenciais e candidatos da "Empresa B". E pior, a LGPD (Lei de Proteção de Dados) vai multar sua empresa pesadamente por vazamento de currículos.

O Banco de Dados tem o poder de blindar contra falhas do Backend usando **Row Level Security (RLS)** no PostgreSQL.
Sua missão: 
1. Habilite o RLS na tabela `vaga`.
2. Crie uma Policy (Política) afirmando que o usuário conectado no banco só pode enxergar as vagas cujo `empresa_id` coincida com a dele (dica: usando `current_user` ou uma variável de sessão).
Escreva a sintaxe SQL necessária para isso.

---
## Perguntas
- O que é o famigerado ataque de **SQL Injection** e por que usar Prepared Statements (Queries parametrizadas no Backend) ou ORMs resolve definitivamente esse problema, mesmo sem mudar nada na configuração do Banco?
