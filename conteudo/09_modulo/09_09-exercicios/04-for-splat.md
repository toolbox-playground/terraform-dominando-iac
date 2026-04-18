# Exercício 04 - Expressão `for` e operador Splat `[*]`

*(Integra o exercício original 24)*

## Objetivo

Coletar informações de múltiplos recursos criados dinamicamente.

## Tarefa

1. Criar 3 instâncias usando `count`.
2. Expor em outputs:
   - Todos os IDs via **splat** (`aws_instance.web[*].id`).
   - Todos os IPs privados via splat.
   - Um map `{index => id}` via expressão `for`.
   - Uma lista filtrada: somente instâncias cujo `tags.Role == "web"` (quando aplicável).
3. Comparar o output do splat com o de `for`.

## Dicas

```hcl
resource "aws_instance" "web" {
  count = 3

  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"

  tags = {
    Name = "web-${count.index}"
    Role = count.index == 0 ? "leader" : "web"
  }
}

output "ids_splat" {
  value = aws_instance.web[*].id
}

output "ips_privados_splat" {
  value = aws_instance.web[*].private_ip
}

output "mapa_for" {
  value = { for i, inst in aws_instance.web : i => inst.id }
}

output "ids_web_apenas" {
  value = [for inst in aws_instance.web : inst.id if inst.tags.Role == "web"]
}
```

## Verificação

```bash
terraform apply
# ids_splat = ["i-...", "i-...", "i-..."]
# mapa_for = {0="i-...", 1="i-...", 2="i-..."}
# ids_web_apenas = ["i-...", "i-..."]  # só 2 (a primeira é "leader")
```

## Desafio extra

- Repetir o exercício com `for_each = toset(["a", "b", "c"])`.
- Observar que `for_each` não suporta `[*]` direto: usar `values(aws_instance.web)[*].id` ou um `for`.
