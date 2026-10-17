# Log de Execução — DealDeskGuardrail

Registro auditável de toda operação executada pelo agente na org Salesforce.
**Append-only:** nunca editar ou remover uma entrada; corrigir com uma nova entrada.

- **Projeto:** DealDeskGuardrail
- **Objetivo:** app Salesforce de governança de desconto (margem, semáforo e roteamento de aprovação)
- **Org alvo:** `personal` — Org ID `00Das00000GrzvPEAR` (Enterprise Edition **trial**, `IsSandbox = false`, expira `2026-11-15`; nunca produção)
- **Fuso horário:** America/Sao_Paulo (`-03:00`)
- **Responsável:** usuário humano que confirma cada escrita
- **Regras:** ver [`AGENTS.md`](../AGENTS.md) §5 (guardrails) e §6 (custo)

---

## Formato de Entrada

Cada operação (leitura relevante ou escrita) gera **um bloco**. Preencha os campos; use `-` quando
não se aplicar. Não inclua segredos, tokens ou dados pessoais desnecessários.

```markdown
### [AAAA-MM-DD HH:MM -03:00] <ID-CURTO> — <RESULTADO: OK | FALHA | BLOQUEADO>

| Campo | Valor |
|---|---|
| Operação | <create_record / query / describe / deploy_metadata> |
| Skill | <create-discount-policy / calculate-margin / route-approval / query-salesforce / validate-metadata / deploy-agentforce-action> |
| Ambiente | <dev-trial / sandbox> — Org ID `<00D...>` (IsSandbox: <true/false>) |
| Objeto / Metadado | <Quote / PricebookEntry / DD_Campo__c / Flow> |
| Ferramenta | <sf_query_records / sf_deploy_metadata / sf project deploy start> |
| Parâmetros-chave | `<campo>=<valor>; <campo>=<valor>` |
| Payload / SOQL | `<SOQL ou resumo do payload>` |
| Confirmação humana | <sim — "confirmo" às HH:MM / não aplicável / NÃO OBTIDA> |
| Resultado | <Id criado / N linhas / erro literal> |
| Reversão | <como desfazer: objeto + Id + ação + valor anterior> |
| Tokens (aprox.) | <n> |
| Observações | <uma linha> |
```

### Valores de resultado

| Resultado | Significado |
|---|---|
| `OK` | Operação concluída e verificada |
| `FALHA` | Erro retornado pela org/ferramenta; nada foi gravado ou ficou parcial |
| `BLOQUEADO` | Interrompido por guardrail (produção, falta de confirmação, validação reprovada) |

---

## Índice de Operações

| # | Data | Operação | Objeto | Resultado | Id |
|---|---|---|---|---|---|
| INIT-001 | 2026-10-16 | estruturação do projeto (nenhuma escrita na org) | — | OK | — |
| DOCS-001 | 2026-10-17 | convenção de rastreio por git — D11 (nenhuma escrita na org) | — | OK | — |
| DOCS-002 | 2026-10-17 | plano de ações vivo `docs/task-plan.md` (nenhuma escrita na org) | — | OK | — |
| DEC-001 | 2026-10-17 | 6 decisões de negócio + descoberta F0-05 + proposta de custos (nenhuma escrita na org) | — | OK | — |
| INV-001 | 2026-10-17 | F0-12 investigação de viabilidade de moeda USD × BRL (nenhuma escrita na org) | — | OK | — |
| SED-001 | 2026-10-17 | F0-08 semeadura de custo em 19 `PricebookEntry` + validação F0-09 | PricebookEntry | OK | 19 Ids |
| CHK-001 | 2026-10-17 | verificação de FLS e layout de `FixedCost__c`/`VariableCostPerUnit__c` + regra D20 (nenhuma escrita na org) | PricebookEntry | OK | — |
| PRB-001 | 2026-10-17 | F1-02 probe: `--dry-run` de fórmula na `QuoteLineItem` com referência cruzada ao `PricebookEntry` (nenhuma escrita — dry-run) | QuoteLineItem | OK | — |
| PRB-002 | 2026-10-17 | F1-01 probe: `--dry-run` de Roll-Up Summary na `Quote` sobre campo de fórmula + 2 isolamentos de causa (nenhuma escrita — dry-run) | Quote / QuoteLineItem | FALHA | — |
| FLD-001 | 2026-10-17 | F1-04/F1-05 criação de 9 campos de margem + FLS + layout | Quote / QuoteLineItem | OK | deploy `0Afas00000606y2CAA` |
| FLW-001 | 2026-10-17 | F1-06 Flow `DD_CalculateLineCost` ativo | QuoteLineItem | OK | deploy `0Afas00000604zTCAQ` |
| VAL-001 | 2026-10-17 | F1-07 validação das 3 faixas + massa DEMO- | Quote `0Q0as0000021hOLCAY` | OK | 3 linhas |
| DPM-001 | 2026-10-17 | F2-02 criação do objeto `DD_DiscountPolicy__c` + 12 campos + 2 regras + FLS + layout | DD_DiscountPolicy__c | OK | deploy `0Afas00000606GVCAY` |
| POL-001 | 2026-10-17 | F2-04 criação de 4 políticas `DEMO-` (Parts e Medical Equipment, genérica + específica) | DD_DiscountPolicy__c | OK | 4 Ids |
| PRE-001 | 2026-10-17 | F2-06 teste da precedência genérica × específica por price book (nenhuma escrita) | DD_DiscountPolicy__c | OK | 4 cenários |
| DRE-001 | 2026-10-17 | F3-03 criação do objeto `DD_DiscountRequest__c` + 18 campos + 3 regras + FLS + layout | DD_DiscountRequest__c | OK | deploy `0Afas00000606d4CAA` |
| FLW-002 | 2026-10-17 | F3-04 Flow de cálculo: deployado e **NÃO funcional** (falha em tempo de execução) | DD_CalculateQuoteMargin | FALHA | deploy `0Afas00000608ADCAY` |
| FLW-003 | 2026-10-17 | F3-04 reescrita do Flow de cálculo — funcional, 5 cenários validados | DD_CalculateQuoteMargin | OK | deploy `0Afas00000608oXCAQ`+ |
| QTE-001 | 2026-10-17 | F3-08 massa de teste: 2 cotações + 2 linhas DEMO- | Quote | OK | ver FLW-003 |
| RTE-001 | 2026-10-17 | F3-05/F3-07/F3-08 Flow de roteamento + 3 cenarios ponta a ponta (pedido DR-00000) | DD_DiscountRequest__c | OK | deploy `0Afas00000609HZCAY` |
| CLN-001 | 2026-10-17 | F3-09 limpeza das versoes Obsolete — **bloqueada** (Flow Interview retida) | Flow | FALHA | 24 versoes antigas permanecem |

> Atualize também [`MEMORY.md`](../MEMORY.md) §1 com os Ids criados.

---

## Entradas

### [2026-10-16 22:05 -03:00] INIT-001 — OK (fundação do projeto)

| Campo | Valor |
|---|---|
| Operação | criação de estrutura de projeto (arquivos locais) — **nenhuma escrita na org** |
| Skill | — (não aplicável) |
| Ambiente | dev/trial — Org ID `00Das00000GrzvPEAR` (IsSandbox: false · trial expira `2026-11-15`) |
| Objeto / Metadado | — (arquivos do repositório) |
| Ferramenta | `sf project generate` + edição de arquivos |
| Parâmetros-chave | Projeto DX `DealDeskGuardrail` em `~/Documents/deepseek_salesforce_projeto/DealDeskGuardrail/`; `sourceApiVersion` 68.0 |
| Resultado | Estrutura completa criada: `AGENTS.md`, `MEMORY.md`, `PREFERENCES.md`, `SKILLS.md`, `README.md`, `.dsh/config.yaml`, `.dsh/skills/` (6 skills), `docs/` (architecture, roadmap, risks, lessons-learned, glossary, execution-log, artifacts), `force-app/`, `config/`, `scripts/`, `sfdx-project.json` |
| Confirmação humana | sim — sessão autorizada explicitamente pelo humano, com autonomia total para operações de arquivo |
| Reversão | remover o diretório `~/Documents/deepseek_salesforce_projeto/DealDeskGuardrail/` (nada foi escrito na org) |
| Tokens (aprox.) | 32000 |
| Observações | Conhecimento migrado do projeto `ProgramaRebateQ42026`: aprendizados A1–A51, decisões de arquitetura, cache de metadados dos objetos de venda e os resultados dos testes T1/T2/T3/T4/T6/T7. **Esta entrada não representa escrita na Salesforce** — o log nasce com o projeto |

> O formato acima é o mesmo do projeto de origem, para permitir auditoria cruzada dos dois projetos.

### [2026-10-17 10:12 -03:00] DOCS-001 — OK (convenção de rastreio por git)

| Campo | Valor |
|---|---|
| Operação | edição de arquivos locais — **nenhuma escrita na org** |
| Skill | — (não aplicável) |
| Ambiente | dev/trial — Org ID `00Das00000GrzvPEAR` (IsSandbox: false) |
| Objeto / Metadado | — (`MEMORY.md`, `AGENTS.md`, `docs/execution-log.md`) |
| Ferramenta | `git` + edição de arquivo |
| Parâmetros-chave | decisão **D11** (`MEMORY.md` §2); convenção **11** e item de DoD (`AGENTS.md` §4, §11) |
| Resultado | regra registrada: toda mudança de arquivo termina em `git commit` com mensagem descritiva, por assunto |
| Confirmação humana | sim — pedido direto do humano ("quero que todas as mudanças sejam registradas") |
| Reversão | `git revert` do commit desta entrada (nenhum efeito na org) |
| Tokens (aprox.) | 6000 |
| Observações | repositório já existia (branch `master`, commit base `44c6d61`); convenção vale a partir desta sessão |

### [2026-10-17 10:35 -03:00] DOCS-002 — OK (plano de ações vivo)

| Campo | Valor |
|---|---|
| Operação | criação de arquivo local + referências cruzadas — **nenhuma escrita na org** |
| Skill | — (não aplicável) |
| Ambiente | dev/trial — Org ID `00Das00000GrzvPEAR` (IsSandbox: false) |
| Objeto / Metadado | — (`docs/task-plan.md`, `AGENTS.md`, `docs/roadmap.md`, `.dsh/config.yaml`) |
| Ferramenta | edição de arquivo + `git` |
| Parâmetros-chave | 61 ações (F0 11 · F1 8 · F2 7 · F3 9 · F4 7 · F5 6 · F6 9 · X 4); 7 decisões humanas |
| Resultado | plano de acompanhamento criado e referenciado em `AGENTS.md` §10, no `roadmap.md` e na política de carregamento do `.dsh/config.yaml` |
| Confirmação humana | sim — pedido direto do humano |
| Reversão | `git revert` do commit desta entrada (nenhum efeito na org) |
| Tokens (aprox.) | 9000 |
| Observações | documento vivo: a ação X-02 mantém status e progresso em sincronia a cada ação |

### [2026-10-17 10:55 -03:00] DEC-001 — OK (decisões de negócio + descoberta + proposta)

| Campo | Valor |
|---|---|
| Operação | leitura (SOQL) + edição de arquivos — **nenhuma escrita na org** |
| Skill | query-salesforce |
| Ambiente | dev/trial — Org ID `00Das00000GrzvPEAR` (IsSandbox: false) |
| Objeto / Metadado | leitura: `Product2`, `PricebookEntry`, `Pricebook2`, `User`, `Quote` |
| Ferramenta | `sf data query` + edição de arquivo |
| Parâmetros-chave | 6 decisões (D12–D17); famílias `Parts`/`Medical Equipment`; alvo 30% / piso 20%; aprovador = `User.ManagerId` |
| Payload / SOQL | famílias por `Product2`; entradas por `Pricebook2Id`; `ManagerId` dos 23 usuários ativos; `Pricebook2Id` das 31 `Quote` |
| Confirmação humana | sim — decisões dadas diretamente pelo humano na conversa |
| Resultado | 19 `PricebookEntry` propostas (8 verdes/5 amarelas/6 vermelhas) em [`cost-proposal.md`](../docs/cost-proposal.md); 24 no total após as 5 já semeadas |
| Reversão | `git revert` do commit desta entrada (nenhum efeito na org) |
| Tokens (aprox.) | 14000 |
| Observações | achados: família `Part` ≠ `Parts`; `Medical Equipment` só existe no Standard Price Book; 3 de 23 usuários têm `ManagerId`; as 31 `Quote` têm `Pricebook2Id` nulo |

### [2026-10-17 11:40 -03:00] INV-001 — OK (viabilidade de moeda, F0-12)

| Campo | Valor |
|---|---|
| Operação | leitura (SOQL, describe, Setup em browser) — **nenhuma escrita na org** |
| Skill | query-salesforce · chrome |
| Ambiente | dev/trial — Org ID `00Das00000GrzvPEAR` (IsSandbox: false) |
| Objeto / Metadado | `CurrencyType`, `DatedConversionRate`, `Pricebook2`, `PricebookEntry`, `Quote`, `Opportunity`, `User` |
| Ferramenta | `sf data query`, `sf sobject describe`, Chrome (Setup `CompanyCurrency`) |
| Parâmetros-chave | moeda corporativa `USD` (taxa 1) · `BRL` 3,6995 · ACM desligado · 9 price books todos `USD` · `PricebookEntry.CurrencyIsoCode` imutável |
| Resultado | veredito: **manter USD**, não alterar a moeda corporativa — [`currency-feasibility.md`](../docs/currency-feasibility.md) |
| Confirmação humana | não aplicável (investigação sem escrita) |
| Reversão | `git revert` do commit desta entrada (nenhum efeito na org) |
| Tokens (aprox.) | 21000 |
| Observações | a página de Setup existiu mas não renderizou o corpo; a afirmação sobre pré-requisitos da troca de moeda é documentada, **não** observada (A19) |

**Correção de memória aplicada nesta entrada:** A13 dizia que o default de `CurrencyIsoCode` era "a moeda
da org (`BRL`)". O correto é a **moeda padrão do usuário que cria** (22/23 em `USD`; Lincoln em `BRL`) ou a
moeda do pai. Registrado em `MEMORY.md` §3 (A13) e §1.1.

### [2026-10-17 12:10 -03:00] SED-001 — OK (F0-08: semeadura de 19 custos)

| Campo | Valor |
|---|---|
| Operação | 19 `update` sequenciais em `PricebookEntry` + validação |
| Skill | validate-metadata · query-salesforce |
| Ambiente | dev/trial — Org ID `00Das00000GrzvPEAR` (IsSandbox: false · trial `2026-11-15`) |
| Objeto / Metadado | `PricebookEntry` — campos `FixedCost__c` e `VariableCostPerUnit__c` |
| Ferramenta | `sf data update record` (um registro por vez) |
| Parâmetros-chave | valores da tabela aprovada em [`cost-proposal.md`](../docs/cost-proposal.md) §3; moeda **USD** verificada antes e depois de cada escrita (S12/D19) |
| Confirmação humana | sim — "Tabela aprovada. Pode seguir com os 19 registros" (F0-07) + lote autorizado (D16) |
| Resultado | 19/19 OK · total com custo **24** · **10 verdes / 7 amarelos / 7 vermelhos** · **0 não-`USD`** · nenhum create/delete · `UnitPrice` intocado |
| Reversão | gravar `FixedCost__c = null` e `VariableCostPerUnit__c = null` nos 19 Ids abaixo (valor anterior era `null` em ambos) |
| Tokens (aprox.) | 12000 |
| Observações | `CurrencyIsoCode` no payload é **rejeitado** pela org ("Unable to create/update fields: CurrencyIsoCode") porque o campo é imutável; a regra de ouro foi implementada como verificação pré/pós-escrita com aborto do lote, e não houve divergência |

**Rollback por registro**

| # | Id | Produto | Book | Anterior F/V | Novo F/V |
|---|---|---|---|---|---|
| 1 | `01uas000000RovCAAS` | Battery Compartment Dust Seal Replacement Set | Fleet | `null`/`null` | 14.00 / 5.85 |
| 2 | `01uas000000RovgAAC` | EV Coolant Replacement Pack | Fleet | `null`/`null` | 19.00 / 7.80 |
| 3 | `01uas000000RovRAAS` | Neo Wagon EV Software Update Module | Fleet | `null`/`null` | 18.50 / 7.90 |
| 4 | `01uas000000Rov6AAC` | Windshield Wiper Pack | Fleet | `null`/`null` | 13.50 / 5.80 |
| 5 | `01uas000000RovLAAS` | Cabin Air Filter | Fleet | `null`/`null` | 11.50 / 5.10 |
| 6 | `01uas000000RovaAAC` | Tire Rotation & Balancing Toolset | Fleet | `null`/`null` | 30.50 / 13.30 |
| 7 | `01uas000000RovUAAS` | Drive Motor Lubricant | Fleet | `null`/`null` | 21.50 / 9.45 |
| 8 | `01uas000000RovdAAC` | High-Voltage Safety Gear Set | Fleet | `null`/`null` | 41.50 / 17.55 |
| 9 | `01uas000000Rov9AAC` | Universal EV Fastener & Clip Kit | Fleet | `null`/`null` | 10.50 / 4.30 |
| 10 | `01uas000000RoukAAC` | MediScan Imager | Standard | `null`/`null` | 41600.00 / 17800.00 |
| 11 | `01uas000000RoumAAC` | MediScan Ventilator | Standard | `null`/`null` | 24200.00 / 10300.00 |
| 12 | `01uas000000RoulAAC` | MediScan Sterilizer | Standard | `null`/`null` | 12100.00 / 5180.00 |
| 13 | `01uas000000RourAAC` | MediScan IV Stand | Standard | `null`/`null` | 270.00 / 113.50 |
| 14 | `01uas000000RoupAAC` | MediScan Lab Analyzer | Standard | `null`/`null` | 18400.00 / 7850.00 |
| 15 | `01uas000000RousAAC` | MediScan MedCart | Standard | `null`/`null` | 1700.00 / 790.00 |
| 16 | `01uas000000RoutAAC` | MediScan Hospital Bed | Standard | `null`/`null` | 2600.00 / 1140.00 |
| 17 | `01uas000000RouoAAC` | MediScan Infusion Pump | Standard | `null`/`null` | 1300.00 / 590.00 |
| 18 | `01uas000000RounAAC` | MediScan Pulse Oximeter | Standard | `null`/`null` | 415.00 / 180.00 |
| 19 | `01uas000000RouqAAC` | MediScan Thermo Scanner | Standard | `null`/`null` | 245.00 / 107.00 |

**Validação F0-09:** 24 entradas com custo · 2 price books (Fleet 14, Standard 10) · 2 famílias
(`Parts` 14, `Medical Equipment` 10) · 0 não-`USD` · faixas 10/7/7 conferidas. Amostras batidas à mão:
Battery `(32−14−5,85)/32 = 37,97%` · Imager `(90000−41600−17800)/90000 = 34,00%` · Drive Motor
`(36−21,50−9,45)/36 = 14,03%`. As 5 entradas semeadas em T3 permanecem intactas.

### [2026-10-17 12:40 -03:00] CHK-001 — OK (FLS + layout dos campos de custo + D20)

| Campo | Valor |
|---|---|
| Operação | verificação (SOQL, retrieve de metadata, formulário no browser) + edição de arquivos — **nenhuma escrita na org** |
| Skill | validate-metadata |
| Ambiente | dev/trial — Org ID `00Das00000GrzvPEAR` (IsSandbox: false) |
| Objeto / Metadado | `PricebookEntry.FixedCost__c`, `PricebookEntry.VariableCostPerUnit__c`, `Layout:PricebookEntry-Price Book Entry` |
| Ferramenta | `sf data query` (`FieldPermissions`), `sf project retrieve start`, Chrome |
| Parâmetros-chave | PS do perfil `0PSas000004GBdfGAG`; layout único `Price Book Entry`; 0 record types |
| Resultado | **já estava configurado:** FLS `read=true`/`edit=true` nos dois campos; ambos no layout com `<behavior>Edit</behavior>`; o formulário de edição do registro `01uas000000RovCAAS` renderiza "Fixed Cost" e "Variable Cost Per Unit" |
| Confirmação humana | não aplicável (sem escrita) |
| Reversão | `git revert` do commit desta entrada |
| Tokens (aprox.) | 15000 |
| Observações | a hipótese de FLS/layout faltando **não se confirmou** nesta org; a lacuna era de **processo**, e foi fechada com D20 + S13 + convenção 12 + skill atualizada |

### [2026-10-17 12:42 -03:00] PRB-001 — OK (F1-02: fórmula com referência cruzada ao PricebookEntry)

| Campo | Valor |
|---|---|
| Operação | `sf project deploy start --dry-run` (mdapi) — **nenhuma escrita na org** |
| Skill | validate-metadata |
| Ambiente | dev/trial — Org ID `00Das00000GrzvPEAR` (IsSandbox: false) |
| Objeto / Metadado | `QuoteLineItem.DD_CostPerUnit__c` |
| Ferramenta | `sf project deploy start --metadata-dir /tmp/dd-probes/f1-02 --dry-run` |
| Parâmetros-chave | tipo `Formula (Currency)`; precisão 18, escala 2; API 68.0 |
| Payload / SOQL | `PricebookEntry.FixedCost__c + PricebookEntry.VariableCostPerUnit__c` |
| Confirmação humana | sim — autorização condicional do humano para os 2 probes (mensagem da sessão) |
| Resultado | **`status: Succeeded`** · 2/2 componentes, 0 erros · ID do dry-run `0Afas00000605sICAQ` |
| Reversão | não aplicável (dry-run não grava) |
| Tokens (aprox.) | 3500 |
| Observações | **Q2 respondida = SIM.** `QuoteLineItem.PricebookEntryId` é lookup (relação `PricebookEntry`, confirmada em `FieldDefinition`), então a fórmula alcança o custo sem Flow |

### [2026-10-17 12:43 -03:00] PRB-002 — FALHA (F1-01: roll-up sobre campo de fórmula — com 2 isolamentos)

| Campo | Valor |
|---|---|
| Operação | 3 × `sf project deploy start --dry-run` (mdapi) — **nenhuma escrita na org** |
| Skill | validate-metadata |
| Ambiente | dev/trial — Org ID `00Das00000GrzvPEAR` (IsSandbox: false) |
| Objeto / Metadado | `Quote.DD_Cost__c` (Summary SUM) + `QuoteLineItem.DD_CostAmount__c` (fórmula) |
| Ferramenta | `sf project deploy start --metadata-dir … --dry-run` |
| Parâmetros-chave | `summaryForeignKey = QuoteLineItem.QuoteId` (Master-Detail confirmado); API 68.0 |
| Payload / SOQL | **(a)** SUM sobre fórmula que referencia a fórmula cruzada → **FALHA** · **(b)** SUM sobre fórmula só local (`UnitPrice * Quantity`) → **OK** · **(c)** SUM sobre fórmula única com referência cruzada direta → **FALHA** |
| Confirmação humana | sim — autorização condicional do humano para os 2 probes (mensagem da sessão) |
| Resultado | **(a)** `The summarized field in not deterministic.` + `Unable to use this formula containing derived values because the field is included in the following roll-up summary field(s)` (dry-run `0Afas00000606mpCAA`) · **(b)** `Succeeded`, 4/4 (`0Afas00000606tBCAQ`) · **(c)** `The summarized field in not deterministic.` (dry-run `0Afas00000606OYCAY`) |
| Reversão | não aplicável (dry-run não grava) |
| Tokens (aprox.) | 6000 |
| Observações | **Q1 respondida = DEPENDE**, e a causa está isolada: o bloqueio **não** é multi-moeda nem "fórmula sobre fórmula" — é a **referência cruzada** (valor derivado). Fórmula determinística do filho é agregável; qualquer fórmula que leia outro objeto não é. Registrado como **A53** em [`MEMORY.md`](../MEMORY.md) §3 |

### [2026-10-17 12:52 -03:00] FLD-001 — OK (F1-04/F1-05: 9 campos de margem + FLS + layout)

| Campo | Valor |
|---|---|
| Operação | `sf project deploy start --source-dir force-app` (dry-run + real) |
| Skill | validate-metadata |
| Ambiente | dev/trial — Org ID `00Das00000GrzvPEAR` (IsSandbox: false) |
| Objeto / Metadado | 4 campos `QuoteLineItem.DD_*__c` · 5 campos `Quote.DD_*__c` · `Layout:Quote-Quote Layout` · `Layout:QuoteLineItem-Quote Line Item Layout` · `Profile:Admin` (FLS) |
| Ferramenta | `sf project deploy start` |
| Parâmetros-chave | dry-run `0Afas00000607FlCAI` · real `0Afas00000606y2CAA` · API 68.0 |
| Payload / SOQL | `DD_CostPerUnit__c` e `DD_MarginAmount__c`/`DD_MarginPct__c` (fórmula) · `DD_CostAmount__c` (Currency gravado) · `DD_Revenue__c`/`DD_Cost__c`/`DD_WorstLineMarginPct__c` (roll-up) · `DD_MarginPct__c`/`DD_GuardrailState__c` (fórmula) |
| Confirmação humana | sim — Opção A confirmada pelo humano; S3/S6 atendidos |
| Resultado | **`Succeeded`** — 12 componentes, 0 erros. FLS 9/9 `read=true` (só `DD_CostAmount__c` `edit=true`); layouts 4+5 campos |
| Reversão | remover os 9 campos `CustomField` via `sf_delete_metadata` (sem dados de produção em jogo); `git revert` do commit |
| Tokens (aprox.) | 22000 |
| Observações | 3 erros de dry-run corrigidos antes do deploy: `<length>` em fórmula Text (A52-like), `TotalPrice`/`Subtotal` não referenciáveis (A54). Layout de fórmula/roll-up usou `<behavior>Readonly</behavior>` — exceção estrutural a D20 |

### [2026-10-17 12:56 -03:00] FLW-001 — OK (F1-06: Flow DD_CalculateLineCost)

| Campo | Valor |
|---|---|
| Operação | `sf project deploy start --source-dir force-app` (dry-run ×3 + real) |
| Skill | validate-metadata |
| Ambiente | dev/trial — Org ID `00Das00000GrzvPEAR` (IsSandbox: false) |
| Objeto / Metadado | `Flow:DD_CalculateLineCost` (`AutoLaunchedFlow`, `RecordBeforeSave`, `Active`) |
| Ferramenta | `sf project deploy start` |
| Parâmetros-chave | dry-run final `0Afas00000606GUCAY` · real `0Afas00000604zTCAQ` |
| Payload / SOQL | `Get Records` em `PricebookEntry` por `$Record.PricebookEntryId` → `varCostAmount = (FixedCost__c + VariableCostPerUnit__c) * Quantity` → `$Record.DD_CostAmount__c` |
| Confirmação humana | **dupla (S6):** aprovação do desenho + "Confirmo o Flow e a massa" com payload e impacto à vista |
| Resultado | **`Succeeded`**; `FlowDefinitionView`: `IsActive = true`, `TriggerType = RecordBeforeSave`, objeto `Quote Line Item` |
| Reversão | desativar/remover o Flow; `DD_CostAmount__c` mantém o último valor gravado até nova edição |
| Tokens (aprox.) | 9000 |
| Observações | 2 tentativas recusadas no dry-run: leitura de fórmula com referência cruzada em before-save não é suportada (A55); `assignNullValuesIfNoRecordsFound=true` evita bloquear save sem `PricebookEntry` |

### [2026-10-17 12:58 -03:00] VAL-001 — OK (F1-07: validação das 3 faixas + massa DEMO-)

| Campo | Valor |
|---|---|
| Operação | `sf data create record` (4 registros, 1 por vez) + `sf data query` de verificação |
| Skill | calculate-margin |
| Ambiente | dev/trial — Org ID `00Das00000GrzvPEAR` (IsSandbox: false) |
| Objeto / Metadado | `Quote` `0Q0as0000021hOLCAY` (`DEMO-Quote-Margin-Bands`) + 3 `QuoteLineItem` |
| Ferramenta | `sf data create record`, `sf data query` |
| Parâmetros-chave | `Pricebook2Id=01sas000001nOBJAA2`; `CurrencyIsoCode=USD`; linhas `0QLas0000028wthGAA`, `0QLas0000028wiQGAQ`, `0QLas0000028wvJGAQ` |
| Payload / SOQL | 3 linhas com `Quantity=1` e `UnitPrice` 120 / 200 / 96 sobre `Suspension Inspection Kit`, `Multi-Point Diagnostic Scanner`, `EV Brake Pad Kit` |
| Confirmação humana | sim — "Confirmo o Flow e a massa" |
| Resultado | margens **41,6667% / 28,0000% / 17,7083%**; `DD_Revenue__c` 416 = `TotalPrice` 416; `DD_Cost__c` 293 = 70+144+79; `DD_MarginPct__c` 29,5673%; `DD_WorstLineMarginPct__c` 17,7083%; `DD_GuardrailState__c` = `Requer Justificativa` |
| Reversão | 4 registros criados nesta operação: apagar `0Q0as0000021hOLCAY` (o cascade pode não remover as linhas — conferir) ou as 3 linhas + a Quote; valores anteriores: inexistentes |
| Tokens (aprox.) | 6000 |
| Observações | **A28 atendido:** o custo foi gravado na criação das linhas, o que prova que o Flow executou (nada mais escreve `DD_CostAmount__c`). Acento de `Saudável`/`Aprovação` confirmado por retrieve. A Quote serve à F5-02 |

### [2026-10-17 14:17 -03:00] DPM-001 — OK (F2-02: objeto da política de desconto)

| Campo | Valor |
|---|---|
| Operação | `deploy_metadata` (objeto custom + campos + regras + layout + perfil) |
| Skill | `validate-metadata` §2/§3/§4 |
| Ambiente | dev-trial — Org ID `00Das00000GrzvPEAR` (IsSandbox: `false`, trial até 2026-11-15) |
| Objeto / Metadado | `DD_DiscountPolicy__c` + 12 `CustomField` + 2 `ValidationRule` + 1 `Layout` + `Profile:Admin` |
| Ferramenta | `sf project deploy start` (API 68.0, source format) |
| Parâmetros-chave | `--dry-run` antes; `--metadata CustomObject:DD_DiscountPolicy__c`; `--metadata "Layout:DD_DiscountPolicy__c-DD Discount Policy Layout"`; `--metadata Profile:Admin`; `--test-level NoTestRun` |
| Payload / SOQL | 17 componentes. Objeto: label `Politica de Desconto`, `sharingModel=ReadWrite`, `deploymentStatus=Deployed`, `nameField` Text(80). Campos: `ProductFamily__c` (Picklist 15 valores), `Pricebook__c` (Lookup `Pricebook2`, `SetNull`), `FloorMarginPct__c`/`TargetMarginPct__c`/`MaxDiscountPct__c` (Percent 5,2 required), `EscalationRole__c` Text(80), `SlaHours__c` Number(4,0), `RequiresJustification__c`/`IsActive__c` Checkbox, `EffectiveFrom__c` Date required, `EffectiveTo__c` Date, `Specificity__c` Formula Number = `IF(ISBLANK(Pricebook__c),0,2) + IF(ISPICKVAL(ProductFamily__c,"All"),0,1)` |
| Confirmação humana | sim — "Confirmo — executar dry-run e deploy", payload apresentado às 14:05 |
| Resultado | dry-run `0Afas00000607inCAA` **Succeeded** 17/17 · deploy `0Afas00000606GVCAY` **Succeeded** 17/17, 0 erros |
| Reversão | `sf_delete_metadata` do `CustomObject:DD_DiscountPolicy__c` remove objeto e filhos; o layout e as 7 `fieldPermissions` saem junto com o objeto (o arquivo `Admin.profile-meta.xml` precisa perder os blocos `DD_DiscountPolicy__c.*` e o `layoutAssignments`) |
| Tokens (aprox.) | 12000 |
| Observações | **O dry-run pagou o custo 3x:** (1) `Restrict` é proibido em lookup para `Pricebook2` → virou `SetNull` (A56); (2) FLS não pode ser deployada para campo `required` → 5 blocos removidos (A57); (3) o erro do lookup derrubou `Specificity__c` em cascata. Pós-deploy: 2 regras `Active=true`; 1 layout só (sem resíduo de layout automático); 12/12 campos no layout; `CurrencyIsoCode` **existe** no objeto (30 moedas) |

### [2026-10-17 14:21 -03:00] POL-001 — OK (F2-04: 4 políticas DEMO-)

| Campo | Valor |
|---|---|
| Operação | `create_record` ×4 (uma por vez, S4) |
| Skill | `create-discount-policy` §1 a §5 |
| Ambiente | dev-trial — Org ID `00Das00000GrzvPEAR` (IsSandbox: `false`) |
| Objeto / Metadado | `DD_DiscountPolicy__c` |
| Ferramenta | `sf_create_record`, `sf_query_records` |
| Parâmetros-chave | `CurrencyIsoCode=USD` em todas (D5/S12); piso 20 e alvo 30 (D12); teto 15 genérica / 10 específica; `EffectiveFrom__c=2026-10-17`; `EffectiveTo__c=null`; `EscalationRole__c=Gerente Comercial`; `SlaHours__c=24`; `RequiresJustification__c=true` |
| Payload / SOQL | 1 `DEMO-Policy-Parts-AllPB` (`a0Mas000000PR53EAG`, `Pricebook__c=null`, `Specificity__c=1`) · 2 `DEMO-Policy-Parts-Fleet` (`a0Mas000000PR6fEAG`, `Pricebook__c=01sas000001nOBJAA2`, `Specificity__c=3`) · 3 `DEMO-Policy-MedicalEquip-AllPB` (`a0Mas000000PR8HEAW`, `Pricebook__c=null`, `Specificity__c=1`) · 4 `DEMO-Policy-MedicalEquip-Standard` (`a0Mas000000PR9tEAG`, `Pricebook__c=01sas000001nOBCAA2`, `Specificity__c=3`) |
| Confirmação humana | sim — "Confirmo as 4" às 14:20, após a tabela de payload |
| Resultado | 4/4 criados; releitura confere **4/4 `CurrencyIsoCode=USD`**, **4/4 prefixo `DEMO-`**, percentuais 20/30/15 nas genéricas e 20/30/10 nas específicas, `Specificity__c` 1 e 3 como previsto |
| Reversão | apagar os 4 Ids acima (S5: exige autorização nominal). Nenhum valor anterior — registros novos |
| Tokens (aprox.) | 5000 |
| Observações | Idempotência conferida antes (`SELECT ... FROM DD_DiscountPolicy__c` = 0). **Percent por API é unidade percentual**: enviar `20` grava `20%` (não `0,2`) — a fração só vale em fórmula e validation rule. Desvio de processo: o registro 4 foi criado antes da releitura do 3; ambos foram verificados em seguida, sem efeito |

---

### [2026-10-17 14:21 -03:00] PRE-001 — OK (F2-06: precedência genérica × específica)

| Campo | Valor |
|---|---|
| Operação | `query` (nenhuma escrita) |
| Skill | `create-discount-policy` §3 |
| Ambiente | dev-trial — Org ID `00Das00000GrzvPEAR` (IsSandbox: `false`) |
| Objeto / Metadado | `DD_DiscountPolicy__c` |
| Ferramenta | `sf_query_records` |
| Parâmetros-chave | `ORDER BY Specificity__c DESC, EffectiveFrom__c DESC` — **ordenação por campo de fórmula funciona em SOQL** |
| Payload / SOQL | `WHERE IsActive__c = true AND EffectiveFrom__c <= TODAY AND (EffectiveTo__c = null OR EffectiveTo__c >= TODAY) AND (ProductFamily__c = :fam OR ProductFamily__c = 'All') AND (Pricebook__c = :pb OR Pricebook__c = null) ORDER BY Specificity__c DESC, EffectiveFrom__c DESC` |
| Confirmação humana | não aplicável (leitura) |
| Resultado | **1.** `Parts` + Fleet & Corporate → 2 candidatas ordenadas: `Parts-Fleet` (`Specificity__c=3`, teto 10) **antes** de `Parts-AllPB` (`=1`, teto 15). **2.** `Parts` + Retail → só `Parts-AllPB` (`=1`, teto 15) — fallback correto. **3.** `Medical Equipment` + Standard → `MedicalEquip-Standard` (`=3`) antes de `MedicalEquip-AllPB` (`=1`). **4.** Controle negativo: `Generator` + Fleet → **0 linhas** (nenhuma política inventada) |
| Reversão | não aplicável (leitura) |
| Tokens (aprox.) | 3000 |
| Observações | A específica vence a genérica em ambas as famílias, e a genérica só aparece sozinha quando não há específica — que é exatamente a regra de §3 da skill. **O que este teste NÃO prova (A19):** que um Flow real consiga aplicar a ordenação — o `Get Records` com `ORDER BY` em campo de fórmula é justamente o que a Fase 3 tem de validar |

---

### [2026-10-17 16:05 -03:00] DRE-001 — OK (F3-03: objeto DD_DiscountRequest__c)

| Campo | Valor |
|---|---|
| Operação | `deploy_metadata` (objeto custom + campos + regras + layout + perfil) |
| Skill | `validate-metadata` §2/§3/§4 |
| Ambiente | dev-trial — Org ID `00Das00000GrzvPEAR` (IsSandbox: `false`, trial até 2026-11-15) |
| Objeto / Metadado | `DD_DiscountRequest__c` + 18 `CustomField` + 3 `ValidationRule` + 1 `Layout` + `Profile:Admin` |
| Ferramenta | `sf project deploy start` (API 68.0, source format, `--source-dir` por componente) |
| Parâmetros-chave | `--dry-run` antes; `--source-dir` restrito ao objeto novo, ao layout novo e a `Admin.profile-meta.xml`; `--test-level NoTestRun` |
| Payload / SOQL | 24 componentes. Objeto: label `Pedido de Desconto`, `sharingModel=ReadWrite`, `nameField` **AutoNumber** `DR-{00000}`, `enableHistory=true` (histórico em `Status__c`, `Decision__c`, `Approver__c`). 18 campos, dos quais 4 obrigatórios: `Quote__c` (Lookup `Quote`, `Restrict`), `GuardrailState__c`/`Decision__c`/`Status__c` (Picklist restrita). Snapshot da política: `Policy__c` (`SetNull`), `PolicyName__c`, `PolicySpecificity__c`, `PolicyFloorMarginPct__c`, `PolicyTargetMarginPct__c`, `PolicyMaxDiscountPct__c`, `PolicyEffectiveFrom__c`, `PolicyRequiresJustification__c`. Pedido: `RequestedDiscountPct__c`, `Justification__c`, `Approver__c` (`User`, `SetNull` — A56), `ApproverSource__c`, `DecidedAt__c`, `DecisionNote__c`. **Sem margem, custo ou receita** (D14/D23) |
| Confirmação humana | sim — modelagem apresentada e aprovada ("Aprovo — escada gerente → dono da política → admin ativo") |
| Resultado | 1º dry-run `0Afas00000606I6CAI` **Failed** (1 erro, ver abaixo) · 2º dry-run **Succeeded** 24/24 · deploy `0Afas00000606d4CAA` **Succeeded** 24/24, 0 erros |
| Reversão | `sf_delete_metadata` de `CustomObject:DD_DiscountRequest__c` remove objeto e filhos; o layout e as 14 `fieldPermissions` saem junto com o objeto (o arquivo `Admin.profile-meta.xml` precisa perder os blocos `DD_DiscountRequest__c.*`, o `layoutAssignments` e o `objectPermissions`) |
| Tokens (aprox.) | 15000 |
| Observações | **O dry-run pagou o custo:** o Profile foi rejeitado com `Element fieldPermissions is duplicated at this location in type Profile (166:24)` — a causa **não** era duplicidade de campo, era **ordem de elementos** no MDAPI (`fieldPermissions` tem de vir antes de `layoutAssignments`, que vem antes de `objectPermissions`). Corrigido reinserindo nos três pontos de ordem. Pós-deploy: FLS **14/14** `read+edit` (os 4 obrigatórios não recebem linha — A57); layout com **19/19** campos esperados, obrigatórios como `Required`, `Name` como `Readonly`; **1** layout só (sem duplicata); 3 regras `Active=true`; 4 campos `nillable=false` exatamente como planejado; `CurrencyIsoCode` presente (consulta sem erro) |

---

### [2026-10-17 17:10 -03:00] FLW-002 — FALHA (F3-04: Flow de cálculo deployado, não funcional)

| Campo | Valor |
|---|---|
| Operação | `deploy_metadata` de Flow + 9 invocações via `/services/data/v68.0/actions/custom/flow/...` |
| Skill | `validate-metadata` §2/§3 · skill `calculate-margin` (conferência) |
| Ambiente | dev-trial — Org ID `00Das00000GrzvPEAR` |
| Objeto / Metadado | `DD_CalculateQuoteMargin` (`AutoLaunchedFlow`, `Active`, 40 elementos, 37 variáveis, 12 fórmulas) |
| Ferramenta | `sf project deploy start` + `sf api request rest` (POST actions/custom/flow) |
| Parâmetros-chave | entrada `quoteId='0Q0as0000021hOLCAY'`, `requestedDiscountPct=0` (cotação de 29,5673%, PB Fleet) |
| Confirmação humana | sim — confirmação dupla S6 dada ("Confirmo") |
| Resultado | deploys OK: `0Afas00000607qrCAA` (v1), `0Afas00000607sTCAQ` (v2), `0Afas000006080XCAQ` (v3), `0Afas00000608ADCAY` (v4, estado atual, `Active`). **Toda invocação falha** com `An unhandled fault has occurred in this flow`; nenhum `outputValue` é devolvido |
| Reversão | desativar o Flow e remover versões via Tooling; conferir `FlowDefinitionView` **e** Tooling `Flow` (A46/A50). Já existem **4 versões** → 3 `Obsolete` a limpar |
| Tokens (aprox.) | 22000 |
| Observações | **3 defeitos reais encontrados e corrigidos, 1 aberto.** (1) Os 7 `Get Records` usavam `storeOutputAutomatically=true` e as variáveis de registro declaradas (`quote`, `policyL3`…) **nunca eram populadas** → "cotação não encontrada"; corrigido com `outputReference` (A58). (2) **21 `Assignments` sem `<connector>`**: o Flow deploya e simplesmente termina no meio — o deploy **não valida travessia** (A59). (3) `TEXT()` sobre `Id` é inválido: o Flow já trata `Id` como Text. (4) **Defeito aberto:** após as correções o Flow atravessa a cadeia e estoura num elemento que não foi possível localizar — `FlowInterview`, `FlowInterviewLogEntry` e `Assign_Fault` não ajudaram: `FlowAssignment` e `FlowLoop` **recusam `faultConnector`** na posição tentada (só `Get Records` aceita, e o erro parou antes) |

---

### [2026-10-17 17:40 -03:00] FLW-003 — OK (F3-04: Flow de cálculo reescrito e validado em 5 cenários)

| Campo | Valor |
|---|---|
| Operação | reescrita + 12 deploys iterativos + 9 invocações via actions API |
| Skill | `validate-metadata` §2/§3/§4 · `calculate-margin` (conferência manual) |
| Ambiente | dev-trial — Org ID `00Das00000GrzvPEAR` |
| Objeto / Metadado | `DD_CalculateQuoteMargin` (`AutoLaunchedFlow`, `Active`, 29 elementos, 34 variáveis, 25 fórmulas) |
| Ferramenta | `sf project deploy start` + `sf api request rest` (POST `/actions/custom/flow/...`) |
| Parâmetros-chave | entrada `quoteId` + `requestedDiscountPct`; saída `marginBp`/`worstLineBp` em **pontos-base** |
| Confirmação humana | sim — confirmação dupla S6 ("Confirmo o deploy do novo DD_CalculateQuoteMargin") |
| Resultado | **5/5 cenários com dados reais** (tabela abaixo) |
| Reversão | desativar + remover versões via Tooling; conferir `FlowDefinitionView` e Tooling `Flow` (A46/A50). Há **12 versões** (11 `Obsolete`) a limpar |
| Tokens (aprox.) | 30000 |
| Observações | **3 causas raiz novas** (A61/A62/A63) + a dúvida do percentual resolvida (A64). O `diagnostics` foi decisivo: provou cada hipótese antes de corrigir |

| # | Cenário | Cotação | d | `marginBp` | `decision` | `guardrailState` | Política | `spec` |
|---|---|---|---|---|---|---|---|---|
| 1 | **Verde** | `DEMO-Quote-Guardrail-Green` (`0Q0as0000021j1xCAA`, Fleet) | 0 | 4167 (41,67%) | `AutoApproved` | Saudável | Parts-Fleet | 3 |
| 2 | **Amarelo** | `DEMO-Quote-Margin-Bands` (`0Q0as0000021hOLCAY`, Fleet) | 0 | 2957 (29,57%) | `ManagerApproval` | Requer Justificativa | Parts-Fleet | 3 |
| 3 | **Vermelho** | idem | 25 | 609 (6,09%) | `ManagerApproval` | Requer Aprovação | Parts-Fleet | 3 |
| 4 | **Precedência nível 1** | `DEMO-Quote-Guardrail-Generic` (`0Q0as0000021j3ZCAQ`, Retail) | 0 | 10000 | `AutoApproved` | Saudável | **Parts-AllPB** | **1** |
| 5 | **Sem política** | `0Q0as00000216zyCAA` (família `Part`) | 0 | — | `NoPolicy` | Pendente de Política | nenhuma | — |

**Massa criada (QTE-001):** `Quote` `0Q0as0000021j1xCAA` (`DEMO-Quote-Guardrail-Green`, PB `01sas000001nOBJAA2`, USD) + `QuoteLineItem` `0QLas0000028ydlGAA` (PBE `01uas000000RovXAAS`, qtd 1, preço 120, custo 70 → 41,6667%) · `Quote` `0Q0as0000021j3ZCAQ` (`DEMO-Quote-Guardrail-Generic`, PB `01sas000001nOBHAA2`, USD) + `QuoteLineItem` `0QLas0000028yc9GAA` (PBE `01uas000000RovGAAS`, qtd 1, preço 180, **sem custo semeado** → 100%). Reversão: apagar as 2 cotações (as linhas caem junto).

**Ressalvas (A19):** no cenário 4 a margem é 100% porque o Retail não tem custo semeado (F0-08 semeou só no Fleet) — o que ele prova é a **resolução de política (`spec=1`)**, não a margem. No cenário 5 a família é `Part` (não `Parts`), o que também confirma a armadilha do D17.

---

### [2026-10-17 18:20 -03:00] RTE-001 — OK (F3-05/F3-07/F3-08: roteamento + 3 cenários ponta a ponta)

| Campo | Valor |
|---|---|
| Operação | deploy de Flow + 4 invocações do roteamento + 1 pedido criado/atualizado |
| Skill | `validate-metadata` §2/§3 · `route-approval` |
| Ambiente | dev-trial — Org ID `00Das00000GrzvPEAR` |
| Objeto / Metadado | `DD_RouteDiscountApproval` (`AutoLaunchedFlow`, `Active`, 28 elementos) + `DD_DiscountRequest__c` |
| Ferramenta | `sf project deploy start` + `sf api request rest` (POST `/actions/custom/flow/...`) |
| Confirmação humana | sim — confirmação dupla S6 ("Confirmo o deploy do DD_RouteDiscountApproval") |
| Resultado | deploy `0Afas00000609HZCAY` + 2 redeploys corretivos · **3/3 cenários OK** · pedido `a0Nas00000TgQTdEAN` (`DR-00000`) |
| Reversão | apagar o pedido `a0Nas00000TgQTdEAN` e desativar/remover o Flow |
| Tokens (aprox.) | 18000 |
| Observações | 2 defeitos pegos em execução: (1) `IsNull` sobre **campo de lookup** (`owner.ManagerId`) não é avaliado — o Flow caiu no `Get_Manager` com Id nulo e estourou `columnName: null__NotFound` (A65); (2) filtro em **campo de objeto relacionado** (`Profile.Name`) no `Get Records` não resolve — mesmo erro (A65). Saídas de subflow exigem `assignToReference` + `name`, não `value` (A66) |

| # | Cenário | Entrada | Resultado |
|---|---|---|---|
| 1 | **Verde** | `DEMO-Quote-Guardrail-Green`, `d=0` | `AutoApproved` · Saudável · **nenhum pedido criado** (contagem seguiu 0) |
| 2 | **Amarelo** | `DEMO-Quote-Margin-Bands`, `d=0`, com justificativa | `ManagerApproval` · Requer Justificativa · pedido **`DR-00000`** criado `Submitted` · aprovador `Alan FieldTech` (`FallbackAdmin`) · política `Parts-Fleet` `spec=3` · piso 20 / alvo 30 · `USD` |
| 3 | **Vermelho** | mesma cotação, `d=25` | `ManagerApproval` · Requer Aprovação · **mesmo pedido atualizado** (`DR-00000`, `d=25`) — contagem total permaneceu **1**, provando a idempotência |

**Ressalva (A19):** o aprovador saiu como `FallbackAdmin` → `Alan FieldTech` porque (a) o dono da cotação não tem gestor, (b) o dono da política é o próprio solicitante, e (c) o filtro `Profile.Name` não funciona em `Get Records`. O degrau escolhe o **primeiro usuário ativo ≠ solicitante** ordenado por `Name` — não necessariamente um administrador. Registrado como limitação em D26.

---

### [2026-10-17 18:35 -03:00] CLN-001 — FALHA (F3-09: limpeza das versões Obsolete)

| Campo | Valor |
|---|---|
| Operação | remoção de versões antigas de Flow (24 versões: 22 do cálculo + 2 do roteamento) |
| Skill | `validate-metadata` §5 |
| Ambiente | dev-trial — Org ID `00Das00000GrzvPEAR` |
| Objeto / Metadado | `Flow` (`DD_CalculateQuoteMargin` v1–v22, `DD_RouteDiscountApproval` v1–v2) |
| Ferramenta | `DELETE /tooling/sobjects/Flow/<id>` · `sf data delete record --use-tooling-api -s Flow` · deploy destrutivo |
| Confirmação humana | sim — "autorizo a limpeza (S5)" |
| Resultado | **não removidas.** `DELETE` via Tooling devolve corpo vazio (204) mas a versão permanece; `sf data delete record` retorna `DEPENDENCY_EXISTS: This flow version is referenced in a flow interview`; o deploy destrutivo retorna `insufficient access rights on cross-reference id`; desativar por metadata não existe (`<status>` aceita só `Active`/`Draft`) e o `PATCH` no Tooling devolve 400 |
| Reversão | não aplicável (nada foi alterado) |
| Tokens (aprox.) | 6000 |
| Observações | O bloqueio é a **`FlowInterview` retida** por cada invocação que falhou (`0Foas…`). `FlowInterview` não é consultável por SOQL nem por Tooling nesta org, então não há como apagá-las por script. As versões antigas **não afetam operação** (só a ativa executa) e a contagem de **definições** está no baseline esperado: `FlowDefinitionView` **256** / ativos **219** / locais **32** (254/217/30 + os 2 Flows entregues). Limpeza possível depois que as entrevistas expirarem, pela UI (Setup → Flows → versões) |

---

### [2026-10-17 19:00 -03:00] UI-001 — OK (F4-02 a F4-05: console LWC + FlexiPage + aba + app)

| Campo | Valor |
|---|---|
| Operação | deploy de metadata: `LightningComponentBundle`, `FlexiPage`, `CustomTab`, `CustomApplication` + fragmento de `Profile` |
| Skill | `validate-metadata` §2/§3/§4 · `sf-lwc` |
| Ambiente | dev-trial — Org ID `00Das00000GrzvPEAR` (IsSandbox: **false**) |
| Objeto / Metadado | `ddMarginConsole` · `DD_Quote_Record_Page` · `DD_Margin_Console` · `DD_DealDesk` · `Admin.profile` |
| Ferramenta | `sf project deploy start` (com `--dry-run` antes em cada pacote) |
| Parâmetros-chave | `apiVersion=68.0`; `--test-level NoTestRun`; `--source-dir` restrito a `lwc/`, `flexipages/`, `tabs/`, `applications/`, `profiles/` |
| Confirmação humana | sim — plano apresentado com código e riscos; "Confirmo — prossiga" |
| Resultado | **dry-run 1: FALHA com 2 erros** (A69/A71) → corrigidos · deploy `0Afas00000609kbCAA` (4/4) · re-deploy da aba `0Afas00000609r3CAA` (A70) · perfil `0Afas00000609z7CAA` (A72) · LWC final `0Afas0000060AiHCAU` |
| Reversão | remover os 4 metadados e as entradas `applicationVisibilities`/`tabVisibilities` do `Admin.profile-meta.xml`; a página da `Quote` volta ao padrão ao remover a `actionOverride` do app |
| Tokens (aprox.) | 26000 |
| Observações | O dry-run pegou **2 defeitos que só apareceriam no deploy real**: `lwcComponent` com `c:` (A69) e região `sidebar` com `<mode>Replace</mode>` sem região-mãe (A71). O app ficou **inacessível** após deploy `Succeeded` (A72) e só abriu após `applicationVisibilities` no perfil |

| # | Componente | API name | Verificação |
|---|---|---|---|
| 1 | LWC | `ddMarginConsole` | `targets` `lightning__RecordPage`+`lightning__Tab`, `isExposed=true`, `apiVersion=68.0` |
| 2 | FlexiPage | `DD_Quote_Record_Page` | retrieve confirma `c:ddMarginConsole`, `force:highlightsPanel`, `force:relatedListContainer` (A71) e `force:detailPanel` |
| 3 | CustomTab | `DD_Margin_Console` | `<motif>Custom41: Stack of Cash</motif>` persistido (A70); URL `/lightning/n/DD_Margin_Console` abre |
| 4 | CustomApplication | `DD_DealDesk` | label "Deal Desk"; `actionOverrides` View/Quote → FlexiPage, **Large e Small** (escopo: só este app) |

---

### [2026-10-17 19:15 -03:00] APX-001 — FALHA (plano B com Apex vetado pela plataforma)

| Campo | Valor |
|---|---|
| Operação | tentativa de deploy de `ApexClass` invocadora (`Flow.Interview`) + classe de teste |
| Skill | `validate-metadata` §3 |
| Ambiente | dev-trial — Org ID `00Das00000GrzvPEAR` |
| Objeto / Metadado | `ApexClass:DD_FlowConsoleController` + `DD_FlowConsoleControllerTest` |
| Ferramenta | `sf project deploy start --dry-run --test-level RunLocalTests` |
| Confirmação humana | sim — escolha explícita do plano B por Apex |
| Resultado | **dry-run `Failed` com `numberComponentErrors = 0` e `numFailures = 0`**: 64 testes locais rodaram sem falha, mas a cobertura **org-wide é 0%** (`ApexOrgWideCoverage`) — org não-sandbox exige 75%. **Nenhuma classe chegou a ser criada na org** |
| Reversão | não aplicável (nada deployado); os 4 arquivos locais foram **removidos** do projeto |
| Tokens (aprox.) | 9000 |
| Observações | 2 falhas de teste precederam o veredito e foram corrigidas (A: `STANDARD_PRICE_NOT_DEFINED` exige entrada no price book padrão; moeda do `PricebookEntry` deve casar com a da `Quote`). O bloqueio real é **cobertura org-wide** (A68) — Apex está fora de escopo nesta org. O caminho declarativo com `lightning-flow` foi então depurado e funciona (A67/UI-002) |

---

### [2026-10-17 19:40 -03:00] UI-002 — OK (F4-06: 3 estados, simulador sem DML e botão)

| Campo | Valor |
|---|---|
| Operação | teste funcional no navegador (Chrome real, sessão do usuário) + 3 SOQL de controle |
| Skill | `validate-metadata` §4 · `sf-lwc` |
| Ambiente | dev-trial — Org ID `00Das00000GrzvPEAR` |
| Objeto / Metadado | `Quote` (3 registros) + `ddMarginConsole` + flows `DD_CalculateQuoteMargin`/`DD_RouteDiscountApproval` |
| Ferramenta | `mcp__chrome__*` (navegação, snapshot, innerText) + `sf data query` |
| Confirmação humana | sim — "faça o teste (F4-06) e me apresente o resultado" |
| Resultado | **6/6 verificações OK** (tabela abaixo) |
| Reversão | não aplicável — o teste **não gravou nada** (contagens e `LastModifiedDate` idênticos) |
| Tokens (aprox.) | 14000 |
| Observações | **Achado D14 em aberto:** o painel de detalhes da `Quote` (layout padrão) exibe `DD Receita`, `DD Custo Total` e `DD Margem % da Cotacao` para o **admin**. O console é limpo, mas o fechamento do vazamento para o vendedor é a F5-01 (negar leitura por perm set) |

| # | Verificação | Entrada | Resultado |
|---|---|---|---|
| 1 | Estado verde | `DEMO-Quote-Guardrail-Green` | badge **Saudável** + orientação "não exige pedido" |
| 2 | Estado âmbar | `DEMO-Quote-Margin-Bands` | badge **Requer Justificativa** + campo "Justificativa (obrigatória)" |
| 3 | Estado vermelho | `Dec Asset Repair` | badge **Requer Aprovação** + "sobe para o aprovador da alçada" |
| 4 | Simulador 25% no verde | `d=25` | **Requer Justificativa** · política `DEMO-Policy-Parts-Fleet` · botão volta a "Simular" (flow desmontado, sem banner — A67) |
| 5 | Simulador não grava | 3 SOQL antes/depois | `DD_DiscountRequest__c` = **1 → 1**; `Quote.LastModifiedDate` = **2026-10-17T18:21:52Z** nas duas leituras |
| 6 | Botão "Pedir desconto" | `d=10` + justificativa, cotação verde | **AutoApproved** · "Nenhum pedido foi criado" · zero DML. Sem justificativa no estado projetado âmbar: bloqueia com a mensagem "O estado Requer Justificativa exige justificativa antes do envio" |

**D14 — prova de ausência de número:** `grep` do bundle por `DD_MarginPct__c`, `DD_Cost__c`, `marginBp`, `worstLineBp`, `floorMarginPct` e `diagnostics` → **zero ocorrências**; o texto renderizado do card não contém nenhuma porcentagem numérica. O componente lê apenas `guardrailState`, `policyName`, `decision`, `message`, `requestId` e `approverName` (whitelist em `toOutputMap`).

**Aba:** `/lightning/n/DD_Margin_Console` renderiza o componente sem `recordId` e mostra "Abra o console a partir de uma cotação".

---

### [2026-10-17 20:05 -03:00] QRY-001 — OK (diagnóstico do teste em BRL; somente leitura)

| Campo | Valor |
|---|---|
| Operação | 8 consultas SOQL de diagnóstico (nenhuma escrita) |
| Skill | `query-salesforce` |
| Ambiente | dev-trial — Org ID `00Das00000GrzvPEAR` |
| Objeto / Metadado | `Quote` `00000041` · `QuoteLineItem` · `PricebookEntry` · `Pricebook2` |
| Ferramenta | `sf data query` |
| Confirmação humana | não aplicável (leitura) |
| Resultado | **causa confirmada:** a cotação `Teste cotacao deal` está em **BRL** no **Standard Price Book** e a linha `MediScan Ventilator` usou a entrada **BRL** `01uas000000RpJNAA0`, que **não tem custo**; a entrada **USD** do mesmo produto (`01uas000000RoumAAC`) tem `FixedCost__c=24200` + `VariableCostPerUnit__c=10300` = 34.500. Custo 0 → margem 100% → `Saudável`, e o simulador fica verde até com 90% |
| Reversão | não aplicável |
| Tokens (aprox.) | 4000 |
| Observações | O custo existe em **24 entradas USD** e em **0 entradas BRL** (só 3 BRL existem, todas `Medical Equipment`, no Standard PB). **Não existe price book BRL** — apagar entradas não resolveria (S5 nem foi acionado). Decisão de correção adiada pelo humano: registradas **F5-07** (custo ausente ≠ margem 100%) e **F5-08** (custo das entradas BRL) |

---

### [2026-10-17 18:25 -03:00] FLW-004 — OK (F5-07: custo ausente deixa de parecer margem perfeita)

| Campo | Valor |
|---|---|
| Operação | 1 `update` de campo de fórmula + 1 `update` de picklist + 2 `deploy` de Flow (3 deploys no total: o Flow de cálculo foi republicado) |
| Skill | validate-metadata · calculate-margin |
| Ambiente | dev/trial — Org ID `00Das00000GrzvPEAR` (IsSandbox: false · trial `2026-11-15`) |
| Objeto / Metadado | `Quote.DD_GuardrailState__c` (fórmula) · `DD_DiscountRequest__c.GuardrailState__c` (picklist) · `Flow:DD_CalculateQuoteMargin` · `Flow:DD_RouteDiscountApproval` |
| Ferramenta | `sf project deploy start --metadata <componente>` com `--dry-run` antes de cada escrita |
| Parâmetros-chave | `--test-level NoTestRun`; deploy restrito por componente (nunca `--source-dir force-app`) para não republicar `DD_CalculateLineCost` (A50) |
| Confirmação humana | sim — plano de deploy apresentado e aprovado; segunda confirmação no "pode prosseguir com os deploys" |
| Resultado | 5 deploys `Succeeded`: campos `0Afas0000060Bw5CAE`/`0Afas0000060BxhCAE` · cálculo `0Afas0000060C0vCAE` e correção `0Afas0000060B1fCAE` · roteamento `0Afas0000060C2XCAU`. 5 `dry-run` aprovados antes |
| Reversão | `git revert` dos 6 arquivos + redeploy; a fórmula anterior era `IF(DD_MarginPct__c >= 0.30, "Saudável", IF(DD_MarginPct__c >= 0.20, "Requer Justificativa", "Requer Aprovação"))`; o literal novo da picklist pode ficar (aditivo) |
| Tokens (aprox.) | 30000 |
| Observações | **Duas correções em sequência:** o 1º deploy colocou a checagem de custo **depois** da política e a cotação sem custo e sem política devolveu `Pendente de Política` no simulador enquanto o campo da `Quote` dizia `Pendente de Custo` (A76). O 2º deploy moveu a checagem para **antes** de `Get_Product`. `--dry-run` e deploy passaram nos dois casos: falha semântica não é pega pelo compilador |

**Cenários testados (execução via `POST /actions/custom/flow/DD_CalculateQuoteMargin`)**

| # | Cotação | Desconto | Estado | Decisão | Observação |
|---|---|---|---|---|---|
| 1 | `0Q0as0000021jtBCAQ` (sem custo) | 90% | **Pendente de Custo** | `CostPending` | `costPending=1` no `diagnostics`; antes da correção era `Saudável` |
| 2 | `0Q0as0000021jtBCAQ` | 0% | **Pendente de Custo** | `CostPending` | estado independe do desconto |
| 3 | `0Q0as0000021j1xCAA` (Green) | 0% | Saudável | `AutoApproved` | **sem regressão** |
| 4 | `0Q0as0000021hOLCAY` (Margin-Bands) | 0% | Requer Justificativa | `ManagerApproval` | **sem regressão** |
| 5 | `0Q0as0000021j3ZCAQ` (sem custo e sem política) | 0% | **Pendente de Custo** | `CostPending` | custo tem precedência sobre a política (D29) |

**Roteamento (execução via `POST /actions/custom/flow/DD_RouteDiscountApproval`)**

| Campo | Valor |
|---|---|
| Entrada | `quoteId=0Q0as0000021jtBCAQ`, `requestedDiscountPct=90`, justificativa preenchida |
| Saída | `decision=CostPending`, `status=CostPending`, **`requestId` nulo**, mensagem "o custo das linhas nao esta cadastrado… Nenhum pedido foi criado" |
| Contagem de `DD_DiscountRequest__c` | **1 antes / 1 depois** — nenhum pedido criado com custo pendente |
| Resíduo de versão (A46/A50) | `DD_CalculateQuoteMargin`: v24 e v25 criadas nesta sessão (v25 `Active`, v24 `Obsolete`) · `DD_RouteDiscountApproval`: v4 `Active`, v3 `Obsolete` |

### [2026-10-17 19:00 -03:00] UI-003 — OK (console exibe Pendente de Custo)

| Campo | Valor |
|---|---|
| Operação | 1 deploy de `LightningComponentBundle` |
| Skill | validate-metadata |
| Objeto / Metadado | `LWC ddMarginConsole` (`.js`, `.html`, `.css`) |
| Ferramenta | `sf project deploy start --metadata LightningComponentBundle:ddMarginConsole` (`--dry-run` antes) |
| Confirmação humana | sim — incluída no mesmo plano do FLW-004 |
| Resultado | `Succeeded` — deploy `0Afas0000060C49CAE` |
| Reversão | `git revert` do bundle + redeploy `.lightningComponentBundle` |
| Tokens (aprox.) | 8000 |
| Observações | Verificação no navegador na cotação `0Q0as0000021jtBCAQ`: badge `Pendente de Custo` com fundo `rgb(112,110,107)` (cinza), alerta `data-testid="cost-pending-alert"` renderizado, botão *Pedir desconto* desabilitado com a frase de bloqueio. Simulador a 90% devolveu "Estado projetado: Pendente de Custo" + "Pendente de Custo — o Pricing precisa cadastrar o custo". Nenhum número de margem ou custo na tela (D14) |

### [2026-10-17 19:15 -03:00] FLS-001 — OK (F5-01: permission set DD_DealDesk_User)

| Campo | Valor |
|---|---|
| Operação | 1 `create` de `PermissionSet` + 1 `create` de `PermissionSetAssignment` |
| Skill | validate-metadata |
| Ambiente | dev/trial — Org ID `00Das00000GrzvPEAR` |
| Objeto / Metadado | `PermissionSet:DD_DealDesk_User` (`0PSas000004H6puGAC`) · `PermissionSetAssignment` `0Paas00000BpdrHCAR` |
| Ferramenta | `sf project deploy start --metadata PermissionSet:DD_DealDesk_User` (`--dry-run` antes, 4 vezes) + `sf data create record` |
| Confirmação humana | sim — payload + impacto apresentados; "Confirmo o payload" (S6) |
| Resultado | `Succeeded` — deploy `0Afas0000060D6fCAE` · 5 `objectPermissions` (todos read-only) · tab `DD_Margin_Console` visível · app `DD_DealDesk` visível · 2 `flowAccesses` · **22 `FieldPermissions` de leitura** e **0 negações** |
| Reversão | apagar `0PSas000004H6puGAC` e o assignment `0Paas00000BpdrHCAR` (exige autorização nominal — S5) |
| Tokens (aprox.) | 15000 |
| Observações | **Achado A75:** as 7 linhas com `readable=false` (`Quote.DD_MarginPct__c`, `Quote.DD_Cost__c`, `Quote.DD_WorstLineMarginPct__c`, `QuoteLineItem.DD_MarginPct__c`, `DD_MarginAmount__c`, `DD_CostAmount__c`, `DD_CostPerUnit__c`) foram **descartadas pela org** — permission set só concede. A negação efetiva vem do perfil, provada por SOQL: os 7 campos têm FLS **apenas** no perfil System Administrator e nenhum perfil de vendedor. **Quirks pegos no dry-run (A77):** `<default>` inválido em `PermissionSetApplicationVisibility`; `description` > 255; `Quote` read exige `Opportunity` read. Atribuído ao Standard User `005as000003pCpEAAU` (Alan FieldTech) para a validação sem admin |

### [2026-10-17 19:30 -03:00] DEM-001 — OK (F5-02: massa de demonstração)

| Campo | Valor |
|---|---|
| Operação | 3 `create` em `Quote` + 4 `create` em `QuoteLineItem` (lote único autorizado, precedente D16) |
| Skill | query-salesforce |
| Objeto / Metadado | `Quote` / `QuoteLineItem` |
| Ferramenta | `sf api request rest services/data/v68.0/sobjects/<obj>` (`POST`) |
| Parâmetros-chave | `CurrencyIsoCode=USD` explícito · `Pricebook2Id=01sas000001nOBJAA2` explícito · `Status=Draft` · `ExpirationDate=2026-10-31` · nomes com prefixo `DEMO-` (S11) |
| Confirmação humana | sim — tabela de 7 registros aprovada ("Confirmo os 7 registros") |
| Resultado | `DEMO-Quote-Demo-Saudavel` `0Q0as0000021mHZCAY` (264/164, **37,8788%**, Saudável) · `DEMO-Quote-Demo-Limite` `0Q0as0000021mFyCAI` (160/124, **22,50%**, Requer Justificativa) · `DEMO-Quote-Demo-Abaixo` `0Q0as0000021mJBCAY` (192/158, **17,7083%**, Requer Aprovação) · linhas `0QLas00000291yDGAQ`, `0QLas00000291zpGAA`, `0QLas000002921RGAQ`, `0QLas0000029233GAA` |
| Reversão | apagar as 3 cotações (cascade nas linhas) — exige autorização nominal (S5) |
| Tokens (aprox.) | 7000 |
| Observações | Custo **não** foi escrito à mão: veio do `DD_CalculateLineCost` no insert (prova de que o before-save segue funcionando após os deploys da Fase 5). Simulações validadas: A a 15% → Requer Justificativa (26,9%); B a 5% → Requer Aprovação (18,4%); C a 0% → Requer Aprovação |

### [2026-10-17 19:40 -03:00] QRY-002 — OK (recontagem de custo: 23, e a entrada do MedCart não existe mais)

| Campo | Valor |
|---|---|
| Operação | leitura (`SOQL`, `queryAll`) — nenhuma escrita |
| Skill | query-salesforce |
| Objeto / Metadado | `PricebookEntry` / `Product2` |
| Ferramenta | `sf data query` + `sf api request rest services/data/v68.0/queryAll` |
| Resultado | **23** entradas com `FixedCost__c` (Fleet 14 · Standard 9), não 24. A entrada `01uas000000RousAAC` (`MediScan MedCart`, `1700/790`, semeada em `SED-001`) **não existe mais**, nem em `queryAll` (lixeira vazia / exclusão definitiva). O `Product2` `MediScan MedCart` (`01tas000007Va6yAAC`) está sem nenhuma `PricebookEntry` |
| Reversão | não aplicável |
| Observações | Não foi ação deste agente: na sessão houve apenas deploy de metadado, leitura e criação dos 7 registros de `DEM-001` (nenhum delete). Registrado para rastreio (S10). **Não recriar sem autorização nominal** — pode ter sido remoção deliberada. Baseline `MEMORY.md` §1.6 corrigido de 24 para 23 |

## Registro de Bloqueios

Toda entrada `BLOQUEADO` deve informar qual guardrail atuou.

| # | Data | Guardrail | Motivo | Ação tomada |
|---|---|---|---|---|
| — | — | — | — | — |

Guardrails de referência: `S1` produção · `S3` confirmação ausente · `S4` lote > 1 ·
`S5` exclusão sem autorização · `S6` flow sem dupla confirmação · `S7` deploy sem dry-run.

---

## Manutenção (custo)

- Uma entrada = uma operação. Não agrupar operações distintas.
- Campos-chave resumidos: não colar payloads grandes nem describes completos.
- Ler apenas as últimas entradas ao auditar (não carregar o arquivo inteiro no contexto).
- Rotacionar para `docs/execution-log-<AAAA>.md` ao passar de ~500 linhas, mantendo o índice aqui.
