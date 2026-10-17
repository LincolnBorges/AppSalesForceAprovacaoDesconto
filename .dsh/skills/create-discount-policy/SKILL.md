---
name: create-discount-policy
description: Cria ou atualiza uma política de desconto do Deal Desk (DD_DiscountPolicy__c) — piso de margem, alvo, teto de desconto, alçada e vigência — por família de produto e price book. Use quando o humano pedir para criar, alterar, ativar ou desativar uma política de desconto, ou quando for preciso definir o piso de margem de um produto/segmento.
---

# Skill — create-discount-policy

Cria ou atualiza a **política de desconto** que o guardrail usa como referência.

## 0. Pré-requisitos

- `DD_DiscountPolicy__c` precisa existir (Fase 2). Se não existir, **pare**: a criação do objeto é
  decisão de metadado, não de dados, e segue o checklist `validate-metadata`.
- Confirmar a org antes de qualquer escrita:
  ```sql
  SELECT Id, IsSandbox, OrganizationType, TrialExpirationDate FROM Organization
  ```
  Sem `TrialExpirationDate` e sem `IsSandbox` = produção → **parar** (S1).

## 1. Elicitação (uma pergunta por mensagem, máx. 3 opções)

Nunca assumir. Perguntar, nesta ordem, só o que **não** puder ser descoberto na org:

| # | Pergunta | Por que é decisão humana |
|---|---|---|
| 1 | Família de produto (ou "todas") | Define o alcance da política |
| 2 | Price book (ou "todos") | Proxy de segmento/canal |
| 3 | **Piso de margem** (%) | Decisão de negócio — nunca inventar |
| 4 | Margem alvo (%) | Idem |
| 5 | Teto de desconto (%) | Idem |
| 6 | Alçada de aprovação | Quem decide quando fura o piso |
| 7 | Vigência (início/fim) | Idem |

**Descobrir antes de perguntar:** as famílias existentes e os price books vêm da org, não do humano.

```sql
SELECT Family, COUNT(Id) c FROM Product2 WHERE Family != null AND IsActive = true
GROUP BY Family ORDER BY COUNT(Id) DESC
```
```sql
SELECT Id, Name, IsActive FROM Pricebook2 WHERE IsActive = true ORDER BY IsStandard, Name
```

## 2. Verificar duplicidade (idempotência)

```sql
SELECT Id, Name, ProductFamily__c, Pricebook__c, FloorMarginPct__c, IsActive__c
FROM DD_DiscountPolicy__c
WHERE ProductFamily__c = '<familia>' AND Pricebook__c = <'<pbId>' | null>
```
- Existe e está ativa → **atualizar**, não criar (registrar o valor anterior para rollback, S10).
- Existe e está inativa → perguntar ao humano se é para reativar ou criar nova vigência.

## 3. Regra de precedência (obrigatória)

| Situação | Política aplicada |
|---|---|
| Família **E** price book específicos | Vence — é a mais específica |
| Família específica, `Pricebook__c = null` | Aplica para qualquer price book daquela família |
| Nem um nem outro | **Não há política** → o guardrail não decide. Reportar como pendência, **não** inventar piso |

## 4. Payload

Um registro por vez (S4), após confirmação explícita (S3). Campos:

| Campo | Valor |
|---|---|
| `Name` | `DEMO-Policy-<Família>-<Pricebook>` (S11 — prefixo obrigatório) |
| `ProductFamily__c` | da elicitação, **validado** contra a org |
| `Pricebook__c` | Id vindo de SOQL (nunca inventado) |
| `FloorMarginPct__c` · `TargetMarginPct__c` · `MaxDiscountPct__c` | da elicitação |
| `EscalationRole__c` · `SlaHours__c` · `RequiresJustification__c` | da elicitação |
| `IsActive__c` | `true` |
| `EffectiveFrom__c` / `EffectiveTo__c` | da elicitação |
| `CurrencyIsoCode` | **`USD`** (D5/A13 — nunca omitir) |

Antes de criar, rodar o checklist de `validate-metadata`.

## 5. Verificação pós-escrita (obrigatória)

```sql
SELECT Id, Name, ProductFamily__c, Pricebook__c, FloorMarginPct__c, TargetMarginPct__c,
       MaxDiscountPct__c, IsActive__c, CurrencyIsoCode
FROM DD_DiscountPolicy__c WHERE Id = '<id criado>'
```
Conferir: `CurrencyIsoCode = USD`; percentuais iguais aos confirmados; `Name` com prefixo `DEMO-`.

## 6. Registro

Entrada em [`docs/execution-log.md`](../../../docs/execution-log.md) com `Id`, payload, valor anterior
(se update) e como reverter. Atualizar [`MEMORY.md`](../../../MEMORY.md) §1.2 se a política for
referência para as próximas fases.

## 7. Erros comuns

| Sintoma | Causa provável |
|---|---|
| `REQUIRED_FIELD_MISSING` | Campo `nillable=false` não lido — extrair **todos** antes do payload (A21) |
| `Name` duplicado | Idempotência não foi checada (§2) |
| Percentual gravado errado | `Percent` na API é fração? Conferir o valor relido, não o enviado |
| `INVALID_FIELD` em campo custom novo | Cache do describe pode estar defasado — reconferir com `sf_describe_object` |
