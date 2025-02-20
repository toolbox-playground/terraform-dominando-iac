# terraform-exemplo-aws
Repositório exemplo para uso didático. Aprendizado de Terraform com AWS.

## O que irá encontrar no repositório?
Neste repositório, temos exemplos básicos de execução de terraform com base na AWS. A ideia é trazer de uma forma mais figurativa e prática os passos a passos de cenários de uso do `Terraform` no dia a dia.

## Como configurar o seu ambiente

### Pré Requisito
Seguir passo a passo da instalação do [Terraform](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli).

### Estrutura do repositório
```
|__.github                          # Pasta com os arquivos de CI/CD para o GitHub Actions
|__exercicios                       # Exercícios 
|  |__1-... 
|  |  |__main.tf                    # Arquivo principal para execução do terraform
|  |__2-...                          
|__modulos                          # Módulos para execução de infra estrutura
|__CHANGELOG.md                     # Arquivo de controle de changes do repositório
|__CONTRIBUTINT.md                  # Arquivo com diretrizes de contribuição
|__package.json                     # Arquivo necessário para geração de versionamento automático
|__README.md                        # Você está lendo esse arquivo
|__.versionrc                       # Arquivo necessário para configuração de versionamento
```

### Como executar os exercícios

- É muito importante conhecer os comandos básicos de terraform. 
- Dentro de cada `main.tf`, alterar os placeholder como: `<ALGUMA_COISA_ESCRITA>`
- Criar três variáveis de ambiente e adicionar o conteúdo do da chave criado no console da AWS
- Execute a pré configuração do ambiente:\

*Para Linux*
```
export AWS_ACCESS_KEY_ID="<ACCESS_KEY_ID>"
export AWS_SECRET_ACCESS_KEY="<SECRET_ACCESS_KEY>"
export AWS_DEFAULT_REGION="<DEFAULT_REGION>"
terraform init && terraform plan
```
- Sempre execute os comandos na seguencia: `validate`, `plan` e `apply`. 

Em casos de dúvidas, siga o passo-a-passo [aqui](https://registry.terraform.io/providers/hashicorp/aws/latest/docs#authentication-and-configuration).

### Pastar de exercícios

*1 - Variaveis estáticas*\
Aqui encontraremos um cenário simples, onde todos os parametros já estarão no arquivo main.tf.\
*2 - Variaveis dinâmicas*\
Aqui encontraremos um cenário onde passaremos os dados através de um arquivo ou por command-line.\
*3 - Depends On* WIP \ 
Aqui encontraremos um cenário onde a criação do recurso depende da criação de outro recurso.\
*4 - Deletando Recurso* WIP \
Aqui, removeremos um projeto do arquivo main.tf.\
*5 - Limpando todos recursos* WIP \
Aqui usaremos o destroy para eliminar nossa infra.\

## Contribuindo
Contribuições são bem-vindas! Por favor, leia o arquivo [CONTRIBUTING.md](CONTRIBUTING.md) para mais detalhes.

## Licença
Este projeto está licenciado sob a Licença MIT - veja o arquivo [LICENSE.md](LICENSE.md) para mais detalhes.

### Controle de versão
Para control de versão automático usamos a lib [commit-and-tag-version](https://github.com/absolute-version/commit-and-tag-version)