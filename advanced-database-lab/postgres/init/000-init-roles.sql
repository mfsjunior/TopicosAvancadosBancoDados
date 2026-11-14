-- 000-init-roles.sql
-- Cria uma role intermediária para os alunos poderem criar seus próprios bancos e usuários.
-- Ela tem os privilégios CREATEDB e CREATEROLE, mas NÃO é superuser.
-- Isso impede que os alunos acessem ou apaguem os bancos dos colegas por acidente.

CREATE ROLE aluno_creator WITH LOGIN PASSWORD 'aluno_senha' CREATEDB CREATEROLE;
