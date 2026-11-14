# Script para realizar o backup completo (dump) dos bancos de dados
# Ideal para o professor rodar no fim da aula para garantir que os trabalhos dos alunos nao sejam perdidos.

$BackupDir = ".\backups\" + (Get-Date -Format "yyyy-MM-dd_HH-mm-ss")
New-Item -ItemType Directory -Force -Path $BackupDir | Out-Null

Write-Host "Iniciando backup completo do PostgreSQL (Todos os Bancos/Alunos)..."
# Usa pg_dumpall para garantir que os novos bancos criados pelos alunos sejam exportados.
# Substitua adv_user caso tenha alterado o nome de superusuario no .env
docker exec -t adv_db_postgres pg_dumpall -c -U adv_user > "$BackupDir\postgres_dumpall.sql"

Write-Host "Iniciando backup completo do MongoDB (Todos os Bancos/Alunos)..."
# Usa mongodump para exportar todas as bases
docker exec -t adv_db_mongodb mongodump --archive="/tmp/mongo_dump.archive"
docker cp adv_db_mongodb:/tmp/mongo_dump.archive "$BackupDir\mongo_dump.archive"

Write-Host "Backup finalizado com sucesso! Arquivos estao na pasta: $BackupDir"
Write-Host "--------------------------------------------------------"
