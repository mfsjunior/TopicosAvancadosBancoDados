# Laboratório 16: Transações e Consistência no MongoDB

## Objetivo
Desmistificar o mito de que "NoSQL não suporta transações ACID". Aprender os limites, casos de uso e custos de Transações Multi-documento no MongoDB 4.0+.

## Conceitos
- ACID no MongoDB
- Atualizações Atômicas a nível de documento
- Multi-document Transactions (Sessões)
- Replica Sets (Obrigatório para transações)

## Problema
Em um fluxo de contratação, o sistema precisa:
1. Mudar o status do candidato para "CONTRATADO" no MongoDB.
2. Adicionar o "Bônus de Sucesso" ao saldo do Recrutador em outro documento MongoDB.
Se a aplicação falhar no meio do caminho (energia cai), o candidato consta como contratado mas o recrutador fica sem o bônus, quebrando a consistência do negócio.

## Procedimento (Nível 1 - Execução)

O MongoDB garante atomicidade por padrão **somente para um único documento**. Se as duas informações (Candidato e Saldo do Recrutador) estivessem dentro do mesmo BSON, um único UPDATE resolveria tudo atomicamente.

Mas como estão em documentos separados, precisamos de Transações Globais, inauguradas na versão 4.0.

No terminal Mongosh, simule uma transação multi-documento:
```javascript
// ATENÇÃO: Isso só funcionará se o MongoDB estiver em modo Replica Set!
// Em instâncias Standalone (default do docker sem configs extras), vai gerar erro.

const session = db.getMongo().startSession();
session.startTransaction();

try {
   const currCollection = session.getDatabase("adv_curriculos").curriculos;
   const recrCollection = session.getDatabase("adv_curriculos").recrutadores;

   currCollection.updateOne({ _id: 1 }, { $set: { status: "CONTRATADO" } });
   recrCollection.updateOne({ _id: 99 }, { $inc: { saldo_bonus: 1000 } });

   session.commitTransaction();
   print("Sucesso! Tudo comitado!");
} catch (error) {
   session.abortTransaction();
   print("Erro detectado. Rollback realizado!");
} finally {
   session.endSession();
}
```

## Investigação (Nível 2)
Tente rodar o código acima no nosso MongoDB dockerizado atual. Ele explodirá com um erro parecido com: *"Transaction numbers are only allowed on a replica set member"*.
Por que o MongoDB arquiteturalmente recusa transações em nós avulsos (Standalone) e exige que exista Replicação configurada (Replica Set) com um Oplog (Operations Log)? O que isso nos diz sobre como ele lida com o Controle de Concorrência?

## Desafio (Nível 3)
Você como Arquiteto de Software, depara-se com um sistema financeiro altamente transacional. O Gerente sugere migrar do PostgreSQL para o MongoDB usando essas novas "Transações Multi-Documento" do Mongo para ganhar velocidade.
Pesquise as restrições e custos de performance das transações do MongoDB (e como elas impactam o WiredTiger Storage Engine) e justifique por que essa migração, baseada apenas no desejo de fazer dezenas de tabelas cruzadas em transação, é um péssimo design.

---
## Perguntas
- Se os dados acessados juntos devem ser armazenados juntos (Embedding), qual é o impacto disso na necessidade real de usar Transações ACID multi-documentos no Mongo?
- Por que as transações no MongoDB devem durar menos de 60 segundos (padrão `transactionLifetimeLimitSeconds`)? O que acontece com a memória do nó primário se ela ficar pendurada?
