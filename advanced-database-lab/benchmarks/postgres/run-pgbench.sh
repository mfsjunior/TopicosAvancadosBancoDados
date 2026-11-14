#!/bin/bash
# Wrapper script para rodar pgbench com queries customizadas por dentro do Docker

QUERY_FILE=$1
CLIENTS=${2:-50}
TIME=${3:-30}

if [ -z "$QUERY_FILE" ]; then
    echo "❌ Erro: Faltou informar o arquivo SQL da query."
    echo "📝 Uso: ./run-pgbench.sh queries/arquivo.sql [numero_clientes] [tempo_segundos]"
    echo "💡 Exemplo: ./run-pgbench.sh queries/lab04-pesquisa-email.sql 50 30"
    exit 1
fi

if [ ! -f "$QUERY_FILE" ]; then
    echo "❌ Erro: Arquivo $QUERY_FILE não encontrado."
    exit 1
fi

echo "🔥 Disparando canhão (pgbench) no PostgreSQL..."
echo "📊 Clientes Simultâneos: $CLIENTS"
echo "⏱️  Tempo de Teste: $TIME segundos"
echo "----------------------------------------------------"

# Enviando o arquivo para dentro do container
docker cp "$QUERY_FILE" adv_db_postgres:/tmp/custom_query.sql

# Executando o pgbench sem a inicialização padrao (-n)
docker exec -it adv_db_postgres pgbench -U adv_user -d adv_recruitment -c $CLIENTS -j 2 -T $TIME -f /tmp/custom_query.sql -n

echo "----------------------------------------------------"
echo "✅ Teste concluído. Analise o TPS (Transactions Per Second)!"
