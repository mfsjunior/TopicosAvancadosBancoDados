#!/bin/bash
# Script utilitário para geração de massa de dados na Plataforma de Recrutamento

SIZE=${1:-small}

if [[ "$SIZE" != "small" && "$SIZE" != "medium" && "$SIZE" != "large" ]]; then
    echo "❌ Erro: Tamanho inválido!"
    echo "Uso: ./generate-data.sh [small|medium|large]"
    exit 1
fi

echo "📊 Solicitando geração de dados no PostgreSQL..."
echo "Tamanho selecionado: $SIZE"
echo "Por favor, aguarde, este processo pode demorar alguns minutos para tamanhos maiores..."

# Executa a procedure no PostgreSQL
docker exec -it adv_db_postgres psql -U adv_user -d adv_recruitment -c "CALL generate_data('$SIZE');"

if [ $? -eq 0 ]; then
    echo "✅ Processo de geração concluído com sucesso!"
else
    echo "❌ Ocorreu um erro ao gerar os dados. Verifique se o container está rodando."
fi
