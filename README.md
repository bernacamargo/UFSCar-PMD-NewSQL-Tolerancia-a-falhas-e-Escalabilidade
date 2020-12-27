# NewSQL - Tolerância à falha e escalabilidade com Cockroachdb e MemSQL

#### Autores
- Bernardo Pinheiro Camargo [@bernacamargo](https://github.com/bernacamargo)
- Renata Praisler [@RenataPraisler](https://github.com/RenataPraisler)

# 

## Objetivo
No contexto de bancos de dados relacionais e distribuídos (NewSQL), temos como objetivo deste projeto planejar e elaborar um tutorial intuitivo que permita a qualquer pessoa interessada testar e validar as características relacionadas a tolerância às falhas e escalabilidade na estrutura de NewSQL.

## Introdução

O NewSQL surgiu como uma nova proposta, pois com o uso do NOSQL acabou apresentando alguns problemas como por exemplo: a falta, do uso de transações, das consultas SQL e a estrutura complexa por não ter uma modelagem estruturada. Ele veio com o objetivo de ter os os pontos positivos dos do modelo relacional para as arquiteturas distribuídas e aumentar o desempenhos das queries de SQL, não tendo a necessidade de servidores mais potentes para melhor execução, e utilizando a escalabilidade horizontal e mantendo as propriedades ACID(Atomicidade, Consistência, Isolamento e Durabilidade).


## Tecnologias Habilitadores

- Kubernetes;
- Docker;
- Google Kubernetes Engine (GKE);
- Cockroachdb;
- MemSQL;

## 

## Cluster Kubernetes

Para podermos simular um ambiente isolado e que garanta as características de sistemas distribuídos utilizaremos um cluster local orquestrado pelo Kubernetes, o qual é responsável por gerenciar instâncias de máquinas virtuais para execução de aplicativos em containers. 

Primeiramente precisamos criar nosso cluster e utilizaremos o GKE para isto:

- Acesse a [Google Cloud Console](https://console.cloud.google.com)
- Navegue até o `Kubernetes Engine` e clique em `Clusters`;
- Clique em `Criar cluster` no centro da janela;
- Defina o nome do cluster e clique em `Criar`.

Feito isso, um cluster com três nós será criado e inicializado. Em alguns momentos você já poderá acessá-lo para seguirmos com as configurações.


> Para ambos os softwares Cockroachdb e MemSQL utilizaremos o mesmo processo para inicialização do cluster kubernetes, porém em clusters diferentes.

## Cockroachdb

Antes de iniciar o teste para identificar como é realizado a tolerância a falhas e a escalabilidade, temos que configurar o Cockroachdb no nosso cluster, para nos auxiliar utilizamos as documentações do Cockroachdb e kubernetes, e citaremos abaixo os comandos que devem ser realizados.

Para configurar a aplicação do cockroachdb dentro do cluster podemos fazer de algumas formas:
- [Usando o Operator](https://kubernetes.io/pt/docs/concepts/extend-kubernetes/operator/)
- [Usando o Helm](https://helm.sh/)
- Usando arquivos de configurações sem ferramentas automatizadoras.

Neste exemplo utilizaremos o Operator fornecido pelo Cockroachdb, iremos automatizar a configuração da aplicação e assim não teremos que perde tempo com alguns detalhes mais técnicos.

#### 1. Instalar o Operator no cluster.

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

1.3. Validar se o Operator está rodando

```shell
$ kubectl get pods
``` 
Caso tenha funcionado, você deverá ter como retorno a seguinte mensagem:

    NAME                                 READY   STATUS    RESTARTS   AGE
    cockroach-operator-6867445556-9x6zp   1/1    Running      0      2m51s

> Nota: Caso o status da pod estiver como "ContainerCreating" é só aguardar alguns instantes que o kubernetes esta iniciando o container e logo deverá aparecer como "Running".

#### 2. Configuração da aplicação do cockroachdb.

2.1. Realize o download e a edição do arquivo `example.yaml`, este é responsável por realizar a configuração básica de uma aplicação do cockroachdb através do Operator.
  
```shell
$ curl -O https://raw.githubusercontent.com/cockroachdb/cockroach-operator/master/examples/example.yaml
```

Utilize o `vim`(ou qualquer editor de texto de sua preferência) para abrir o arquivo baixado no passo anterior.

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

2.5. Verifique se as pods subiram.

```shell
$ kubectl get pods
```

O retorno esperado é:

    NAME                                  READY   STATUS    RESTARTS   AGE
    cockroach-operator-6867445556-9x6zp   1/1     Running   0          43m
    cockroachdb-0                         1/1     Running   0          2m29s
    cockroachdb-1                         1/1     Running   0          104s
    cockroachdb-2                         1/1     Running   0          67sa
    

#### 3. Executando comandos SQL na pod.

Feito isso já temos nosso cluster e nossa aplicação configurados e executando. Agora chegou o momento de realizarmos nossos testes para averiguar a tolerância a falhas e a escalabilidade do CockroachDB.

3.1. Acesse o bash de uma das pods que estão rodando a aplicação

```shell
$ kubectl exec -it cockroachdb-2 bash
```

> Nota: Para alterar qual pod voce está acessando basta alterar a parte do comando `cockroachdb-2` para o nome da pod que você deseja acessar.

3.2. Dentro da pod inicialize o [build-in SQL client](https://www.cockroachlabs.com/docs/v20.2/cockroach-sql) do cockroach

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

3.2. Popular nossa base de dados

Antes de iniciar os testes iremos popular a nossa base de dados através do arquivo [employees.csv](https://github.com/tmcnab/northwind-mongo/blob/master/employees.csv), disponibilizado no GitHub [@tmcnab/northwind-mongo](https://github.com/tmcnab/northwind-mongo/).

```sql
IMPORT TABLE employes (
    EmployeeID UUID PRIMARY KEY,
    LastName TEXT,
    FirstName TEXT,
    Title TEXT,
    TitleOfCourtesy TEXT,
    BirthDate TEXT,
    HireDate TEXT,
    Address TEXT,
    City TEXT,
    Region TEXT,
    PostalCode TEXT,
    Country TEXT,
    HomePhone TEXT,
    Extension TEXT,
    Photo TEXT,
    Notes TEXT,
    ReportsTo TEXT,
    PhotoPath TEXT
)
CSV DATA ('https://raw.githubusercontent.com/tmcnab/northwind-mongo/master/employees.csv')
WITH
    nullif = ''
;
```
### MemSQL
