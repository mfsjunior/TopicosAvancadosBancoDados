## 🚀 Desafio Final (Nível 4) - Resgate do Sistema em Produção

**O Cenário:**
Você foi contratado como Consultor Sênior de Banco de Dados para o *Hospital e Complexo de Saúde*. Um desenvolvedor júnior da equipe cometeu dois erros arquiteturais graves em Produção que estão custando muito dinheiro para a empresa. 

Sua missão é diagnosticar o problema e propor a solução técnica.

### Missão 1: Integração Noturna
Uma vez por mês, o hospital recebe um lote governamental contendo **5 milhões de novos registros** de pacientes para serem inseridos na tabela `paciente`. O desenvolvedor júnior, visando "deixar a tabela rápida", havia criado 6 índices B-Tree diferentes na tabela (no CPF, Nome, Data de Nascimento, Telefone, Email e CEP).
Quando a rotina mensal de `INSERT` massivo rodou na madrugada, o banco de dados levou 8 horas para processar, a máquina exauriu seus recursos de disco (I/O) e o sistema inteiro caiu.

*   **A) Diagnóstico:** Utilizando o conceito de "Page Split" e rebalanceamento de árvores, explique tecnicamente ao desenvolvedor por que o banco de dados sofreu tanto para fazer essa inserção.
*   **B) A Solução (Plano de Ação):** Escreva o passo a passo de como a rotina de inserção mensal deve ser arquitetada a partir de agora para que esses 5 milhões de registros sejam inseridos em poucos minutos. (Dica: Pense no ciclo de vida dos índices durante um Bulk Insert).

---

### Missão 2: Lista Telefônica
No módulo de RH do hospital, as duas buscas mais comuns feitas pelos recrutadores na tabela `candidato` são:
*   **Busca A:** `SELECT * FROM candidato WHERE estado = 'SP' AND profissao = 'Enfermeiro';`
*   **Busca B:** `SELECT * FROM candidato WHERE profissao = 'Médico Cirurgião';`

Para otimizar o sistema, o dev júnior rodou o seguinte comando:
`CREATE INDEX idx_estado_profissao ON candidato (estado, profissao);`

Ele notou maravilhado que a **Busca A** ficou instantânea. No entanto, o sistema de monitoramento apontou que a **Busca B** está demorando minutos e o banco de dados está ignorando completamente o índice, fazendo um custoso *Sequential Scan* na tabela inteira.

*   **A) Diagnóstico:** Utilizando a analogia do catálogo telefônico (hierarquia de ordenação), explique por que o banco de dados foi forçado a ignorar o índice criado na **Busca B**.
*   **B) A Solução (Refatoração SQL):** Escreva o comando SQL de criação de **um único índice composto** que seja capaz de otimizar de forma eficiente tanto a **Busca A** quanto a **Busca B** simultaneamente.
