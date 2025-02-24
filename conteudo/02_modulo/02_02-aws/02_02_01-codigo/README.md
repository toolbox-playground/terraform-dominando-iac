# terraform-exemplo-aws
Repositório exemplo para uso didático. Aprendizado de Terraform com AWS.

## O que irá encontrar no repositório?
Neste repositório, temos exemplos básicos de execução de terraform com base na AWS. A ideia é trazer de uma forma mais figurativa e prática os passos a passos de cenários de uso do `Terraform` no dia a dia.

## Como configurar o seu ambiente

### Pré Requisito
Seguir passo a passo da instalação do [Terraform](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli).


### Como executar os exercícios

- É muito importante conhecer os comandos básicos de terraform. 
- Dentro de cada `main.tf`, alterar os placeholder como: `<ALGUMA_COISA_ESCRITA>`
- Criar três variáveis de ambiente e adicionar o conteúdo do da chave criado no console da AWS
- Execute a pré configuração do ambiente:\

*Para Windows com powershell*
```
$env:AWS_ACCESS_KEY_ID = ""
$env:AWS_SECRET_ACCESS_KEY = ""
terraform init; terraform plan; 
```

*Para Linux*
```
export AWS_ACCESS_KEY_ID="<ACCESS_KEY_ID>"
export AWS_SECRET_ACCESS_KEY="<SECRET_ACCESS_KEY>"
export AWS_DEFAULT_REGION="<DEFAULT_REGION>"
terraform init && terraform plan
```
- Sempre execute os comandos na seguencia: `validate`, `plan` e `apply`. 

Em casos de dúvidas, siga o passo-a-passo [aqui](https://registry.terraform.io/providers/hashicorp/aws/latest/docs#authentication-and-configuration).

