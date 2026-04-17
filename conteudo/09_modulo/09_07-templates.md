# 09_07 - Templates e `templatefile`

Quando você precisa gerar arquivos (user-data, manifest Kubernetes, policy JSON), use templates.

## `templatefile(path, vars)`

Lê um arquivo e substitui `${...}` pelos valores do map passado.

### Arquivo `templates/user-data.sh.tpl`:

```bash
#!/bin/bash
set -e

echo "Ambiente: ${ambiente}"
echo "Host: ${hostname}"

apt-get update
apt-get install -y ${pacote}

systemctl enable --now ${servico}
```

### Uso:

```hcl
resource "aws_instance" "web" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"

  user_data = templatefile("${path.module}/templates/user-data.sh.tpl", {
    ambiente = var.ambiente
    hostname = "web-${var.ambiente}"
    pacote   = "nginx"
    servico  = "nginx"
  })

  tags = {
    Name = "web-${var.ambiente}"
  }
}
```

Terraform lê o arquivo, substitui as variáveis, e passa como string para `user_data`.

## Por que usar arquivos externos

- **Editor com highlight** (bash, YAML, JSON).
- **Testável**: você pode rodar o script sozinho (substituindo por valores manualmente) antes de plugar no Terraform.
- **Reutilizável** entre recursos.
- **Diff limpo** em PRs (apenas o template, sem HCL ao redor).

## Diretivas dentro de templates

Você pode usar condicionais e loops:

```bash
#!/bin/bash
echo "Deploy de ${app}"

%{ if debug }
set -x
%{ endif }

%{ for pacote in pacotes ~}
apt-get install -y ${pacote}
%{ endfor ~}
```

Chamada:

```hcl
user_data = templatefile("${path.module}/user-data.sh.tpl", {
  app      = "api"
  debug    = var.ambiente != "prod"
  pacotes  = ["nginx", "curl", "jq"]
})
```

## Templates YAML / JSON

### JSON via `jsonencode`

Prefira `jsonencode` ao invés de template para JSON:

```hcl
resource "aws_iam_policy" "app" {
  name = "app-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["s3:GetObject"]
      Resource = "${aws_s3_bucket.dados.arn}/*"
    }]
  })
}
```

Sem risco de escapes errados.

### YAML via `yamlencode`

```hcl
locals {
  deployment = yamlencode({
    apiVersion = "apps/v1"
    kind       = "Deployment"
    metadata   = { name = "app" }
    spec = {
      replicas = 3
      # ...
    }
  })
}
```

Para YAMLs muito grandes, ainda pode ser interessante usar `templatefile` com `.yaml.tpl`.

## `file()` vs. `templatefile()`

- **`file("path")`**: lê arquivo cru, sem substituição.
- **`templatefile("path", vars)`**: lê e substitui.

```hcl
user_data = file("${path.module}/static.sh")         # cru
user_data = templatefile("${path.module}/dynamic.sh", { ... })
```

## `path.module` vs. `path.root` vs. `path.cwd`

| Variável | Descrição |
|----------|-----------|
| `path.module` | Diretório do módulo atual |
| `path.root` | Raiz do projeto (onde `terraform init` rodou) |
| `path.cwd` | Diretório em que `terraform` foi invocado |

Em módulos reutilizáveis, **sempre** use `path.module`:

```hcl
templatefile("${path.module}/templates/x.tpl", vars)
```

## Limites de tamanho

User-data AWS: **16 KB** após base64. Scripts gigantes ou devem:

- Ser divididos e baixados em tempo de boot via S3.
- Usar `cloud-init` com múltiplos stages.

## Templates + `for_each`

Cada iteração tem seu próprio template:

```hcl
resource "aws_s3_object" "config" {
  for_each = var.aplicacoes

  bucket = aws_s3_bucket.configs.id
  key    = "configs/${each.key}.yaml"

  content = templatefile("${path.module}/templates/config.yaml.tpl", {
    app_name = each.key
    replicas = each.value.replicas
    image    = each.value.image
  })
}
```

## Template heredoc inline

Quando o template é curto:

```hcl
resource "aws_iam_role_policy" "x" {
  # ...
  policy = <<-EOT
  {
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Action": "s3:GetObject",
      "Resource": "${aws_s3_bucket.x.arn}/*"
    }]
  }
  EOT
}
```

Mas prefira `jsonencode` — menos error-prone.

## Evitar escape hell

Se o template tem muitos `$` literais (ex.: variáveis bash), escape com `$$`:

```bash
#!/bin/bash
FOO=$$USER     # $USER literal, não interpolado pelo Terraform
BAR=${ambiente}  # interpolado pelo Terraform
```

## Boas práticas

- **Arquivos externos** com extensão que indica o conteúdo (`.sh.tpl`, `.yaml.tpl`, `.json.tpl`).
- **Pasta `templates/`** por módulo.
- **Minimize lógica no template**; prefira preparar em HCL e passar pronto.
- **Teste o template** substituindo valores manualmente.

## Exemplo: config Nginx parametrizada

Arquivo `templates/nginx.conf.tpl`:

```nginx
server {
    listen ${porta};
    server_name ${hostname};

    %{ for path, upstream in rotas ~}
    location ${path} {
        proxy_pass ${upstream};
    }
    %{ endfor ~}
}
```

Uso:

```hcl
resource "aws_s3_object" "nginx_conf" {
  bucket = aws_s3_bucket.configs.id
  key    = "nginx.conf"

  content = templatefile("${path.module}/templates/nginx.conf.tpl", {
    porta    = 80
    hostname = "app.exemplo.com"
    rotas = {
      "/api"   = "http://api-backend:3000"
      "/admin" = "http://admin-backend:4000"
    }
  })
}
```

Próximo tópico: **funções built-in** essenciais.
