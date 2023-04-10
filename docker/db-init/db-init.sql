ALTER USER postgres PASSWORD 'password1';
CREATE DATABASE ledgerdb;
GRANT ALL ON DATABASE ledgerdb TO postgres;
CREATE SCHEMA IF NOT EXISTS ledgerdb AUTHORIZATION postgres;
GRANT ALL ON SCHEMA ledgerdb TO postgres;
