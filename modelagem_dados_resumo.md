# Formas Normais e Dependências (Guia Simplificado e Prático)

A normalização é como fazer uma "faxina" nos seus dados. O objetivo principal é organizar as tabelas de forma que não haja repetições inúteis (redundância) e que você não precise alterar o mesmo dado em dez lugares diferentes quando algo mudar no mundo real.

Para sair do absoluto zero (uma tabela gigante tipo planilha de Excel) até a cobiçada **3ª Forma Normal (3FN)**, você só precisa fazer as perguntas certas para os seus dados. 

Aqui está o passo a passo com exemplos práticos visuais de como isso acontece no dia a dia:

---

## Passo 1: O Fim das "Listinhas" (1ª Forma Normal - 1FN)

**O Conceito:** Para estar na 1FN, os atributos devem ser atômicos (indivisíveis). Uma célula da sua tabela não pode conter uma lista de coisas, e você não deve ter colunas repetidas para o mesmo propósito.

**A Pergunta a fazer aos dados:**
> *"Coluna, você está guardando mais de uma informação aqui dentro?"* (Ex: 'Celular, Fixo' na mesma célula).

### ❌ Mundo Real (Erro 1FN): A Planilha de Clientes
O atendente anotou todos os telefones do João na mesma célula.

| ID_Cliente | Nome | Telefones |
| :--- | :--- | :--- |
| 1 | João Silva | 9999-1111, 8888-2222 |
| 2 | Maria Souza| 7777-3333 |

**O Problema:** Tente fazer uma busca (Query) para saber de quem é o telefone "8888-2222". O banco terá que vasculhar o texto dentro da célula, o que é péssimo para performance.

### ✅ Solução (Aplicando a 1FN):
Arranque os atributos multivalorados e crie uma **NOVA TABELA** ligada à principal.

**Tabela `Cliente`**
| ID_Cliente | Nome |
| :--- | :--- |
| 1 | João Silva |
| 2 | Maria Souza|

**Tabela `Cliente_Telefone`**
| ID_Cliente (FK) | Telefone |
| :--- | :--- |
| 1 | 9999-1111 |
| 1 | 8888-2222 |
| 2 | 7777-3333 |

---

## 🛑 Ponto de Parada: Achando a Chave Primária e Entendendo Dependências

Antes de ir para os próximos passos, você precisa definir qual é a **Chave Primária (PK)** da sua tabela.
* A pergunta base de dependência é: *"Se eu te der o valor da Chave Primária, você consegue me dizer com exatidão o valor das outras colunas?"* Se sim, essas colunas **dependem** da chave.

---

## Passo 2: O Fim dos "Caroneiros" (2ª Forma Normal - 2FN)

> [!TIP]
> **Alerta de Atalho:** Você **SÓ** precisa se preocupar com a 2FN se a sua tabela tiver uma Chave Primária Composta (formada por duas ou mais colunas, ex: `ID_Pedido` + `ID_Produto`). 

**O Conceito:** Para estar na 2FN, todo atributo comum deve depender da Chave Primária **INTEIRA**, e não apenas de um pedaço dela (Dependência Parcial).

**A Pergunta a fazer aos dados:**
> *"Ei, atributo X, para eu saber quem você é, você precisa das DUAS colunas da nossa Chave Primária, ou você precisa de apenas uma delas?"*

### ❌ Mundo Real (Erro 2FN): O Carrinho de Compras
A chave primária aqui é composta: precisamos do `ID_Pedido` e do `ID_Produto` juntos para identificar a linha.

| ID_Pedido (PK) | ID_Produto (PK) | Quantidade | Nome_Produto |
| :--- | :--- | :--- | :--- |
| 100 | 5 | 2 | Teclado Gamer |
| 100 | 8 | 1 | Mouse Sem Fio |
| 101 | 5 | 3 | Teclado Gamer |

**O Problema:** A coluna `Nome_Produto` está sofrendo de **Dependência Parcial**. O nome "Teclado Gamer" não liga a mínima para o `ID_Pedido`. Ele depende **APENAS** do `ID_Produto`. Se você mudar o nome do teclado, terá que atualizar as linhas do Pedido 100 e 101. E se nenhum pedido tiver o produto 5, você perde o cadastro do Teclado!

### ✅ Solução (Aplicando a 2FN):
Tire o atributo caroneiro e crie a tabela que é dona dele.

**Tabela `Item_Pedido`** (Chave: Pedido + Produto)
| ID_Pedido (PK) | ID_Produto (PK) | Quantidade |
| :--- | :--- | :--- |
| 100 | 5 | 2 |
| 100 | 8 | 1 |
| 101 | 5 | 3 |

**Tabela `Produto`**
| ID_Produto (PK) | Nome_Produto |
| :--- | :--- |
| 5 | Teclado Gamer |
| 8 | Mouse Sem Fio |

---

## Passo 3: O Fim das "Fofocas" (3ª Forma Normal - 3FN)

**O Conceito:** Para estar na 3FN, um atributo comum não pode depender de outro atributo comum. Ele deve depender **DIRETAMENTE e EXCLUSIVAMENTE** da Chave Primária. 

**A Pergunta a fazer aos dados:**
> *"Ei, atributo X, você depende da Chave Primária da tabela, ou você na verdade depende daquele outro atributo comum ali do lado?"*

### ❌ Mundo Real (Erro 3FN): O Registro de Vendas
A Chave Primária desta tabela é o `ID_Venda`.

| ID_Venda (PK) | Data | Vendedor_ID | Nome_Vendedor |
| :--- | :--- | :--- | :--- |
| 5001 | 10/08 | 12 | Carlos Almeida |
| 5002 | 11/08 | 12 | Carlos Almeida |

**O Problema:** Temos uma **Dependência Transitiva**. O `Nome_Vendedor` não está amarrado à Venda (5001 ou 5002). Na verdade, o Nome do Vendedor depende do `Vendedor_ID`. Um atributo comum "entregando" a identidade do outro gera redundância absurda. Se o Carlos casar e mudar de sobrenome, você terá que rodar um UPDATE em 5 mil vendas no banco.

### ✅ Solução (Aplicando a 3FN):
Separe os fofoqueiros. Se o Nome depende do ID do Vendedor, coloque-os na tabela de Vendedores!

**Tabela `Venda`**
| ID_Venda (PK) | Data | Vendedor_ID (FK) |
| :--- | :--- | :--- |
| 5001 | 10/08 | 12 |
| 5002 | 11/08 | 12 |

**Tabela `Vendedor`**
| Vendedor_ID (PK) | Nome_Vendedor |
| :--- | :--- |
| 12 | Carlos Almeida |

---

## Resumo Rápido das Dependências

*   **Dependência Funcional (Correta):** *"Me dê X (a chave) e eu te revelo Y (o atributo)"*. 
*   **Dependência Parcial (Viola 2FN):** *"Me dê a chave composta inteira? Não precisa, só a metade dela já me revela quem eu sou"*. 
*   **Dependência Transitiva (Viola 3FN):** *"Eu não obedeço a Chave Primária, eu obedeço aquele outro atributo comum ali"*.
