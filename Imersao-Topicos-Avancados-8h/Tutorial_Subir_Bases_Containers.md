# Tutorial Prático: Como Subir os Bancos Hospitalares nos Containers Docker

Este guia ensina o passo a passo completo para iniciar os containers do **PostgreSQL** e **MongoDB**, conectar-se a eles (via **DBeaver**, **VS Code** ou **Terminal/CLI**) e executar os scripts do [laboratório hospitalar](laboratorio-hospital/).

---

## 🧭 Visão Geral do Ambiente

O projeto utiliza a stack configurada no diretório [`advanced-database-lab/`](../advanced-database-lab/):

| Serviço | Imagem Docker | Porta do Host | Porta Container | Usuário Padrão | Senha Padrão | Banco de Dados |
| :--- | :--- | :---: | :---: | :--- | :--- | :--- |
| **PostgreSQL** | `postgres:15-alpine` | **`5433`** *(ou 5432)* | `5432` | `adv_user` | `adv_password` | `adv_recruitment` *(ou postgres)* |
| **MongoDB** | `mongo:6-jammy` | **`27017`** | `27017` | `root` | `root_password` | `admin` (auth) / `hospital_db` |

> [!NOTE]
> A porta do PostgreSQL no arquivo `.env` está configurada como **`5433`** para evitar conflito com instâncias locais do Postgres que já usam a porta `5432`.

---

## 🚀 PASSO 1: Subir os Containers Docker

Abra o terminal (PowerShell no Windows ou Bash no Linux) na raiz do projeto:

```powershell
# 1. Navegue até a pasta do laboratório que contém o docker-compose.yml:
cd advanced-database-lab

# 2. Se for a primeira vez e ainda não tiver o arquivo .env:
Copy-Item .env.example .env

# 3. Inicie os containers em segundo plano:
docker-compose up -d
```

### Validando se os containers estão rodando
Execute:
```powershell
docker ps --filter "name=adv_db"
```
Você deverá ver os containers **`adv_db_postgres`** e **`adv_db_mongodb`** com status `Up (healthy)`.

---

## 🐘 PASSO 2: Carga da Base Relacional no PostgreSQL

Arquivo de origem: [`01_schema_relacional_postgres.sql`](laboratorio-hospital/01_schema_relacional_postgres.sql)

Você pode carregar a base de **duas formas** (escolha a que preferir):

### Opção A: Pelo Terminal / Linha de Comando (Mais Rápido e Direto)
Execute o comando abaixo no terminal a partir da pasta `Imersao-Topicos-Avancados-8h`:

```powershell
Get-Content ".\laboratorio-hospital\01_schema_relacional_postgres.sql" | docker exec -i adv_db_postgres psql -U adv_user -d adv_recruitment
```

> [!TIP]
> Se preferir rodar dentro de um banco limpo chamado `hospital_db`:
> ```powershell
> # Cria o banco hospital_db:
> docker exec -it adv_db_postgres psql -U adv_user -d postgres -c "CREATE DATABASE hospital_db;"
> # Injeta o script no novo banco:
> Get-Content ".\laboratorio-hospital\01_schema_relacional_postgres.sql" | docker exec -i adv_db_postgres psql -U adv_user -d hospital_db
> ```

---

### Opção B: Pelo DBeaver Community (Interface Gráfica)

1. **Abra o DBeaver** e clique no menu **Banco de Dados ➔ Nova Conexão ➔ PostgreSQL**.
2. **Preencha os parâmetros de conexão:**
   * **Host:** `localhost`
   * **Port:** `5433` *(verifique seu .env)*
   * **Database:** `adv_recruitment` *(ou postgres)*
   * **Username:** `adv_user`
   * **Password:** `adv_password`
3. Clique em **Testar Conexão** e depois em **Concluir**.
4. No DBeaver, clique em **Arquivo ➔ Abrir Arquivo...** e selecione o script `01_schema_relacional_postgres.sql` na pasta `laboratorio-hospital/`.
5. Pressione **`Alt + X`** (ou clique no botão *Executar Script SQL*).
6. **Verificação de Sucesso:**
   * No navegador de objetos à esquerda, expanda o banco ➔ **Esquemas (Schemas)** ➔ **`hospital_lab`** ➔ **Tabelas**.
   * Você verá as 14 tabelas normalizadas (`Consulta`, `Paciente`, `Medico`, etc.) povoadas com os 12 atendimentos do CSV.

---

## 🍃 PASSO 3: Carga da Base NoSQL no MongoDB

Arquivo de origem: [`02_schema_nosql_mongodb.js`](laboratorio-hospital/02_schema_nosql_mongodb.js)

### Opção A: Pelo Terminal / Linha de Comando (Via `mongosh`)
Execute o comando abaixo no terminal a partir da pasta `Imersao-Topicos-Avancados-8h`:

```powershell
Get-Content ".\laboratorio-hospital\02_schema_nosql_mongodb.js" | docker exec -i adv_db_mongodb mongosh -u root -p root_password --authenticationDatabase admin
```

O `mongosh` criará automaticamente o banco `hospital_db`, inserirá os documentos com dados incorporados e executará os relatórios de agregação no console.

---

### Opção B: Pelo DBeaver Community (Interface Gráfica)

1. **Abra o DBeaver** e clique em **Banco de Dados ➔ Nova Conexão ➔ MongoDB**.
2. **Preencha os parâmetros:**
   * **Host:** `localhost`
   * **Port:** `27017`
   * **Database:** `hospital_db`
   * Na aba **Autenticação (Authentication)**:
     * **Database de Autenticação:** `admin`
     * **Username:** `root`
     * **Password:** `root_password`
3. Clique em **Testar Conexão** e depois em **Concluir**.
4. Abra um novo Editor SQL/Script para a conexão MongoDB e copie o conteúdo de [`02_schema_nosql_mongodb.js`](laboratorio-hospital/02_schema_nosql_mongodb.js).
5. Selecione o texto e execute (`Ctrl + Enter` ou `Alt + X`).
6. **Verificação de Sucesso:**
   * No menu esquerdo, atualize (`F5`) a árvore do MongoDB.
   * Expanda `hospital_db` ➔ **Collections** ➔ **`atendimentos`**.
   * Dê dois cliques em `atendimentos` e visualize os documentos JSON estruturados com arrays de procedimentos e prescrições.

---

## 🩺 PASSO 4: Testes Rápidos de Verificação

### No PostgreSQL:
Abra uma aba de consulta e rode:
```sql
SET search_path TO hospital_lab, public;

-- 1. Contar pacientes e atendimentos faturados:
SELECT COUNT(*) AS total_consultas, SUM(Valor_Total_Faturado) AS receita_total
FROM Consulta;

-- 2. Testar o Índice Composto e o EXPLAIN:
EXPLAIN ANALYZE
SELECT c.ID_Consulta, p.Nome_Completo, m.Nome_Medico
FROM Consulta c
JOIN Paciente p ON c.ID_Paciente = p.ID_Paciente
JOIN Medico m ON c.ID_Medico = m.ID_Medico
WHERE c.ID_Medico = 1;
```

### No MongoDB:
No `mongosh` ou DBeaver:
```javascript
use("hospital_db");

// 1. Contar documentos:
db.atendimentos.countDocuments();

// 2. Buscar atendimentos de Cardiologia:
db.atendimentos.find({ "medico.especialidade_atendimento": "Cardiologia" }, { "paciente.nome": 1, valor_total_faturado: 1 });
```

---

## 🛑 Comandos Úteis de Gerenciamento

```powershell
# Parar os containers sem perder dados:
cd c:\projetos\TopicosAvancadosBD\advanced-database-lab
docker-compose stop

# Reiniciar os containers parados:
docker-compose start

# Ver logs em tempo real (útil para ver deadlocks ou erros de conexão):
docker-compose logs -f postgres
docker-compose logs -f mongodb

# Resetar o ambiente do zero (apagar volumes e recriar limpo):
docker-compose down -v
docker-compose up -d
```
