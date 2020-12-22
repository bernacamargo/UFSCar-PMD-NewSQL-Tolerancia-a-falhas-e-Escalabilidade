# Tolerância à falha e escalabilidade com Cockroachdb e MemSQL

### Autores
- Bernardo Pinheiro Camargo [@bernacamargo](https://github.com/bernacamargo)
- Renata Praisler

### Objetivos
No contexto de bancos de dados relacionais e distribuídos, temos como objetivo planejar e elaborar um tutorial intuitivo que permita a qualquer pessoa interessada testar e verificar as características relacionadas a tolerância às falhas e escalabilidade.

### Introdução

### Tecnologias Habilitadores

- Kubernetes
- Docker
- Cockroachdb
- MemSQL
- Google Kubernetes Engine (GKE)

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



### MemSQL