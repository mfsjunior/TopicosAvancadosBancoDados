param (
    [string]$Size = "small"
)

if ($Size -notin @("small", "medium", "large")) {
    Write-Host "❌ Erro: Tamanho inválido!" -ForegroundColor Red
    Write-Host "Uso: .\generate-data.ps1 [small|medium|large]"
    exit 1
}

Write-Host "📊 Solicitando geração de dados no PostgreSQL..."
Write-Host "Tamanho selecionado: $Size"
Write-Host "Por favor, aguarde, este processo pode demorar alguns minutos para tamanhos maiores..."

# Executa a procedure no PostgreSQL
docker exec adv_db_postgres psql -U adv_user -d adv_recruitment -c "CALL generate_data('$Size');"

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Processo de geração concluído com sucesso!" -ForegroundColor Green
} else {
    Write-Host "❌ Ocorreu um erro ao gerar os dados. Verifique se o container está rodando." -ForegroundColor Red
}
