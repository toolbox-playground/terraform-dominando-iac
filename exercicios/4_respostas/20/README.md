## Passos para Utilização dos Workspaces

Inicialize o Terraform:
```
terraform init
```

Crie os Workspaces para Cada Ambiente: Crie os workspaces para os ambientes dev, staging e prod:
```
terraform workspace new dev
terraform workspace new staging
terraform workspace new prod
```

Selecione um Workspace e Aplique as Configurações: Por exemplo, para trabalhar no ambiente de desenvolvimento:
```
terraform workspace select dev
terraform apply
```

Repita o processo para os demais ambientes, selecionando o workspace desejado.