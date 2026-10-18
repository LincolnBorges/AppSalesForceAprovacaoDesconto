---
name: route-approval
description: Decide e aciona o guardrail de desconto de uma cotação — aprova automaticamente, escala para o aprovador com contexto, ou bloqueia — criando/atualizando o DD_DiscountRequest__c e notificando a alçada. Use quando o vendedor pedir um desconto, quando a margem de uma Quote ficar abaixo do piso da política, ou quando for preciso reenviar/decidir um pedido de desconto pendente.
---

# Skill — route-approval

Executa a decisão do guardrail. É a **skill que escreve** — toda cautela se aplica.

## 0. Pré-requisitos

- `DD_DiscountPolicy__c` com política ativa para a família/price book da cotação (skill
  `create-discount-policy`).
- Flow `DD_RouteDiscountApproval` **Active** (Fase 3).
- Margem calculada e conferida (skill `calculate-margin`).
- Confirmação da org (S1) e do humano (S3) antes de qualquer escrita.

## 1. A decisão (não é do agente)

| Condição | `Decision__c` | Efeito |
|---|---|---|
| `margem >= TargetMarginPct__c` | `AutoApproved` | Nenhum pedido criado; registrar que passou |
| `FloorMarginPct__c <= margem < TargetMarginPct__c` | `ManagerApproval` | Cria `DD_DiscountRequest__c`, `Status__c = Submitted`, define `Approver__c`, notifica a alçada |
| `margem < FloorMarginPct__c` **ou** `desconto > MaxDiscountPct__c` | `Blocked` | **Nenhum pedido.** Devolve o motivo ao vendedor |

Quem decide é o **Flow**, a partir da política. O agente **não** recalcula a regra de negócio por
conta própria (R9 em [`risks.md`](../../../docs/risks.md)).

**Tela do aprovador (F5-12, 2026-10-18).** O pedido criado pelo Flow é submetido ao `ApprovalProcess`
`DD_DiscountRequest__c.DD_Manager_Approval` pelo `DD_MarginConsoleController` (chamada
`Approval.process`). O gerente decide em **"Itens para Aprovar"**; aprovar/rejeitar grava `Status__c` e
`DecidedAt__c` por `WorkflowFieldUpdate`. Consequências para esta skill: (a) **não** criar submissão
manual nem botão próprio de aprovação; (b) pedido já submetido fica **travado** (`recordEditability =
AdminOnly`) — uma segunda tentativa do vendedor na mesma cotação falha no `Update_Request` do Flow;
(c) o agente continua proibido de gravar `Approved`. Detalhe em `docs/execution-log.md` APR-001.

## 2. Snapshot, não referência viva (obrigatório)

O pedido grava a política e a margem **do momento da decisão**:

| Campo | Por quê |
|---|---|
| `Policy__c` | Se a política mudar amanhã, o pedido de ontem precisa continuar explicável |
| `QuotedAmount__c` / `CostAmount__c` | Idem para os valores |
| `ResultingMarginPct__c` | Idem para o resultado |
| `RequestedDiscountPct__c` | O que foi efetivamente pedido |

Não usar fórmula para esses campos: fórmula recalcula e reescreve o passado.

## 3. Payload do pedido (um por vez, S4)

| Campo | Valor |
|---|---|
| `Name` | `DEMO-DR-<QuoteNumber>-<n>` (S11) — se for autonumber, registrar a exceção (A14) |
| `Quote__c` | Id da cotação (SOQL) |
| `Policy__c` | Id da política aplicada (SOQL) |
| `RequestedDiscountPct__c` | da elicitação |
| `QuotedAmount__c` / `CostAmount__c` / `ResultingMarginPct__c` | do cálculo, **snapshot** |
| `Decision__c` · `Status__c` | da tabela §1 |
| `Justification__c` | **exigido** se `RequiresJustification__c` na política — perguntar, não preencher |
| `Approver__c` | conforme `EscalationRole__c` |
| `CurrencyIsoCode` | **`USD`** (A13) |

## 4. Guardrails desta skill

| Risco | Guardrail |
|---|---|
| O agente concluir que "aprovou" | O agente **nunca** escreve `Status__c = Approved`. Só o humano aprova |
| **Contornar o piso** sugerindo alternativa | Proibido. Se `Blocked`, informar o motivo e parar |
| Recursão de Flow (o Flow grava no objeto que o dispara) | Validar em `--dry-run` e testar com 1 registro; se necessário, condição de entrada que exclua o próprio registro |
| Escrita em campo computado | O pedido é objeto próprio; não escrever em campo de fórmula da `Quote` (A15) |

## 5. Verificação pós-escrita (obrigatória)

```sql
SELECT Id, Name, Quote__c, Policy__c, RequestedDiscountPct__c, ResultingMarginPct__c,
       Decision__c, Status__c, Approver__c, CurrencyIsoCode
FROM DD_DiscountRequest__c WHERE Id = '<id criado>'
```
Conferir: `CurrencyIsoCode = USD`; `Decision__c` coerente com a margem; `Name` com `DEMO-`;
`Policy__c` é a política que a regra de precedência manda (não uma qualquer).

Testar os **3 cenários** antes de considerar pronto:

| Cenário | Margem | Esperado |
|---|---|---|
| Confortável | ≥ alvo | `AutoApproved`, sem pedido |
| Limite | entre piso e alvo | `ManagerApproval`, com pedido e aprovador |
| Abaixo do piso | < piso | `Blocked`, **sem** pedido, com motivo |

## 6. Registro

Entrada em [`docs/execution-log.md`](../../../docs/execution-log.md) com `Id`, decisão, política
aplicada, valor anterior (se update) e reversão. Atualizar [`MEMORY.md`](../../../MEMORY.md) §1.2.

## 7. Erros comuns

| Sintoma | Causa provável |
|---|---|
| Nenhum pedido criado e nenhum erro | Fluxo de decisão caiu em `AutoApproved`; conferir a política aplicada |
| `Policy__c` apontando para a política genérica | Regra de precedência não implementada (Fase 2, §3) |
| Flow dispara a si mesmo em loop | Condição de entrada do Flow · testar com 1 registro e `--dry-run` (S6/S7) |
| Política não encontrada | A família do produto não tem política ativa — **pendência**, não improvisar piso |
