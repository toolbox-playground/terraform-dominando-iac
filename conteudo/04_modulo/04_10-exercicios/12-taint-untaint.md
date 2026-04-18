# Exercício 12 - Taint, Untaint e `-replace`

## Contexto

Você deseja simular a necessidade de **recriar** um recurso, como se ele tivesse sido corrompido. Vai experimentar o comando `taint` (histórico) e a forma moderna (`-replace`).

## Objetivo

Entender como forçar a recriação de um recurso via state e via flag, reconhecendo as diferenças e quando cada abordagem é apropriada.

## Pré-requisitos

- Ter um diretório com pelo menos um recurso simples (ex.: `aws_instance` ou `aws_s3_bucket`) já aplicado.

## Tarefas

### 1. Usar `-replace` (moderno, recomendado)

```bash
terraform plan -replace="aws_instance.web"
```

Observe:

- O plan mostra `-/+ resource` com a nota "will be replaced, as requested".
- Quantos recursos são afetados? Só o que você pediu, ou os dependentes também?

Aplique:

```bash
terraform apply -replace="aws_instance.web"
```

Confirme no console que a instância foi **destruída e recriada** (o ID mudou).

### 2. Experimentar `taint` (depreciado)

```bash
terraform taint aws_instance.web
```

Observe:

- A saída avisa que `taint` está depreciado.
- O state foi alterado diretamente (`terraform state list` ainda mostra, mas com flag de tainted internamente).

Rode `terraform plan`:

- O plan mostra `-/+`, mas **sem** a nota "as requested" — é como se o Terraform "inferisse" que precisa recriar.

Desfaça:

```bash
terraform untaint aws_instance.web
terraform plan
```

Agora o plan volta a "no changes".

### 3. Comparar as duas abordagens

| Aspecto | `taint` | `-replace` |
|---------|---------|-----------|
| Modifica state direto? | Sim, na hora | Não, só no apply |
| Aparece no plan? | Indiretamente | Sim, explícito |
| Reversível? | Com `untaint` | Basta não aplicar |
| Status oficial | Depreciado | Oficial moderno |

### 4. `replace_triggered_by` (avançado)

Teste o meta-argumento moderno:

```hcl
resource "aws_instance" "web" {
  ami           = "ami-0123"
  instance_type = "t3.micro"

  lifecycle {
    replace_triggered_by = [
      null_resource.rebuild_trigger.id
    ]
  }
}

resource "null_resource" "rebuild_trigger" {
  triggers = {
    deploy_version = var.deploy_version
  }
}
```

Agora rode:

```bash
terraform apply -var="deploy_version=1"
terraform apply -var="deploy_version=2"
```

- O que acontece na segunda execução?
- Sem `replace_triggered_by`, aconteceria o mesmo?

## Critério de conclusão

- Você conseguiu forçar replace usando `-replace`.
- Entende por que `taint` foi depreciado.
- Conhece a alternativa moderna `replace_triggered_by`.

## Referências

- [Tópico 04_06 - Taint/Replace](../04_06-taint-replace.md)
- [replace_triggered_by](https://developer.hashicorp.com/terraform/language/meta-arguments/lifecycle#replace_triggered_by)
