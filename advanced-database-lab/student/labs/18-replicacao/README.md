# Laboratório 17: Arquitetura - Replicação e Alta Disponibilidade

## Objetivo
Entender como Bancos de Dados sobrevivem à queima de Servidores Físicos e garantem Alta Disponibilidade (High Availability) e Balanceamento de Leitura (Read Scaling).

## Conceitos
- Replica Set (MongoDB) / Streaming Replication (Postgres)
- Nós Primary (Master) e Secondary (Slaves)
- Oplog / WAL (Log de Operações)
- Eleição (Election) e Quórum

## Procedimento (Nível 1 - Execução)

Vamos conceituar a Replicação com base no MongoDB. Em uma arquitetura real, você configuraria pelo menos **3 servidores** no Docker (Mongo-Primary, Mongo-Secondary1, Mongo-Secondary2). 

Toda escrita vai obrigatoriamente para o Primário. Ele grava no disco e joga a ação no seu arquivo de Log (`oplog.rs`). Os secundários "sugam" esse arquivo de log e repetem os passos nas suas próprias máquinas.

No Mongosh, conecte-se ao nó primário e veja o status do cluster (Nota: nosso docker-compose está como Standalone, este é um exercício teórico/simulado):
```javascript
// Comando que usariamos em cluster real
rs.status()
```

Ele retornaria o status de saúde e *uptime* de cada nó.

## Investigação (Nível 2)

Se você tem um site bombando com 1 milhão de acessos por segundo pesquisando vagas (SELECT), o servidor Primário pode não aguentar. 
Nas arquiteturas distribuídas, ativamos as Leituras nos Secundários (Read Preferences).
O MongoDB permite que a aplicação especifique: `readPreference: "secondaryPreferred"`.
Qual é o grande perigo de ler do Secundário? Pense na Replicação Assíncrona. 

## Desafio (Nível 3)
Um raio caiu no Data Center de São Paulo. O servidor Primário pegou fogo.
Como um cluster configurado em número ímpar (3 nós, por exemplo) com algoritmo de consenso resolve esse problema automaticamente sem que a aplicação e o usuário final percebam que o banco "caiu"? Descreva detalhadamente o processo de Eleição, Heartbeats e o que acontece quando o antigo primário volta da manutenção horas depois.

---
## Perguntas
- Por que ter APENAS DOIS servidores (1 Primário e 1 Secundário) em configurações de Alta Disponibilidade (Replica Sets) é uma falha gravíssima de arquitetura quando ocorre a "Queda do Primário"? (Dica: Pense na palavra "Quórum" de votação).
