# Laboratório 13: Modelagem em MongoDB (Embedding vs Referencing)

## Objetivo
Romper a mentalidade Relacional (Normalização) e entender como modelar para o MongoDB baseado em "Padrões de Leitura" e "Localidade de Dados".

## Conceitos
- Embedding (Embutir) vs Referencing (Referenciar)
- A Regra de Ouro: "Dados que são acessados juntos devem ser armazenados juntos"
- Limite de 16MB por Documento BSON

## Problema
O líder técnico (fã ardoroso de Normalização) decidiu migrar as "Vagas" para o MongoDB também. Ele criou a Collection de Vagas e a Collection de Empresa separadamente, usando o `empresa_id` para conectá-las.
Porém, toda vez que a tela do site carrega, a aplicação faz DUAS requisições (uma para buscar a vaga, e outra para buscar a logo e nome da empresa pelo ID). Isso está sobrecarregando a rede.

## Procedimento (Nível 1 - Execução)

A Modelagem Relacional que ele fez no Mongo:
```javascript
// Documento na collection empresas
{
   _id: ObjectId("5f1f..."),
   nome: "TechCorp",
   logo: "url_da_logo.jpg"
}

// Documento na collection vagas
{
   _id: ObjectId("9a2c..."),
   empresa_id: ObjectId("5f1f..."), // Referenciamento!
   titulo: "Engenheiro de Dados"
}
```

No MongoDB, JOINS existem (`$lookup`), mas são desencorajados para uso transacional frequente. 
Como a tela de Vagas **sempre** precisa do Nome e Logo da Empresa, o modelo ideal é **Embedding Parcial** (ou Desnormalização).

## Investigação (Nível 2)
Crie (inserindo no mongosh) o documento de vaga ideal utilizando Embedding para os dados da empresa.
```javascript
db.vagas.insertOne({
    titulo: "Engenheiro de Dados",
    salario: 10000,
    empresa: {
        id: "referencia_opcional",
        nome: "TechCorp",
        logo: "url_da_logo.jpg"
    }
});
```
Se o nome da empresa for alterado de "TechCorp" para "TechCorp Global" no futuro, esse modelo sofrerá com "Anomalia de Atualização". Como a comunidade do MongoDB defende esse trade-off? 

## Desafio (Nível 3)
Avalie o cenário de **Candidaturas** de uma Vaga.
Uma vaga da Amazon pode receber 10.000 currículos em dois dias. 
Se você decidir embutir as Candidaturas DENTRO do documento da Vaga (Embedding) no formato de um Array de Objetos:
1. Qual limite físico rígido do BSON você corre o risco de estourar?
2. Esse seria um bom caso para Embedding ou Referencing? Justifique técnica e arquiteturalmente.

---
## Perguntas
- Quando você lê que "O MongoDB tem schema-less", isso significa que você não precisa desenhar diagramas de modelagem? 
- "Favoreça o tempo de Leitura em detrimento da redundância de Escrita". Como essa filosofia explica o fato de o MongoDB aceitar dados duplicados?
