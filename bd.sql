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
    (NULL, 'Pessoa 01', '5482-3', '85377-3', 'CORRENTE', 51230),
    (NULL, 'Pessoa 02', '3123-5', '43176-4', 'CORRENTE', 1500),
    (NULL, 'Pessoa 03', '4235-1', '12524-2', 'CORRENTE', 30000),
    (NULL, 'Pessoa 04', '2315-3', '48255-9', 'POUPANÇA', 4232),
    (NULL, 'Pessoa 05', '5144-7', '90132-8', 'CORRENTE', 84412),
    (NULL, 'Pessoa 06', '7223-6', '98431-5', 'POUPANÇA', 554876),
    (NULL, 'Pessoa 07', '2623-3', '68232-5', 'CORRENTE', 10000000),
    (NULL, 'Pessoa 08', '9184-9', '12537-6', 'CORRENTE', 54656654),
    (NULL, 'Pessoa 09', '5143-5', '10255-1', 'POUPANÇA', 974113),
    (NULL, 'Pessoa 10', '8743-5', '23985-3', 'CORRENTE', 642154);