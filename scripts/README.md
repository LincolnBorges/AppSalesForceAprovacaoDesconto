# scripts/ — consultas e utilitários de apoio

Scripts de linha de comando para as operações recorrentes do projeto. Nada aqui é executado
automaticamente: são atalhos para o agente e para o humano.

---

## `soql/`

| Arquivo | Para quê |
|---|---|
| [`org-baseline.soql`](soql/org-baseline.soql) | Baselines de metadado e detecção de resíduo (comparar com `MEMORY.md` §1.6) |
| [`margin-base.soql`](soql/margin-base.soql) | Base de cálculo da margem: custo por `PricebookEntry`, linhas da cotação, e o que falta semear |
| [`quote-drafts.soql`](soql/quote-drafts.soql) | Cotações em aberto e distribuição por status |

Executar uma consulta:

```bash
sf data query -o personal -f scripts/soql/org-baseline.soql
```

> Os arquivos `.soql` aceitam **uma consulta por linha** quando usados com `-f`; linhas iniciadas por
> `--` são comentários. Ao rodar manualmente, copie apenas a consulta desejada.

---

## Comandos do dia a dia

```bash
# Identidade da org — SEMPRE antes de escrever (S1)
sf data query -o personal -q "SELECT Id, IsSandbox, OrganizationType, TrialExpirationDate FROM Organization"

# Deploy de metadata comum (LWC, Flow, objetos) — dry-run primeiro (S7)
sf project deploy start --dry-run --source-dir force-app --target-org personal --test-level NoTestRun
sf project deploy start --source-dir force-app --target-org personal --test-level NoTestRun

# Metadados de Agentforce — SEMPRE em API 66.0 e por bundle mdapi
sf project deploy start --metadata-dir mdapi --dry-run --target-org personal --test-level NoTestRun
sf org list metadata --metadata-type GenAiFunction --api-version 66.0 -o personal

# Validação de integridade de uma ação de agente (A45/A49 — obrigatória)
sf project retrieve start --metadata "GenAiFunction:<nome>" \
  --target-metadata-dir retrieved --api-version 66.0 --target-org personal
```

---

## Notas

- `config/project-scratch-def.json` existe por herança do template DX e **não é usado**:
  a org alvo já tem tudo provisionado e scratch orgs não expõem o necessário (A7/A8/A9).
- Nenhum script aqui deve conter credenciais. Autenticação vem do Salesforce CLI (`SF_ALIAS`).
