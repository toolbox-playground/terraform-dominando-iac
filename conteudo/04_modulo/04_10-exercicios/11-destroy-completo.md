# Exercício 11 - Destruição completa

## Contexto

A equipe decidiu que um ambiente de testes não é mais necessário. Você precisa remover toda a infraestrutura criada pelo Terraform, garantindo que nada fique cobrando.

## Objetivo

Executar um `terraform destroy` com confiança, observando o plano de destruição e confirmando que nada ficou para trás.

## Pré-requisitos

Ter um diretório Terraform com pelo menos um recurso aplicado (pode ser o bucket S3 do Exercício 15 do Módulo 3, ou qualquer outro).

## Tarefas

### 1. Plano de destruição

```bash
terraform plan -destroy
```

Observe:

- Quantos recursos serão destruídos?
- A ordem (deve respeitar dependências).
- Recursos com `prevent_destroy` falham aqui? (Ver `lifecycle`.)

### 2. Destroy

```bash
terraform destroy
```

Leia atentamente o plano e confirme com `yes` apenas se estiver certo.

### 3. Verifique no console da nuvem

Abra o console AWS/GCP e confirme que os recursos desapareceram:

- Bucket S3: `aws s3 ls`
- EC2: `aws ec2 describe-instances --query 'Reservations[].Instances[?State.Name==\`running\`].[InstanceId,Tags]'`

### 4. Estado após destroy

```bash
terraform state list
```

Deve retornar vazio.

### 5. Cenário: destroy parcial

Reaplique a infra (`terraform apply`) e depois destrua apenas um recurso:

```bash
terraform destroy -target="aws_s3_bucket.logs"
```

- Quais recursos foram destruídos?
- Aplique novamente — o Terraform recria só o bucket, preservando o resto.

### 6. Reflexão

- Qual o impacto de destruir um recurso com dependentes?
- Como você protegeria um recurso crítico de destroy acidental? (Pesquise `lifecycle { prevent_destroy }`.)

## Critério de conclusão

- Destroy executado com sucesso.
- Console da nuvem confirma deleção.
- Você testou pelo menos um `destroy -target`.

## Referências

- [Tópico 04_01 - Destroy](../04_01-destroy.md)
- [lifecycle prevent_destroy](https://developer.hashicorp.com/terraform/language/meta-arguments/lifecycle#prevent_destroy)
