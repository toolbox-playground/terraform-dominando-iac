# 04_01 - Destroy

## O que faz

`terraform destroy` **remove todos os recursos** gerenciados pela configuração atual. É o oposto simétrico de `apply`:

- `apply`: estado desejado (código) > estado atual → cria/modifica.
- `destroy`: estado desejado = vazio → destrói tudo.

```bash
terraform destroy
```

O Terraform mostra o plano de destruição e pede confirmação.

## Por que importa

- **Ambientes efêmeros** (dev, feature branches, demos) precisam ser derrubados para não gerar custo.
- **Limpeza de laboratórios** após estudos.
- **Descomissionamento** de projetos inteiros.
- Em **CI/CD**, um job pode criar ambiente de teste e destruí-lo ao final.

## Funcionamento

Internamente, o destroy é equivalente a:

```bash
terraform plan -destroy
terraform apply -destroy
```

Ele:

1. Lê o state.
2. Lê a realidade na nuvem (refresh).
3. Monta grafo de dependências **invertido**.
4. Destrói recursos na ordem certa (dependentes primeiro).
5. Atualiza state.

## Exemplo

```text
Terraform will perform the following actions:

  # aws_instance.web will be destroyed
  - resource "aws_instance" "web" {
      - ami           = "ami-0123" -> null
      - instance_type = "t3.micro" -> null
      # ...
    }

  # aws_s3_bucket.logs will be destroyed
  - resource "aws_s3_bucket" "logs" {
      - bucket = "logs-prod-2026" -> null
      # ...
    }

Plan: 0 to add, 0 to change, 2 to destroy.

Do you really want to destroy all resources?
  Terraform will destroy all your managed infrastructure, as shown above.
  There is no undo. Only 'yes' will be accepted to confirm.

  Enter a value:
```

## Flags importantes

| Flag | Uso |
|------|-----|
| `-auto-approve` | Sem confirmação. CI only. |
| `-target=ADDR` | Destrói só um recurso (e dependentes). |
| `-var` / `-var-file` | Variáveis. |
| `-parallelism=N` | Paralelismo. |
| `-refresh=false` | Sem refresh (mais rápido; pode falhar se state estiver desatualizado). |

## Destruir apenas um recurso

```bash
terraform destroy -target="aws_s3_bucket.logs_temp"
```

Casos válidos:

- Limpar recurso temporário sem afetar o resto.
- Recuperar de estado inconsistente.

Casos ruins:

- "Quero remover esse recurso do gerenciamento do Terraform". Para isso use `terraform state rm`, não destroy.

## Ordem de destruição

Terraform destrói respeitando dependências, **invertidas**:

- Se um resource depende de outro, o dependente é destruído primeiro.
- Ex.: `aws_eip` (Elastic IP) depende de `aws_instance` → destrói EIP primeiro, depois a instância.

**Atenção**: dependências implícitas (via atributo) funcionam; dependências semânticas (ex.: políticas IAM que precisam ser soltas antes do recurso principal) podem precisar de `depends_on` explícito.

## Cenários onde destroy falha

### 1. Recurso não é deletável pela API

Ex.: bucket S3 com objetos dentro. Por padrão, a AWS impede delete.

Solução: adicionar `force_destroy = true` ao recurso:

```hcl
resource "aws_s3_bucket" "logs" {
  bucket        = "logs-prod-2026"
  force_destroy = true
}
```

Cuidado: é perigoso em prod.

### 2. Dependência externa

Ex.: VPC com recursos criados fora do Terraform (alguém subiu uma EC2 no console usando essa VPC). A VPC não deleta.

Solução: remover manualmente o recurso órfão ou usar `-target` para destruir só o que é possível.

### 3. Timeouts

Alguns recursos (RDS, EKS) demoram minutos pra deletar. Provider tem timeouts default; você pode ajustar:

```hcl
resource "aws_db_instance" "main" {
  # ...
  timeouts {
    delete = "30m"
  }
}
```

### 4. Lifecycle `prevent_destroy`

```hcl
resource "aws_db_instance" "prod" {
  # ...
  lifecycle {
    prevent_destroy = true
  }
}
```

Com isso, `destroy` falha em prod deliberadamente. Bom para recursos críticos.

## Boas práticas

### Sempre revise o plan antes

Aceitar sem olhar "25 resources will be destroyed" em prod é receita de desastre.

### Use `prevent_destroy` em recursos críticos

Bancos de produção, DNS principal, IAM root policies — tudo que um `destroy` acidental seria catastrófico.

### Ambientes efêmeros com CI/CD

```yaml
# pipeline CI
teardown:
  script:
    - terraform init
    - terraform destroy -auto-approve
  when: manual  # ou automático em schedule
```

### Backup antes de destruir

Se há dados (snapshots de RDS, backup de S3, export de configuração), **faça backup** antes do destroy. Destroy é irreversível.

### Não destrua "pra refazer" sem pensar

Tentando resolver drift com "destroy tudo e refaz"? Revise primeiro — refazer em prod pode gerar novo hostname, novo IP, downtime.

## Alternativas ao destroy total

- **`terraform state rm`**: remove do gerenciamento sem destruir na nuvem.
- **`-target`**: destrói apenas um recurso.
- **Comentando código + apply**: remover `resource` do código e aplicar → Terraform entende como destroy daquele recurso específico.

## Referências

- [terraform destroy](https://developer.hashicorp.com/terraform/cli/commands/destroy)
- [lifecycle prevent_destroy](https://developer.hashicorp.com/terraform/language/meta-arguments/lifecycle#prevent_destroy)
