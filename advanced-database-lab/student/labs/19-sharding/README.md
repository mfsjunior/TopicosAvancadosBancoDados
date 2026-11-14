# Laboratório 18: Sharding e Bancos Distribuídos

## Objetivo
Explorar o limite vertical das máquinas (quando adicionar Memória RAM e CPU não resolve mais o problema) e entender a Distribuição Horizontal (Sharding).

## Conceitos
- Vertical Scaling (Scale Up) vs Horizontal Scaling (Scale Out)
- Sharding / Particionamento Distribuído
- Shard Key
- CAP Theorem (Consistency, Availability, Partition Tolerance)

## Problema
O LinkedIn (a nossa inspiração) tem Petabytes de dados de perfis de pessoas pelo mundo inteiro.
Nenhum disco rígido único e nenhum processador do mundo consegue rodar o banco de dados inteiro em uma máquina (ou Replica Set simples). Eles precisaram fatiar (Shard) a collection gigantesca de usuários.

## Procedimento (Nível 1 - Execução)

O MongoDB divide a coleção em fatias ("Chunks") através de uma Chave Mestre escolhida por você (Shard Key).

No mongosh, o comando para ligar o Sharding num banco e numa coleção seria:
```javascript
// (Simulação lógica, exige setup de Routers (Mongos) e Config Servers)
sh.enableSharding("adv_curriculos")

// Decidindo sharding da tabela de currículos pela chave "estado"
sh.shardCollection("adv_curriculos.curriculos", { estado: "hashed" })
```
O Router (Mongos) distribuirá os candidatos que moram em São Paulo para o Servidor A, os do Rio de Janeiro pro B, os de Minas Gerais pro C.

## Investigação (Nível 2)
O Teorema CAP afirma que na presença de tolerância ao particionamento de rede (P), sistemas distribuídos precisam escolher entre Consistência Total (C) e Disponibilidade Total (A).
Como um sistema grande lida com a Consistência Eventual? Se um candidato curte uma vaga em SP (Servidor A) e o recrutador está conectado no nó de réplica distribuído globalmente em NY, tudo bem o "like" aparecer 2 segundos depois?

## Desafio (Nível 3) - Escolha da Shard Key
Uma startup fatiou seu sistema de log de auditoria global no MongoDB. Para a Shard Key, eles escolheram a coluna `data_hora_log` (Timestamp) que cresce ordenadamente a cada milissegundo, achando que isso deixaria as buscas super rápidas.
**Desastre na produção:** Um único servidor do Shard (o Servidor C, responsável pelas datas mais recentes) derreteu de carga (CPU em 100%), enquanto os Servidores A e B estavam dormindo em 0% de uso de CPU.
Analise: Como a escolha de uma Shard Key Monotonicamente Crescente (Datas ou Sequenciais) gera o temido "Hotspot" de Inserção na Arquitetura Distribuída? Qual seria a solução matemática correta?

---
## Perguntas
- A query `db.curriculos.find({ nome: "João" })` executada em um banco Shardado (com Shard Key em `estado`) será enviada para qual servidor? (Pesquise sobre "Scatter and Gather").
- Em quais condições o PostgreSQL tradicional supera imensamente arquiteturas NoSQL Shardadas?
