#  NewSQL  e Tolerância às falhas e Escalabilidade
## Bernardo Camargo e Renata Praisler

## CockroachDB

### 1. Criar uma ponte para que os três nós possam se conectar

docker network create -d bridge roachnet

### 2. Inicializar os nós do cluster

#### 2.1 Inicializar o primeiro nó do cluster

docker run -d `
--name=roach1 `
--hostname=roach1 `
--net=roachnet `
-p 26257:26257 -p 8080:8080  `
-v "//c/Users/<username>/cockroach-data/roach1:/cockroach/cockroach-data"  `
cockroachdb/cockroach:v20.2.2 start `
--insecure `
--join=roach1,roach2,roach3

#### 2.2 Inicializar o segundo nó do cluster

docker run -d `
--name=roach2 `
--hostname=roach2 `
--net=roachnet `
-v "//c/Users/Bernardo/cockroach-data/roach2:/cockroach/cockroach-data"  `
cockroachdb/cockroach:v20.2.2 start `
--insecure `
--join=roach1,roach2,roach3


#### 2.3 Inicializar o terceiro nó do cluster

docker run -d `
--name=roach3 `
--hostname=roach3 `
--net=roachnet `
-v "//c/Users/Bernardo/cockroach-data/roach3:/cockroach/cockroach-data"  `
cockroachdb/cockroach:v20.2.2 start `
--insecure `
--join=roach1,roach2,roach3


### 3. Inicializar o cluster com nó primário sendo o roach1

docker exec -it roach1 ./cockroach init --insecure

### TESTES....