# FASE 1: Modelagem de Dados e Fundamentos

## Cenário Real: Sistema de Gestão Hospitalar Complexo (SGHC)

### 1. Problema

Um complexo hospitalar precisa modernizar seu sistema central para lidar não apenas com agendamentos simples, mas com toda a parte de infraestrutura, múltiplos convênios e procedimentos executados. Atualmente, os sistemas legados não conseguem relacionar corretamente as especialidades dos médicos, os recursos das salas e os diferentes planos de saúde dos pacientes.

### 2. Restrições do Negócio (Novas Regras)

*   **Pacientes e Convênios:** Um paciente pode ter vários planos de saúde ativos (ex: Unimed, Bradesco Saúde), cada um com um número de carteirinha próprio. Uma consulta pode ser "Particular" ou ser coberta por UM desses convênios.
*   **Médicos e Especialidades:** Um médico pode possuir **múltiplas** especialidades (ex: Pediatria e Neurologia). No momento de uma consulta, deve ficar registrado por qual especialidade ele atendeu o paciente. O médico não pode atender duas consultas no mesmo horário.
*   **Salas e Equipamentos:** O hospital possui salas numeradas. Algumas salas abrigam **Equipamentos** médicos específicos (ex: Máquina de Ultrassom, Aparelho de Raio-X).
*   **Consultas e Procedimentos:** Durante uma consulta, além de prescrever medicamentos, o médico pode realizar ou solicitar múltiplos **Procedimentos** (ex: Eletrocardiograma, Endoscopia). Cada procedimento possui um código oficial (CID/TUSS) e um nome.
*   **Prescrições:** O médico pode prescrever nenhum, um, ou vários medicamentos durante a consulta.

### 3. Dados Disponíveis (Requisitos de Informação)

*   **Paciente:** CPF, Nome Completo, Data de Nascimento, Telefones, Histórico de Alergias.
*   **Planos de Saúde (Convênios):** CNPJ, Nome da Operadora, Tipo de Plano. Para o paciente: Número da Carteirinha e Data de Validade.
*   **Médico:** CRM, Estado (UF) do CRM, Nome.
*   **Especialidade:** Nome da Especialidade, Conselho.
*   **Equipamento:** Número de Série, Nome do Equipamento, Data de Manutenção.
*   **Consulta:** Data e Hora de Início, Duração Prevista, Paciente, Médico, Sala, Status (Agendada, Realizada, Cancelada), Convênio Utilizado (ou se foi Particular).
*   **Procedimento:** Código TUSS, Nome do Procedimento, Valor Base.
*   **Prescrição:** Medicamento, Dosagem, Instruções de Uso.

---

##  Desafio de Modelagem (Nível Avançado)

Pensando no fluxo de **Modelagem Conceitual** para o **Modelo Lógico** (antes mesmo de escrevermos o código DDL para o SGBD), como você estruturaria essas entidades considerando as regras estritas da **3ª Forma Normal (3FN)**?

**Por favor, apresente sua proposta respondendo aos seguintes pontos:**

1. **Tabelas:** Quais serão as tabelas principais e as tabelas associativas (de ligação) do nosso sistema?
2. **Chaves Primárias (PK):** Para cada tabela, qual seria a PK que você escolheria (natural ou artificial)?
3. **Chaves Estrangeiras (FK):** Onde estarão as FKs para garantir a integridade referencial, especialmente nos relacionamentos N:M (Muitos para Muitos)?

> [!CAUTION]
> **Atenção:** Muitas das restrições exigem tabelas intermediárias. Pense cuidadosamente em como representar o fato de que "Um paciente tem um convênio e uma carteirinha específica, e a consulta usa essa carteirinha".
