# Exercício 01 - Instalar e verificar o Terraform

## Contexto

Você acabou de ingressar em uma equipe de plataforma/DevOps e precisa garantir que o Terraform esteja corretamente instalado na sua máquina local para poder participar dos próximos exercícios do curso.

## Objetivo

Instalar o Terraform no seu sistema operacional e verificar se a instalação foi bem-sucedida.

## Tarefas

1. Escolha um dos métodos de instalação descritos em [02_08-instalacao](../02_08-instalacao/02_08-instalacao.md) apropriado para o seu sistema operacional.
2. Após instalar, execute no terminal:

   ```bash
   terraform version
   ```

   A saída deve indicar a versão instalada (ex.: `Terraform v1.7.5`).

3. (Opcional, recomendado) Instale também um editor preparado:
   - VS Code + extensão **HashiCorp Terraform**.
   - Configure `format on save`.

4. (Opcional, avançado) Instale o **tfenv** para gerenciar múltiplas versões.

## Critério de conclusão

- `terraform version` imprime uma versão >= 1.5.
- Você consegue abrir um arquivo `.tf` no seu editor com syntax highlighting.

## Referências

- Tópico [02_08 - Instalação](../02_08-instalacao/02_08-instalacao.md)
- [developer.hashicorp.com/terraform/install](https://developer.hashicorp.com/terraform/install)
