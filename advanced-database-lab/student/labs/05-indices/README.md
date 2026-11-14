# Laboratório 05: Índices (B-Tree e Otimizações)

## Objetivo
Entender como índices funcionam, quando criá-los e como eles impactam o banco de dados.

## 📚 Referência: Conceitos de Índices

Antes de iniciar os desafios, consulte este guia prático com os conceitos-chave de indexação:

### 1. Índices B-Tree (Balanced Tree)
**O que é?** É o índice padrão (default) do PostgreSQL e da maioria dos bancos relacionais. Ele organiza os dados de uma coluna como uma "árvore balanceada" (imagine o índice de um livro em ordem alfabética).
**Para que serve?**
- Excelente para operações de comparação matemática e de texto (`=`, `<`, `<=`, `>`, `>=`, `BETWEEN`, `IN`).
- Exemplo: Ao buscar um candidato pelo telefone, em vez do banco ler a tabela inteira linha por linha (Seq Scan), ele navega rapidamente pelos galhos da árvore, chegando ao registro exato em frações de milissegundo (Index Scan).

### 2. Índices Compostos (Composite Indexes)
**O que é?** É a criação de um único índice que envolve **duas ou mais colunas** simultaneamente.
**Para que serve?**
- É muito utilizado quando uma consulta quase sempre faz filtros utilizando várias colunas juntas no `WHERE` (Ex: `WHERE estado = 'SP' AND cidade = 'São Paulo'`).
- **Ponto crucial (Ordem importa):** Se você cria um índice em `(A, B)`, ele otimiza buscas por `A` sozinho, ou buscas por `A e B` juntos. No entanto, ele **quase nunca** ajuda eficientemente uma busca que filtre apenas pela coluna `B`. Portanto, a coluna mais filtrada deve vir primeiro.

### 3. Índices Parciais (Partial Indexes)
**O que é?** É um índice inteligente que possui uma cláusula `WHERE` no momento de sua criação. Ou seja, ele só indexa um **subconjunto** de linhas da tabela, em vez da tabela inteira.
**Para que serve?**
- **Economia extrema de espaço em disco e memória:** Se você tem uma tabela de 10 milhões de registros de vagas, mas apenas 50 mil estão com `status = 'ABERTA'`, você não precisa indexar as 9 milhões e 950 mil encerradas.
- O índice fica minúsculo, super-rápido de ser atualizado (no momento de `INSERT`/`UPDATE`) e atende 99% das buscas da aplicação, já que os recrutadores só querem ver as vagas ativas.

### 4. Covering Indexes (Índices de Cobertura / INCLUDE)
**O que é?** É um índice que, além de possuir sua chave principal de busca, carrega o valor de outras colunas como "anexos" (payload), utilizando a cláusula `INCLUDE`.
**Para que serve?**
- Permite o famoso cenário de **Index-Only Scan** (Escaneamento Apenas no Índice).
- Exemplo: Se você sempre busca um usuário pelo `email` e precisa saber apenas o seu `nome` (`SELECT nome FROM candidato WHERE email = ?`), você pode criar um índice em `email INCLUDE (nome)`.
- Quando a query rodar, o banco de dados vai achar o e-mail na árvore de índice e, como o nome já está anexado ali mesmo na "folha" da árvore, ele nem precisa ir ler o disco onde os dados pesados da tabela estão guardados. A resposta é imediata.


## Problema
O volume de candidaturas cresceu exponencialmente. Os recrutadores estão reclamando que a busca por candidatos através do e-mail ou do telefone está extremamente lenta. Além disso, listar as vagas pelo status "ABERTA" também começou a demorar.

## Procedimento (Nível 1 - Execução)

1. Garanta que você possui uma massa de dados média ou grande rodando o script: `./scripts/generate-data.sh medium`
2. Conecte-se ao banco de dados: `docker exec -it adv_db_postgres psql -U adv_user -d adv_recruitment`
3. Tente buscar um candidato por um e-mail aleatório:
   ```sql
   SELECT * FROM candidato WHERE email = 'candidato5000@email.com';
   ```
4. Note que a consulta demorou um pouco mais. O PostgreSQL teve que escanear a tabela inteira (Seq Scan).
5. Vamos criar o índice:
   ```sql
   CREATE INDEX idx_candidato_email ON candidato(email);
   ```
6. Execute a consulta novamente. Notou a diferença de tempo?

## Investigação (Nível 2)
Os recrutadores frequentemente pesquisam vagas combinando o `empresa_id` e o `status`. 
1. Crie um índice composto adequado para otimizar essa busca: `SELECT * FROM vaga WHERE empresa_id = X AND status = 'ABERTA';`
2. Avalie: Por que criar índices em todas as colunas não é a solução mágica para a performance? Qual o impacto negativo que um índice traz para o sistema?

CREATE INDEX idx_vaga_empresa_status ON vaga (empresa_id, status);

O impacto negativo de criar índices em todas as colunas: Criar índices em todas as colunas não é a "solução mágica" porque índices cobram um preço nas operações de escrita. Toda vez que você faz um INSERT, UPDATE ou DELETE na tabela, o banco de dados é obrigado a ir nos bastidores e atualizar todos os índices associados para mantê-los sincronizados. Se uma tabela tiver 10 índices, um único INSERT exigirá 11 operações de escrita no disco (1 para a tabela e 10 para as árvores B-Tree dos índices). Portanto, muitos índices aceleram a Leitura (SELECT), mas deixam a Escrita (INSERT/UPDATE) extremamente lenta, além de consumirem muito espaço em disco.


## Desafio (Nível 3) - O Índice Parcial
A maioria das buscas de vagas foca apenas naquelas que ainda estão com status `ABERTA`. Vagas encerradas raramente são buscadas pela equipe de recrutamento, mas são mantidas no banco por questões de auditoria.
**Desafio**: Crie um índice na tabela `vaga` que indexe APENAS as vagas onde o `status = 'ABERTA'`. Esse é o conceito de **Índice Parcial**. Compare mentalmente a diferença de tamanho (no disco) desse índice parcial contra um índice padrão B-Tree na mesma coluna.
Escreva seu código SQL.

CREATE INDEX idx_vagas_abertas_parcial ON vaga (empresa_id) WHERE status = 'ABERTA';


Um índice comum (B-Tree completo) criaria "ponteiros" para 100% das linhas da tabela vaga. Já o Índice Parcial cria ponteiros apenas para as vagas abertas. Se uma plataforma possui 5 milhões de vagas, mas apenas 50.000 (1%) estão abertas no momento, o índice parcial terá o tamanho de apenas 1% do índice original. Isso economiza drasticamente disco, acelera a inserção (ele só atualiza o índice se a vaga for inserida como 'ABERTA') e cabe inteiro na memória RAM, garantindo uma busca "voando".
---
## Perguntas
- O que acontece nos bastidores com os índices de uma tabela quando você faz um `INSERT` massivo (como a carga de dados que fizemos)?
- Por que a ordem das colunas em um **Índice Composto** é importante?

1. O que acontece nos bastidores com os índices de uma tabela quando você faz um INSERT massivo (como a carga de dados que fizemos)? Para cada uma das milhões de linhas inseridas, a estrutura de árvore do índice (B-Tree) precisa ser percorrida, dividida e rebalanceada (o que chamamos de Page Split) para achar e acomodar a nova informação ordenadamente. Esse esforço de disco repetido exaure a máquina. É por isso que, no mundo real, a melhor prática para um Bulk Insert (carga massiva de milhões de dados) é excluir ou desativar os índices da tabela antes do INSERT e mandá-los recriar (fazer o rebuild) somente após a carga terminar, pois reordenar tudo de uma vez no final é muito mais rápido do que atualizar a árvore 10 milhões de vezes.

2. Por que a ordem das colunas em um Índice Composto é importante? Pense em um índice composto como uma lista telefônica antiga estruturada por (Sobrenome, Nome). A lista telefônica é extremamente rápida se eu te pedir para buscar todas as pessoas da "Família Silva" e, dentro deles, achar o "João". Mas e se eu te pedir para buscar todas as pessoas do país que se chamam "João", independentemente do sobrenome? O índice perde toda a utilidade, e você terá que ler o livro página por página. Da mesma forma, no banco de dados, um índice (A, B) pode ser usado para buscar só por A, ou por A e B juntos. Mas nunca poderá ser usado para otimizar uma busca que filtra APENAS pela coluna B. A ordem dita se o banco conseguirá usar aquela "árvore" ou não. A regra de ouro é sempre colocar a coluna pela qual você sempre pesquisa como a primeira do índice.