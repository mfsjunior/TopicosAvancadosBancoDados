# Laboratório 02: PostgreSQL Internals (Por dentro do Banco)

## Objetivo
Entender como o PostgreSQL armazena, acessa e processa os dados no disco e em memória. Antes de otimizar consultas, você deve compreender as peças fundamentais do motor relacional.

## Conceitos
- Processos do PostgreSQL (Postmaster, Background Writer, WAL Writer)
- Arquitetura de Memória (Shared Buffers, Work Mem)
- Armazenamento em Disco (Páginas, Tuplas, Filenode)
- Write-Ahead Logging (WAL)
- Catálogo de Sistemas (`pg_class`, `pg_stat_activity`)

## Procedimento (Nível 1 - Execução)

1. Conecte-se ao banco:
   ```bash
   docker exec -it adv_db_postgres psql -U adv_user -d adv_recruitment
   ```
2. Vamos visualizar informações do catálogo sobre a nossa tabela `candidatura`:
   ```sql
   SELECT relname, relpages, reltuples 
   FROM pg_class 
   WHERE relname = 'candidatura';
   ```
   *(Nota: `relpages` mostra quantas páginas de disco a tabela ocupa).*

3. Qual é o arquivo físico dessa tabela no servidor?
   ```sql
   SELECT pg_relation_filepath('candidatura');
   ```

## Investigação (Nível 2)

O tamanho das tabelas afeta diretamente a performance, pois páginas precisam subir para a memória (Shared Buffers). 
Use as funções `pg_size_pretty()` e `pg_total_relation_size()` para descobrir:
1. Qual é a maior tabela do nosso sistema de recrutamento atualmente?
2. Quanto do tamanho total de `candidatura` corresponde a dados e quanto corresponde a índices?

## Desafio (Nível 3)

**Modificando a Geração de Dados para sobrecarregar a Memória**
Acesse o banco de dados e gere a massa de dados média ou grande:
```sql
CALL generate_data('medium');
```
*Atenção: Isso truncará as tabelas e inserirá milhares de novos registros.*
Após a execução, descubra onde ficam os **Shared Buffers** do PostgreSQL investigando os parâmetros do sistema com o comando `SHOW shared_buffers;`. 
- Esse tamanho padrão (normalmente 128MB no Docker) seria suficiente se a tabela `candidato` tivesse 5GB e nós rodássemos um `SELECT * FROM candidato`? Por que o conceito de WAL é importante para garantir que modificações em memória não sejam perdidas caso o container pare abruptamente?

---
## Perguntas
- Por que o PostgreSQL usa páginas (normalmente de 8KB) em vez de gravar linha por linha diretamente de forma isolada?
- Qual processo do PostgreSQL é responsável por garantir que uma transação recém-confirmada não seja perdida em uma falha de energia?
