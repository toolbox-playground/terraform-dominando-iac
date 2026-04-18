# Módulo 11 - Exercícios

Sequência de exercícios que constroem, do zero, um pipeline Terraform completo no GitLab.

## Lista

1. [Pipeline de validação](01-pipeline-validate.md)
2. [State remoto no GitLab](02-state-gitlab.md)
3. [Plan em MR + apply em main](03-plan-apply-mr.md)
4. [OIDC com AWS](04-oidc.md)
5. [Multi-ambiente (dev/hml/prod)](05-multi-ambiente.md)
6. [Publicar módulo na GitLab Terraform Registry](06-publicar-modulo.md)

## Progressão sugerida

Faça **em sequência**. Cada exercício assume o que foi feito no anterior.

Ao final do exercício 5, você terá um pipeline **pronto para produção** com segurança, progressão e approvals. O exercício 6 fecha o ciclo com módulos reutilizáveis versionados.

## Ambiente necessário

- Conta GitLab (gitlab.com serve).
- Opcional: AWS / GCP / Azure para aplicar de verdade (ou LocalStack para simulação).
- Terraform >= 1.6 localmente (para init inicial antes do CI assumir).

## Custo estimado

- Pipelines na gitlab.com: plano free tem minutos limitados — suficiente para o curso.
- AWS: se usar só `null_resource` + `random`, custo é zero.
- AWS com EC2/RDS: cuidado com `terraform destroy` ao final para não queimar saldo.
