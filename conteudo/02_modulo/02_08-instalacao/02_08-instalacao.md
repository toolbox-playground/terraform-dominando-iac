# 02_08 - Instalação do Terraform

Este guia cobre as formas de instalar e verificar o Terraform em **Windows, macOS e Linux**, além de opções como **tfenv** (gerenciador de versões) e **Docker**.

## Requisitos

- Sistema operacional compatível (Windows 10+, macOS 10.13+, distribuições Linux modernas).
- Acesso à linha de comando (Terminal, PowerShell, cmd, WSL, bash, zsh).
- Permissões de administrador para instalar pacotes.
- Conexão com a internet na primeira execução (`terraform init` baixa providers).

## Instalação por sistema operacional

### Windows

#### Opção 1: Binário direto (mais simples)

1. Acesse [developer.hashicorp.com/terraform/install](https://developer.hashicorp.com/terraform/install).
2. Baixe o ZIP para Windows 64-bit.
3. Extraia o arquivo `terraform.exe` em um diretório (ex.: `C:\terraform`).
4. Adicione esse diretório ao `PATH`:
   - Painel de Controle → Sistema → Configurações Avançadas → Variáveis de Ambiente.
   - Edite `Path`, adicione `C:\terraform`.
5. Abra um novo PowerShell/cmd e verifique:

   ```powershell
   terraform -v
   ```

#### Opção 2: Chocolatey

```powershell
choco install terraform
```

#### Opção 3: Scoop

```powershell
scoop install terraform
```

#### Opção 4: WSL (Windows Subsystem for Linux)

Se você usa WSL, siga as instruções de Linux abaixo dentro do WSL — em geral essa é a experiência mais próxima do que verá em produção.

### macOS

#### Homebrew (recomendado)

```bash
brew tap hashicorp/tap
brew install hashicorp/tap/terraform
```

Verifique:

```bash
terraform -v
```

Para atualizar:

```bash
brew upgrade hashicorp/tap/terraform
```

Se você não tem Homebrew, instale em [brew.sh](https://brew.sh).

#### Binário direto

1. Baixe em [developer.hashicorp.com/terraform/install](https://developer.hashicorp.com/terraform/install) (Darwin amd64 ou arm64).
2. Descompacte:
   ```bash
   unzip terraform_*.zip
   sudo mv terraform /usr/local/bin/
   ```
3. Verifique:
   ```bash
   terraform -v
   ```

### Linux

#### Ubuntu / Debian (apt)

```bash
sudo apt update && sudo apt install -y gnupg software-properties-common

wget -O- https://apt.releases.hashicorp.com/gpg | \
  sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg

echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
  https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
  sudo tee /etc/apt/sources.list.d/hashicorp.list

sudo apt update
sudo apt install terraform
terraform -v
```

#### Fedora / RHEL / CentOS (dnf/yum)

```bash
sudo dnf install -y dnf-plugins-core
sudo dnf config-manager --add-repo https://rpm.releases.hashicorp.com/fedora/hashicorp.repo
sudo dnf -y install terraform
terraform -v
```

#### Arch Linux

```bash
sudo pacman -S terraform
```

#### Binário direto

```bash
wget https://releases.hashicorp.com/terraform/1.7.5/terraform_1.7.5_linux_amd64.zip
unzip terraform_1.7.5_linux_amd64.zip
sudo mv terraform /usr/local/bin/
terraform -v
```

## tfenv — gerenciador de versões

Em times com múltiplos projetos que usam versões diferentes do Terraform, um gerenciador de versões evita dor de cabeça. O **[tfenv](https://github.com/tfutils/tfenv)** é inspirado no `rbenv`/`nvm`.

### Instalação (macOS / Linux)

```bash
brew install tfenv                 # macOS via Homebrew
# ou
git clone https://github.com/tfutils/tfenv.git ~/.tfenv
echo 'export PATH="$HOME/.tfenv/bin:$PATH"' >> ~/.zshrc
```

### Uso

```bash
tfenv list-remote       # ver versões disponíveis
tfenv install 1.7.5     # instala versão específica
tfenv use 1.7.5         # define como padrão
tfenv install latest    # instala a mais recente
```

Você pode colocar um arquivo `.terraform-version` na raiz do seu projeto com a versão desejada — o tfenv troca automaticamente ao entrar no diretório.

### Windows

Use **[tfswitch](https://github.com/warrensbox/terraform-switcher)** (alternativa multiplataforma) ou o próprio tfenv via WSL.

## Docker

Se preferir rodar via container (útil em CI/CD ou ambiente sem instalação):

```bash
docker run --rm -it \
  -v "$(pwd):/workspace" \
  -w /workspace \
  hashicorp/terraform:1.7.5 \
  init
```

Útil para garantir que todo mundo da equipe usa a **mesma versão** sem configurar localmente.

## Autocomplete no terminal

Após instalar, ative autocomplete (bash/zsh):

```bash
terraform -install-autocomplete
```

Reinicie o shell.

## Verificação final

Independente do método usado:

```bash
terraform version
```

Saída esperada:

```text
Terraform v1.7.5
on darwin_arm64
```

Se aparecer "command not found", o binário não está no PATH — revise a instalação.

## Configuração opcional para desenvolvimento

No VS Code, instale a extensão **HashiCorp Terraform** para:
- Sintaxe highlighting.
- Autocomplete de atributos de providers.
- Linting em tempo real.
- Formatação automática ao salvar (se configurado).

Configuração recomendada em `settings.json`:

```json
{
  "editor.formatOnSave": true,
  "[terraform]": {
    "editor.defaultFormatter": "hashicorp.terraform"
  }
}
```

## Referências

- [developer.hashicorp.com/terraform/install](https://developer.hashicorp.com/terraform/install)
- [tfenv](https://github.com/tfutils/tfenv)
- [VS Code Terraform extension](https://marketplace.visualstudio.com/items?itemName=HashiCorp.terraform)
