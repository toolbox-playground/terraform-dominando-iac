# 11_09 - Boas práticas e armadilhas

Síntese de princípios que valem para qualquer pipeline Terraform, independente de CI escolhido.

## Princípios

### 1. O pipeline é o ponto único de apply

- Ninguém roda `terraform apply` no laptop em prod.
- Local apenas: `fmt`, `validate`, `plan` exploratório.
- CI é a **única** mão que escreve em backends remotos de prod.

### 2. Credenciais efêmeras sempre que possível

- OIDC > Assume role com chave > Chave estática.
- Credenciais escopadas por pipeline/ambiente/projeto.
- Rotação automática: com OIDC, cada job recria.

### 3. Blast radius mínimo

- **Estados separados** por ambiente/stack.
- **Roles IAM separadas** por pipeline.
- **Tags/labels** para identificar o que é `terraform-managed` via qual pipeline.

### 4. Plan revisado antes de apply

- MR com `plan` visível no diff.
- Approval obrigatório (1 ou mais).
- `plan` artifact → `apply` consome o mesmo.
- Em prod: re-plan no momento do apply para detectar drift.

### 5. Revise o que o pipeline executa

- O `.gitlab-ci.yml` **é código** e deve passar por PR.
- Atacantes tendem a alterar pipeline para exfiltrar segredos.
- Require approval em mudanças de `.gitlab-ci.yml` (use [`CODEOWNERS`](https://docs.gitlab.com/ee/user/project/codeowners/)).

## Segurança

### 1. Secrets

- **Nunca** em código ou tfvars commitados.
- **Sempre** em variáveis masked + protected do GitLab.
- Prefira **Secrets Manager / Vault** e puxe em runtime.
- Marque outputs derivados de secrets como `sensitive = true`.

### 2. State

- Criptografado em repouso (S3 SSE, GitLab disk encryption).
- Acesso restrito (só quem precisa).
- Backup periódico (cron de `state pull`).

### 3. Logs

- Masked tokens automaticamente pelo GitLab.
- Redija logs customizados: `set +x` antes de comando com secret.
- Jobs públicos (em repos abertos) = cuidado redobrado.

### 4. Dependências

- Pinne versões de providers, módulos, images Docker.
- `.terraform.lock.hcl` commitado.
- Use registries internas mirror-adas para módulos críticos.
- Revise updates com ferramentas como [Renovate](https://docs.renovatebot.com/).

### 5. Branch e tag protection

- `main` protegida, apenas merge via MR aprovada.
- Tags de release protegidas.
- `CODEOWNERS` para arquivos críticos.

## Qualidade

### 1. Hierarquia de checks

```
1. fmt            (milissegundos)
2. validate       (segundos)
3. tflint         (segundos)
4. checkov / tfsec (segundos)
5. plan           (minutos — só depois de tudo passar)
```

Rápido primeiro. Caro por último.

### 2. Pipelines reusáveis

- Crie repo `ci-templates` com jobs reutilizáveis.
- Consumidores fazem `include: project: infra/ci-templates`.
- Versione com tags.

### 3. Testes funcionais

- [Terratest](https://terratest.gruntwork.io/) (Go) para testes E2E.
- [`terraform test`](https://developer.hashicorp.com/terraform/language/tests) (nativo, beta) para testes de unidade.
- Ambiente ephemeral em conta sandbox.
- Cleanup automático via `on_stop` action.

### 4. Estimativa de custo

[Infracost](https://www.infracost.io/) em MR mostra diferença de custo:

```yaml
infracost:
  stage: validate
  image: infracost/infracost:ci-latest
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
  script:
    - infracost breakdown --path . --format json --out-file infracost.json
    - infracost comment gitlab --path infracost.json --repo $CI_PROJECT_PATH --merge-request $CI_MERGE_REQUEST_IID --gitlab-token $INFRACOST_GITLAB_TOKEN
```

## Operação

### 1. Monitoramento

- Dashboards de pipelines (success rate, duration, drift).
- Alertas em Slack/Teams para falhas em prod.
- Integração com Datadog/Grafana via webhooks.

### 2. Drift detection

Schedule diário: `terraform plan -detailed-exitcode`. Notifique quando exit code = 2.

### 3. DR (Disaster Recovery)

- Backup de state em outro storage (cron de `state pull`).
- Teste de `destroy + recreate` em ambiente sandbox.
- Documente runbooks para recovery de cada stack.

### 4. Observabilidade de deploys

- Environments do GitLab mostram histórico.
- Tags em recursos: `ManagedByPipeline = "gitlab-ci-123"`, `LastAppliedAt = timestamp()`.

## Pitfalls comuns

### 1. `tfplan` reaproveitado entre ambientes

**Errado**: gerar plan em `dev`, aplicar em `prod` com o mesmo tfplan. Cada ambiente tem state próprio.

### 2. `apply` em branch errada

Sempre limitar com `rules: if $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH`.

### 3. Secrets em logs

Nunca: `echo "token: $SECRET_TOKEN"`. Mesmo com masking, evite.

### 4. Dependência circular de states

Stack A lê state de B via `terraform_remote_state`; B lê de A. Impossível aplicar do zero. **Evite**.

### 5. Muitos `if`s empilhados em rules

```yaml
rules:
  - if: $A == "x" && $B == "y" && ($C == "z" || $D)
```

Vira inmanutenível. Separe em jobs distintos.

### 6. Imagens Docker ad-hoc

`image: hashicorp/terraform:latest` é instável. Use version pinned (`:1.9.0`).

### 7. Runners shared sem isolamento

Runners que rodam muitos projetos podem vazar contexto (cache, temporários, imagens). Use runners dedicados para prod.

### 8. `allow_failure: true` sorrateiro

Fácil esconder problema pondo `allow_failure: true`. Só use quando tiver certeza que o job pode falhar sem consequência.

### 9. Ignorar drift

Drift em dev é aviso; drift em prod é alarme. Ative detection e **responda**.

### 10. Sem plano de onboarding

Novo dev não sabe:
- Como criar MR de infra.
- Quem aprova.
- Como debugar pipeline vermelho.
- Onde estão as credenciais.

**Documente** isso num README de plataforma.

## Checklist de maturidade

Use como auto-avaliação da sua operação:

- [ ] Todo apply em prod passa por CI.
- [ ] OIDC (ou equivalente) configurado.
- [ ] States separados por ambiente.
- [ ] Branch `main` protegida.
- [ ] Environments protegidas.
- [ ] Approval humano em prod.
- [ ] Plan visível em MR (widget ou comentário).
- [ ] `fmt`, `validate`, `tflint`, `checkov` em pipeline.
- [ ] `.terraform.lock.hcl` commitado.
- [ ] Módulos versionados com SemVer.
- [ ] Módulos publicados em registry privada.
- [ ] Drift detection schedule ativo.
- [ ] CHANGELOG automático ou revisado.
- [ ] Infracost em MR.
- [ ] Runbooks de rollback e DR.
- [ ] Onboarding documentado.
- [ ] DORA metrics acompanhadas.

Atingir 100% leva tempo. Comece pelos itens críticos (segurança, separação de estados, plan em MR).

## Antipadrões a evitar

- **"Roda localmente, manda pra mim"**: sem apply local em prod.
- **"Vou commitar o state só dessa vez"**: nunca.
- **"tfvars com senha, tudo bem"**: nunca.
- **"Pipeline manual resolvendo tudo"**: automatize.
- **"Módulo sem versão, só main"**: breaking changes em silêncio.
- **"CI_JOB_TOKEN deu erro, vou usar meu PAT"**: PAT pessoal vira dependência individual.

## Resumo

Segurança, qualidade e operabilidade são os três pilares. Segurança protege — qualidade evita retrabalho — operabilidade permite crescer. Nenhum sozinho basta.

Próximo tópico: **exercícios** que consolidam tudo.
