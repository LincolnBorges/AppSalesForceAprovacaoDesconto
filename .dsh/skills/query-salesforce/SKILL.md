---
name: query-salesforce
description: Regras de ouro e consultas SOQL prontas para o Deal Desk — produtos e famílias, price books e entradas de preço com custo, cotações e linhas, políticas de desconto, pedidos de desconto — sempre seletivas e limitadas para reduzir custo de tokens. Use em qualquer leitura da org, antes de montar payload, ou quando precisar descobrir valores reais (IDs, picklists, contagens) em vez de assumi-los.
---

# Skill — query-salesforce

Toda leitura da org no Deal Desk passa por aqui. **Somente leitura.**

## 1. Regras de ouro

| # | Regra |
|---|---|
| 1 | **Campos explícitos + `WHERE` + `LIMIT`.** Nunca `SELECT` de objeto inteiro |
| 2 | **Nunca inventar Id nem API name.** Se não veio de SOQL ou de `sf_describe_object`, não existe |
| 3 | **`COUNT()` primeiro** quando só a ordem de grandeza importa — é muito mais barato |
| 4 | **Uma consulta por pergunta.** Não reler o que já está em [`MEMORY.md`](../../../MEMORY.md) §4 |
| 5 | **`describe` antes de payload.** Em objeto novo, extrair **todos** os `nillable=false` (A21) |
| 6 | **Objeto ausente não é bug de ferramenta.** `INVALID_TYPE` = não existe nesta org (A7) |
| 7 | **Coluna ausente**: `ListPrice` não existe em `PricebookEntry` nesta org; usar `UnitPrice` (A42) |

## 2. Consultas prontas

### 2.1 Ambiente — sempre antes de escrever (S1)

```sql
SELECT Id, Name, OrganizationType, IsSandbox, TrialExpirationDate FROM Organization
```
Sem `TrialExpirationDate` **e** sem `IsSandbox` = produção → **parar**.

### 2.2 Produtos e famílias (dimensão da política)

```sql
SELECT Family, COUNT(Id) c FROM Product2
WHERE IsActive = true AND Family != null
GROUP BY Family ORDER BY COUNT(Id) DESC
```

### 2.3 Price books

```sql
SELECT Id, Name, IsActive, IsStandard FROM Pricebook2 ORDER BY IsStandard, Name
```

### 2.4 Entradas de preço **com custo** (base do app)

```sql
SELECT Id, Product2Id, UnitPrice, FixedCost__c, VariableCostPerUnit__c, CurrencyIsoCode
FROM PricebookEntry
WHERE Pricebook2Id = '01sas000001nOBJAA2' AND IsActive = true
ORDER BY UnitPrice DESC
```

### 2.5 Entradas **sem** custo (o que falta semear — Fase 0)

```sql
SELECT COUNT(Id) c, Pricebook2Id FROM PricebookEntry
WHERE FixedCost__c = null GROUP BY Pricebook2Id
```

### 2.6 Cotações em aberto (onde o guardrail atua)

```sql
SELECT Id, Name, Status, OpportunityId, Pricebook2Id, ExpirationDate, CurrencyIsoCode
FROM Quote WHERE Status = 'Draft' ORDER BY CreatedDate DESC LIMIT 20
```

### 2.7 Linhas de uma cotação, com o custo do price book

```sql
SELECT Id, Product2.Name, Product2.Family, Quantity, UnitPrice, Discount,
       PricebookEntry.FixedCost__c, PricebookEntry.VariableCostPerUnit__c
FROM QuoteLineItem WHERE QuoteId = '<quoteId>' ORDER BY UnitPrice DESC
```

### 2.8 Políticas ativas

```sql
SELECT Id, Name, ProductFamily__c, Pricebook__c, FloorMarginPct__c, TargetMarginPct__c,
       MaxDiscountPct__c, IsActive__c, EffectiveFrom__c, EffectiveTo__c
FROM DD_DiscountPolicy__c WHERE IsActive__c = true ORDER BY ProductFamily__c
```

### 2.9 Pedidos de desconto pendentes (fila do aprovador)

```sql
SELECT Id, Name, Quote__c, Decision__c, Status__c, ResultingMarginPct__c, Approver__c, CreatedDate
FROM DD_DiscountRequest__c
WHERE Status__c IN ('Submitted','InReview') ORDER BY CreatedDate ASC
```

### 2.10 Baselines de metadado (detectar resíduo)

```sql
SELECT COUNT() FROM FlowDefinitionView
SELECT COUNT() FROM FlowDefinitionView WHERE IsActive = true
SELECT COUNT() FROM FlowDefinitionView WHERE NamespacePrefix = null
```
Comparar com [`MEMORY.md`](../../../MEMORY.md) §1.6. Tipos de Agentforce exigem `--api-version 66.0`.

## 3. Armadilhas conhecidas nesta org

| Armadilha | Detalhe |
|---|---|
| **Moeda** | 223 das 241 `PricebookEntry` são `USD`; existem 3 cada de `EUR`/`AUD`/`GBP`/`CAD`/`BRL`/`JPY` (Standard Price Book). Filtrar por `CurrencyIsoCode` ao comparar preço |
| **Só 15 contas têm oportunidade** | Cross-sell/whitespace por conta não tem massa — não é caminho para demo |
| **`OpportunityHistory` não tem histórico real** | Todas as linhas têm o mesmo `CreatedDate` (seeding) → análise de velocidade não tem lastro |
| **`Task` 19 / `Event` 0** | Insights baseados em atividade não têm dado |
| **`GenAiPlannerBundle` em 68.0** | Falha com *"Cannot use … in this version"* — sempre `--api-version 66.0` |
| **`OpportunityLineItem` não tem `Discount`** | Desconto em linha de oportunidade tem de ser derivado; é por isso que o app opera em `QuoteLineItem` |

## 4. Ferramentas

| Ferramenta | Uso |
|---|---|
| `sf_query_records` | SOQL com `LIMIT` (padrão 200; ceiling, não dica) |
| `sf_describe_object` | Uma vez por objeto por sessão; resumir e gravar em `MEMORY.md` §4 |
| `sf_get_record` | Um registro por Id — preferir SOQL se vários campos |
| `sf_search_records` | SOSL, quando o termo é livre e o objeto incerto |
| CLI (`sf data query --use-tooling-api`) | Quando o MCP falhar por versão de API |
