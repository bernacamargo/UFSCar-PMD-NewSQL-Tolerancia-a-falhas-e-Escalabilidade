<h1>NewSQL - Tolerância à falha e escalabilidade com CockroachDB e SingleStore</h1>

## Autores
- Bernardo Pinheiro Camargo [@bernacamargo](https://github.com/bernacamargo)
- Renata Praisler [@RenataPraisler](https://github.com/RenataPraisler)

## Sumário
- [Autores](#autores)
- [Sumário](#sumário)
- [Objetivo](#objetivo)
- [Introdução](#introdução)
- [Tecnologias que vamos utilizar](#tecnologias-que-vamos-utilizar)
- [Pré-requisitos](#pré-requisitos)
- [Recursos necessários](#recursos-necessários)
- [Criar um Cluster Kubernetes](#criar-um-cluster-kubernetes)
- [CockroachDB](#cockroachdb)
  - [1. Deploy do Operator](#1-deploy-do-operator)
  - [2. Deploy do cluster](#2-deploy-do-cluster)
  - [3. Executando comandos SQL](#3-executando-comandos-sql)
  - [4. Testes de tolerância a falhas](#4-testes-de-tolerância-a-falhas)
  - [5. Testes de Escalabilidade](#5-testes-de-escalabilidade)
- [SingleStore](#singlestore)
  - [1. Conceitos básicos](#1-conceitos-básicos)
  - [2. Preparar manifestos para instalar o Operator no cluster](#2-preparar-manifestos-para-instalar-o-operator-no-cluster)
  - [3. Executando o deploy](#3-executando-o-deploy)
  - [4. Acessando o Cluster](#4-acessando-o-cluster)
  - [5. Testes de tolerância à falhas](#5-testes-de-tolerância-à-falhas)
  - [6. Testes de escalabilidade](#6-testes-de-escalabilidade)
- [Benchmark](#benchmark)
- [Conclusão](#conclusão)
   
#
## Objetivo
No contexto de bancos de dados relacionais e distribuídos (NewSQL), temos como objetivo deste projeto planejar e elaborar um tutorial intuitivo que permita a qualquer pessoa interessada testar e validar as características relacionadas a tolerância às falhas e escalabilidade na estrutura de NewSQL.

## Introdução

O NewSQL surgiu como uma nova proposta, pois com o uso do NOSQL acabou apresentando alguns problemas como por exemplo: a falta, do uso de transações, das consultas SQL e a estrutura complexa por não ter uma modelagem estruturada. Ele veio com o objetivo de ter os os pontos positivos dos do modelo relacional para as arquiteturas distribuídas e aumentar o desempenhos das queries de SQL, não tendo a necessidade de servidores mais potentes para melhor execução, e utilizando a escalabilidade vertical e mantendo as propriedades ACID(Atomicidade, Consistência, Isolamento e Durabilidade).

## Tecnologias que vamos utilizar

- Kubernetes;
- Docker;
- Google Kubernetes Engine (GKE);
- CockroachDB;
- SingleStore;

## Pré-requisitos

Antes de começarmos, é necessário que você atente-se à alguns detalhes considerados como pré-requisitos deste tutorial.

- Acesso a internet;
- Conhecimentos básicos em SQL, Kubernetes, Docker e Google Cloud;
- Conta no Google Cloud com créditos;

## Recursos necessários

- CockroachDB

  RECURSO | RECOMENDAÇÃO
  ------- | -------
  CPU   | 2 núcleos de vCPU por nó
  Memória | No mínimo 4GB por núcleo de vCPU
  Armazenamento | Cada nó deve ter pelo menos 150GB por núcleo de vCPU

- SingleStore
  
  RECURSO | RECOMENDAÇÃO
  ------- | -------
  CPU   | 4 núcleos de vCPU por nó
  Memória | No mínimo 4GB por núcleo de vCPU
  Armazenamento | Pelo menos 3 vezes a quantidade de memória RAM

## Criar um Cluster Kubernetes

Para podermos simular um ambiente isolado e que garanta as características de sistemas distribuídos utilizaremos um cluster local orquestrado pelo Kubernetes, o qual é responsável por gerenciar instâncias de máquinas virtuais para execução de aplicativos em containers. 

Neste projeto utilizaremos o GKE para gerenciar e hospedar nossos dois clusters Kubernetes, contudo é possível realizar o procedimento com qualquer outra vertente de cluster, como AWS, Microsoft Azure ou um cluster local. Atente-se nas configurações mínimas para executar cada aplicação.

Primeiramente precisamos criar nosso cluster no GKE:

- Acesse a [Google Cloud Console](https://console.cloud.google.com)
- No menu da esqueda, navegue até `Kubernetes Engine` e clique em `Clusters`;
- Clique em `Criar cluster` no centro da janela;
- Defina o nome do cluster;
- Configure a quantidade de recursos do cluster;
  - Clique em `Pools dos nós` para expandir o menu;
  - Clique em `Nós`;
  - Procure pelo campo `Tipo de máquina` e clique para expandir as opções;
  -  Agora basta selecionar a opção que contempla os requisitos dos softwares utilizados;
- Clique em `Criar`.
  

Feito isso, um cluster com três nós será criado e inicializado. Em alguns momentos você já poderá acessá-lo para seguirmos com as configurações.

> Para ambos os softwares CockroachDB e SingleStore utilizaremos o mesmo processo para inicialização do cluster kubernetes, porém em clusters com configurações diferentes.

#
## CockroachDB

Antes de iniciar os testes, temos que configurar o CockroachDB no nosso cluster e para nos auxiliar utilizamos as documentações do CockroachDB e kubernetes, e citaremos abaixo os comandos que devem ser realizados.

Para configurar a aplicação do CockroachDB dentro do cluster podemos fazer de algumas formas:
- [Usando o Operator](https://kubernetes.io/pt/docs/concepts/extend-kubernetes/operator/)
- [Usando o Helm](https://helm.sh/)
- Usando arquivos de configurações sem ferramentas automatizadoras.

Neste exemplo utilizaremos o `Operator` fornecido pelo CockroachDB, pois ele irá automatizar diversas configuração do cluster.

>Nota: É importante notar que temos um cluster kubernetes, composto de três instâncias de máquina virtual (1 master e 2 workers), onde as pods são alocadas e cada uma representa um nó do CockroachDB que está executando. Dessa forma quando falamos sobre os nós do CockroachDB estamos nos referindo as pods e quando falamos dos nós do cluster estamos falando das instâncias de máquina virtual do Kubernetes.

### 1. Deploy do Operator

- Definir as autorizações para o Operator gerenciar o cluster

  ```shell
  $ kubectl apply -f CockroachDB/operator-rbac.yaml
  ```

- Criar o CustomResourceDefinition (CRD) para o Operator

  ```shell
  $ kubectl apply -f CockroachDB/operator-crd.yaml
  ```

  O retorno esperado é:

      customresourcedefinition.apiextensions.k8s.io/crdbclusters.crdb.cockroachlabs.com created

  > Nota: É interessante notar que o operator irá ser executado como uma pod do cluster.

- Criar o Controller do Operator

  ```shell
  $ kubectl apply -f CockroachDB/operator-deploy.yaml
  ```
      
  O retorno esperado é:

      clusterrole.rbac.authorization.k8s.io/cockroach-operator-role created
      serviceaccount/cockroach-operator-default created
      clusterrolebinding.rbac.authorization.k8s.io/cockroach-operator-default created
      deployment.apps/cockroach-operator created

- Validar se o Operator está executando

  ```shell
  $ kubectl get pods
  ``` 
  Caso tenha funcionado, você deverá ter como retorno a seguinte mensagem:

      NAME                                 READY   STATUS    RESTARTS   AGE
      cockroach-operator-6867445556-9x6zp   1/1    Running      0      2m51s

  > Nota: Caso o status da pod estiver como "ContainerCreating" é só aguardar alguns instantes que o kubernetes esta iniciando o container e logo deverá aparecer como "Running".

### 2. Deploy do cluster
  
- Abra o arquivo `cockroachdb-cluster.yaml` com um editor de texto
- Esta etapa é opcional, porém extremamente recomendada em ambientes de produção. <br> Vamos configurar a quantidade de CPU e memoria para cada pod do cluster. Basta procurar no arquivo pelo código abaixo, descomentar as linhas e alterar os valores de `cpu` e `memory`, seguindo a regra de 4GB de memória RAM para cada um núcleo de CPU.

  ```yaml
  resources:
      requests:
          cpu: "2"
          memory: "8Gi"
          
      limits:
          cpu: "2"
          memory: "8Gi"
  ```

  > Nota: Caso não defina nenhum valor inicial a aplicação extendera seus limites de uso de cpu/memoria até o limite do nó do cluster. 
          
- Modifique a quantidade de armazenamento cada pod terá, altere o valor do campo `storage` seguindo a regra de 150GB por núcleo de CPU.
  ```yaml
  resources:
      requests:
          storage: "300Gi"
  ```

- Aplique as configurações feitas no arquivo `cockroachdb-cluster.yaml`.

  ```shell
  $ kubectl apply -f cockroachdb-cluster.yaml
  ```

  O retorno esperado é:

      crdbcluster.crdb.cockroachlabs.com/CockroachDB created    

  > Nota: Este arquivo irá solicitar para o Operador que crie uma aplicação StatefulSet com três pods que funcionarão como um cluster CockroachDB.

- Aguarde alguns minutos e verifique se as pods estão sendo executadas.

  ```shell
  $ kubectl get pods
  ```

  O retorno esperado é:

      NAME                                  READY   STATUS    RESTARTS   AGE
      cockroach-operator-6867445556-9x6zp   1/1     Running   0          43m
      cockroachdb-0                         1/1     Running   0          2m29s
      cockroachdb-1                         1/1     Running   0          104s
      cockroachdb-2                         1/1     Running   0          67sa
      

### 3. Executando comandos SQL

Feito isso, já temos nosso cluster e nossa aplicação configurados e executando, temos que popular nosso banco de dados para realizar os testes. 

- Acesse o bash de uma das pods que estão executando a aplicação

  ```shell
  $ kubectl exec -it cockroachdb-2 -- bash
  ```

  > Nota: Para alterar qual pod voce está acessando basta alterar a parte do comando `cockroachdb-2` para o nome da pod que você deseja acessar.

- Dentro da pod inicialize o [build-in SQL client](https://www.cockroachlabs.com/docs/v20.2/cockroach-sql) do cockroach

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

- Crie o banco de dados chamado `bank`

  ```sql
  CREATE DATABASE bank;
  ```

- Crie uma tabela chamada `bank.accounts`

  ```sql
  CREATE TABLE bank.accounts (
      id          int             NOT NULL    AUTO_INCREMENT,
      nome        VARCHAR(255)    NOT NULL,
      agencia     VARCHAR(15)     NOT NULL,
      conta       VARCHAR(15)     NOT NULL,
      tipo_conta  VARCHAR(50)     NOT NULL,
      saldo       FLOAT           NOT NULL,
      PRIMARY KEY (id)
  );
  ```

- Crie os dados para a tabela
  
  ```sql
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
  ```

- Agora realize um SELECT na tabela para ver seus dados.

  ```sql
  SELECT * FROM bank.accounts;
  ```

  O retorno deve ser parecido com:

      +----+-----------+---------+---------+------------+----------+
      | id | nome      | agencia | conta   | tipo_conta | saldo    |
      +----+-----------+---------+---------+------------+----------+
      |  8 | Pessoa 08 | 9184-9  | 12537-6 | CORRENTE   | 54656700 |
      |  1 | Pessoa 01 | 5482-3  | 85377-3 | CORRENTE   |    51230 |
      |  3 | Pessoa 03 | 4235-1  | 12524-2 | CORRENTE   |    30000 |
      |  6 | Pessoa 06 | 7223-6  | 98431-5 | POUPANA    |   554876 |
      |  5 | Pessoa 05 | 5144-7  | 90132-8 | CORRENTE   |    84412 |
      |  7 | Pessoa 07 | 2623-3  | 68232-5 | CORRENTE   | 10000000 |
      |  2 | Pessoa 02 | 3123-5  | 43176-4 | CORRENTE   |     1500 |
      |  4 | Pessoa 04 | 2315-3  | 48255-9 | POUPANA    |     4232 |
      | 10 | Pessoa 10 | 8743-5  | 23985-3 | CORRENTE   |   642154 |
      |  9 | Pessoa 09 | 5143-5  | 10255-1 | POUPANA    |   974113 |
      +----+-----------+---------+---------+------------+----------+

Agora chegou o momento de realizarmos nossos testes para averiguar a tolerância a falhas e a escalabilidade do CockroachDB.

#
### 4. Testes de tolerância a falhas

>Nota: É importante ressaltar que temos um cluster kubernetes, composto de três instâncias de máquinas virtuais (3 workers), onde as pods são executadas e cada pod representa um nó do CockroachDB. Dessa forma quando falamos sobre os nós do CockroachDB estamos nos referindo as pods e quando falamos dos nós do cluster estamos nos referindo as instâncias de máquina virtual do Kubernetes.
    
A tolerância à falhas tem como objetivo impedir que alguma mudança da nossa base de dados seja perdida por conta de algum problema, com isso é realizado o método de replicação para que todos os nós tenham as mudanças realizadas, e assim caso um nó tenha algum problema, o outro nó do sistema terá as informações consistentes. 

Sabendo disso, vamos simular alguns casos para você perceber o este funcionamento. 
Antes de simular uma falha do nó, vamos passar pelo conceito da replicação na prática, para isso vamos efeturar uma operação de atualização(UPDATE) em um nó e verificar o que acontece com os outros nós. 

- Replicação de dados

  Primeiramente vamos verificar como está o dado que desejamos modificar, execute o seguinte comando SQL para busca-lo na tabela `accounts`.

  ```sql
  SELECT * FROM bank.accounts WHERE nome = 'Pessoa 01';
  ```

  O retorno deve ser

      +----+-----------+---------+---------+------------+----------+
      | id | nome      | agencia | conta   | tipo_conta | saldo    |
      +----+-----------+---------+---------+------------+----------+
      |  1 | Pessoa 01 | 5482-3  | 85377-3 | CORRENTE   |    51230 |
      +----+-----------+---------+---------+------------+----------+

  Execute o comando abaixo para realizar a alteração no nó 2. 

  ```sql
  UPDATE bank.accounts SET tipo_conta='POUPANÇA' WHERE nome = 'Pessoa 01';
  ```

  Agora acesse o nó 1, repetindo os passos da etapa [3](https://github.com/bernacamargo/PMD-tutorial#3-executando-comandos-sql-na-pod), e após entrar no build-in SQL, execute a consulta abaixo

  ```sql
  SELECT * FROM bank.accounts WHERE nome = 'Pessoa 01';
  ```

    O retorno deve ser

      +----+-----------+---------+---------+------------+----------+
      | id | nome      | agencia | conta   | tipo_conta | saldo    |
      +----+-----------+---------+---------+------------+----------+
      |  1 | Pessoa 01 | 5482-3  | 85377-3 | POUPANÇA   |    51230 |
      +----+-----------+---------+---------+------------+----------+

  Como podemos observar, a atualização foi realizada e também foi replicada para as outras pods. Dessa forma podemos realizar este mesmo teste com as outras pods e veremos que todas estão sincronizadas.

- Simulando a falha de uma pod.
   
  Vamos deletar um nó do CockroachDB utilizando o comando abaixo:
    
  ```shell
  $ kubectl delete pod cockroachdb-2
  ```
          
  Você terá o retorno que o nó foi deletado.  

      pod "cockroachdb-2" deleted

  O que é interessante, é que no arquivo `cockroachdb-cluster.yaml`, definimos que teremos `3 nodes` executando o CockroachDB. Então quando deletamos o nó 2, o Kubernets irá verificar que o nó 2 teve uma falha, e  automaticamente reiciciará a pod e atualizará os dados baseados nos outros nós.

  Executando esse comando no terminal, verificamos que a pod já foi reiniciada e esta com o **status: Running**. 
          
  ```shell
  $ kubectl get pod cockroachdb-2
  ```

      NAME            READY     STATUS    RESTARTS   AGE
      cockroachdb-2   1/1       Running   0          15s
  
### 5. Testes de Escalabilidade

Para o escalonamento do nosso cluster, utilizaremos a escalabilidade horizontal, que consiste em utilizar mais equipamentos e existe a partionalização dos dados de acordo com os critérios de cada projeto, diferente do vertical, que consiste em aumentar a capacidade da máquina, porém no horizontal também temos o aumento de capacidade de memória e de processamento, mas isso terá o impacto pela soma das máquinas em funcionamento. 

Para entender o motivo que precisamos realizar este escalomamento, vamos supor que existe uma necessidade de processamento maior dos dados num período de tempo, como por exemplo a black friday (data em novemembro em que o comércio realiza descontos em cima de produtos), para isso seja necessário um aumento de quantidade de máquina para que não tenha impacto no processamento para o cliente final, mas em outras datas não tenha o mesmo volume de acesso, então podemos reduzir também nossas pods para que tenha uma redução no valor de processamento. 

Todas essas ações são necessários estudos e estragégias que vão depender do propósito e abordagem desejada para cada projeto, por isso é importante se aprofundar para analisar os impactos positivos de cada ação, para que isso não atinja o usuário final. 

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
      name: CockroachDB/cockroach:v20.2.0
  nodes: 5
  ```

  Com o arquivo salvo, podemos executar o deploy da aplicação novamente com o comando

  ```shell
  $ kubectl apply -f cockroachdb-cluster.yaml
  ```

  O retorno deve ser parecido com o seguinte:

      crdbcluster.crdb.cockroachlabs.com/CockroachDB configured

  >Nota: O comando `apply` do Kubernetes permite que alteremos a configuração inicial da aplicação do CockroachDB sem que seja necessário reinicia-la.

  Podemos verificar que nossa aplicação foi escalonada através das pods existentes

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
#
## SingleStore

Nesta etapa vamos definir e executar as configurações de deploy do SingleStore em um cluster Kubernetes gerenciado pelo GKE, para assim podermos realizar os testes de escalabilidade e tolerância a falhas.

### 1. Conceitos básicos
Primeiramente precisamos criar nosso cluster e utilizaremos o GKE para isto:

- Acesse a [Google Cloud Console](https://console.cloud.google.com)
- Navegue até o `Kubernetes Engine` e clique em `Clusters`;
- Clique em `Criar cluster` no centro da janela;
- Defina o nome do cluster e clique em `Criar`.

Feito isso, um cluster com três nós será criado e inicializado. Em alguns momentos você já poderá acessá-lo para seguirmos com as configurações.

> Nota: o teste foi realizaado com o cluster com as configurações mínimas para rodar o software e que os testes serem realizadas. 

### 2. Preparar manifestos para instalar o Operator no cluster

> Para garantir o funcionamento do cluster altere apenas o arquivo `singlestore-cluster.yaml `

- rbac.yaml

  Essa configuração irá criar a definição de um ServiceAccount para o MemSQL Operator utilizar. 


  ```yaml
  apiVersion: v1
  kind: ServiceAccount
  metadata:
    name: memsql-operator
  ---
  apiVersion: rbac.authorization.k8s.io/v1
  kind: Role
  metadata:
    name: memsql-operator
  rules:
  - apiGroups:
    - ""
    resources:
    - pods
    - services
    - endpoints
    - persistentvolumeclaims
    - events
    - configmaps
    - secrets
    verbs:
    - '*'
  - apiGroups:
    - policy
    resources:
    - poddisruptionbudgets
    verbs:
    - '*'
  - apiGroups:
    - batch
    resources:
    - cronjobs
    verbs:
    - '*'
  - apiGroups:
    - ""
    resources:
    - namespaces
    verbs:
    - get
  - apiGroups:
    - apps
    - extensions
    resources:
    - deployments
    - daemonsets
    - replicasets
    - statefulsets
    verbs:
    - '*'
  - apiGroups:
    - memsql.com
    resources:
    - '*'
    verbs:
    - '*'
  ---
  kind: RoleBinding
  apiVersion: rbac.authorization.k8s.io/v1
  metadata:
    name: memsql-operator
  subjects:
  - kind: ServiceAccount
    name: memsql-operator
  roleRef:
    kind: Role
    name: memsql-operator
    apiGroup: rbac.authorization.k8s.io
  ```

- SingleStore-cluster-crd.yaml

  Define um recurso específico MemSQLCluster como um tipo de recurso para ser utilizado pelo Operator.

  ```yaml
  apiVersion: apiextensions.k8s.io/v1beta1
  kind: CustomResourceDefinition
  metadata:
    name: memsqlclusters.memsql.com
  spec:
    group: memsql.com
    names:
      kind: MemsqlCluster
      listKind: MemsqlClusterList
      plural: memsqlclusters
      singular: memsqlcluster
      shortNames:
        - memsql
    scope: Namespaced
    version: v1alpha1
    subresources:
      status: {}
    additionalPrinterColumns:
    - name: Aggregators
      type: integer
      description: Number of MemSQL Aggregators
      JSONPath: .spec.aggregatorSpec.count
    - name: Leaves
      type: integer
      description: Number of MemSQL Leaves (per availability group)
      JSONPath: .spec.leafSpec.count
    - name: Redundancy Level
      type: integer
      description: Redundancy level of MemSQL Cluster
      JSONPath: .spec.redundancyLevel
    - name: Age
      type: date
      JSONPath: .metadata.creationTimestamp
  ```

- deployment.yaml

  Realiza o deploy do Operator, iniciando uma pod para executa-lo.

  ```yaml
  apiVersion: apps/v1
  kind: Deployment
  metadata:
    name: memsql-operator
  spec:
    replicas: 1
    selector:
      matchLabels:
        name: memsql-operator
    template:
      metadata:
        labels:
          name: memsql-operator
      spec:
        serviceAccountName: memsql-operator
        containers:
          - name: memsql-operator
            image: memsql/operator:1.2.3-centos-ef2b8561
            imagePullPolicy: Always
            args: [
              # Cause the operator to merge rather than replace annotations on services
              "--merge-service-annotations",
              # Allow the process inside the container to have read/write access to the `/var/lib/memsql` volume.
              "--fs-group-id", "5555"
            ]
            env:
              - name: WATCH_NAMESPACE
                valueFrom:
                  fieldRef:
                    fieldPath: metadata.namespace
              - name: POD_NAME
                valueFrom:
                  fieldRef:
                    fieldPath: metadata.name
              - name: OPERATOR_NAME
                value: "memsql-operator"
  ```

  > Nota: Neste projeto a imagem utilizada para a criação do container do operator é a `memsql/operator:1.2.3-centos-ef2b8561` disponibilizada no Docker Hub pelo SingleScore.

- SingleStore-cluster.yaml 

  Esta é a configuração principal do nosso cluster, é através deste arquivo que iremos definir se nosso cluster será replicado e também a quantidade de recursos alocados para cada nó.

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

  - Altere o campo `name` para o nome do seu cluster;
  - Altere o campo `license` e cole a sua [licença do SingleStore](https://portal.SingleStore.com/licenses);
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

  > Nota: Todos os arquivos .yaml acima também estão disponiveis na [documentação do SingleStore](https://docs.SingleStore.com/v7.3/guides/deploy-memsql/self-managed/kubernetes/step-3/).


### 3. Executando o deploy

- Primeiramente precisamos instalar os recursos do memsql
  ```shell
  $ kubectl apply -f SingleStore/operator-rbac.yaml
  ```

      serviceaccount/memsql-operator created
      role.rbac.authorization.k8s.io/memsql-operator created
      rolebinding.rbac.authorization.k8s.io/memsql-operator created

- Agora instale as definições de recurso para o Operator

  ```shell
  $ kubectl apply -f SingleStore/operator-crd.yaml
  ```
      customresourcedefinition.apiextensions.k8s.io/memsqlclusters.memsql.com created

- Realize o deploy do MemSQL Operator

  ```shell
  $ kubectl apply -f SingleStore/operator-deploy.yaml
  ```

      deployment.apps/memsql-operator created

- Aguarde a pod chamada "memsql-operator" ter seu status como `Running`

  ```shell
  $ kubectl get pods
  ```
      NAME                               READY   STATUS    RESTARTS   AGE
      memsql-operator-5f4b595f89-hfqzt   1/1     Running   0          14s

- Realizar o deploy do cluster MemSQL.

  ```shell
  $ kubectl apply -f SingleStore/SingleStore-cluster.yaml
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

  A partir deste momento já temos nosso cluster Memsql configurado e funcionando, dessa forma já podemos iniciar os testes com querys SQL básicas.

### 4. Acessando o Cluster

- Verificar os serviços criados no deploy

  ```shell
  $ kubectl get pods
  ```
      NAME                     TYPE           CLUSTER-IP     EXTERNAL-IP     PORT(S)          AGE
      kubernetes               ClusterIP      10.120.0.1     <none>          443/TCP          10m
      svc-memsql-cluster       ClusterIP      None           <none>          3306/TCP         3m16s
      svc-memsql-cluster-ddl   LoadBalancer   10.120.7.169   35.247.216.80   3306:32748/TCP   3m16s

  Existem três serviços sendo executados em nosso cluster Kubernetes, contudo o que nos importa agora é o que possue o `TYPE` de `LoadBalancer`, chamado `svc-memsql-cluster-ddl`. 
  Este serviço é responsável por encaminhar as requisições recebidas no seu IP externo para as pods do cluster, no caso, para os nós do nosso cluster. 

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

  Agora podemos executar nossos comandos SQL dentro do cluster.

- Crie o banco de dados chamado `bank`

  ```sql
  CREATE DATABASE bank;
  ```

- Crie uma tabela chamada `bank.accounts`

  ```sql
  CREATE TABLE bank.accounts (
      id          int             NOT NULL    AUTO_INCREMENT,
      nome        VARCHAR(255)    NOT NULL,
      agencia     VARCHAR(15)     NOT NULL,
      conta       VARCHAR(15)     NOT NULL,
      tipo_conta  VARCHAR(50)     NOT NULL,
      saldo       FLOAT           NOT NULL,
      PRIMARY KEY (id)
  );
  ```

- Crie os dados para a tabela
  
  ```sql
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
  ```

- Agora realize um SELECT na tabela para ver seus dados.

  ```sql
  SELECT * FROM bank.accounts;
  ```

  O retorno deve ser parecido com:

      +----+-----------+---------+---------+------------+----------+
      | id | nome      | agencia | conta   | tipo_conta | saldo    |
      +----+-----------+---------+---------+------------+----------+
      |  8 | Pessoa 08 | 9184-9  | 12537-6 | CORRENTE   | 54656700 |
      |  1 | Pessoa 01 | 5482-3  | 85377-3 | CORRENTE   |    51230 |
      |  3 | Pessoa 03 | 4235-1  | 12524-2 | CORRENTE   |    30000 |
      |  6 | Pessoa 06 | 7223-6  | 98431-5 | POUPANA    |   554876 |
      |  5 | Pessoa 05 | 5144-7  | 90132-8 | CORRENTE   |    84412 |
      |  7 | Pessoa 07 | 2623-3  | 68232-5 | CORRENTE   | 10000000 |
      |  2 | Pessoa 02 | 3123-5  | 43176-4 | CORRENTE   |     1500 |
      |  4 | Pessoa 04 | 2315-3  | 48255-9 | POUPANA    |     4232 |
      | 10 | Pessoa 10 | 8743-5  | 23985-3 | CORRENTE   |   642154 |
      |  9 | Pessoa 09 | 5143-5  | 10255-1 | POUPANA    |   974113 |
      +----+-----------+---------+---------+------------+----------+

### 5. Testes de tolerância à falhas

Relembrando o objetivo da tolerância à falhas, ela impede que alguma mudança da nossa base de dados seja perdida por conta de algum problema, com isso é realizado o método de replicação para que todos os nós tenham as mudanças realizadas, e assim caso um nó tenha algum problema, o outro nó do sistema terá as informações consistentes. 

Sabendo disso, vamos simular alguns casos para você perceber o este funcionamento, antes de simular uma falha do nó, vamos passar pelo conceito da replicação na prática.

Diferentemente do cockroach, em que configuramos um cluster totalmente replicado, no SingleStore temos um cluster gerenciado pelo nó master e seus dados armazenados e particionados em seus nós folha. Dessa forma só devemos realizar as operações de dados no nosso nó master, e assim a partição será realizada nas folhas através dos nossos agregadores, assim qualquer consulta que é feita pelo nó master, é processados pelos nós folhas. Isso ficará mais claro na prática, que demostraremos abaixo.


- Simulando a falha de um nó.
   
  Após nos termos populado nosso banco pelo nosso nó master, nós vamos deletar o nosso nó master com o comando abaixo:
    
  ```shell
  $ kubectl delete pods node-memsql-cluster-master-0
  ```
  Você terá o retorno que o nó foi deletado.  

      pod "node-memsql-cluster-master-0" deleted

  Logo em seguida verifique o status das pods

  ```shell
  $ kubectl get pods
  ```

      NAME                               READY   STATUS        RESTARTS   AGE
      memsql-operator-5f4b595f89-49q9k   1/1     Running       0          69m
      node-memsql-cluster-leaf-ag1-0     2/2     Running       0          68m
      node-memsql-cluster-leaf-ag1-1     2/2     Running       0          68m
      node-memsql-cluster-master-0       2/2     Terminating   0          40m

  Quando deletamos o nó, o Operator do cluster irá reiniciar o nó automáticamente copiando as informações do nós folhas, ou seja, irá recriar o banco atraves das partições. 

  Se rodarmos esse comando no terminal, verificamos que a pod já foi reiniciada e esta com o **status: Running**. 

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
  SELECT * FROM bank.accounts;
  ```

  O retorno deve ser

      +----+-----------+---------+---------+------------+----------+
      | id | nome      | agencia | conta   | tipo_conta | saldo    |
      +----+-----------+---------+---------+------------+----------+
      |  8 | Pessoa 08 | 9184-9  | 12537-6 | CORRENTE   | 54656700 |
      |  1 | Pessoa 01 | 5482-3  | 85377-3 | CORRENTE   |    51230 |
      |  3 | Pessoa 03 | 4235-1  | 12524-2 | CORRENTE   |    30000 |
      |  6 | Pessoa 06 | 7223-6  | 98431-5 | POUPANA    |   554876 |
      |  5 | Pessoa 05 | 5144-7  | 90132-8 | CORRENTE   |    84412 |
      |  7 | Pessoa 07 | 2623-3  | 68232-5 | CORRENTE   | 10000000 |
      |  2 | Pessoa 02 | 3123-5  | 43176-4 | CORRENTE   |     1500 |
      |  4 | Pessoa 04 | 2315-3  | 48255-9 | POUPANA    |     4232 |
      | 10 | Pessoa 10 | 8743-5  | 23985-3 | CORRENTE   |   642154 |
      |  9 | Pessoa 09 | 5143-5  | 10255-1 | POUPANA    |   974113 |
      +----+-----------+---------+---------+------------+----------+


#
### 6. Testes de escalabilidade

O escalonamento do cluster será executado baseado no conceito de escalabilidade vertical. Este conceito representa o aumentar a capacidade dos recursos de uma mesma máquina. Em nosso contexto a escalabilidade vertical vai ser aplicada através da manipulação da quantidade de instâncias do banco de dados(pods).

<!-- Para o escalonamento do nosso cluster, utilizaremos a escalabilidade horizontal, que consiste em utilizar mais equipamentos e existe a partionalização dos dados de acordo com os critérios de cada projeto, diferente do vertical, que consiste em aumentar a capacidade da máquina, porém no horizontal também temos o aumento de capacidade de memória e de processamento, mas isso terá o impacto pela soma das máquinas em funcionamento.  -->

Como fizemos o deploy do cluster SingleStore utilizando um Operator, toda escalabilidade será realizada modificando o arquivo de configuração do cluster e realizando seu deploy novamente.

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
Este é o trecho de código que iremos modificar para podermos testar a escalabilidade do cluster. A seguir temos as opções disponíveis:

- Alta Disponibilidade:
  
  No inicio temos o campo `redundancyLevel`, este é responsável por ativar a `Alta Disponibilidade`, que irá criar no mesmo cluster outro conjunto de nós agregadores que atuaram apenas como replicas do primeiro conjunto de nós. Neste tutorial não iremos abordar esta função, pois será necessário uma infraestrutura muito mais potente.

  > Nota: Quando o modo de Alta Disponibilidade está ativado, todos os nós do cluster são duplicados, assim como a solicitação de recursos.

- Aumentando/Diminuindo o número de nós do cluster

  Para podermos realizar o escalonamento horizontal de nosso cluster, precisamos adicionar mais nós para ele. Assim precisaremos apenas alterar os campos de `aggregatorSpec.count` e `leafSpec.count`, sendo a quantidade de nós do agregador(master) e de seus nós folha, respectivamente.

- Aumentando/Diminuindo o armazenamento dos nós

  Para modificarmos a capacidade de armazenamento de nossos nós, basta que alteremos os valores dos campos de `aggregatorSpec.storageGB` e `leafSpec.storageGB`, sendo a quantidade em GigaBytes de capacidade de armazenamento nós do agregador(master) e de seus nós folha, respectivamente.

- Aumentando/Diminuindo a quantidade de núcleos de CPU e da Memória RAM de cada nó

  Para podermos dar mais potência para nossos nós utilizaremos a propriedade `height`, a qual recebe um valor inteiro e representa um multiplicador para uma quantidade fixa de vCPU e memória ram. Dessa forma temos que o valor `1` representa a quantidade de 8 núcleos de CPU e 32GB de memória RAM.

  > Nota: O menor valor aceitável para o campo `height` é 0.5, ou seja, para cada nó é necessário no mínimo 4 núcleos de CPU e 16GB de memória RAM.

- Aplicando as alterações

  Para realizar o deploy do cluster com a nova configuração basta realizar o commando `apply` novamente.

  ```shell
  $ kubectl apply -f SingleStore/SingleStore-cluster.yaml
  ```
      memsqlcluster.memsql.com/memsql-cluster configured

## Benchmark

Antes da escolha dos softawares que usariamos dentro deste projeto, nos realizamos um benchmark para escolher o que mais se encaixava, com isso nós levantamos algumas coisas que seriam essenciais que foram: uma boa documentação que contesse vídeos e bons exemplos, gratuitos ou até mesmo com um valor alto de créditos para testes iniciais e gostariamos que os softwares entre si tivessem alguma diferência significativa. 

Após esses critérios criados, nos escolhemos 

## Conclusão

Quando iniciamos o projeto já sabiamos que ele seria desafiador, pois muito mais do que a prática envolvida teriamos que provar e exemplificar através dos testes os conceitos e definições tanto do NewSQL como também as particularidades de cada software, do kubernetes que escolhemos para nos auxiliar e o google cloud, que foi na nossa escolha tanto pela documentação que existe, quanto também com a quantidade de créditos que eles dão para o teste gratuito.

Durante o processo tivemos que realizar algumas escolhas, como por exemplo, deixar de simular de maneira local da nossa máquina e partir para o cloud, e com isso tivemos dificuldade com as configurações mínimas de hardware, em particularidade do SingleStore, antigo MemSQL, e assim os cenários que nós imaginavamos que seria o ideal para os testes acabou que teve que ser adaptado para conseguirmos entregar o projeto de acordo com as expectativas.

Com esse trabalho, por fim, finalizamos o projeto com grande aprendizado dos conceitos de tolerância à falhas e escalabilidade e também com um conceito mais básico e prático do funcionamento da cloud. 
