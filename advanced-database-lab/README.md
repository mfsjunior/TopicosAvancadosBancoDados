# Laboratório de Tópicos Avançados de Banco de Dados

Bem-vindo ao laboratório da disciplina **Tópicos Avançados de Banco de Dados**.

Neste laboratório, simularemos e evoluiremos uma **Plataforma de Recrutamento** que sofre com problemas de concorrência, performance e modelagem à medida que cresce.

> **UM PROJETO → MUITAS AULAS → MUITOS PROBLEMAS → UMA ARQUITETURA FINAL**

---

## 🚀 Como Iniciar

1. **Clone o repositório** e abra o terminal na pasta raiz do projeto.
2. **Copie o arquivo de configuração (.env):**
   - *Windows (PowerShell)*: `Copy-Item .env.example .env`
   - *Linux/Mac*: `cp .env.example .env`
3. **Suba o ambiente (PostgreSQL e MongoDB):**
   - *Windows (PowerShell)*: `.\scripts\start.ps1`
   - *Linux/Mac (Bash)*: `./scripts\start.sh`
4. **Geração de Massa de Dados (Opcional):**
   O banco já sobe com uma massa "small". Se precisar aumentar para os laboratórios seguintes:
   - *Windows*: `.\scripts\generate-data.ps1 medium`
   - *Linux/Mac*: `./scripts\generate-data.sh medium`

---

## 🔌 Conectando aos Bancos de Dados

Para realizar as consultas e laboratórios, recomendamos fortemente o uso do **DBeaver** ou do **VSCode**.

### Opção A: DBeaver (Recomendado)
O [DBeaver Community](https://dbeaver.io/) suporta tanto bancos Relacionais (PostgreSQL) quanto NoSQL (MongoDB).

#### PostgreSQL
- Abra o DBeaver, clique em **Nova Conexão** e selecione **PostgreSQL**.
- **Host**: `localhost` | **Port**: `5432` | **Database**: `adv_recruitment`
- **Username**: `adv_user` | **Password**: `adv_password`
- Teste a conexão e salve.

#### MongoDB
- Clique em **Nova Conexão**, selecione **MongoDB**.
- **Host**: `localhost` | **Port**: `27017`
- Na aba de Autenticação (Authentication): **Database**: `admin` | **Username**: `root` | **Password**: `root_password`
- Teste a conexão e salve.

### Opção B: Visual Studio Code
Para quem não quer sair do editor de código.

#### PostgreSQL (via extensão SQLTools)
- Instale a extensão **SQLTools** + **SQLTools PostgreSQL/Redshift Driver**.
- Adicione uma conexão PostgreSQL com:
  - **Server Address**: `localhost` | **Port**: `5432` | **Database**: `adv_recruitment`
  - **Username**: `adv_user` | **Password**: `adv_password`

#### MongoDB (via extensão oficial)
- Instale a extensão **MongoDB for VS Code**.
- Adicione uma conexão e insira a seguinte string:
  ```text
  mongodb://root:root_password@localhost:27017/?authSource=admin
  ```

---

## 📚 Acesso ao Material

### Alunos
Todo o material, laboratórios e desafios para você estão no diretório `student/labs`. As aulas são numeradas em ordem (ex: `01-ambiente`, `02-postgres-internals`, etc).

### Professores
As soluções, gabaritos e benchmarks de referência estão restritos ao diretório `teacher/solutions`.

## 🛠️ Tecnologias Utilizadas
- **PostgreSQL 15+** (OLTP, Transações, MVCC)
- **MongoDB 6+** (NoSQL, Documentos, Sharding)
- **Docker & Docker Compose** (Isolamento, Redes, Clusters)
- **PL/pgSQL & Bash / PowerShell** (Scripts utilitários e geração de massa)

---
*Este material acompanha a disciplina e evolui incrementalmente, aula após aula.*
