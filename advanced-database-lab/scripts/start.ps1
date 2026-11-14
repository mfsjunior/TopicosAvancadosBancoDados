Write-Host "🚀 Iniciando ambiente Docker para o Laboratório Avançado..."
docker-compose up -d

Write-Host "--------------------------------------------------------"
Write-Host "✅ Serviços iniciados em background:"
Write-Host "- PostgreSQL: porta 5432"
Write-Host "- MongoDB: porta 27017"
Write-Host "Para visualizar os logs, execute: docker-compose logs -f"
