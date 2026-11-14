#!/bin/bash
# Script utilitário para parar o ambiente do laboratório

echo "🛑 Parando e removendo containers do laboratório..."
docker-compose down

echo "--------------------------------------------------------"
echo "✅ Ambiente desligado."
echo "Nota: Seus dados nos volumes continuam salvos."
