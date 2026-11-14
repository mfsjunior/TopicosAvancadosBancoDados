#!/bin/bash
# Wrapper script para rodar testes de performance de JavaScript no Mongosh

echo "🔥 Disparando canhão (Loop JavaScript) no MongoDB..."
echo "Tempo estimado: Dependerá do processador e dos índices criados."
echo "----------------------------------------------------"

# Envia o script JS e executa
docker cp ./test-performance.js adv_db_mongodb:/tmp/test-performance.js
docker exec -it adv_db_mongodb mongosh -u root -p root_password adv_curriculos /tmp/test-performance.js

echo "----------------------------------------------------"
echo "✅ Teste concluído."
