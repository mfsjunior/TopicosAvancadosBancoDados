// Script MongoDB para teste de leitura bruta (Aulas 14/15)

// Removendo log excessivo
print("⏳ Iniciando teste de carga (5000 Buscas)...");

var start = new Date();
var success = 0;

for (var i = 1; i <= 5000; i++) {
    // Buscar um usuário aleatório 
    var randUser = "user" + Math.floor(Math.random() * 100);
    var doc = db.log_eventos.findOne({ "usuario": randUser });
    if(doc != null) success++;
}

var end = new Date();
var timeTaken = (end - start) / 1000;

print("📊 Resultado Final:");
print("--------------------------");
print("Total de buscas: 5000");
print("Tempo decorrido: " + timeTaken + " segundos.");
print("Buscas por segundo (TPS Estimado): " + Math.round(5000 / timeTaken));
print("--------------------------");
print("💡 DICA: Se estiver lento, você criou o índice {usuario: 1} ?");
