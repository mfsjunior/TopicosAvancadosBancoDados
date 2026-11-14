# Laboratório 01: Ambiente e Conexões

## Objetivo
O objetivo deste primeiro laboratório é garantir que você compreenda e saiba operar a infraestrutura base de bancos de dados modernos, utilizando contêineres Docker, persistência de dados em volumes e comunicação via rede interna.

## Conceitos
- Contêineres vs Máquinas Virtuais
- Volumes e persistência de dados
- Redes Docker
- Clientes de Conexão (psql, mongosh, DBeaver, pgAdmin)

## Pré-requisitos
- Docker e Docker Compose instalados.
- Ter o repositório clonado em sua máquina local.

## Problema
Sua equipe acaba de receber a incumbência de modernizar a infraestrutura de dados de uma antiga agência de recrutamento. A empresa possui dados estruturados (relacionais) e planeja introduzir análise de currículos (dados semiestruturados). Vocês decidiram iniciar com **PostgreSQL** e **MongoDB**. 
Sua tarefa imediata é subir esse ambiente na sua máquina de desenvolvimento.

## Procedimento (Nível 1 - Execução)

1. No terminal, acesse a pasta raiz do laboratório.
2. Copie o arquivo `.env.example` para `.env`.
3. Inicie a infraestrutura:
   ```bash
   ./scripts/start.sh
   ```
4. Verifique se os containers estão rodando:
   ```bash
   docker ps
   ```
5. Conecte-se ao PostgreSQL usando a CLI:
   ```bash
   docker exec -it adv_db_postgres psql -U adv_user -d adv_recruitment
   ```
6. Dentro do banco, liste as tabelas criadas automaticamente:
   ```sql
   \dt
   ```

## Investigação (Nível 2)

1. Tente encontrar os dados inseridos nas tabelas `empresa` e `candidato`. Quantas linhas existem na configuração `small`?
2. Saia do PostgreSQL (`\q`) e pare os containers com o script `./scripts/stop.sh`. 
3. Reinicie os containers e verifique se os dados ainda estão lá.

## Desafio (Nível 3)

**Como provar que os dados sobrevivem mesmo se o container for destruído?**
Destrua a instância do container manualmente (`docker rm -f adv_db_postgres`). Depois rode `./scripts/start.sh` novamente. Explique tecnicamente como e por que o PostgreSQL conseguiu recuperar os dados das empresas e candidatos criados anteriormente.

---
## Perguntas
- Se você apagar o diretório listado como volume em `docker-compose.yml`, o que acontece com seus dados?
- Por que utilizamos redes virtuais (`adv_db_net`) no Docker ao invés de deixarmos as portas abertas globalmente sem restrições?
