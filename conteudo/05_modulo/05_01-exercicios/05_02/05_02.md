# 05_02 - Exercício Utilizando Meta Argumentos no Terraform

## Objetivo
	•	Aprender a utilizar os meta argumentos count, for_each e lifecycle.
	•	Criar múltiplos recursos de forma dinâmica.
	•	Proteger e gerenciar mudanças na infraestrutura com lifecycle.

## Cenário

Você precisa criar uma infraestrutura AWS que contenha:
	1.	Múltiplas instâncias EC2, usando count para criá-las dinamicamente.
	2.	Múltiplos buckets S3, utilizando for_each para mapear os nomes dos buckets.
	3.	Proteção contra destruição acidental, usando lifecycle.

### Passo 1: Inicializando e Aplicando o Terraform
Execute o arquivo **main.tf** presente nesse diretório:
```bash
terraform init
terraform apply -auto-approve
```

### Passo 2: Criando Múltiplos Buckets S3 com for_each

Agora, vamos criar buckets S3 dinamicamente a partir de uma lista de nomes.

# Conclusão

✅ O que você aprendeu?  
	•	Como criar múltiplos recursos dinamicamente com count e for_each.  
	•	Como proteger recursos contra destruição acidental usando lifecycle.prevent_destroy.  
	•	Como evitar que certas configurações sejam alteradas com lifecycle.ignore_changes.  

# Desafio Extra
	1.	Modifique count para criar instâncias com tipos diferentes, alternando entre t2.micro e t3.micro.  
	2.	Adicione mais configurações ao lifecycle, como create_before_destroy para recriar um recurso antes de destruir o antigo.  
	3.	Experimente criar buckets com for_each usando um mapa, onde cada bucket tenha uma tag diferente.  
