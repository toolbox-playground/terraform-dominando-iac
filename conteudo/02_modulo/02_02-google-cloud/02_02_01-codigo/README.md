# terraform-exemplo-gcp
Repositório exemplo para uso didático. Aprendizado de Terraform com GCP

## O que irá encontrar no repositório?
Neste repositório, temos exemplos básicos de execução de terraform com base no cloud Google Cloud Platform. A ideia é trazer de uma forma mais figurativa e prática os passos a passos de cenários de uso do `Terraform` no dia a dia.

## Como configurar o seu ambiente

### Pré Requisito
Seguir passo a passo da instalação do [Terraform](https://developer.hashicorp.com/terraform/tutorials/gcp-get-started/install-cli).
Seguir passo a passo da instalação do [gcloud sdk](https://cloud.google.com/sdk/docs/install).

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
~- Criar uma variavem de ambiente `GOOGLE_CREDENTIALS` e adicione o conteúdo do .json da sua service account conforme orientado ~
- Faça download da chave .json para autenticar com o Google Cloud e salve na raiz do projeto com o nome `gcp.json`
- Execute a pré configuração do ambiente:\

*Para Windows com powershell*
```
$jsonContent = Get-Content gcp.json | ConvertFrom-Json
$firstObject = $jsonContent[0] | ConvertTo-Json -Compress
$env:GOOGLE_CREDENTIALS = $firstObject
terraform init; terraform plan; 
```

*Para Linux*
```
export GOOGLE_CREDENTIALS=$(cat gcp.json | jq -c )
export GOOGLE_APPLICATION_CREDENTIALS=gcp.json
terraform init && terraform plan
```
- Sempre execute os comandos na seguencia: `validate`, `plan` e `apply`. 

Em casos de dúvidas, siga o passo-a-passo [aqui](https://registry.terraform.io/providers/hashicorp/google/latest/docs/guides/provider_reference#running-terraform-outside-of-google-cloud).

### Pastar de exercícios

*1 - Variaveis estáticas*\
Aqui encontraremos um cenário simples, onde todos os parametros já estarão no arquivo main.tf.\
*2 - Variaveis dinâmicas*\
Aqui encontraremos um cenário onde passaremos os dados através de um arquivo ou por command-line.\
*3 - Depends On*\
Aqui encontraremos um cenário onde a criação do recurso depende da criação de outro recurso.\
*4 - Deletando Recurso*\
Aqui, removeremos recursos criados pelo `main.tf.` usando destroy.\

## Contribuindo
Contribuições são bem-vindas! Por favor, leia o arquivo [CONTRIBUTING.md](CONTRIBUTING.md) para mais detalhes.

## Licença
Este projeto está licenciado sob a Licença MIT - veja o arquivo [LICENSE.md](LICENSE.md) para mais detalhes.

### Controle de versão
Para control de versão automático usamos a lib [commit-and-tag-version](https://github.com/absolute-version/commit-and-tag-version)
