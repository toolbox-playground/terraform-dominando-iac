### Boas práticas:

- Não versionar o arquivo state: Adicione os arquivos terraform.tfstate e terraform.tfstate.backup ao arquivo .gitignore para evitar que sejam commitados.

- Utilizar armazenamento remoto: Configure backends remotos (por exemplo, S3) para centralizar e proteger o state.

- Segurança: Garanta que o backend remoto utilize criptografia e políticas de acesso restritivas.
Essas práticas evitam a exposição de informações sensíveis e facilitam a colaboração na infraestrutura.