#  NewSQL -Tolerância às falhas e Escalabilidade
## Bernardo Camargo e Renata Praisler
## Introdução 
  O NewSQL surgiu como uma nova proposta, pois com o uso do NOSQL acabou apresentando alguns problemas como por exemplo: a falta, do uso de transações, das consultas SQL e a estrutura complexa por não ter uma modelagem estruturada. Ele veio com o objetivo de ter os os pontos positivos dos do modelo relacional para as arquiteturas distribuídas e aumentar o desempenhos das queries de SQL, não tendo a necessidade de servidores mais potentes para melhor execução, e utilizando a escalabilidade horizontal e mantendo as propriedades ACID(Atomicidade, Consistência, Isolamento e Durabilidade).
 STONEBRAKER e CATTEL (2011) definem cinco características de um SGBD NewSQL:
     1.Linguagem SQL como meio de interação entre o SGBD e a aplicação;
     2.Suporte para transações ACID;
     3.Controle de concorrência não bloqueante, para que as leituras e escritas não causem conflitos entre si;
     4.Arquitetura que forneça um maior desempenho por nó de processamento;
     5.Arquitetura escalável, com memória distribuída e com capacidade de funcionar em um aglomerado com um grande número de nós.
 Neste trabalho vamos analisar mais profundamente a tolerância a falhas e escalabilidade.


## Tolerência a falhas
  Nos NewSQL os sistemas são projetados e implementados a partir do zero, ou seja, não foram construídos a partir de um outro sistema existente. São fundamentados com arquiteturas distribuídas que atuam em recursos não compartilhados, com o controle de concorrência de vários nós incluindo componentes para suporte, tolerância a falhas por meio de replicação, controle de 23 fluxos e processamento de consulta distribuída. Assim, ao projetar sua arquitetura não há preocupação com detalhes herdados de um sistema legado. A distribuição dos recursos do banco de dados é feita pelo SGBD por intermédio de um mecanismo personalizado. (CÁ, 2018)	
  A replicação garante o armazenamento do mesmo dado em diferentes data centers, mantendo seus dados seguros em caso de falhas em algum data center, mesmo quando separados geograficamente. Contudo ainda é necessário utilizar uma arquitetura hierárquica para que os clusters consigam conversar entre si para garantir a consistência dos dados.
  Para garantir essa consistência, existe o algoritmo de ”consensus“, que funciona de forma que necessite um quórum de nós ativos para aceitar uma transação, sendo o menor número possível para essa funcionalidade de três nós ativos,esta técnica é utilizada em um dos softwares que será abordado nos próximos blocos. Conforme existam falhas na replicação é feita uma análise para que seja possível redistribuir o trabalho para os nós ativos restantes para garantir o funcionamento do sistema.

![Figura 1 - Replicação ](https://lh3.googleusercontent.com/a2YCi0og6P52TCkkfl6900dS-4LxwkTnB3BY5gXqQUTssvxEU6X57VpdS2CUwJCfY1VfvBwZqhpNwAf3bD7F0PTtM7z-SqZ2n3QSsziEwtDaM3SxFDt8U787_grVTAfjtN81-2DE)

## Escalabilidade 

  O NewSQL possui uma escalabilidade horizontal  que proporciona um aumento de execução e processamentos de tarefas, para isso ele adiciona  mais servidores para dividir o trabalho, muito indicado para sistemas distribuídos e sistemas que se utilizam de BigData para o processamento. 
	Como podemos observar na figura 1, diferente da escalabilidade vertical, que possuo um servidor principal que recebe o principal fluxo de dados e tarefas e possui outros processadores de menor potência para ajudar nesse processamento, o recurso horizontal, permite o volume de dados sejam divididos em pequenas porções para que sejam processados em muito servidores, porém essa forma de organização demanda uma competência técnica para que seja benéfica para a aplicação.


## CockroachDB

### 1. Criar uma ponte para que os três nós possam se conectar

`docker network create -d bridge roachnet`

### 2. Inicializar os nós do cluster

#### 2.1 Inicializar o primeiro nó do cluster

`docker run -d --name=roach1 --hostname=roach1 --net=roachnet -p 26257:26257 -p 8080:8080 -v "//c/Users/<username>/cockroach-data/roach1:/cockroach/cockroach-data" cockroachdb/cockroach:v20.2.2 start  --insecure --join=roach1,roach2,roach3`

#### 2.2 Inicializar o segundo nó do cluster

`docker run -d --name=roach2 --hostname=roach2 --net=roachnet -v "//c/Users/<username>/cockroach-data/roach2:/cockroach/cockroach-data"  cockroachdb/cockroach:v20.2.2 start --insecure --join=roach1,roach2,roach3`


#### 2.3 Inicializar o terceiro nó do cluster

`docker run -d --name=roach3 --hostname=roach3 --net=roachnet -v "//c/Users/<username>/cockroach-data/roach3:/cockroach/cockroach-data"  cockroachdb/cockroach:v20.2.2 start --insecure --join=roach1,roach3,roach3`


### 3. Inicializar o cluster com nó primário sendo o roach1

`docker exec -it roach1 ./cockroach init --insecure`

### TESTES....
