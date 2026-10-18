---
name: validate-metadata
description: Checklist obrigatório antes de criar ou alterar qualquer metadado ou registro no Deal Desk — objetos, campos, fórmulas, roll-ups, flows, LWC, FlexiPage, CustomTab, permission sets e deploys. Inclui a regra das duas versões de API, as armadilhas de dry-run conhecidas e a conferência de resíduo após remoção. Use antes de todo create/update/deploy, sem exceção.
---

# Skill — validate-metadata

Nenhuma escrita acontece sem passar por aqui. **Este checklist é a barreira (S3, S6, S7).**

## 1. Pré-voo — sempre

- [ ] **Org confirmada (S1):**
      `SELECT Id, IsSandbox, OrganizationType, TrialExpirationDate FROM Organization`
      Sem `TrialExpirationDate` **e** sem `IsSandbox` = produção → **parar**.
- [ ] **Versão de API correta:**

      | Tipo de metadado | Versão | Como |
      |---|---|---|
      | Objetos, campos, fórmulas, LWC, `FlexiPage`, `CustomTab`, permissões, Flow | **68.0** | `--source-dir`, `sourceApiVersion` |
      | `GenAiFunction`, `GenAiPlugin`, `GenAiPlannerBundle`, `Bot` | **66.0** | bundle mdapi (`<version>66.0</version>`) ou MCP |

      **Nunca misturar os dois no mesmo `package.xml`.**
- [ ] **API names confirmados** por `sf_describe_object` (nunca inventados).
- [ ] **Todos os campos `nillable=false`** extraídos, não só os "que eu acho que uso" (A21).
- [ ] **Cache consultado:** [`MEMORY.md`](../../../MEMORY.md) §4 antes de re-descrever.

## 2. Checklist por tipo

### Objeto / campo custom
- [ ] Prefixo **`DD_`** em objeto e campos.
- [ ] `describe` antes do deploy: `createable` **não** é garantia em campo computado (A15).
- [ ] Se fórmula/roll-up: **`--dry-run` de 1 campo primeiro** (resolver Q1/Q2 da
      [`architecture`](../../../docs/architecture.md) §9 antes de modelar tudo).
- [ ] Roll-up summary exige relação **master-detail** (`Quote → QuoteLineItem` é).
- [ ] `Name` gravável? Se não, **S11 é inaplicável** — registrar a exceção (A14).
- [ ] **FLS concedida ao perfil System Administrator (S13/D20)** — `Visible` **e** `Editable`, na
      **mesma** operação do deploy do campo:

      ```sql
      SELECT Field, PermissionsRead, PermissionsEdit FROM FieldPermissions
      WHERE ParentId = '<PS do perfil>' AND Field = '<Objeto>.<Campo__c>'
      -- ParentId = PermissionSet do perfil (0PS...), NÃO o ProfileId
      ```
- [ ] **Campo no Page Layout padrão (S13/D20)** com `<behavior>Edit</behavior>`. O fullName do layout
      usa o **label**, não o API name — e pode ter espaços:

      ```bash
      sf project retrieve start -o personal --metadata "Layout:PricebookEntry-Price Book Entry" \
        --target-metadata-dir /tmp/lay --unzip
      grep -c "<Campo__c>" "/tmp/lay/unpackaged/unpackaged/layouts/<Layout>.layout"   # esperado: >=1
      ```
- [ ] **Nenhum dos dois pode ficar para depois:** campo sem FLS/layout não dá erro — apenas desaparece
      da tela (D20). Se o objeto tiver **record types**, confirmar a qual layout cada um está atribuído.

### Flow
- [ ] Tipo correto: **`AutoLaunchedFlow`** se for virar ação de agente (agente **não** invoca Screen Flow).
- [ ] `status = Active` (Flow em Draft é invisível para o agente).
- [ ] `<label>` **e** `<processType>` presentes — a ausência só aparece no dry-run (A47).
- [ ] Se for ação de agente: variáveis com **`isInput`/`isOutput` explícitos** (D8).
- [ ] **Confirmação dupla** (payload + impacto) — Flow é alto risco (S6).
- [ ] Condição de entrada que evite recursão quando o Flow escreve no objeto que o dispara.

### LWC / FlexiPage / CustomTab
- [ ] `CustomTab` **exige `<motif>`** — sem ele: `Invalid motif:null` (A39/A47).
- [ ] LWC com `targets` corretos (`lightning__RecordPage`, `lightning__Tab`).
- [ ] `isExposed = true` se for aparecer em builder/tab.
- [ ] Sem lógica de negócio no componente: cálculo vem do Flow/campo (arquitetura §5).

### Permission set
- [ ] Prefixo `DD_`, FLS conferida por objeto **e** campo.
- [ ] Testar como usuário sem `ModifyAllData` — o describe do admin mente (A15).

### Registro de dados
- [ ] `Name` inicia com **`DEMO-`** (S11) — ou exceção registrada (A14).
- [ ] `CurrencyIsoCode` **explícito** (`USD`) — omitir cria filho na moeda errada sem erro (A13).
- [ ] Idempotência checada (`WHERE Name = ...`) antes de criar.
- [ ] **1 registro por vez** (S4); valor anterior registrado para rollback (S10).

## 3. Deploy — a sequência obrigatória

```bash
# 1. SEMPRE dry-run primeiro (S7)
sf project deploy start --dry-run --source-dir force-app --target-org personal --test-level NoTestRun

# 2. Só depois do dry-run limpo
sf project deploy start --source-dir force-app --target-org personal --test-level NoTestRun
```

Para bundle mdapi (Agentforce):
```bash
sf project deploy start --metadata-dir mdapi --dry-run --target-org personal --test-level NoTestRun
sf project deploy start --metadata-dir mdapi --target-org personal --test-level NoTestRun
```

> **O dry-run não é cerimônia.** Em 4 sessões consecutivas ele pegou um erro que só apareceria no
> deploy real: `Invalid motif:null` (A39), `Required field is missing: label` (A47), e mais dois.

## 4. Verificação pós-deploy

| Tipo | Como verificar |
|---|---|
| Campo | Reler o valor gravado — **não** confiar no que foi enviado |
| Campo (visibilidade) | **FLS**: `FieldPermissions` do PS do perfil com `PermissionsRead/PermissionsEdit = true` · **Layout**: `grep` do campo no XML do layout retornado. Sem os dois, o campo é invisível na tela mesmo com deploy `Succeeded` (S13/D20) |
| Flow | `SELECT ApiName, ProcessType, IsActive, TriggerType FROM FlowDefinitionView WHERE ApiName='<x>'` |
| LWC / Tab | `sf org list metadata --metadata-type <tipo>` e conferir a contagem contra o baseline (`MEMORY.md` §1.6) |
| **`GenAiFunction`** | **`sf project retrieve start --metadata "GenAiFunction:<nome>"`** — se voltarem os **3 arquivos**, está íntegro (A45/A49) |
| Registro | SOQL pelo `Id` criado, conferindo `CurrencyIsoCode` e `Name` |

## 5. Remoção (só com autorização nominal — S5)

- [ ] Autorização explícita do humano para **aquele** artefato.
- [ ] **Flow ativo precisa ser desativado antes** de remover.
- [ ] `sf_delete_metadata` de Flow remove só a versão mais recente.
- [ ] Conferir resíduo em **duas** fontes:
      `SELECT COUNT() FROM FlowDefinitionView WHERE ApiName LIKE 'DD_%'`
      `SELECT Id, Status FROM Flow WHERE Definition.DeveloperName = '<x>'` (Tooling API)
- [ ] Se sobrou versão `Obsolete`, apagar via Tooling API (A46/A50).
- [ ] Conferir as contagens contra o baseline de [`MEMORY.md`](../../../MEMORY.md) §1.6.
- [ ] Registrar a exceção ao S5 no log.

## 6. Registro

Toda operação gera entrada em [`docs/execution-log.md`](../../../docs/execution-log.md) com: operação,
skill, ambiente, objeto, ferramenta, parâmetros, **confirmação humana**, resultado, **reversão** e
tokens. Atualizar [`MEMORY.md`](../../../MEMORY.md) §1 e §4 quando aplicável.

## 7. Falhas conhecidas e o que significam

| Erro literal | Causa | Ação |
|---|---|---|
| `Invalid motif:null` | `CustomTab` sem `<motif>` | Adicionar `<motif>Custom61: Money</motif>` (A39) |
| `Required field is missing: label` | `Flow` sem `<label>`/`<processType>` | Adicionar ambos (A47) |
| `Cannot use: <tipo> in this version` | Tipo de Agentforce em API 68.0 | Usar `--api-version 66.0` / bundle mdapi |
| `Unknown type:<tipo>` | Tipo realmente inexistente | Confirmar no `describeMetadata` |
| `RESOURCE_NOT_FOUND … schema is missing` | `GenAiFunction` sem os `schema.json` | Deployar o bundle de 3 arquivos (A43) |
| `You cannot delete this flow version because it is active` | Flow ativo | Desativar antes (A46) |
| `You cannot deploy to a required field: <Objeto>.<Campo>` | Campo custom `required` **não aceita** `fieldPermissions` no deploy (nem `editable=true`); a mensagem aponta um campo por vez | Tornar o campo opcional, criar `ValidationRule` equivalente e então conceder FLS read-only (A88) |
| `insufficient access rights on cross-reference id` | Resíduo/referência cruzada na remoção | Remover versão `Obsolete` via Tooling API |
| `INVALID_TYPE` em objeto | Objeto não existe nesta org | Não é bug de ferramenta (A7) |
| `not well-formed (invalid token)` | Comentário XML com dois hífens seguidos (`--dry-run`, `--metadata-dir`) | Remover os `--` de dentro do comentário (A52). **Validar o XML com um parser antes do deploy** |
| `Can not specify a length for CustomFields that have a formula` | Campo `Formula` do tipo `Text` com `<length>` | Remover o `<length>` — fórmula Text não declara tamanho |
| `Field <X> does not exist. Check spelling.` em `QuoteLineItem` | `TotalPrice`/`Subtotal` existem no `describe` e no layout, mas **não** são referenciáveis em fórmula | Inlinar a receita: `UnitPrice * Quantity * (1 - Discount / 100)` (A54) |
| `The summarized field in not deterministic.` | Roll-up `SUM`/`MIN` sobre fórmula com **referência cruzada** | Trocar o resumo por campo **gravado** (Flow) — A53 |
| `the $Record.<campo> field isn't supported` com `RecordBeforeSave` | Fórmula com referência cruzada lida em before-save | Usar `Get Records` no objeto relacionado dentro do Flow (A55) |

> **Silêncio não é sucesso.** Um campo deployado com `Succeeded` e **sem** FLS e layout não gera erro
> nenhum — ele simplesmente não aparece para o usuário. É o único tipo de falha deste projeto que o
> dry-run **não** pega: por isso a verificação de visibilidade da §4 é obrigatória (S13/D20).
