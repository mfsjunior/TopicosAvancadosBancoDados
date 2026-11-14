-- Script de carga para a Aula 08: Lock Contention (Disputa de Vaga)
-- Como todos tentarão atualizar A MESMA vaga, veremos o Lock escalar!

BEGIN;

-- Tentando atualizar o salário da vaga ID 1 (Fixo para causar Lock Contention intenso)
UPDATE vaga SET salario = salario + 1 WHERE id = 1;

COMMIT;
