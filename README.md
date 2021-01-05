# NewSQL - Tolerância à falha e escalabilidade com Cockroachdb e SingleStore

#### Autores
- Bernardo Pinheiro Camargo [@bernacamargo](https://github.com/bernacamargo)
- Renata Praisler [@RenataPraisler](https://github.com/RenataPraisler)

# 

## Objetivo
No contexto de bancos de dados relacionais e distribuídos (NewSQL), temos como objetivo deste projeto planejar e elaborar um tutorial intuitivo que permita a qualquer pessoa interessada testar e validar as características relacionadas a tolerância às falhas e escalabilidade na estrutura de NewSQL.

## Introdução

O NewSQL surgiu como uma nova proposta, pois com o uso do NOSQL acabou apresentando alguns problemas como por exemplo: a falta, do uso de transações, das consultas SQL e a estrutura complexa por não ter uma modelagem estruturada. Ele veio com o objetivo de ter os os pontos positivos dos do modelo relacional para as arquiteturas distribuídas e aumentar o desempenhos das queries de SQL, não tendo a necessidade de servidores mais potentes para melhor execução, e utilizando a escalabilidade horizontal e mantendo as propriedades ACID(Atomicidade, Consistência, Isolamento e Durabilidade).

## Tecnologias que vamos utilizar

- Kubernetes;
- Docker;
- Google Kubernetes Engine (GKE);
- Cockroachdb;
- SingleStore;

## 

## Cluster Kubernetes

Para podermos simular um ambiente isolado e que garanta as características de sistemas distribuídos utilizaremos um cluster local orquestrado pelo Kubernetes, o qual é responsável por gerenciar instâncias de máquinas virtuais para execução de aplicativos em containers. 

Primeiramente precisamos criar nosso cluster e utilizaremos o GKE para isto:

- Acesse a [Google Cloud Console](https://console.cloud.google.com)
- Navegue até o `Kubernetes Engine` e clique em `Clusters`;
- Clique em `Criar cluster` no centro da janela;
- Defina o nome do cluster e clique em `Criar`.

Feito isso, um cluster com três nós será criado e inicializado. Em alguns momentos você já poderá acessá-lo para seguirmos com as configurações.

> Para ambos os softwares Cockroachdb e SingleStore utilizaremos o mesmo processo para inicialização do cluster kubernetes, porém em clusters diferentes.

## Cockroachdb

Antes de iniciar o teste para identificar como é realizado a tolerância a falhas e a escalabilidade, temos que configurar o Cockroachdb no nosso cluster, para nos auxiliar utilizamos as documentações do Cockroachdb e kubernetes, e citaremos abaixo os comandos que devem ser realizados.

Para configurar a aplicação do cockroachdb dentro do cluster podemos fazer de algumas formas:
- [Usando o Operator](https://kubernetes.io/pt/docs/concepts/extend-kubernetes/operator/)
- [Usando o Helm](https://helm.sh/)
- Usando arquivos de configurações sem ferramentas automatizadoras.

Neste exemplo utilizaremos o Operator fornecido pelo Cockroachdb, pois ele automatiza a configuração da aplicação e assim não teremos que entrar a fundo em alguns detalhes mais técnicos do Kubernetes.

>Nota: É importante notar que temos um cluster kubernetes, composto de três instâncias de máquina virtual (1 master e 2 workers), onde as pods são alocadas e cada pod representa um nó do CockroachDB que está executando. Dessa forma quando falamos sobre os nós do cockroachdb estamos nos referindo as pods e quando falamos dos nós do cluster estamos falando das instâncias de máquina virtual do Kubernetes.

### 1. Instalar o Operator no cluster.

1.1. Criar o CustomResourceDefinition (CRD) para o Operator

```shell
$ kubectl apply -f https://raw.githubusercontent.com/cockroachdb/cockroach-operator/master/config/crd/bases/crdb.cockroachlabs.com_crdbclusters.yaml
```

O retorno esperado é:

    customresourcedefinition.apiextensions.k8s.io/crdbclusters.crdb.cockroachlabs.com created

> Nota: É interessante notar que o operator irá ser executado como uma pod do cluster.

1.2. Criar o Controller do Operator

```shell
$ kubectl apply -f https://raw.githubusercontent.com/cockroachdb/cockroach-operator/master/manifests/operator.yaml
```
    
O retorno esperado é:

    clusterrole.rbac.authorization.k8s.io/cockroach-operator-role created
    serviceaccount/cockroach-operator-default created
    clusterrolebinding.rbac.authorization.k8s.io/cockroach-operator-default created
    deployment.apps/cockroach-operator created

1.3. Validar se o Operator está executando

```shell
$ kubectl get pods
``` 
Caso tenha funcionado, você deverá ter como retorno a seguinte mensagem:

    NAME                                 READY   STATUS    RESTARTS   AGE
    cockroach-operator-6867445556-9x6zp   1/1    Running      0      2m51s

> Nota: Caso o status da pod estiver como "ContainerCreating" é só aguardar alguns instantes que o kubernetes esta iniciando o container e logo deverá aparecer como "Running".

### 2. Configuração da aplicação do cockroachdb.

2.1. Realize o download e a edição do arquivo `example.yaml`, este é responsável por realizar a configuração básica de uma aplicação do cockroachdb através do Operator.
  
```shell
$ curl -O https://raw.githubusercontent.com/cockroachdb/cockroach-operator/master/examples/example.yaml
```

Utilize o `vim`(ou qualquer editor de texto de sua preferência) para abrir o arquivo baixado na etapa anterior.

```shell
$ vim example.yaml
```
  
2.2. Com o arquivo aberto no editor de texto, vamos configurar a quantidade de CPU e memoria para cada pod do cluster. Basta procurar no arquivo baixado pelo código abaixo, descomentar as linhas e alterar os valores de `cpu` e `memory` para os que desejar.

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

> Nota: Essa etapa é opicional e contudo é recomendada em ambientes de produção, visto que limitar o uso de recurso na aplicação pode evitar um desperdício de recurso.
        
2.3. Modifique a quantidade de armazenamento cada pod terá, altere para quantos GigaBytes você desejar.
```yaml
resources:
    requests:
        storage: "1Gi"
```

> Nota: caso você queira outra configuração para outro teste ou projeto, se atente de verificar as [configurações recomendadas para a execução da aplicação cockroachdb](https://www.cockroachlabs.com/docs/v20.2/recommended-production-settings#hardware).

2.4. Aplique as configurações feitas no arquivo `example.yaml`.

```shell
$ kubectl apply -f example.yaml
```

O retorno esperado é:

    crdbcluster.crdb.cockroachlabs.com/cockroachdb created    

> Nota: Este arquivo irá solicitar para o Operador que crie uma aplicação StatefulSet com três pods que funcionarão como um cluster cockroachdb.

2.5. Aguarde alguns minutos e verifique se as pods estão sendo executadas.

```shell
$ kubectl get pods
```

O retorno esperado é:

    NAME                                  READY   STATUS    RESTARTS   AGE
    cockroach-operator-6867445556-9x6zp   1/1     Running   0          43m
    cockroachdb-0                         1/1     Running   0          2m29s
    cockroachdb-1                         1/1     Running   0          104s
    cockroachdb-2                         1/1     Running   0          67sa
    

### 3. Executando comandos SQL na pod.

Feito isso, já temos nosso cluster e nossa aplicação configurados e executando, temos que popular nosso banco de dados para realizar os testes. 

#### 3.1. Acesse o bash de uma das pods que estão executando a aplicação

```shell
$ kubectl exec -it cockroachdb-2 bash
```

> Nota: Para alterar qual pod voce está acessando basta alterar a parte do comando `cockroachdb-2` para o nome da pod que você deseja acessar.

#### 3.2. Dentro da pod inicialize o [build-in SQL client](https://www.cockroachlabs.com/docs/v20.2/cockroach-sql) do cockroach

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

A partir deste momento, já é possível executar comandos SQL diretamente em nossas aplicações do cockroachdb.

#### 3.3. Crie o banco de dados.

```sql
CREATE DATABASE commic_book;
```

#### 3.4. Popular a base de dados

Agora vamos importar a nossa base antes de iniciar os testes, e para isso utilizaremos o arquivo [marvel.csv](https://raw.githubusercontent.com/bernacamargo/PMD-tutorial/main/marvel.csv).

```sql
IMPORT TABLE commic_book.marvel (
    url STRING,
    name_alias STRING,
    appearances STRING,
    current STRING,
    gender STRING,
    probationary STRING,
    full_reserve STRING,
    years STRING,
    years_since_joining STRING,
    honorary STRING,
    death1 STRING,
    return1 STRING,
    death2 STRING,
    return2 STRING,
    death3 STRING,
    return3 STRING,
    death4 STRING,
    return4 STRING,
    death5 STRING,
    return5 STRING,
    notes STRING
)
CSV DATA ("https://raw.githubusercontent.com/bernacamargo/PMD-tutorial/main/marvel.csv")
;
```

Caso a importação não encontre nenhum problema, o retorno esperado deve ser:

            job_id       |  status   | fraction_completed | rows | index_entries | bytes
    ---------------------+-----------+--------------------+------+---------------+--------
    619735075436953602 | succeeded |                  1 |  159 |             0 | 31767
    (1 row)

    Time: 617ms total (execution 617ms / network 0ms)


Agora realize um SELECT na tabela para ver seus dados.

```sql
SELECT * FROM commic_book.marvel;
```

Agora chegou o momento de realizarmos nossos testes para averiguar a tolerância a falhas e a escalabilidade do CockroachDB.
#
### 4. Testes de tolerância a falhas

>Nota: É importante ressaltar que temos um cluster kubernetes, composto de três instâncias de máquinas virtuais (3 workers), onde as pods são executadas e cada pod representa um nó do CockroachDB. Dessa forma quando falamos sobre os nós do cockroachdb estamos nos referindo as pods e quando falamos dos nós do cluster estamos nos referindo as instâncias de máquina virtual do Kubernetes.
    
A tolerância à falhas tem como objetivo impedir que alguma mudança da nossa base de dados seja perdida por conta de algum problema, com isso é realizado o método de replicação para que todos os nós tenham as mudanças realizadas, e assim caso um nó tenha algum problema, o outro nó do sistema terá as informações consistentes. 

Sabendo disso, vamos simular alguns casos para você perceber o este funcionamento. 
Antes de simular uma falha do nó, vamos passar pelo conceito da replicação na prática, para isso vamos efeturar uma operação de atualização(UPDATE) em um nó e verificar o que acontece com os outros nós. 

#### 4.1. Replicação de dados

Primeiramente vamos verificar como está o dado que desejamos modificar, execute o seguinte comando SQL para busca-lo na tabela `marvel`.

```sql
SELECT url, name_alias FROM commic_book.marvel WHERE url='http://marvel.wikia.com/Anthony_Stark_(Earth-616)';
```

O retorno esperado é:

                            url                        |   name_alias
    ----------------------------------------------------+-----------------
    http://marvel.wikia.com/Anthony_Stark_(Earth-616) | Homem de ferro
    (1 row)

    Time: 2ms total (execution 1ms / network 0ms)


Execute o comando abaixo para realizar a alteração no nó 2. 

```sql
UPDATE commic_book.marvel SET name_alias = 'Homem de ferro' WHERE  url='http://marvel.wikia.com/Anthony_Stark_(Earth-616)';
```

E agora acesse o nó 1, repetindo os passos da etapa [3](https://github.com/bernacamargo/PMD-tutorial#3-executando-comandos-sql-na-pod), e após entrar no build-in SQL, execute a consulta abaixo

```sql
SELECT url, name_alias FROM commic_book.marvel WHERE url='http://marvel.wikia.com/Anthony_Stark_(Earth-616)';
```
Como podemos observar, a atualização foi realizada e também foi replicada para as outras pods. Dessa forma podemos realizar este mesmo teste com as outras pods e veremos que todas estão sincronizadas.

#### 4.2 Simulando a falha de uma pod.
   
Vamos deletar um nó do cockroachdb utilizando o comando abaixo:
   
```shell
$ kubectl delete pod cockroachdb-2
```
        
Você terá o retorno que o nó foi deletado.  

    pod "cockroachdb-2" deleted

O que é interessante, é que no arquivo `example.yaml`, definimos que teremos `3 nodes` executando o cockroachdb. Então quando deletamos o nó 2, o Kubernets irá verificar que o nó 2 teve uma falha, e  automaticamente reiciciará a pod e atualizará os dados baseados nos outros nós.

Executando esse comando no terminal, verificamos que a pod já foi reiniciada e esta com o **status: Running**. 
        
```shell
$ kubectl get pod cockroachdb-2
```

    NAME            READY     STATUS    RESTARTS   AGE
    cockroachdb-2   1/1       Running   0          15s
  
### 5 Testes de Escalabilidade

O NewSQL utiliza a escalabilidade horizontal, que consiste em utilizar mais equipamentos e existe a partionalização dos dados de acordo com os critérios de cada projeto, diferente do vertical, que consiste em aumentar a capacidade da máquina, porém no horizontal também temos o aumento de capacidade de memória e de processamento, mas isso terá o impacto pela soma das máquinas em funcionamento. 

Para entender o motivo que precisamos realizar este escalomamento, vamos supor que existe uma necessidade de processamento maior dos dados num período de tempo, como por exemplo a black friday (data em novemembro em que o comércio realiza descontos em cima de produtos), para isso seja necessário um aumento de quantidade de máquina para que não tenha impacto no processamento para o cliente final, mas em outras datas não tenha o mesmo volume de acesso, então podemos reduzir também nossas pods para que tenha uma redução no valor de processamento. 

Todas essas ações são necessários estudos e estragégias que vão depender do propósito e abordagem desejada para cada projeto, por isso é importante se aprofundar para analisar os impactos positivos de cada ação, para que isso não atinja o usuário final. 

>Nota: Vale ressaltar que o cockroachdb precisa de pelo menos 3 nós para funcionar em cloud do cockroach.

#### 5.1. Modificar o número de nós do cockroachdb

Nesta etapa iremos editar a quantidade de `nodes` que nossa aplicação do cockroachdb irá se sustentar.

Primeiramente abra o arquivo `example.yaml`

```shell
$ vim example.yaml
```

Agora altere a última linha que explicita o número de nodes da aplicação e defina para **5** o valor dos `nodes`

O arquivo alterado deve ficar da seguinte forma:

```yaml
...
tlsEnabled: true
image:
    name: cockroachdb/cockroach:v20.2.0
nodes: 5
```

Com o arquivo salvo, podemos executar o deploy da aplicação novamente com o comando

```shell
$ kubectl apply -f example.yaml
```

O retorno deve ser parecido com o seguinte:

    crdbcluster.crdb.cockroachlabs.com/cockroachdb configured

>Nota: O comando `apply` do Kubernetes permite que alteremos a configuração inicial da aplicação do cockroachdb sem que seja necessário reinicia-la.

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

>Nota: Para realizar a redução na quantidade de nós basta refazer o procedimento explicado acima reduzindo o número de nós. 
#
## SingleStore

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

#### 2.1. rbac.yaml
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

2.2 singlestore-cluster-crd.yaml

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

2.3 deployment.yaml

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

2.4 singlestore-cluster.yaml 

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
- Altere o campo `license` e cole a sua [licença do SingleStore](https://portal.singlestore.com/licenses);
- Defina no campo `adminHashedPassword` sua senha encriptografada para o usuário `admin`
O hash existente no arquivo representa a senha `123456`, o qual utilizaremos para esse tutorial. Caso queira criar uma senha utilize o seguinte algoritmo:
```python
from hashlib import sha1
print("*" + sha1(sha1('secretpass').digest()).hexdigest().upper())
```
- Altere o campo `redundancyLevel` para `2` caso deseje ativar o recruso de [Alta Disponibilidade](https://docs.singlestore.com/v7.3/guides/cluster-management/high-availability-and-disaster-recovery/managing-high-availability/managing-high-availability/);
- Altere os campos `count` para aumentar ou diminuir a quantidade de nós agregadores ou folha;
- O campo `height` define a quantidade de núcleos de CPU e memória RAM serão separados para o nó. O valor `1` representa a quantidade recomendada: `8 núcleos CPU e 32GB RAM`. O menor valor possível é `0.5` que representa metade da quantidade recomendada, ou seja, `4 núcleos CPU e 16GB RAM`;
- Os campos `storageGB` definem a quantidade de armazenamento que será solicitado para cada volume persistente nos nós.

> Nota: Todos os arquivos .yaml acima também estão disponiveis na [documentação do SingleStore](https://docs.singlestore.com/v7.3/guides/deploy-memsql/self-managed/kubernetes/step-3/).


### 3. Fazendo o deploy

#### 3.1 Primeiramente precisamos instalar os recursos do memsql
```shell
$ kubectl apply -f singlestore/operator-rbac.yaml
```

    serviceaccount/memsql-operator created
    role.rbac.authorization.k8s.io/memsql-operator created
    rolebinding.rbac.authorization.k8s.io/memsql-operator created

#### 3.2 Agora instale as definições de recurso para o Operator

```shell
$ kubectl apply -f singlestore/operator-crd.yaml
```
    customresourcedefinition.apiextensions.k8s.io/memsqlclusters.memsql.com created
#### 3.3 Realize o deploy do MemSQL Operator

```shell
$ kubectl apply -f singlestore/operator-deploy.yaml
```

    deployment.apps/memsql-operator created

#### 3.4 Aguarde a pod chamada "memsql-operator" ter seu status como `Running`

```shell
$ kubectl get pods
```
    NAME                               READY   STATUS    RESTARTS   AGE
    memsql-operator-5f4b595f89-hfqzt   1/1     Running   0          14s

#### 3.5 Finalmente iremos realizar o deploy do cluster MemSQL.

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

A partir deste momento já temos nosso cluster Memsql configurado e funcionando, dessa forma já podemos iniciar os testes com querys SQL básicas.

### 4. Acessando o Cluster

#### 4.1 Verificar os serviços criados no deploy

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

#### 4.2. Baixe o arquivo CSV para importação

Agora vamos precisar copiar nosso arquivo `marvel.csv` para o container que está executando o memsql.

```shell
$ kubectl exec -it [POD_NAME] -- bash
$ curl -O https://raw.githubusercontent.com/bernacamargo/PMD-tutorial/using-gcloud/marvel.csv
```

#### 4.3. Acesse o banco de dados

> Nota: Para continuar é necessário que você tenha o MySQL instalado em sua máquina.

Como já temos nossas credenciais, podemos iniciar a conexão com o serviço. Para isso basta acessar via bash ou qualquer interface utilizando os seguintes dados:

    HOST              PORTA         USUÁRIO         SENHA
    35.247.216.80     3306          admin           123456

```shell
$ mysql -u admin -h 35.247.216.80 -P 3306 -p
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
#### 4.4. Crie o banco de dados.

```sql
CREATE DATABASE commic_book;
```
#### 4.5. Popular a base de dados

```sql
CREATE TABLE commic_book.marvel (
    url VARCHAR(255),
    name_alias VARCHAR(255),
    appearances VARCHAR(255),
    current VARCHAR(255),
    gender VARCHAR(255),
    probationary VARCHAR(255),
    full_reserve VARCHAR(255),
    years VARCHAR(255),
    years_since_joining VARCHAR(255),
    honorary VARCHAR(255),
    death1 VARCHAR(255),
    return1 VARCHAR(255),
    death2 VARCHAR(255),
    return2 VARCHAR(255),
    death3 VARCHAR(255),
    return3 VARCHAR(255),
    death4 VARCHAR(255),
    return4 VARCHAR(255),
    death5 VARCHAR(255),
    return5 VARCHAR(255),
    notes VARCHAR(255)
);
```

```sql
LOAD DATA INFILE "/home/memsql/marvel.csv"
INTO TABLE commic_book.marvel
FIELDS TERMINATED BY ',';
```

> Nota: o arquivo utilizado para importação é o que consta no git, [marvel](https://raw.githubusercontent.com/bernacamargo/PMD-tutorial/main/marvel.csv)
### 5. Testes de tolerância à falhas

Relembrando o objetivo da tolerância à falhas, ela impede que alguma mudança da nossa base de dados seja perdida por conta de algum problema, com isso é realizado o método de replicação para que todos os nós tenham as mudanças realizadas, e assim caso um nó tenha algum problema, o outro nó do sistema terá as informações consistentes. 

Sabendo disso, vamos simular alguns casos para você perceber o este funcionamento, antes de simular uma falha do nó, vamos passar pelo conceito da replicação na prática.

Diferentemente do cockroach, em que configuramos um cluster totalmente replicado, no SingleStore temos um cluster gerenciado pelo nó master e seus dados armazenados e particionados em seus nós folha. Dessa forma só devemos realizar as operações de dados no nosso nó master, e assim a partição será realizada nas folhas através dos nossos agregadores, assim qualquer consulta que é feita pelo nó master, é processados pelos nós folhas. Isso ficará mais claro na prática, que demostraremos abaixo.


#### 5.1 Simulando a falha de uma pod.
   
Após nos termos populado nosso banco pelo nosso nó master, nós vamos deletar o nosso nó master com o comando abaixo:
   
```shell
$ kubectl delete pods node-memsql-cluster-master-0
```

Você terá o retorno que o nó foi deletado.  

    pod "node-memsql-cluster-master-0" deleted

Então quando deletamos o nó, o Kubernets irá reiniciar o nó baseados nos nós folhas, ou seja, irá recriar o banco atraves das partições, então se rodarmos esse comando no terminal, verificamos que a pod já foi reiniciada e esta com o **status: Running**. 
        
```shell
$ kubectl get pods
```

E podemos acessar o banco de dados no nó master e verificar que a nossa base de dados está atualizada. 
'''
colocar os bagulhos aqui 
'''

### 6. Testes de escalabilidade
#
## Conclusões

