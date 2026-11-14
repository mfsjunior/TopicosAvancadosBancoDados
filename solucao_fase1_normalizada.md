# Solução: Modelagem Hospitalar Normalizada

Com base nos fundamentos de Dependências e Formas Normais apresentados, aqui está a reestruturação dos dados do Sistema de Gestão Hospitalar (SGH) para atingir pelo menos a **3ª Forma Normal (3FN)**.

---

## 1. Análise e Normalização

Antes de definirmos as tabelas, precisamos resolver algumas quebras de formas normais nos "Dados Disponíveis" originais:

1.  **Violação da 1FN (Atributos Multivalorados):** 
    *   O **Telefone** e o **Histórico de Alergias** do Paciente podem conter múltiplos valores. (Ex: o paciente tem 2 celulares e 3 alergias diferentes). Para respeitar a 1FN, precisamos extrair esses dados para tabelas dependentes (1:N).
2.  **Chaves Naturais vs. Artificiais:** 
    *   Como alertado pela dica do desafio, usar `CPF` ou a combinação `CRM + UF` como Chave Primária (PK) é arriscado. Documentos podem ser digitados errados ou sofrerem alterações de formato. Além disso, uma PK composta (CRM+UF) faria com que a tabela `Consulta` tivesse que armazenar essas duas colunas para a FK. **Solução:** Adotaremos IDs numéricos gerados automaticamente (Chaves Artificiais ou *Surrogate Keys*) para todas as entidades principais.
3.  **Violação da 3FN (Dependência Transitiva / Domínios):**
    *   Atributos como `Especialidade` no Médico e `Status` ou `Sala` na Consulta poderiam gerar anomalias de atualização se mantidos como simples textos (ex: alguém digita "Cardio" e outro "Cardiologia"). 
    *   **Solução:** Transformar em tabelas de domínio para padronização.

---

## 2. Estrutura de Tabelas (Modelo Lógico)

Abaixo estão as tabelas principais e auxiliares, com suas Chaves Primárias (PK) e Chaves Estrangeiras (FK).

### Paciente e seus dados multivalorados (1FN)
*   **Tabela `Paciente`**
    *   **PK:** `ID_Paciente` (Inteiro/Auto-incremento)
    *   *Colunas:* `CPF` (Unique), `Nome_Completo`, `Data_Nascimento`.
*   **Tabela `Paciente_Telefone`**
    *   **PK:** `ID_Telefone`
    *   **FK:** `ID_Paciente` (Referencia `Paciente.ID_Paciente`)
    *   *Colunas:* `Numero_Telefone`.
*   **Tabela `Paciente_Alergia`**
    *   **PK:** `ID_Alergia`
    *   **FK:** `ID_Paciente` (Referencia `Paciente.ID_Paciente`)
    *   *Colunas:* `Descricao_Alergia`.

### Médico e Especialidade (3FN)
*   **Tabela `Especialidade`**
    *   **PK:** `ID_Especialidade`
    *   *Colunas:* `Nome_Especialidade` (Unique).
*   **Tabela `Medico`**
    *   **PK:** `ID_Medico`
    *   **FK:** `ID_Especialidade` (Referencia `Especialidade.ID_Especialidade`)
    *   *Colunas:* `CRM`, `UF_CRM`, `Nome_Medico`. *(O conjunto CRM + UF_CRM deve ter restrição Unique).*

### Estrutura do Hospital
*   **Tabela `Sala`**
    *   **PK:** `ID_Sala`
    *   *Colunas:* `Numero_Sala` (Unique), `Andar`, `Ativa` (Booleano).

### Transações e Atendimentos
*   **Tabela `Consulta`**
    *   **PK:** `ID_Consulta`
    *   **FKs:** 
        *   `ID_Paciente` (Referencia `Paciente`)
        *   `ID_Medico` (Referencia `Medico`)
        *   `ID_Sala` (Referencia `Sala`)
    *   *Colunas:* `Data_Hora_Inicio`, `Duracao_Prevista_Minutos`, `Status` (Pode ser um ENUM 'Agendada', 'Realizada', 'Cancelada' ou uma FK para tabela de Status).
    *   *Restrições de Negócio:* Garantir via banco ou aplicação que a mesma Sala ou mesmo Médico não tenham consultas no mesmo horário (sobreposição).

*   **Tabela `Medicamento`** (Extração para evitar dependência transitiva/anomalia de digitação)
    *   **PK:** `ID_Medicamento`
    *   *Colunas:* `Nome_Medicamento`, `Principio_Ativo`.

*   **Tabela `Prescricao`**
    *   **PK:** `ID_Prescricao`
    *   **FKs:**
        *   `ID_Consulta` (Referencia `Consulta`)
        *   `ID_Medicamento` (Referencia `Medicamento`)
    *   *Colunas:* `Dosagem`, `Instrucoes_Uso`.

---

## 3. Conclusão das Respostas

1.  **Tabelas:** `Paciente`, `Paciente_Telefone`, `Paciente_Alergia`, `Especialidade`, `Medico`, `Sala`, `Consulta`, `Medicamento` e `Prescricao`.
2.  **Chaves Primárias (PK):** Optou-se por Chaves Artificiais (ex: `ID_Paciente`, `ID_Medico`) para garantir chaves curtas, estáveis (não mudam com o tempo, diferente de um documento que pode ser atualizado) e que otimizam a performance das junções (*joins*).
3.  **Chaves Estrangeiras (FK):** As FKs foram distribuídas na `Consulta` para ligar as entidades principais, e nas tabelas "filhas" (`Paciente_Telefone`, `Paciente_Alergia`, `Prescricao`) ligando-as à sua entidade "pai". Isso garante a integridade referencial solicitada.
