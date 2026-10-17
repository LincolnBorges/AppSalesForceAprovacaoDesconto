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

Nunca assumir. Perguntar, nesta ordem, só o que **não** puder ser descoberto na org **e** ainda não
estiver decidido em [`MEMORY.md`](../../../MEMORY.md) §2 — repetir uma decisão já tomada (D12 fixou piso
20 / alvo 30) é desperdício de rodada e convida a divergência.

| # | Pergunta | Por que é decisão humana |
|---|---|---|
| 1 | Família de produto (ou "todas" → valor `All`) | Define o alcance da política |
| 2 | Price book (ou "todos" → `Pricebook__c = null`) | Proxy de segmento/canal |
| 3 | **Piso de margem** (%) | Decisão de negócio — nunca inventar |
| 4 | Margem alvo (%) | Idem |
| 5 | Teto de desconto (%) | Idem |
| 6 | Alçada de aprovação | Quem decide quando fura o piso |
| 7 | Vigência (início/fim) | Idem |

> **Duas perguntas podem ser fundidas sem virar interrogatório:** o teto e a decisão de a política
> específica ser mais rígida que a genérica cabem numa só pergunta de 3 opções. Se as duas políticas
> tiverem números idênticos, a precedência só é observável por `Name`/`Specificity__c` — prefira números
> diferentes para que o teste seja falsificável.

**Descobrir antes de perguntar:** as famílias existentes e os price books vêm da org, não do humano.

```sql
SELECT Family, COUNT(Id) c FROM Product2 WHERE Family != null AND IsActive = true
GROUP BY Family ORDER BY COUNT(Id) DESC
```
```sql
SELECT Id, Name, IsActive FROM Pricebook2 WHERE IsActive = true ORDER BY IsStandard, Name
```

Em que price books uma família realmente vive (evita política para par inexistente — o
`Parts Price Book` **não** contém a família `Parts`):

```sql
SELECT Pricebook2.Name, Pricebook2Id, COUNT(Id) c
FROM PricebookEntry WHERE Product2.Family = '<familia>' AND IsActive = true
GROUP BY Pricebook2.Name, Pricebook2Id ORDER BY Pricebook2.Name
```

**Campos obrigatórios que a elicitação não pode deixar em branco** (`nillable=false`):
`ProductFamily__c`, `FloorMarginPct__c`, `TargetMarginPct__c`, `MaxDiscountPct__c`, `EffectiveFrom__c`.

## 2. Verificar duplicidade (idempotência)

```sql
SELECT Id, Name, ProductFamily__c, Pricebook__c, FloorMarginPct__c, IsActive__c
FROM DD_DiscountPolicy__c
WHERE ProductFamily__c = '<familia>' AND Pricebook__c = <'<pbId>' | null>
```
- Existe e está ativa → **atualizar**, não criar (registrar o valor anterior para rollback, S10).
- Existe e está inativa → perguntar ao humano se é para reativar ou criar nova vigência.

## 3. Regra de precedência (obrigatória)

A precedência **não** é um campo digitado: o objeto a deriva em `Specificity__c`, um campo de fórmula.
Nunca escrever `Specificity__c` no payload.

```
Specificity__c = IF(ISBLANK(Pricebook__c), 0, 2) + IF(ISPICKVAL(ProductFamily__c, "All"), 0, 1)
```

| Nível | Família | `Pricebook__c` | Situação | `Specificity__c` |
|---|---|---|---|---|
| **3** | específica | específico | vence — a mais específica | 3 |
| 2 | `All` | específico | canal/segmento para todas as famílias | 2 |
| 1 | específica | nulo | genérica da família — qualquer price book | 1 |
| 0 | `All` | nulo | padrão global | 0 |
| — | sem política que case | — | **Não há política** → o guardrail não decide. Reportar como pendência, **não** inventar piso | — |

Pergunta que a resolução faz (é este o contrato; `ORDER BY` em campo de fórmula funciona em SOQL,
validado em PRE-001):

```sql
SELECT Id, Name, Specificity__c, FloorMarginPct__c, TargetMarginPct__c, MaxDiscountPct__c
FROM DD_DiscountPolicy__c
WHERE IsActive__c = true
  AND EffectiveFrom__c <= TODAY
  AND (EffectiveTo__c = null OR EffectiveTo__c >= TODAY)
  AND (ProductFamily__c = :familia OR ProductFamily__c = 'All')
  AND (Pricebook__c = :pbId OR Pricebook__c = null)
ORDER BY Specificity__c DESC, EffectiveFrom__c DESC
LIMIT 1
```

- `EffectiveFrom__c DESC` desempata políticas de mesma especificidade.
- Não existe chave única em (família, price book) — de propósito, para permitir **nova vigência** do
  mesmo par depois que a anterior expira. A idempotência do §2 é o que evita a duplicata.

## 4. Payload

Um registro por vez (S4), após confirmação explícita (S3). Campos:

| Campo | Valor |
|---|---|
| `Name` | `DEMO-Policy-<Família>-<Pricebook>`, sem espaços nem acentos; no price book use o apelido curto (`Fleet`, `Standard`, `Retail`) e **`AllPB`** quando for a genérica: `DEMO-Policy-Parts-AllPB`, `DEMO-Policy-Parts-Fleet`, `DEMO-Policy-MedicalEquip-Standard` (S11 — prefixo obrigatório) |
| `ProductFamily__c` | da elicitação, **validado** contra a org; o valor tem de ser **idêntico** ao de `Product2.Family`, inclusive com espaço (`Medical Equipment`). `All` representa todas as famílias |
| `Pricebook__c` | Id vindo de SOQL (nunca inventado). **Omitir o campo** para a genérica — não enviar string vazia |
| `FloorMarginPct__c` · `TargetMarginPct__c` · `MaxDiscountPct__c` | da elicitação, em **unidade percentual** (ver §7) |
| `EscalationRole__c` · `SlaHours__c` · `RequiresJustification__c` | da elicitação |
| `IsActive__c` | `true` |
| `EffectiveFrom__c` / `EffectiveTo__c` | da elicitação; `EffectiveTo__c` nulo = sem fim |
| `CurrencyIsoCode` | **`USD`** (D5/A13 — nunca omitir). O campo **existe** no objeto, ainda que ele não tenha valor monetário próprio |

Antes de criar, rodar o checklist de `validate-metadata`.

## 5. Verificação pós-escrita (obrigatória)

```sql
SELECT Id, Name, ProductFamily__c, Pricebook__r.Name, Specificity__c,
       FloorMarginPct__c, TargetMarginPct__c, MaxDiscountPct__c,
       IsActive__c, EffectiveFrom__c, EffectiveTo__c, CurrencyIsoCode
FROM DD_DiscountPolicy__c WHERE Id = '<id criado>'
```
Conferir, nesta ordem:

1. `CurrencyIsoCode = USD` (S12);
2. percentuais **relidos** iguais aos confirmados;
3. `Name` com prefixo `DEMO-`;
4. **`Specificity__c` igual ao nível esperado pela §3** — é a prova de que a precedência daquela
   política está correta. Genérica de família → `1`; família + price book → `3`.

## 6. Registro

Entrada em [`docs/execution-log.md`](../../../docs/execution-log.md) com `Id`, payload, valor anterior
(se update) e como reverter. Atualizar a tabela de políticas em [`MEMORY.md`](../../../MEMORY.md) §1.7.

## 7. Erros comuns

| Sintoma | Causa provável |
|---|---|
| `REQUIRED_FIELD_MISSING` | Campo `nillable=false` não lido — extrair **todos** antes do payload (A21): são 5, ver §1 |
| `Name` duplicado | Idempotência não foi checada (§2) |
| Percentual gravado errado | **Resolvido na prática (POL-001):** pela API o valor é **unidade percentual** — enviar `20` grava `20%`. A **fração** só vale em fórmula e em validation rule (`1` = 100%). Enviar `0.2` grava `0,2%`, e a diferença é silenciosa: confirmar pelo valor relido |
| `FIELD_CUSTOM_VALIDATION_EXCEPTION` em `DD_Policy_Margin_Bands` | Alvo menor que o piso, ou algum percentual fora de 0–100 |
| `FIELD_CUSTOM_VALIDATION_EXCEPTION` em `DD_Policy_Effective_Dates` | `EffectiveTo__c` anterior a `EffectiveFrom__c` |
| `INVALID_FIELD` em campo custom novo | Cache do describe pode estar defasado — reconferir com `sf_describe_object` |
| `INVALID_TYPE` em `CurrencyIsoCode` | Objeto sem moeda — não é o caso deste: o campo existe, confirmado no describe |

## 8. O que já foi verificado na prática (2026-10-17)

Não redescobrir. Evidência nas entradas `DPM-001`, `POL-001` e `PRE-001` do
[`execution-log`](../../../docs/execution-log.md).

| Fato | Evidência |
|---|---|
| `ORDER BY` em campo de fórmula (`Specificity__c`) **funciona** em SOQL | PRE-001: as 2 candidatas voltaram ordenadas 3 → 1 |
| Específica vence a genérica; sem específica, a genérica resolve sozinha | PRE-001: `Parts` + Fleet devolveu `Parts-Fleet` antes de `Parts-AllPB`; `Parts` + Retail devolveu só `Parts-AllPB` |
| Família sem política devolve **0 linhas** | PRE-001, cenário 4 (`Generator` + Fleet) |
| `CurrencyIsoCode` existe neste objeto e aceita `USD` | 4/4 registros criados em `USD` |
| `Pricebook__c` só aceita `SetNull` — `Restrict`/`Cascade` são proibidos em lookup para `Pricebook2` (A56) | DPM-001: recusado no dry-run |
| Percentual pela API é unidade percentual | POL-001: enviei `20`/`30`/`15` e voltou `20`/`30`/`15` |
| `ORDER BY` em campo de fórmula **funciona**, mas `GROUP BY` **não** — `field 'Specificity__c' can not be grouped in a query call` | PRE-001 usa `ORDER BY`; um relatório por especificidade tem de agregar por `ProductFamily__c`/`Pricebook__c` e agrupar a especificidade fora do SOQL |
