# Guia de Instalação do Terraform

Este guia fornece instruções para a instalação do Terraform no seu sistema operacional.

## Requisitos

Sistema operacional compatível:
- Windows
- macOS
- Linux

- Acesso à linha de comando (cmd, PowerShell, Terminal ou Bash)
- Permissões de administrador para instalar pacotes

## Instalação

### Windows

Acesse o site oficial do Terraform: https://developer.hashicorp.com/terraform/downloads

Baixe o pacote correspondente ao Windows (arquivo ZIP)
Extraia o conteúdo do arquivo ZIP em um diretório de sua preferência (exemplo: C:\terraform)
Adicione o caminho do diretório extraído à variável de ambiente Path:
No Windows, abra o Painel de Controle > Sistema > Configurações Avançadas do Sistema

Clique em Variáveis de Ambiente
No campo Path, adicione o caminho onde o Terraform foi extraído
Para verificar a instalação, abra o Prompt de Comando ou PowerShell e execute:

```
terraform -v
```

### macOS

Instale usando Homebrew:

```
brew tap hashicorp/tap
brew install hashicorp/tap/terraform
```

Verifique a instalação:
```
terraform -v
```

Caso não tenha o Homebrew instalado, siga as instruções no site https://brew.sh

### Linux

Usando um pacote pré-compilado
Baixe o pacote adequado para seu sistema no site oficial: https://developer.hashicorp.com/terraform/downloads
Extraia o binário e mova para /usr/local/bin:

```
unzip terraform_*.zip
sudo mv terraform /usr/local/bin/
```

Verifique a instalação:
```
terraform -v
```

Usando um gerenciador de pacotes (Ubuntu/Debian)
Adicione o repositório do HashiCorp:
```
sudo apt update && sudo apt install -y gnupg software-properties-common
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update
```

Instale o Terraform:
```
sudo apt install terraform
```
Verifique a instalação:
```
terraform -v
```


Após a instalação, você pode verificar se o Terraform está funcionando corretamente executando:
```
terraform version
```

Isso exibirá a versão instalada do Terraform.