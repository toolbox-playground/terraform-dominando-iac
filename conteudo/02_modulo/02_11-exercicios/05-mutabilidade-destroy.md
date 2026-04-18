# Exercício 05 - Mutabilidade e Destroy

## Objetivo

Observar na prática o comportamento do Terraform ao **modificar** um recurso existente e, em seguida, ao **destruir** toda a infraestrutura criada.

## Pré-requisitos

Ter concluído o [Exercício 03 (Lab AWS)](03-lab-aws/) — a instância EC2 precisa estar provisionada.

## Tarefas

### 1. Modifique um recurso

- Abra o arquivo [`03-lab-aws/instance.tf`](03-lab-aws/instance.tf).
- Altere a tag `Name` de `Toolbox-Playground-AWS-1` para `Toolbox-Playground-AWS-Modified`.
- Execute:

  ```bash
  terraform plan
  ```

- **Observe** o que o Terraform vai fazer. A tag deve aparecer com `~` (modificação in-place), não com `-/+` (replace).

- Aplique:

  ```bash
  terraform apply
  ```

- Confirme no console da AWS que a tag da instância foi alterada.

### 2. Modifique um atributo imutável

- Altere o `instance_type` de `t3.micro` para `t3.small`.
- Execute `terraform plan`.
- **Observe** agora: dependendo da versão do provider e tipo de instância, isso pode ser `~` (update in-place para instance_type é um dos atributos mutáveis do EC2).

- Agora altere o valor da chave da variável `amis` (simule uma AMI diferente). Execute `terraform plan`.
- AMI é **imutável**: o plan vai mostrar `-/+` (destroy + create).
- **Não aplique**; apenas reverta a alteração.

### 3. Destrua a infraestrutura

```bash
terraform destroy
```

- Digite `yes` para confirmar.
- Confirme na interface web da AWS ou CLI que a instância foi removida:

  ```bash
  aws ec2 describe-instances --filters "Name=tag:Name,Values=Toolbox-Playground-AWS-*"
  ```

## Reflexão

- Qual a diferença prática entre modificar **uma tag** e modificar **a AMI**?
- Como isso se relaciona com o conceito de [infraestrutura imutável](../../01_modulo/01_03-infraestrutura-imutavel.md)?
- O que acontece com o `terraform.tfstate` após o `destroy`?

## Critério de conclusão

- Você viu pelo menos um `~` (update) e um `-/+` (replace) no `plan`.
- A infraestrutura foi destruída e o state reflete zero recursos (`terraform show` vazio).
