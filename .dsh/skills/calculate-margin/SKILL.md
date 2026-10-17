---
name: calculate-margin
description: Calcula a margem por linha de cotação e a margem consolidada de uma Quote a partir do custo do PricebookEntry (FixedCost__c + VariableCostPerUnit__c), diagnostica divergências entre o campo calculado e o cálculo manual, e simula o efeito de um desconto. Use quando o humano perguntar a margem de um produto, de uma linha ou de uma cotação, quando a margem exibida parecer errada, ou antes de decidir sobre um desconto.
---

# Skill — calculate-margin

Responde "qual a margem?" com **dado da org**, nunca com estimativa. **Somente leitura.**

## 0. A fórmula (fonte única de verdade)

```
custo unitário   = PricebookEntry.FixedCost__c + PricebookEntry.VariableCostPerUnit__c
margem unitária  = UnitPrice − custo unitário
margem %         = margem unitária / UnitPrice × 100
```

| Situação | Fórmula |
|---|---|
| Margem da linha | `(QuoteLineItem.UnitPrice − custo unitário) / UnitPrice` |
| Margem da cotação (consolidada) | `(Σ TotalPrice − Σ (custo unitário × Quantity)) / Σ TotalPrice` |
| Margem com desconto pedido | recalcular com `UnitPrice × (1 − desconto%/100)` |

**A margem da cotação é ponderada por receita**, não a média das linhas. Média simples distorce.

## 1. Consulta base — linhas com custo

```sql
SELECT Id, Product2.Name, Product2.Family, Quantity, UnitPrice, Discount, DiscountAmount,
       PricebookEntry.FixedCost__c, PricebookEntry.VariableCostPerUnit__c,
       DD_CostPerUnit__c, DD_MarginPct__c
FROM QuoteLineItem
WHERE QuoteId = '<quoteId>'
ORDER BY UnitPrice DESC
```
> `QuoteLineItem` tem `PricebookEntryId`: a referência cruzada ao custo do price book funciona na
> própria linha — não é preciso trazer o `PricebookEntry` em consulta separada.

## 2. Quando o custo não existe

`PricebookEntry.FixedCost__c` é `null` em **236 das 241** entradas da org. Se a linha não tem custo:

1. **Pare.** Não estime margem, não use preço de outro price book, não assuma custo zero.
2. Reportar o `PricebookEntryId` sem custo e a família do produto.
3. A correção é semear o custo (ver `create-discount-policy` para contexto de política, e a Fase 0 do
   [`roadmap`](../../../docs/roadmap.md) para a decisão de semeadura).

> Custo zero silencioso transforma toda margem em 100% e **destrói o valor do guardrail**. Tratar
> `null` como ausência, nunca como zero.

## 3. Simulação de desconto (sem gravar)

| Desconto pedido | `UnitPrice` resultante | Margem unitária | Margem % |
|---|---|---|---|
| 0% | `UnitPrice` | `U − C` | `(U−C)/U` |
| `<d>%` | `UnitPrice × (1 − d/100)` | `U×(1−d/100) − C` | `((U×(1−d/100)) − C) / (U×(1−d/100))` |

Calcular **no relatório da resposta**, não no banco. Gravar só quando o humano decidir (skill
`route-approval`).

## 4. Diagnóstico de divergência

Quando o campo calculado da org não bate com o cálculo manual:

| Hipótese | Verificação |
|---|---|
| Custo alterado depois do cálculo | Comparar `LastModifiedDate` do `PricebookEntry` com o da linha |
| `CurrencyIsoCode` divergente entre linha e price book | Selecionar o campo nos dois; a org não converte sozinha em fórmula (A13) |
| `Quantity` diferente da usada | Conferir `Quantity` e se o valor é unitário ou total |
| Campo é **computado** e não aceita o valor esperado | Lembrar A15: o describe descreve o contrato, o runtime decide |

## 5. Checklist de resposta

- [ ] A margem veio de **dado da org**, com o `Id` da cotação/linha registrado?
- [ ] Ficou explícito se é margem **unitária** ou **consolidada**?
- [ ] Se algum custo estava `null`, isso foi **dito** em vez de assumido como zero?
- [ ] A moeda é a mesma na linha e no price book (`USD`)?

## 6. Erros comuns

| Sintoma | Causa provável |
|---|---|
| Margem 100% em toda linha | Custo `null` tratado como zero (§2) |
| `INVALID_FIELD` em `PricebookEntry.ListPrice` | Esse campo **não existe** nesta org (A42) — usar `UnitPrice` |
| Consulta vazia sem erro | `PricebookEntry` acessado por caminho de relação inexistente — conferir `sf_describe_object` |
