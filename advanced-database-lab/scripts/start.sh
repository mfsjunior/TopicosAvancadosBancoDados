#!/bin/bash
# Script utilitário para iniciar o ambiente do laboratório

echo "🚀 Iniciando ambiente Docker para o Laboratório Avançado..."
docker-compose up -d

echo "--------------------------------------------------------"
echo "✅ Serviços iniciados em background:"
echo "- PostgreSQL: porta 5432"
echo "- MongoDB: porta 27017"
echo "Para visualizar os logs, execute: docker-compose logs -f"
