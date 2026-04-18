# Módulo 10 - Exercícios

## Lista

1. [Seu primeiro módulo](01-primeiro-modulo.md) *(integra exercício original 16)*
2. [Módulo `bucket-seguro`](02-modulo-bucket-seguro.md)
3. [Composição de módulos (rede + SG + EC2)](03-composicao-modulos.md)
4. [Consumindo módulo da Registry](04-modulo-registry.md)

## Dica geral

Após criar/modificar um módulo, **sempre** rode:

```bash
terraform init    # baixa/reconecta módulos
terraform fmt -recursive
terraform validate
terraform plan
```

Se adicionou o módulo e o Terraform reclama de "Module not installed", é porque você esqueceu o `init`.

## Respostas de referência

Solução de referência do primeiro exercício em [`respostas/`](respostas/).
