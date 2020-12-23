# NewSQL - Tolerância à falha e escalabilidade com Cockroachdb e MemSQL

### Autores
- Bernardo Pinheiro Camargo [@bernacamargo](https://github.com/bernacamargo)
- Renata Praisler [@renatapraisler](https://github.com/RenataPraisler)

### Objetivos
No contexto de bancos de dados relacionais e distribuídos, temos como objetivo planejar e elaborar um tutorial intuitivo que permita a qualquer pessoa interessada testar e verificar as características relacionadas a tolerância às falhas e escalabilidade na estrutura de NewSQL.

### Introdução

### Tecnologias Habilitadores

- Kubernetes;
- Docker;
- Cockroachdb;
- MemSQL;
- Google Kubernetes Engine (GKE).

## 

### Cluster Kubernetes

Para podermos simular um ambiente isolado e que garanta as características de sistemas distribuídos utilizaremos um cluster local orquestrado pelo Kubernetes, o qual é responsável por gerenciar instâncias de máquinas virtuais para execução de aplicativos em containers. 

Primeiramente precisamos criar nosso cluster e utilizaremos o GKE para isto:

- Acesse a [Google Cloud Console](https://console.cloud.google.com)
- Navegue até o `Kubernetes Engine` e clique em `Clusters`;
- Clique em `Criar cluster` no centro da janela;
- Defina o nome do cluster e clique em `Criar`.

Feito isso, um cluster com três nós será criado e inicializado. Em alguns momentos você já poderá acessá-lo para seguirmos com as configurações.

> Para ambos os softwares testados utilizaremos o mesmo processo para inicialização do cluster kubernetes.

### Cockroachdb

Antes de iniciar o teste para identificar como é realizado a tolerância a falhas e a escalabilidade, temos que configurar o Cockroachdb no nosso cluster, para nos auxiliar utilizamos as documentações do Cockroachdb e  kubernets, e citaremos abaixo os comandos que devem ser realizados.

  - Iniciar o Operator do nosso cluster. 
> O operator,  será responsável por manter a operação do cockroachdb dentro do nosso cluster, assim toda vez que a gente for iniciar o nó (pods), ele irá instalar tudo que é necessário dentro deste nó (pods)  

  1. Estartar o minikube no seu Cluster
  
    > minikube start
  2. Aplicar o CustomResourceDefinition (CRD) do Operator(operador)
  
    > kubectl apply -f https://raw.githubusercontent.com/cockroachdb/cockroach-operator/master/config/crd/bases/crdb.cockroachlabs.com_crdbclusters.yaml
  3. Aplicar o Operator manifest
  
    > kubectl apply -f https://raw.githubusercontent.com/cockroachdb/cockroach-operator/master/manifests/operator.yaml
    
  4. Validar se o Operator está rodando
  
    > kubectl get pods
    
  Ele deverá responder como o exemplo abaixo:
  
     clusterrole.rbac.authorization.k8s.io/cockroach-operator-role created
  serviceaccount/cockroach-operator-default created
  clusterrolebinding.rbac.authorization.k8s.io/cockroach-operator-default created
  deployment.apps/cockroach-operator created


  - Agora vamos partir para configuração em si do cluster.
  
  1. Realize o download e a edição do arquivo exemple.yaml, ele vai informar as configurações que o opertator deve ter para a configuração do nosso cluster.
  
  > curl -O https://raw.githubusercontent.com/cockroachdb/cockroach-operator/master/examples/example.yaml
  > vi example.yaml
  
  2. Neste passo vamos configurar nossa CPU e memoria para cada pod(nó) do nosso cluster. Neste caso, vamos utilizar o mímimo de configuração que é possível para atingir nosso objetivo de teste.
  
  >  resources:
     requests:
        cpu: "2"
        memory: "8Gi"
      limits:
        cpu: "2"
        memory: "8Gi"
      
   3. Modifique o resources.requests.storage
   
   > resources:
    requests:
    storage: "1Gi"
   
    Obs: caso você queira outra configuração para outro teste ou projeto, se atente de verificar as configurações necessárias disponibilizadas [aqui](https://www.cockroachlabs.com/docs/v20.2/recommended-production-settings#hardware)

### MemSQL
