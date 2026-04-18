# 07_04 - State Locking

Sem lock, dois `apply` simultâneos podem corromper o state. **Lock** serializa mudanças: apenas um Terraform por vez consegue modificar determinado state.

## Por que lock é crítico

Cenário sem lock:

1. Alice roda `apply`. Terraform lê state, aplica mudanças, grava state v5.
2. **Paralelamente**, Bob roda `apply`. Lê state v4 (antes de Alice gravar), aplica suas mudanças com base num state desatualizado, grava state v5' sobrescrevendo o de Alice.
3. **Resultado**: recursos criados por Alice sumiram do state; no próximo `plan`, o Terraform acha que precisa criar de novo (já existem) → erros.

Com lock:

1. Alice roda `apply`. Terraform adquire lock.
2. Bob roda `apply`. Recebe `Error acquiring the state lock`. Espera.
3. Alice termina, libera lock.
4. Bob começa com state atualizado.

## Backends com lock nativo

- **`s3`** + **DynamoDB** (`dynamodb_table` obrigatório para lock).
- **`gcs`** (lock via object generation).
- **`azurerm`** (lock via blob lease).
- **`http`** (se o servidor implementar endpoints de lock).
- **`remote`**/`cloud` (Terraform Cloud gerencia).
- **`consul`**, **`pg`**, **`kubernetes`**.

Backend **local** também tem lock — via `flock` no disco — mas só protege contra processos na **mesma máquina**.

## Como o lock funciona no S3 + DynamoDB

Terraform escreve um item numa tabela DynamoDB:

```json
{
  "LockID": "minha-empresa-tfstate/prod/rede/terraform.tfstate-md5",
  "Operation": "OperationTypeApply",
  "Info": "",
  "Who": "alice@laptop",
  "Version": "1.9.0",
  "Created": "2026-04-17T12:00:00Z",
  "Path": "minha-empresa-tfstate/prod/rede/terraform.tfstate"
}
```

Se o item existe, qualquer outro Terraform que tentar gravar recebe erro.

Após finalizar (sucesso ou falha), Terraform apaga o item.

## Erros típicos

```
Error acquiring the state lock

Error message: ConditionalCheckFailedException: ...
Lock Info:
  ID:        abc123
  Path:      s3://.../terraform.tfstate
  Operation: OperationTypeApply
  Who:       alice@laptop
  Version:   1.9.0
  Created:   2026-04-17 12:00:00 UTC
```

Soluções:

1. **Esperar**: se outro apply está em andamento, aguarde.
2. **Consultar** quem está aplicando (campo `Who`).
3. **`force-unlock`** apenas se garantir que ninguém está aplicando:

```bash
terraform force-unlock abc123
```

O ID vem na mensagem de erro.

## Locks "fantasmas"

Às vezes o lock fica preso quando:

- O `apply` foi interrompido (`Ctrl+C` + `kill -9`).
- Crash de rede/VPN no meio.
- Container de CI foi morto abruptamente.

Investigação no DynamoDB:

```bash
aws dynamodb scan --table-name terraform-locks
```

Se houver item antigo (`Created` de horas atrás), provavelmente é fantasma. Confirme com o time e então `force-unlock`.

## Lock timeouts e retries

Flags úteis:

```bash
# Esperar até 10 minutos por um lock
terraform apply -lock-timeout=10m

# Desabilitar lock (perigoso, só use como último recurso)
terraform apply -lock=false
```

Bom padrão em CI: `-lock-timeout=5m`.

## Boas práticas

1. **Sempre** configure lock no backend remoto.
2. Em **dev local**, aceite esperar pelo lock em vez de burlar (`-lock=false`).
3. Em **CI**, garanta que cada pipeline serializa (um job apply por vez por state).
4. **Observe logs**: CloudTrail/Audit para detectar tentativas concorrentes suspeitas.
5. Monitore **itens órfãos** no DynamoDB (script de limpeza pode ajudar).

## Lock vs. workspaces

Cada workspace tem **seu próprio state** e **seu próprio lock**. Isso é bom: ambientes `dev` e `prod` não se bloqueiam mutuamente.

## Exemplo: script para auditar locks órfãos (AWS)

```bash
#!/bin/bash
TABLE="terraform-locks"
NOW=$(date -u +%s)
STALE_HOURS=2

aws dynamodb scan --table-name $TABLE --output json | \
jq -r --arg now $NOW --argjson hours $STALE_HOURS '
  .Items[] |
  select((($now | tonumber) - ((.Created.S | fromdateiso8601))) > ($hours * 3600)) |
  .LockID.S
'
```

Roda em cron e envia alerta se encontrar lock antigo.

## Resumo

- Lock impede corrupção por concorrência.
- Backends remotos têm lock nativo — use-os.
- `force-unlock` é emergencial, não rotina.
- Configure `-lock-timeout` e monitore locks órfãos.

No próximo tópico: **dados sensíveis no state** e como protegê-los.
