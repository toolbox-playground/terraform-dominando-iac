# 02_03 - Exercício Modificando e Destruindo Recursos com Terraform

## Objetivo
Ensinar sobre a mutabilidade e imutabilidade da infraestrutura.  

### Passos
1. Modifique um Recurso:  
- No main.tf, altere a ACL do bucket de "private" para "public-read";  
- Execute:
```bash
terraform plan
terraform apply
```
- Observe as mudanças.  

2. Destrua a Infraestrutura:  
- Execute terraform destroy para remover os recursos criados;  
- Confirme a remoção na interface web ou CLI do provedor.  

