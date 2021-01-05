CREATE DATABASE bank;

CREATE TABLE bank.accounts (
    id          int             NOT NULL    AUTO_INCREMENT,
    nome        VARCHAR(255)    NOT NULL,
    agencia     VARCHAR(15)     NOT NULL,
    conta       VARCHAR(15)     NOT NULL,
    tipo_conta  VARCHAR(50)     NOT NULL,
    saldo       FLOAT           NOT NULL,
    PRIMARY KEY (id)
);

INSERT INTO bank.accounts(id, nome, agencia, conta, tipo_conta, saldo) 
VALUES 
    (NULL, 'Pessoa 1', '5482-3', '85377-3', 'CORRENTE', 50),
    (NULL, 'Pessoa 2', '3123-5', '43176-4', 'CORRENTE', 1500),
    (NULL, 'Pessoa 3', '4235-1', '12524-2', 'CORRENTE', 30000);
