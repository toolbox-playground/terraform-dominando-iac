# 06_02 - required_providers

## Onde declarar

O bloco `required_providers` vive **dentro** do bloco `terraform`:

```hcl
terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}
```

## Por que é obrigatório

Até o Terraform 0.13, providers oficiais podiam ser detectados automaticamente pelo prefixo do recurso. A partir do 0.14, `required_providers` é **obrigatório** para:

- Garantir **reprodutibilidade**.
- Permitir múltiplos providers do mesmo tipo (ex.: `aws` oficial + `aws` custom fork).
- Suportar **registries privados** e namespaces customizados.
- Permitir `alias` de providers em múltiplas configs.

## Estrutura de cada entrada

```hcl
<nome_local> = {
  source                = "HOSTNAME/NAMESPACE/TYPE"  # obrigatório
  version               = "..."                       # fortemente recomendado
  configuration_aliases = [aws.us_east, aws.eu_west]  # opcional, módulos
}
```

### `nome_local`

É como você **referencia** o provider dentro deste módulo. Normalmente você usa o nome do tipo (`aws`, `google`), mas poderia ser qualquer coisa:

```hcl
required_providers {
  mycloud = {
    source  = "hashicorp/aws"
    version = "~> 5.0"
  }
}

# Usa o nome local ao configurar
provider "mycloud" {
  region = "us-east-1"
}
```

Na prática: **use o nome idiomático** (`aws`, `google`, `azurerm`) para não confundir leitores.

### `source`

Formato: `[HOSTNAME/]NAMESPACE/TYPE`.

- **HOSTNAME** (opcional): padrão `registry.terraform.io`.
- **NAMESPACE**: organização que mantém (`hashicorp`, `cloudflare`).
- **TYPE**: nome curto do provider (`aws`, `google`).

Se omitir hostname, assume o Registry público da HashiCorp.

Registry privado:

```hcl
source = "terraform.empresa.com/plataforma/aws-internal"
```

### `version`

Constraint em SemVer. Veja [06_01 - O que são Providers](06_01-o-que-sao-providers.md#versão-version) para a tabela de operadores.

**Boa prática**: use `~> X.Y` em libraries/modules e `~> X.Y.Z` em aplicações estáveis.

### `configuration_aliases`

Só importa em **módulos reutilizáveis** que recebem providers configurados externamente. Detalhado em [06_04 - Aliases e múltiplas instâncias](06_04-aliases-multiplas-instancias.md).

## Arquivo `versions.tf` convencional

Uma convenção muito adotada (e que este curso recomenda): centralizar `required_providers` em um arquivo `versions.tf`:

```hcl
# versions.tf
terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
```

Vantagens:

- Fácil de achar as versões.
- Atualização centralizada.
- Ferramentas (Renovate, Dependabot) sabem onde olhar.

## Múltiplos providers no mesmo projeto

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}
```

Projeto típico de produção usa **3 a 8 providers**. Muito normal ver AWS + Kubernetes + Helm + Datadog + Cloudflare.

## Fluxo com `terraform init`

Quando você declara/ajusta `required_providers`, rode `terraform init`. Ele:

1. Lê os `source` + `version`.
2. Consulta o Registry.
3. Baixa o binário compatível para `.terraform/providers/...`.
4. Registra a versão exata escolhida em `.terraform.lock.hcl`.

Detalhes completos em [06_05 - Autenticação e credenciais](06_05-autenticacao.md) e no Módulo 3 (`terraform init`).

## Upgrades

Para atualizar um provider:

```bash
# Atualiza respeitando a constraint
terraform init -upgrade
```

Isso **sobrescreve** `.terraform.lock.hcl`. Revise o diff no commit.

Se você mudar a `version` para algo fora da constraint atual do lock (ex.: de `~> 5.0` para `~> 6.0`), também é necessário `-upgrade`.

## Erros comuns

- **Esquecer `required_providers`**: Terraform 1.x geralmente avisa, mas alguns fluxos falham.
- **Usar versões exatas em tudo**: impede adoção de patches de segurança. Prefira `~>`.
- **Não commitar `.terraform.lock.hcl`**: gera inconsistência entre devs e CI.
- **Remover manualmente a pasta `.terraform/`**: ok, mas rode `init` em seguida.
- **Versão do provider incompatível com a da CLI**: provider novo pode exigir Terraform 1.6+, por exemplo.

## Validação rápida

```bash
# Listar providers instalados
terraform providers

# Ver resolução de versões
terraform version

# Mostrar lock resultante
cat .terraform.lock.hcl
```

No próximo tópico: **configuração do bloco `provider`**.
