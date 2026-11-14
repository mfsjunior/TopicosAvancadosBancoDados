# Laboratório 20: Projeto Prático Integrador

## O Desafio Final
Chegamos ao fim da jornada disciplinar. Você vivenciou os problemas da Plataforma de Recrutamento desde a criação ingênua e lenta do modelo relacional, passou pela otimização severa, locks concorrentes e expandiu a capacidade e velocidade adotando arquiteturas em Nuvem (PostgreSQL para OLTP Transacional e MongoDB para NoSQL Analítico e Documental).

Sua tarefa de encerramento é entregar uma Modelagem e Justificativa Arquitetural para o projeto "Recruta+ V2.0".

## Os Requisitos do Negócio

A Plataforma atingiu escala nacional. Agora temos os seguintes problemas documentados:
1. **Chat Interno:** Candidatos e Recrutadores conversam em tempo real. Cada vaga gera centenas de milhares de mensagens curtas. A busca pelo histórico precisa ser instantânea.
2. **Sistema Financeiro Intocável:** Pagamentos de comissões, faturas de empresas, e débitos. A lei obriga que qualquer falha na rede anule completamente o pagamento de ponta a ponta (Nenhum centavo pode sumir num estado inconsistente).
3. **Análise Textual de Currículos e Redes Sociais:** Milhões de currículos, certificados PDFs convertidos, textões do Linkedin em formatos caóticos e altamente mutáveis. 
4. **Relatórios Globais do RH (Analytics):** Agregações pesadas rodando pela madrugada cruzando dados de contratação com os gastos em tempo real, sem que isso derrube ou lerde o site para os usuários normais de manhã.

## O que você deve entregar

Você não precisa escrever o código DDL inteiro desta vez, mas deve apresentar um **Desenho Arquitetural Justificado**.

### 1. Seleção Tecnológica
Especifique EXATAMENTE para qual Banco (PostgreSQL ou MongoDB) você direcionará cada um dos 4 requisitos acima. Por quê?

### 2. Estratégia de Escalabilidade e Alta Disponibilidade
Como sua arquitetura vai se recuperar sozinha se a Zona A da AWS / Azure cair completamente? 

### 3. Evitando Hotspots
Para o Chat Interno (onde o volume é insano), explique a estratégia que você vai usar (Sharding? Particionamento? Índice de Cobertura?) para que a busca seja barata para o bolso da empresa na Nuvem.

### 4. Segurança e Auditoria
Qual o desenho da política de isolamento e backup que garante a sobrevivência da startup caso o desenvolvedor da API seja vítima de Ransomware e tente "droppar" as Collections e Tabelas?

---
> **"A diferença entre um programador júnior que sabe SQL e um Arquiteto Sênior é a capacidade de saber 'Onde', 'Por que' e 'Como' armazenar dados para sobreviver à pior tempestade possível."**
> 
> *Boa sorte!*
