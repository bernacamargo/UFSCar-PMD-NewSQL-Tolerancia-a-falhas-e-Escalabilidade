<h1>NewSQL - Tolerância à falha e escalabilidade com CockroachDB e SingleStore</h1>
Projeto desenvolvido na disciplina de Processamento Massivo de Dados na UFSCar Sorocaba, ministrada pela Profª Drª Sahudy Montenegro

<hr>
<h2>Autores</h2>

- Bernardo Pinheiro Camargo [@bernacamargo](https://github.com/bernacamargo)
- Renata Praisler [@RenataPraisler](https://github.com/RenataPraisler)

<h2>Sumário</h2>

- [1. Objetivo](#1-objetivo)
- [2. Introdução](#2-introdução)
- [3. Estudo de caso](#3-estudo-de-caso)
  - [3.1. Testes de tolerância a falhas](#31-testes-de-tolerância-a-falhas)
  - [3.2. Testes de escalabilidade](#32-testes-de-escalabilidade)
- [4. Tecnologias habilitadoras](#4-tecnologias-habilitadoras)
- [5. Pré-requisitos](#5-pré-requisitos)
- [6. Requisitos mínimos](#6-requisitos-mínimos)
  - [6.1 CockroachDB](#61-cockroachdb)
  - [6.2 SingleStore](#62-singlestore)
- [7. Criar um Cluster Kubernetes](#7-criar-um-cluster-kubernetes)
- [8. CockroachDB](#8-cockroachdb)
  - [8.1. Deploy do Operator](#81-deploy-do-operator)
  - [8.2. Deploy do *cluster*](#82-deploy-do-cluster)
  - [8.3. Executando comandos SQL](#83-executando-comandos-sql)
  - [8.4. Testes de tolerância à falhas](#84-testes-de-tolerância-à-falhas)
  - [8.5. Testes de Escalabilidade](#85-testes-de-escalabilidade)
- [9. SingleStore](#9-singlestore)
  - [9.1. Conceitos básicos](#91-conceitos-básicos)
  - [9.2. Deploy do Operator](#92-deploy-do-operator)
  - [9.3. Deploy do Cluster](#93-deploy-do-cluster)
  - [9.4. Acessando o Cluster](#94-acessando-o-cluster)
  - [9.5. Testes de tolerância à falhas](#95-testes-de-tolerância-à-falhas)
  - [9.6. Testes de escalabilidade](#96-testes-de-escalabilidade)
- [10. Benchmark](#10-benchmark)
- [11. Conclusão](#11-conclusão)
- [12. Referências](#12-referências)
   
#
## 1. Objetivo
No contexto de bancos de dados relacionais e distribuídos, temos como objetivo deste projeto planejar e elaborar um tutorial intuitivo que permita a qualquer pessoa interessada testar e validar as características relacionadas a tolerância às falhas e escalabilidade na estrutura de NewSQL.

> Voltar ao: [Sumário](#sumário)

## 2. Introdução

Inicialmente, nos trabalhavamos apenas com os bancos relacionais, que foram criados na decada de 70 e ainda utilizamos atualmente, mas para alguns casos, isso porque hoje nos temos uma variedade de cenários em que perceberam que existia a necessidade de outra forma de estrutura e organização, já que hoje na era da web 3.0 temos que processar muitos dados, e para isso foi criado o NoSQL, que permitem uma escalabilidade mais barata e menos trabalhosa, além de ter um processamento muito maior já que realiza o processamento paralelo e para adapatar ainda mais a cenários existentes no mercado, foi criado o paradigma NewSQL.

O paradigma NewSQL surgiu como uma nova proposta, pois com o uso do NOSQL acabou apresentando alguns problemas como por exemplo: a falta, do uso de transações, das consultas SQL e a estrutura complexa por não ter uma modelagem estruturada. Ele veio com o objetivo de ter os os pontos positivos dos do modelo relacional para as arquiteturas distribuídas e aumentar o desempenhos das queries de SQL, não tendo a necessidade de servidores mais potentes para melhor execução, e utilizando a escalabilidade vertical e mantendo as propriedades ACID(Atomicidade, Consistência, Isolamento e Durabilidade).

> Voltar ao: [Sumário](#sumário)

## 3. Estudo de caso

A base de dados *Northwind* é uma base de dados modelo que foi originalmente criada pela Microsoft e utilizada para os seus tutoriais numa variedade de produtos de base de dados durante décadas. A base de dados *Northwind* contém os dados de vendas de uma empresa fictícia chamada *"Northwind Traders"*, que importa e exporta alimentos especializados de todo o mundo. É um excelente esquema de simulação para um ERP de pequenas empresas, com clientes, encomendas, inventário, compras, fornecedores, expedição, empregados, e contabilidade de entrada única. 

O conjunto de dados inclui as seguintes tabelas:

- *Suppliers:* Fornecedores e vendedores de *Northwind*
- *Customers:* Clientes que compram produtos da *Northwind*
- *Employees:* Detalhes dos empregados dos comerciantes de *Northwind*
- *Products:* Informação sobre produtos
- *Shippers:* Os detalhes dos expedidores que enviam os produtos dos comerciantes para os clientes finais
- *Orders e Order_Details:* Transações de ordens de venda que ocorrem entre os clientes e a empresa

A seguir o diagrama de relacionamento das tabelas:

![](https://docs.yugabyte.com/images/sample-data/northwind/northwind-er-diagram.png)

<center>
  <sub>Figura 1: Diagrama de relacionamento do banco Northwind<</sub>
</center>
<br>

Os arquivos para importação da estrutura das tabelas e seus dados estão na pasta `database`
- [database/northwind-tables](https://raw.githubusercontent.com/bernacamargo/UFSCar-PMD-NewSQL-Tolerancia-a-falhas-e-Escalabilidade/main/database/northwind-tables.sql)
- [database/northwind-data](https://raw.githubusercontent.com/bernacamargo/UFSCar-PMD-NewSQL-Tolerancia-a-falhas-e-Escalabilidade/main/database/northwind-data.sql)

> Nota: Os dados foram obtidos no https://github.com/jpwhite3/northwind-MySQL e https://github.com/pthom/northwind_psql/

Utilizando esses dados iremos criar um cenário para executar os testes descritos abaixo:

### 3.1. Testes de tolerância a falhas

  A tolerância à falhas tem como objetivo impedir que alguma mudança da nossa base de dados seja perdida por conta de algum problema, com isso é realizado o método de replicação para que todos os nós tenham as mudanças realizadas, e assim caso um nó tenha algum problema, o outro nó do sistema terá as informações consistentes. 

  Sabendo disso, vamos simular alguns casos para você perceber o este funcionamento. 
  Antes de simular uma falha do nó, vamos passar pelo conceito da replicação na prática, para isso vamos efeturar uma operação de atualização(*UPDATE*) em um nó e verificar o que acontece com os outros nós. 

### 3.2. Testes de escalabilidade

  Para o escalonamento do nosso *cluster*, utilizaremos a escalabilidade horizontal, que consiste em utilizar mais equipamentos e existe a partionalização dos dados de acordo com os critérios de cada projeto, diferente do vertical, que consiste em aumentar a capacidade da máquina, porém no horizontal também temos o aumento de capacidade de memória e de processamento, mas isso terá o impacto pela soma das máquinas em funcionamento. 

  Para entender o motivo que precisamos realizar este escalonamento, vamos supor que existe uma necessidade de processamento maior dos dados num período de tempo, como por exemplo a *black friday* (data em novemembro em que o comércio realiza descontos em cima de produtos), para isso seja necessário um aumento de quantidade de máquina para que não tenha impacto no processamento para o cliente final, mas em outras datas não tenha o mesmo volume de acesso, então podemos reduzir também nossas pods para que tenha uma redução no valor de processamento. 

  Todas essas ações são necessários estudos e estragégias que vão depender do propósito e abordagem desejada para cada projeto, por isso é importante se aprofundar para analisar os impactos positivos de cada ação, para que isso não atinja o usuário final.

> Voltar ao: [Sumário](#sumário)

## 4. Tecnologias habilitadoras

- [Kubernetes](#12-referências);
- [Docker](#12-referências);
- [Google Kubernetes Engine (GKE)](#12-referências);
- [CockroachDB](#12-referências);
- [SingleStore](#12-referências);

> Voltar ao: [Sumário](#sumário)

## 5. Pré-requisitos

Antes de começarmos, é necessário que você atente-se à alguns detalhes considerados como pré-requisitos deste tutorial.

- Acesso a internet;
- Conhecimentos básicos em SQL, Kubernetes, Docker e Google Cloud;
- Conta no Google Cloud com créditos;

> Voltar ao: [Sumário](#sumário)

## 6. Requisitos mínimos

### 6.1 CockroachDB

  RECURSO | VALOR
  ------- | -------
  Nós do cluster | 3
  CPU   | 2 núcleos de vCPU por nó
  Memória | No mínimo 4GB por núcleo de vCPU
  Armazenamento | Cada nó deve ter pelo menos 150GB por núcleo de vCPU

<center>
  <sub>Tabela 1: Recomendações de configurações para o cluster CockroachDB</sub>
</center>
<br>

<br>

### 6.2 SingleStore
  
  RECURSO | VALOR
  ------- | -------
  Nós do cluster | 3
  CPU   | 4 núcleos de vCPU por nó
  Memória | No mínimo 4GB por núcleo de vCPU
  Armazenamento | Pelo menos 3 vezes a quantidade de memória RAM
  
<center>
  <sub>Tabela 2: Recomendações de configurações para o cluster SingleStore</sub>
</center>
<br>

> Nota: Para calcular os requisitos mínimos para o host do cluster basta multiplicar o recurso pela quantidade de nós.

 > Voltar ao: [Sumário](#sumário)


## 7. Criar um Cluster Kubernetes

Para podermos simular um ambiente isolado e que garanta as características de sistemas distribuídos utilizaremos um *cluster* local orquestrado pelo Kubernetes, o qual é responsável por gerenciar instâncias de máquinas virtuais para execução de aplicativos em containers. 

Neste projeto utilizaremos o GKE para gerenciar e hospedar nossos dois *clusters* Kubernetes, contudo é possível realizar o procedimento com qualquer outra vertente de *cluster*, como AWS, Microsoft Azure ou um *cluster* local. Atente-se nas configurações mínimas para executar cada aplicação.

Primeiramente precisamos criar nosso *cluster* no GKE:

- Acesse a [Google Cloud Console](https://console.cloud.google.com)
- No menu da esqueda, navegue até `Kubernetes Engine` e clique em `Clusters`;
- Clique em `Criar cluster` no centro da janela;
- Defina o nome do *cluster*;
- Configure a quantidade de recursos do *cluster*;
  - Clique em `Pools dos nós` para expandir o menu;
  - Clique em `Nós`;
  - Procure pelo campo `Tipo de máquina` e clique para expandir as opções;
  -  Agora basta selecionar a opção que contempla os requisitos dos softwares utilizados;
- Clique em `Criar`.
  

Feito isso, um *cluster* com três nós será criado e inicializado. Em alguns momentos você já poderá acessá-lo para seguirmos com as configurações.

> Para ambos os softwares CockroachDB e SingleStore utilizaremos o mesmo processo para inicialização do *cluster* kubernetes, porém em *clusters* com configurações diferentes.

> Voltar ao: [Sumário](#sumário)

#
## 8. CockroachDB

Antes de iniciar os testes, temos que configurar o CockroachDB no nosso *cluster* e para nos auxiliar utilizamos a documentações do [CockroachDB](#12-referências), [Kubernetes](#12-referências), e [Google Cloud](#12-referências). Abaixo citaremos os comandos que devem ser realizados.

Para configurar a aplicação do CockroachDB dentro do *cluster* podemos fazer de algumas formas:
- Usando o Operator
- Usando o Helm
- Usando arquivos de configurações sem ferramentas automatizadoras.

Neste projeto utilizaremos o [Kubernetes Operator](#12-referências) fornecido pelo CockroachDB, pois ele irá automatizar diversas configuração do *cluster*.

>Nota: É importante notar que temos um *cluster* kubernetes, composto de três instâncias de máquina virtual (1 *master* e 2 *workers*), onde as *pods* são alocadas e cada uma representa um nó do CockroachDB que está executando. Dessa forma quando falamos sobre os nós do CockroachDB estamos nos referindo as *pods* e quando falamos dos nós do *cluster* estamos falando das instâncias de máquina virtual do Kubernetes.

### 8.1. Deploy do Operator

- Definir as autorizações para o Operator gerenciar o *cluster*

  ```shell
  $ kubectl apply -f cockroachdb/operator-rbac.yaml
  ```
      role.rbac.authorization.k8s.io/cockroach-operator-role created
      rolebinding.rbac.authorization.k8s.io/cockroach-operator-rolebinding created
      clusterrole.rbac.authorization.k8s.io/cockroach-operator-role created
      serviceaccount/cockroach-operator-sa created
      clusterrolebinding.rbac.authorization.k8s.io/cockroach-operator-default created

- Criar o *CustomResourceDefinition* (CRD) para o Operator

  ```shell
  $ kubectl apply -f cockroachdb/operator-crd.yaml
  ```

  O retorno esperado é:

      customresourcedefinition.apiextensions.k8s.io/crdbclusters.crdb.cockroachlabs.com created

  > Nota: É interessante notar que o operator irá ser executado como uma *pod* do *cluster*.

- Criar o *Controller* do *Operator*

  ```shell
  $ kubectl apply -f cockroachdb/operator-deploy.yaml
  ```
      
  O retorno esperado é:

      deployment.apps/cockroach-operator created

- Validar se o *Operator* está executando

  ```shell
  $ kubectl get pods
  ``` 
  Caso tenha funcionado, você deverá ter como retorno a seguinte mensagem:

      NAME                                 READY   STATUS    RESTARTS   AGE
      cockroach-operator-6867445556-9x6zp   1/1    Running      0      2m51s

  > Nota: Caso o *status* da *pod* estiver como *"ContainerCreating"* é só aguardar alguns instantes que o kubernetes esta iniciando o *container* e logo deverá aparecer como *"Running"*.

### 8.2. Deploy do *cluster*
  
- Abra o arquivo `cockroachdb-cluster.yaml` com um editor de texto
- Vamos configurar a quantidade de CPU e memoria para cada *pod* do *cluster*. Basta procurar no arquivo pelo código abaixo, descomentar as linhas e alterar os valores de `cpu` e `memory`, seguindo a regra de 4GB de memória RAM para cada um núcleo de CPU.

  ```yaml
  resources:
      requests:
          cpu: "2"
          memory: "8Gi"
          
      limits:
          cpu: "2"
          memory: "8Gi"
  ```
  Esta etapa é opcional, porém extremamente [recomendada em ambientes de produção](#12-referências).

  > Nota: Caso não defina nenhum valor inicial a aplicação extendera seus limites de uso de cpu/memoria até o limite do nó do *cluster*. 
          
- Modifique a quantidade de armazenamento cada *pod* terá, altere o valor do campo `storage` seguindo a regra de 150GB por núcleo de CPU.
  ```yaml
  resources:
      requests:
          storage: "300Gi"
  ```

- Aplique as configurações feitas no arquivo `cockroachdb-cluster.yaml`.

  ```shell
  $ kubectl apply -f cockroachdb/cockroachdb-cluster.yaml
  ```

  O retorno esperado é:

      crdbcluster.crdb.cockroachlabs.com/CockroachDB created    

  > Nota: Este arquivo irá solicitar para o *Operador* que crie uma aplicação *StatefulSet* com três *pods* que funcionarão como um *cluster* CockroachDB.

- Aguarde alguns minutos e verifique se as *pods* estão sendo executadas.

  ```shell
  $ kubectl get pods
  ```

  O retorno esperado é:

      NAME                                  READY   STATUS    RESTARTS   AGE
      cockroach-operator-6867445556-9x6zp   1/1     Running   0          43m
      cockroachdb-0                         1/1     Running   0          2m29s
      cockroachdb-1                         1/1     Running   0          104s
      cockroachdb-2                         1/1     Running   0          67s
      

### 8.3. Executando comandos SQL

Feito isso, já temos nosso *cluster* e nossa aplicação configurados e executando, temos que popular nosso banco de dados para realizar os testes. 

- Acesse o bash de uma das *pods* que estão executando a aplicação

  ```shell
  $ kubectl exec -it cockroachdb-2 -- bash
  ```

  > Nota: Para alterar qual pod voce está acessando basta alterar a parte do comando `cockroachdb-2` para o nome da pod que você deseja acessar.

- Dentro da pod inicialize o [built-in SQL client](#12-referências) do *cockroach*

  ```shell
  $ cockroach sql --certs-dir cockroach-certs
  ```

  ```shell
  #
  # Welcome to the CockroachDB SQL shell.
  # All statements must be terminated by a semicolon.
  # To exit, type: \q.
  #
  # Server version: CockroachDB CCL v20.2.0 (x86_64-unknown-linux-gnu,
  built 2020/11/09 16:01:45, go1.13.14) (same version as client)
  # Cluster ID: ff66ae62-8a67-4e24-a636-ce5f5fd2607d
  #
  root@:26257/defaultdb>
  ```

  A partir deste momento, já é possível executar comandos SQL diretamente em nossas aplicações do CockroachDB.

- Crie o banco de dados

  ```sql
  CREATE DATABASE northwind;
  ```

- Importe o banco de dados
  
  Abra o arquivo `database/cockroachdb-northwind-tables.sql`, copie a estrutura das tabelas e cole no terminal aberto no passo anterior. Repita o mesmo processo para o arquivo `database/cockroachdb-northwind-data.sql`.

### 8.4. Testes de tolerância à falhas

>Nota: É importante ressaltar que temos um *cluster* kubernetes, composto de três instâncias de máquinas virtuais (3 *workers*), onde as pods são executadas e cada *pod* representa um nó do CockroachDB. Dessa forma quando falamos sobre os nós do CockroachDB estamos nos referindo as *pods* e quando falamos dos nós do *cluster* estamos nos referindo as instâncias de máquina virtual do Kubernetes.
    
- Replicação de dados

  Primeiramente faça a importação dos arquivos disponibilizados na pasta [database](https://github.com/bernacamargo/UFSCar-PMD-NewSQL-Tolerancia-a-falhas-e-Escalabilidade/tree/main/database). 
  
  Vamos verificar como está o dado que desejamos modificar, execute o seguinte comando SQL para busca-lo na tabela `suppliers`.

  ```sql
  SELECT supplier_id, company_name, city, country 
  FROM northwind.suppliers
  WHERE supplier_id = 1;
  ```

  O retorno deve ser

        supplier_id |  company_name  |  city  | country
      --------------+----------------+--------+----------
                  1 | Exotic Liquids | London | UK
  Execute o comando abaixo para realizar a alteração no nó 2. 

  ```sql
  UPDATE suppliers 
  SET city='Indaiatuba', country='BR' 
  WHERE  supplier_id = 1;  
  ```

  Agora acesse o nó 1, repetindo os passos da etapa [3](https://github.com/bernacamargo/PMD-tutorial#3-executando-comandos-sql-na-pod), e após entrar no build-in SQL, execute novamente a consulta abaixo
  
  ```sql
  SELECT supplier_id, company_name, city, country 
  FROM northwind.suppliers
  WHERE supplier_id = 1;
  ```
    O retorno deve ser

        supplier_id |  company_name  |    city    | country
      --------------+----------------+------------+----------
                  1 | Exotic Liquids | Indaiatuba | BR

  Como podemos observar, a atualização foi realizada e também foi replicada para as outras *pods*. Dessa forma podemos realizar este mesmo teste com as outras pods e veremos que todas estão sincronizadas.

- Simulando a falha de uma *pod*.
   
  Vamos deletar um nó do CockroachDB utilizando o comando abaixo:
    
  ```shell
  $ kubectl delete pod cockroachdb-2
  ```
          
  Você terá o retorno que o nó foi deletado.  

      pod "cockroachdb-2" deleted

  O que é interessante, é que no arquivo `cockroachdb-cluster.yaml`, definimos que teremos `3 nodes` executando o CockroachDB. Então quando deletamos o nó 2, o Kubernets irá verificar que o nó 2 teve uma falha, e  automaticamente reiciciará a *pod* e atualizará os dados baseados nos outros nós.

  Executando esse comando no terminal, verificamos que a *pod* já foi reiniciada e esta com o **status: Running**. 
          
  ```shell
  $ kubectl get pod cockroachdb-2
  ```

      NAME            READY     STATUS    RESTARTS   AGE
      cockroachdb-2   1/1       Running   0          15s
  
### 8.5. Testes de Escalabilidade 

- Modificar o número de nós do CockroachDB

  Nesta etapa iremos editar a quantidade de `nodes` que nossa aplicação do CockroachDB irá se sustentar.

  Primeiramente abra o arquivo `cockroachdb-cluster.yaml`

  ```shell
  $ vim cockroachdb-cluster.yaml
  ```

  Agora altere a última linha que explicita o número de nodes da aplicação e defina para **5** o valor dos `nodes`

  O arquivo alterado deve ficar da seguinte forma:

  ```yaml
  .
  .
  .
  tlsEnabled: true
  image:
      name: cockroachdb/cockroach:v20.2.0
  nodes: 5
  ```

  Com o arquivo salvo, podemos executar o deploy da aplicação novamente com o comando

  ```shell
  $ kubectl apply -f cockroachdb-cluster.yaml
  ```

  O retorno deve ser parecido com o seguinte:

      crdbcluster.crdb.cockroachlabs.com/CockroachDB configured

  >Nota: O comando `apply` do Kubernetes permite que alteremos a configuração inicial da aplicação do CockroachDB sem que seja necessário reinicia-la.

  Podemos verificar que nossa aplicação foi escalonada através das *pods* existentes

  ```shell
  $ kubectl get pods
  ```

  O retorno deve ser parecido com o seguinte:

      NAME                                  READY   STATUS    RESTARTS   AGE
      cockroach-operator-6867445556-5ll4v   1/1     Running   0          154m
      cockroachdb-0                         1/1     Running   0          152m
      cockroachdb-1                         1/1     Running   0          151m
      cockroachdb-2                         1/1     Running   0          150m
      cockroachdb-3                         1/1     Running   0          15m
      cockroachdb-4                         1/1     Running   0          15m

  Dessa forma todas as requisições feitas à aplicação serão diluídas em mais dois nós (cockroachdb-3 e cockroachdb-4).

  >Nota: Para realizar a redução na quantidade de nós basta refazer o procedimento explicado acima diminuindo o número de nós. 
  
  > Voltar ao: [Sumário](#sumário)

#
## 9. SingleStore

Nesta etapa vamos definir e executar as configurações de deploy do SingleStore em um *cluster* Kubernetes gerenciado pelo GKE, para assim podermos realizar os testes de escalabilidade e tolerância à falhas.

> Nota: importante se atentar que a estrutura é composta em dois níveis: nós agregadores e nós folhas.

### 9.1. Conceitos básicos
Primeiramente precisamos criar nosso cluster e utilizaremos o GKE para isto:

- Acesse a [Google Cloud Console](https://console.cloud.google.com)
- Navegue até o `Kubernetes Engine` e clique em `Clusters`;
- Clique em `Criar cluster` no centro da janela;
- Defina o nome do cluster e clique em `Criar`.

Feito isso, um *cluster* com três nós será criado e inicializado. Em alguns momentos você já poderá acessá-lo para seguirmos com as configurações.

> Nota: o teste foi realizado com o *cluster* com as configurações mínimas para rodar o *software* e que os testes serem realizadas. 

### 9.2. Deploy do Operator

- [operator-rbac.yaml](https://github.com/bernacamargo/UFSCar-PMD-NewSQL-Tolerancia-a-falhas-e-Escalabilidade/blob/main/singlestore/operator-rbac.yaml)

  Essa configuração irá criar a definição de um *ServiceAccount* para o MemSQL *Operator* utilizar.
  ```shell
  $ kubectl apply -f singlestore/operator-rbac.yaml
  ```

      serviceaccount/memsql-operator created
      role.rbac.authorization.k8s.io/memsql-operator created
      rolebinding.rbac.authorization.k8s.io/memsql-operator created

- [operator-crd.yaml](https://github.com/bernacamargo/UFSCar-PMD-NewSQL-Tolerancia-a-falhas-e-Escalabilidade/blob/main/singlestore/operator-crd.yaml)

  Define um recurso específico *MemSQLCluster* como um tipo de recurso para ser utilizado pelo *Operator*.

  ```shell
  $ kubectl apply -f singlestore/operator-crd.yaml
  ```
      customresourcedefinition.apiextensions.k8s.io/memsqlclusters.memsql.com created

- [operator-deploy.yaml](https://github.com/bernacamargo/UFSCar-PMD-NewSQL-Tolerancia-a-falhas-e-Escalabilidade/blob/main/singlestore/operator-deploy.yaml)

  Realiza o deploy do *Operator*, iniciando uma pod para executa-lo.
  ```shell
    $ kubectl apply -f singlestore/operator-deploy.yaml
    ```

        deployment.apps/memsql-operator created
  > Nota: Neste projeto a imagem utilizada para a criação do *container do operator* é a `memsql/operator:1.2.3-centos-ef2b8561` disponibilizada no Docker Hub pelo SingleScore.

### 9.3. Deploy do cluster

Esta é a configuração principal do nosso *cluster*, é através do arquivo `singlestore-cluster.yaml` que iremos definir se nosso *cluster* será replicado e também a quantidade de recursos alocados para cada nó.

```yaml
apiVersion: memsql.com/v1alpha1
kind: MemsqlCluster
metadata:
  name: memsql-cluster
spec:
  license: LICENSE_KEY
  adminHashedPassword: "*6BB4837EB74329105EE4568DDA7DC67ED2CA2AD9"
  nodeImage:
    repository: memsql/node
    tag: centos-7.3.2-a364d4b31f

  redundancyLevel: 1

  serviceSpec:
    objectMetaOverrides:
      labels:
        custom: label
      annotations:
        custom: annotations

  aggregatorSpec:
    count: 1
    height: 0.5
    storageGB: 25
    storageClass: standard

    objectMetaOverrides:
      annotations:
        optional: annotation
      labels:
        optional: label

  leafSpec:
    count: 2
    height: 0.5
    storageGB: 25
    storageClass: standard

    objectMetaOverrides:
      annotations:
        optional: annotation
      labels:
        optional: label
```

Neste arquivo você precisará fazer algumas alterações:

- Altere o campo `name` para o nome do seu *cluster*;
- Altere o campo `license` e substitua `LICENSE_KEY` pela sua [licença do SingleStore](https://portal.SingleStore.com/licenses);
- Defina no campo `adminHashedPassword` sua senha encriptografada para o usuário `admin`
O hash existente no arquivo representa a senha `123456`, o qual utilizaremos para esse tutorial. Caso queira criar uma senha utilize o seguinte algoritmo:
  ```python
  from hashlib import sha1
  print("*" + sha1(sha1('secretpass').digest()).hexdigest().upper())
  ```
- Altere o campo `redundancyLevel` para `2` caso deseje ativar o recruso de [Alta Disponibilidade](https://docs.SingleStore.com/v7.3/guides/cluster-management/high-availability-and-disaster-recovery/managing-high-availability/managing-high-availability/);
- Altere os campos `count` para aumentar ou diminuir a quantidade de nós agregadores ou folha;
- O campo `height` define a quantidade de núcleos de CPU e memória RAM serão separados para o nó. O valor `1` representa a quantidade recomendada: `8 núcleos CPU e 32GB RAM`. O menor valor possível é `0.5` que representa metade da quantidade recomendada, ou seja, `4 núcleos CPU e 16GB RAM`;
- Os campos `storageGB` definem a quantidade de armazenamento que será solicitado para cada volume persistente nos nós.


- Aguarde a *pod* chamada "memsql-operator" ter seu *status* como `Running`

  ```shell
  $ kubectl get pods
  ```
      NAME                               READY   STATUS    RESTARTS   AGE
      memsql-operator-5f4b595f89-hfqzt   1/1     Running   0          14s

- Realizar o deploy do *cluster* MemSQL.

  ```shell
  $ kubectl apply -f singlestore/singlestore-cluster.yaml
  ```
      memsqlcluster.memsql.com/memsql-cluster created

  Verifique se os nós foram iniciados corretamente

  ```shell
  $ kubectl get pods
  ```

      NAME                               READY   STATUS    RESTARTS   AGE
      memsql-operator-5f4b595f89-hfqzt   1/1     Running   0          110s
      node-memsql-cluster-leaf-ag1-0     2/2     Running   0          54s
      node-memsql-cluster-leaf-ag1-1     2/2     Running   0          54s
      node-memsql-cluster-master-0       2/2     Running   0          54s

  A partir deste ponto já temos nosso cluster SingleStore configurado e funcionando, dessa forma já podemos iniciar os testes com *querys* SQL básicas.

> Nota: Todos os arquivos .yaml acima também estão disponiveis na [SingleStore: Deploy Kubernetes - Create the Object Definition Files](#12-referências).

### 9.4. Acessando o Cluster

- Verificar os serviços criados no *deploy*

  ```shell
  $ kubectl get pods
  ```
      NAME                     TYPE           CLUSTER-IP     EXTERNAL-IP     PORT(S)          AGE
      kubernetes               ClusterIP      10.120.0.1     <none>          443/TCP          10m
      svc-memsql-cluster       ClusterIP      None           <none>          3306/TCP         3m16s
      svc-memsql-cluster-ddl   LoadBalancer   10.120.7.169   35.247.216.80   3306:32748/TCP   3m16s

  Existem três serviços sendo executados em nosso *cluster* Kubernetes, contudo o que nos importa agora é o que possue o `TYPE` de `LoadBalancer`, chamado `svc-memsql-cluster-ddl`. 
  Este serviço é responsável por encaminhar as requisições recebidas no seu IP externo para as *pods* do *cluster*, no caso, para os nós do nosso *cluster*. 

  Analisando o retorno do último comando, temos que o `host` do nosso serviço de banco de dados é `35.247.216.80` e que a `porta` é a `3306`.

- Acesse o banco de dados

  > Nota: Para continuar é necessário que você tenha o MySQL instalado em sua máquina.

  Como já temos nossas credenciais, podemos iniciar a conexão com o serviço. Para isso basta acessar via bash ou qualquer interface utilizando os seguintes dados:

      HOST              PORTA         USUÁRIO         SENHA
      35.247.216.80     3306          admin           123456

  ```shell
  $ mysql -u admin -h 35.247.216.80 -p
  ```

  Após executar este comando irá aparecer para inserir a senha do usuário, faça isso e deverá ter acesso ao servidor.

      Welcome to the MySQL monitor.  Commands end with ; or \g.
      Your MySQL connection id is 1203
      Server version: 5.5.58 MemSQL source distribution (compatible; MySQL Enterprise & MySQL Commercial)

      Copyright (c) 2000, 2020, Oracle and/or its affiliates. All rights reserved.

      Oracle is a registered trademark of Oracle Corporation and/or its
      affiliates. Other names may be trademarks of their respective
      owners.

      Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

      mysql>

  Agora podemos executar nossos comandos SQL dentro do *cluster*.

- Crie o banco de dados

  ```sql
  CREATE DATABASE northwind;
  ```

- Importe o banco de dados
  
  Abra o arquivo `database/singlestore-northwind-tables.sql`, copie a estrutura das tabelas e cole no terminal aberto no passo anterior. Repita o mesmo processo para o arquivo `database/singlestore-northwind-data.sql`.


### 9.5. Testes de tolerância à falhas


- Simulando a falha de um nó.
   
  Após nos termos populado nosso banco pelo nosso nó *master*, nós vamos deletar o nosso nó master com o comando abaixo:
    
  ```shell
  $ kubectl delete pods node-memsql-cluster-master-0
  ```
  Você terá o retorno que o nó foi deletado.  

      pod "node-memsql-cluster-master-0" deleted

  Logo em seguida verifique o *status* das *pods*

  ```shell
  $ kubectl get pods
  ```

      NAME                               READY   STATUS        RESTARTS   AGE
      memsql-operator-5f4b595f89-49q9k   1/1     Running       0          69m
      node-memsql-cluster-leaf-ag1-0     2/2     Running       0          68m
      node-memsql-cluster-leaf-ag1-1     2/2     Running       0          68m
      node-memsql-cluster-master-0       2/2     Terminating   0          40m

  Quando deletamos o nó, o *Operator* do *cluster* irá reiniciar o nó automáticamente copiando as informações do nós folhas, ou seja, irá recriar o banco atraves das partições. 

  Se rodarmos esse comando no terminal, verificamos que a *pod* já foi reiniciada e esta com o  **status: Running** . 

  ```shell
  $ kubectl get pods
  ```

      NAME                               READY   STATUS    RESTARTS   AGE
      memsql-operator-5f4b595f89-49q9k   1/1     Running   0          70m
      node-memsql-cluster-leaf-ag1-0     2/2     Running   0          69m
      node-memsql-cluster-leaf-ag1-1     2/2     Running   0          69m
      node-memsql-cluster-master-0       2/2     Running   0          53s

  Agora vamos acessar o banco de dados novamente e verificar se os dados ainda existem.

  ```shell
  $ kubectl exec -it node-memsql-cluster-master-0 -- memsql -u admin -p
  ```

  ```sql
  SELECT id, company, first_name, last_name, city, state_province 
  FROM northwind.suppliers 
  WHERE id = 1;
  ```

  O retorno deve ser

      +----+------------+--------------+-----------+------+----------------+
      | id | company    | first_name   | last_name | city | state_province |
      +----+------------+--------------+-----------+------+----------------+
      |  1 | Supplier A | Elizabeth A. | Andersen  | NULL | NULL           |
      +----+------------+--------------+-----------+------+----------------+


#
### 9.6. Testes de escalabilidade

Primeiramente precisamos abrir o arquivo `singlestore-cluster.yaml`, pois é neste que iremos realizar as configurações de escalabilidade.

```yaml
.
.
.
  redundancyLevel: 1

  serviceSpec:
    objectMetaOverrides:
      labels:
        custom: label
      annotations:
        custom: annotations

  aggregatorSpec:
    count: 1
    height: 0.5
    storageGB: 25
    storageClass: standard

    objectMetaOverrides:
      annotations:
        optional: annotation
      labels:
        optional: label

  leafSpec:
    count: 2
    height: 0.5
    storageGB: 25
    storageClass: standard

    objectMetaOverrides:
      annotations:
        optional: annotation
      labels:
        optional: label
```
Este é o trecho de código que iremos modificar para podermos testar a escalabilidade do *cluster*. A seguir temos as opções disponíveis:

- Alta Disponibilidade:
  
  No inicio temos o campo `redundancyLevel`, este é responsável por ativar a `Alta Disponibilidade`, que irá criar no mesmo *cluster* outro conjunto de nós agregadores que atuaram apenas como replicas do primeiro conjunto de nós. Neste tutorial não iremos abordar esta função, pois será necessário uma infraestrutura muito mais potente.

  > Nota: Quando o modo de Alta Disponibilidade está ativado, todos os nós do *cluster* são duplicados, assim como a solicitação de recursos.

- Aumentando/Diminuindo o número de nós do *cluster*

  Para podermos realizar o escalonamento horizontal de nosso *cluster*, precisamos adicionar mais nós para ele. Assim precisaremos apenas alterar os campos de `aggregatorSpec.count` e `leafSpec.count`, sendo a quantidade de nós do agregador(master) e de seus nós folha, respectivamente.

- Aumentando/Diminuindo o armazenamento dos nós

  Para modificarmos a capacidade de armazenamento de nossos nós, basta que alteremos os valores dos campos de `aggregatorSpec.storageGB` e `leafSpec.storageGB`, sendo a quantidade em GigaBytes de capacidade de armazenamento nós do agregador(master) e de seus nós folha, respectivamente.

- Aumentando/Diminuindo a quantidade de núcleos de CPU e da Memória RAM de cada nó

  Para podermos dar mais potência para nossos nós utilizaremos a propriedade `height`, a qual recebe um valor inteiro e representa um multiplicador para uma quantidade fixa de vCPU e memória ram. Dessa forma temos que o valor `1` representa a quantidade de 8 núcleos de CPU e 32GB de memória RAM.

  > Nota: O menor valor aceitável para o campo `height` é 0.5, ou seja, para cada nó é necessário no mínimo 4 núcleos de CPU e 16GB de memória RAM.

- Aplicando as alterações

  Para realizar o *deploy* do *cluster* com a nova configuração basta realizar o commando `apply` novamente.

  ```shell
  $ kubectl apply -f singlestore/singlestore-cluster.yaml
  ```
      memsqlcluster.memsql.com/memsql-cluster configured

> Voltar ao: [Sumário](#sumário)

## 10. Benchmark

Antes da escolha dos softwares que usariamos dentro deste projeto, nos buscamos *benchmarks* para escolher o que mais se encaixava, com isso nós levantamos algumas coisas que seriam essenciais que foram: uma boa documentação que contesse vídeos e bons exemplos, gratuitos ou até mesmo com um valor alto de créditos para testes iniciais e gostariamos que os *softwares* entre si tivessem alguma diferência significativa. 

Após esses critérios criados, nos escolhemos o cockroachdb e o single store(antigo MemSQL).

O cockroachdb nos chamou atenção por ser um banco de dados *open-source* e possui em sua versão gratuita *Core*. O banco tem como objetivo rodar em um computador pessoal comum, ser consistente e escalável, mas ele não utiliza o armazenamento em memória principal, ele utiliza a estrutura de *clocks* atômicos e possui outras camadas de estrutura: *SQL Layer*, *Transaction Layer* (que garante as propriedades **ACID**), *Distribution Layer*, *Replication Layer* e *Storage Layer*. 

Já o MemSQL já nos chamou atenção, pois diferente do cockroachdb, ele tem o armazenamento na memória principal e sua estrutura é composta em dois níveis: nós agregadores e nós folhas, porém ela contem algumas barreiras na questão gratuita, isso porque a versão *Developer* não é recomendada para ambientes de produção e possui algumas limitações de recursos, e também possui uma dependência de uma infraestrutura com grande poder de processamento. 

Agora vamos apresentar algumas comparações entre eles.

Como no caso das operações das latências das operações de atualização, inserção e remoção retirado do benckmark dos autores [Karambir Kaur e Monika Sachdeva](#12-referências)

![Tabela3: Retirada do Benckmark - Médias de parâmetro em segundos](https://i.ibb.co/WsNPftR/image.png)

<center>
  <sub>Figura 2: Benckmark - Médias de parâmetro em segundos</sub>
</center>
<br>


>Nota: a tabela está com o nome antigo do SingleStore.

Outra comparação entre eles importante para o nosso trabalho, foi o uso de recursos em que citamos no item [Requisitos mínimos](#6-requisitos-mínimos), retirados da [documentação dos softwares](#12-referências).

RECURSO | VALOR
  ------- | -------
  Nós do cluster | 3
  CPU   | 2 núcleos de vCPU por nó
  Memória | No mínimo 4GB por núcleo de vCPU
  Armazenamento | Cada nó deve ter pelo menos 150GB por núcleo de vCPU

<center>
  <sub>Tabela 1: Recomendações de configurações para o cluster CockroachDB</sub>
</center>


  RECURSO | VALOR
  ------- | -------
  Nós do cluster | 3
  CPU   | 4 núcleos de vCPU por nó
  Memória | No mínimo 4GB por núcleo de vCPU
  Armazenamento | Pelo menos 3 vezes a quantidade de memória RAM
  
<center>
  <sub>Tabela 2: Recomendações de configurações para o cluster SingleStore</sub>
</center>
<br>

Como podemos observar nas tabelas acima, o SingleStore necessita do dobro de CPU e também muito mais armazenamento, o que é uma diferença bem grande, tanto para casos pequenos mas pricipalmente em maiores escalas.

> Voltar ao: [Sumário](#sumário)

## 11. Conclusão

Quando iniciamos o projeto já sabiamos que ele seria desafiador, pois muito mais do que a prática envolvida teriamos que provar e exemplificar através dos testes os conceitos e definições tanto do NewSQL como também as particularidades de cada *software*, do kubernetes que escolhemos para nos auxiliar e o *google cloud*, que foi na nossa escolha tanto pela documentação que existe, quanto também com a quantidade de créditos que eles dão para o teste gratuito.

Durante o processo tivemos que realizar algumas escolhas, como por exemplo, deixar de simular de maneira local da nossa máquina e partir para o *cloud*, e com isso tivemos dificuldade com as configurações mínimas de *hardware*, em particularidade do SingleStore, antigo MemSQL, e assim os cenários que nós imaginavamos que seria o ideal para os testes acabou que teve que ser adaptado para conseguirmos entregar o projeto de acordo com as expectativas.

Com esse trabalho, por fim, finalizamos o projeto com grande aprendizado dos conceitos de tolerância à falhas e escalabilidade e também com um conceito mais básico e prático do funcionamento da *cloud*. 

> Voltar ao: [Sumário](#sumário)

## 12. Referências

- COCKROACH LABS. [CockroachDB: Architecture Overview](https://www.cockroachlabs.com/docs/v20.1/architecture/). Cockroach Labs, 2020.
- COCKROACH LABS. [CockroachDB: Orchestrate a Local Cluster with Kubernetes](https://www.cockroachlabs.com/docs/stable/orchestrate-a-local-cluster-with-kubernetes.html). Cockroach Labs, 2020.
- COCKROACH LABS. [CockroachDB: Production Checklist](https://www.cockroachlabs.com/docs/stable/recommended-production-settings.html). Cockroach Labs, 2020.
- COCKROACH LABS. [CockroachDB: Production Checklist - Orchestration / Kubernetes](https://www.cockroachlabs.com/docs/v20.2/recommended-production-settings.html#orchestration-kubernetes). Cockroach Labs, 2020.
- COCKROACH LABS. [CockroachDB: Cockroach built-in SQL](https://www.cockroachlabs.com/docs/v20.2/cockroach-sql). Cockroach Labs, 2020.

- KUBERNETES. [Kubernetes: Padrão Operador](https://kubernetes.io/pt/docs/concepts/extend-kubernetes/operator/). Kubernetes, 2020.
- KUBERNETES. [Kubernetes: Documentation](https://kubernetes.io/docs/home/). Kubernetes, 2020.

- DOCKER. [Docker: Documentations](https://docs.docker.com/).

- GOOGLE. [Google Kubernetes Engine (GKE)](https://cloud.google.com/kubernetes-engine/). Google, 2020.

- GITHUB. [pthom/northwind_psql](https://github.com/pthom/northwind_psql). Pascal Thomet, 2020.
- GITHUB. [pwhite3/northwind-MySQL](https://github.com/jpwhite3/northwind-MySQL). JP White, 2020.

- SINGLESTORE. [SingleStore: Documentation](https://docs.singlestore.com/v7.3/guides/overview/). SingleStore, 2020.
- SINGLESTORE. [SingleStore: Deploy Kubernetes - Create the Object Definition Files](https://docs.SingleStore.com/v7.3/guides/deploy-memsql/self-managed/kubernetes/step-3/). SingleStore, 2020.
- SINGLESTORE. [SingleStore: Learn how to manage a SingleStore DB cluster](https://docs.singlestore.com/v7.3/guides/cluster-management/). SingleStore, 2020.

- IEEE XPLORE. [Performance evaluation of NewSQL databases](https://ieeexplore.ieee.org/document/8068585). Karambir Kaur; Monika Sachdeva, 2017.

- Kiswono Prayogo . [Huge List of Database Benchmark](http://kokizzu.blogspot.com/2019/04/huge-list-of-database-benchmark.html)