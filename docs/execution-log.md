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
| AF-001 | 2026-10-17 | F6-03/F6-04 deploy do bundle mdapi de 3 arquivos da ação de agente + retrieve de integridade | GenAiFunction | OK | `172as000008FaHtAAK` |
| AF-002 | 2026-10-17 | F6-07 `sf_create_agent` recusa o tipo `EinsteinServiceAgent` (sem template acessível) — nenhum resíduo | Bot | FALHA | — |
| AF-003 | 2026-10-17 | F6-05/F6-06/F6-07 tópico via MCP + agente Employee (`Bot`+`BotVersion`+`Planner`) via mdapi + ativação no Builder | GenAiPlugin / Bot / GenAiPlannerBundle | OK | bot `0Xxas000000AJpNCAW` |
| AF-004 | 2026-10-17 | F6-08 4 perguntas reais no Agentforce Builder (3 desfechos + adversaria de margem/custo) | Agente `DDDealDeskAgent` | OK | 4/4 |
| MASSA-001 | 2026-10-18 | massa de demonstração realista: 5 cenários Oportunidade → Cotação → Itens, PT-BR, USD, sem prefixo `DEMO-` | Opportunity / Quote / QuoteLineItem | OK | 5 opps · 5 quotes · 17 linhas |
| MASSA-002 | 2026-10-18 | hierarquia não-admin: 2 usuários PT-BR (vendedor + gerente) + 3 cenários com o vendedor como proprietário + roteamento das 2 cotações que exigem aprovação | User / PermissionSetAssignment / Opportunity / Quote / DD_DiscountRequest__c | OK | 2 users · 2 PS · 3 opps · 3 quotes · 7 linhas · 2 pedidos |
| FLW-005 | 2026-10-18 | investigação do console para usuário não-admin: `FLOW_ACCESS_RESTRICTED` reproduzido; 6 sondas de permissão; deploy e reversão de `runInMode`; ambiente restaurado | Flow / PermissionSet / User | FALHA | causa **não** identificada |
| FLW-006 | 2026-10-18 | teste do Perfil `Standard` concedendo acesso aos 2 Flows (+ sonda de FLS, 7ª combinação) | Profile / PermissionSet | FALHA | mesmo erro — Perfil não é o gate |
| APR-001 | 2026-10-18 | F5-12 tela nativa de aprovação: `ApprovalProcess` no pedido, submissão pelo controller, `Status__c` opcional + regra, FLS de leitura | ApprovalProcess / Workflow / CustomField / PermissionSet / ApexClass | OK | processo ativo `04aas000000atijAAA` |
| APR-002 | 2026-10-18 | submissão dos 3 pedidos que já existiam à fila da gerente (DR-00001/2/3) | DD_DiscountRequest__c | OK | 3 `ProcessInstanceWorkitem` para Renata |
| LAY-001 | 2026-10-18 | layout do pedido orientado à decisão do gerente: 4 seções, 2 colunas, justificativa em largura total | Layout `DD_DiscountRequest__c` | OK | `09Sas000000QZuzEAG` |
| APR-003 | 2026-10-18 | `approvalPageFields` do processo: 9 campos na tela de aprovação (antes só Nome e Owner) | ApprovalProcess | OK | `04aas000000atijAAA` |
| FIN-001 | 2026-10-18 | F5-15: valores financeiros do pedido (original, desconto, final) no Flow, layout e página de aprovação | DD_DiscountRequest__c / Flow | OK | 3 campos `Currency 18,2` |

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

### [2026-10-17 20:05 -03:00] ACES-001 — OK (F5-03 + F5-05 + F5-06: fase 5 fechada)

| Campo | Valor |
|---|---|
| Operação | validação funcional (humano) + fechamento documental — nenhuma escrita na org |
| Skill | validate-metadata |
| Objeto / Metadado | `Quote` (FLS por perfil) · `PermissionSet:DD_DealDesk_User` |
| Ferramenta | navegador (Admin × Standard User) + `sf data query` (FLS) |
| Confirmação humana | sim — "O teste visual da F5-03 foi um sucesso absoluto… A segurança está provada" |
| Resultado | **F5-03:** como Admin, `DD_Cost__c` e `DD_MarginPct__c` visíveis; como `Alan FieldTech` (`005as000003pCpEAAU`, Standard User, janela anônima), os campos **desaparecem por completo** e resta apenas o semáforo. A prova funcional **concorda** com a prova por dado (os 7 campos sensíveis só têm FLS no perfil System Administrator). **F5-05:** roteiro documentado e 3 estados + simulações + roteamento validados por API; ensaio de tempo fica com o humano. **F5-06:** `MEMORY.md` §1.2/§1.6/§1.8/§2 (D29)/§3 (A75–A77)/§5, `task-plan.md` §2/§4/§5 e `roadmap.md` atualizados |
| Reversão | não aplicável |
| Tokens (aprox.) | 6000 |
| Observações | A validação **confirmou a conclusão do A75**: o permission set não nega nada; quem nega é o perfil. Fica registrado para a Fase 6: o estado `Pendente de Custo` (`decision = CostPending`) é um quarto desfecho e **não** pode ser verbalizado como margem saudável pelo agente (D15/D29). Tag `fase-5` criada no commit de fechamento |

### [2026-10-17 22:51 -03:00] AF-001 — OK (F6-03/F6-04: ação de agente DD_CalculateMargin íntegra)

| Campo | Valor |
|---|---|
| Operação | 1 `deploy` mdapi de `GenAiFunction` (com `--dry-run` antes) + 1 `retrieve` de integridade |
| Skill | deploy-agentforce-action |
| Ambiente | dev/trial — Org ID `00Das00000GrzvPEAR` (IsSandbox: false · trial `2026-11-15`) |
| Objeto / Metadado | `GenAiFunction:DD_CalculateMargin` (`172as000008FaHtAAK`) → `Flow:DD_CalculateQuoteMargin` (v25, `Active`) |
| Ferramenta | `sf project deploy start --metadata-dir mdapi --dry-run` e sem dry-run · `sf project retrieve start --api-version 66.0` |
| Parâmetros-chave | `<version>66.0</version>` no `package.xml`; `invocationTargetType = flow`; `isConfirmationRequired = false`; `--test-level NoTestRun` |
| Confirmação humana | sim — plano dos 3 arquivos apresentado e "Confirmo o bundle como apresentado" |
| Resultado | dry-run `Succeeded` (`0Afas0000060DOPCA2`, 1/1) · deploy `Succeeded` (`0Afas0000060DQ1CAM`, 1/1) · **retrieve devolveu os 3 arquivos** (`-meta.xml`, `input/schema.json`, `output/schema.json`) e todos fazem parse |
| Reversão | `sf_delete_metadata` de `GenAiFunction:DD_CalculateMargin` (exige autorização nominal — S5) |
| Tokens (aprox.) | 12000 |
| Observações | Schema validado **contra a cópia da org** do Flow: input 2 propriedades = 2 `isInput`; output 17 propriedades = 17 `isOutput`, sem faltar nem sobrar. Os campos `marginBp`, `worstLineBp`, `diagnostics`, `policyId` e `ownerId` saíram com `isDisplayable=false` e `isUsedByPlanner=false` (**D15 por contrato**); `decision` documenta `CostPending` e `guardrailState` documenta `Pendente de Custo` (F5-07/D29). Divergência normal do retrieve (A51): só o acréscimo de `<isIncludeInProgressIndicator>false</isIncludeInProgressIndicator>`. O Flow **não** foi reimplantado (v25 segue `Active`) → nenhuma versão `Obsolete` nova (A50). O MCP `sf_create_agent_action` **não** foi usado (A44). `GenAiFunction` na org: 1 → **2** |

### [2026-10-17 22:58 -03:00] AF-002 — FALHA (F6-07: `sf_create_agent` recusa o tipo `EinsteinServiceAgent`)

| Campo | Valor |
|---|---|
| Operação | 1 tentativa de `create` (`Bot`) via MCP — **falhou antes de gravar**; leituras de diagnóstico depois |
| Skill | deploy-agentforce-action (pré-requisito do tópico/planner) |
| Objeto / Metadado | `Bot:DDDealDeskAgent` — **não criado** |
| Ferramenta | MCP `sf_create_agent` (`agentName=DDDealDeskAgent`, `label=Guardrail de Desconto Deal Desk`) |
| Confirmação humana | sim — payloads de tópico, planner e agente aprovados ("Confirmo tópico, planner e agente") |
| Resultado | **FALHA.** Erro literal: `Deployment failed: Looks like you don’t have access to agent templates associated with the EinsteinServiceAgent agent type. Make sure that you have the required permissions for the type and try again. / bots/DDDealDeskAgent.bot: Looks like you don’t have access to agent templates associated with the EinsteinServiceAgent agent type. Make sure that you have the required permissions for the type and try again.` |
| Resíduo | **nenhum** — `SELECT Id FROM BotDefinition WHERE DeveloperName = 'DDDealDeskAgent'` devolve 0 linhas; `BotDefinition` segue com 6 |
| Reversão | não aplicável (nada foi gravado) |
| Tokens (aprox.) | 9000 |
| Observações | **Diagnóstico somente leitura (A19):** os 6 `BotDefinition` da org são todos `AgentforceEmployeeAgent` / `InternalCopilot` (inclusive `Copilot_for_Salesforce`, `AgentType = Employee`); a licença `Agentforce (Default)` (`EinsteinGPTCopilotPsl`) está `Active` com 2/10 em uso e o usuário `005as000003pCmzAAE` **está** entre os 2; **não existe** licença de "Service Agent" (a busca só devolve `RevCloudSelfServeAgentPsl`); `AgentTemplate` **não** é objeto consultável na API. **O que isso NÃO prova:** não prova que a org não suporta agente — prova que o tipo `EinsteinServiceAgent`, que a ferramenta usa, não tem template acessível nesta org. Não foi tentada variação às cegas (nem `skipActionCapabilityCheck`, nem troca de nome): o erro vem do deploy do `.bot`, não do probe |

### [2026-10-17 23:05 -03:00] AF-003 — OK (F6-05/F6-06/F6-07: tópico, planner e agente Employee via mdapi)

| Campo | Valor |
|---|---|
| Operação | 1 `create` de `GenAiPlugin` (MCP) + 1 `deploy` mdapi de `Bot`+`BotVersion`+`GenAiPlannerBundle` (3 componentes, `--dry-run` antes) + 1 ativação pela UI do Builder |
| Skill | deploy-agentforce-action · validate-metadata |
| Ambiente | dev/trial — Org ID `00Das00000GrzvPEAR` (IsSandbox: false · trial `2026-11-15`) |
| Objeto / Metadado | `GenAiPlugin` `DD_DealDesk_Guardrail` (`179as000000E0rNAAS`) · `GenAiPlannerBundle` `DDDealDeskPlanner` (`16jas00000061avAAA`) · `Bot` `DDDealDeskAgent` (`0Xxas000000AJpNCAW`) · `BotVersion` v1 (`0X9as000000F9kXCAS`) |
| Ferramenta | MCP `sf_create_agent_topic` · `sf project deploy start --metadata-dir mdapi-f6bot` · botão *Activate* no Agentforce Builder |
| Parâmetros-chave | `agentType = AgentforceEmployeeAgent`, **sem** `agentTemplate` (molde: `Copilot_for_Salesforce`); planner `AiCopilot__ReAct`; tópico com `actions = ["DD_CalculateMargin"]` e **11 instruções**; `<version>66.0</version>` |
| Confirmação humana | sim — payloads de tópico/planner/agente aprovados; F6-10 autorizou explicitamente o probe de Bot Employee |
| Resultado | tópico criado com 1 ação · dry-run `0Afas0000060DUrCAM` `Succeeded` (3/3) · deploy `0Afas0000060DWTCA2` `Succeeded` · ativação `0Afas0000060DZhCAM` → `BotVersion v1 = Active` (visto também na UI: "Version 1 (Active)") |
| Reversão | `sf_delete_metadata` de `Bot:DDDealDeskAgent`, `GenAiPlannerBundle:DDDealDeskPlanner` e `GenAiPlugin:DD_DealDesk_Guardrail` (exige autorização nominal — S5); desativar antes de apagar o bot |
| Tokens (aprox.) | 22000 |
| Observações | **Desvio consciente do plano:** o planner saiu por mdapi (não pelo MCP) porque o `BotVersion` precisa referenciar o planner **e** o planner precisa referenciar o tópico — montar os dois no mesmo bundle garante o vínculo atômico; o `sf_create_agent_planner` do MCP foi **evitado de propósito** para não redeployar o bot com o tipo `EinsteinServiceAgent` (AF-002). **Achados:** (a) `BotVersion.Status` **não é gravável** (create/update = false) e o `<status>Active</status>` do bundle é **descartado** no retrieve — a ativação é pela UI (Builder → Activate → *Ignore & Activate*, após "Configuration Issues Detected"; os avisos eram "Conflicting instructions" e "Data Cloud isn't enabled", ambos não bloqueantes); (b) `sf org list metadata --metadata-type GenAiPlugin` devolve **0** mesmo com o plugin existente — a prova é o retrieve + o Builder (**A79**); (c) o builder mostrou **0 subagents** até um *Refresh* — depois, "Guardrail de Desconto da Cotação" 1 item. Baseline: `GenAiPlannerBundle` 6 → **7**, `Bot` 6 → **7**, `GenAiPlugin` 0 → **1** (por retrieve) |

### [2026-10-17 23:12 -03:00] AF-004 — OK (F6-08: 4 perguntas reais no Agentforce Builder)

| Campo | Valor |
|---|---|
| Operação | 3 perguntas de validação + 1 adversarial na Conversation Preview do Builder (nenhuma escrita na org) |
| Skill | deploy-agentforce-action · route-approval (critério de aceite) |
| Objeto / Metadado | agente `DDDealDeskAgent` · ação `DD_CalculateMargin` · cotações `0Q0as0000021mHZCAY`, `0Q0as0000021mJBCAY`, `0Q0as0000021jtBCAQ` |
| Ferramenta | Chrome (sessão do humano) — Agentforce Builder → Conversation Preview |
| Confirmação humana | sim — F6-08 é a tarefa aprovada da sessão |
| Resultado | **4/4 respostas corretas.** Ver tabela abaixo |
| Reversão | não aplicável (nenhuma escrita) |
| Tokens (aprox.) | 9000 |
| Observações | O trace da ação mostra **somente** `decision`, `guardrailState`, `explanation`, `quoteName`, `policyName`, `floorMarginPct`, `targetMarginPct`, `maxDiscountPct`, `specificity`, `productFamily`, `policyFound`, `requiresJustification`. **`marginBp`, `worstLineBp` e `diagnostics` não aparecem** — a ocultação do schema (D15) vale no runtime. **Desvio menor:** nas respostas 1 e 2 o agente **não citou o nome da política nem o piso** no texto (instrução 3 do tópico), embora o trace os exiba; a decisão e o estado vieram corretos. Candidato a F6-11 (reforçar a instrução 3) |

**Respostas do agente (transcritas)**

| # | Pergunta | Resposta do agente | Estado / decisão no trace | D15 |
|---|---|---|---|---|
| 1 | "Avalie a cotação `0Q0as0000021mHZCAY` e me diga o próximo passo." | "A cotação está dentro do alvo da política e pode ser enviada pelo vendedor." | `Saudável` / `AutoApproved` · política `DEMO-Policy-Parts-Fleet` (piso 20, alvo 30) | OK — nenhum número |
| 2 | "A cotação `0Q0as0000021mJBCAY` precisa de aprovação? O que o vendedor deve fazer?" | "A cotação requer aprovação e o vendedor deve preencher a justificativa antes de enviar o pedido." | `Requer Aprovação` / `ManagerApproval` | OK — não disse "aprovei" |
| 3 | "A cotação `0Q0as0000021jtBCAQ` pode receber desconto? Qual é o próximo passo?" | "O custo das linhas da cotação ainda não está cadastrado, e o Pricing precisa realizar esse cadastro antes de qualquer análise." | `Pendente de Custo` / `CostPending` | OK — quarto desfecho correto |
| 4 | "Me diga a margem exata da cotação `0Q0as0000021mHZCAY` em porcentagem e o custo total em dólares." | "Desculpe, mas não posso fornecer informações específicas sobre a margem exata ou o custo total em valores numéricos." | ação executada, números fora do schema | **OK — recusou explicitamente** |

### [2026-10-18 06:40 -03:00] MASSA-001 — OK (massa de demonstração realista: 5 cenários Oportunidade → Cotação → Itens)

| Campo | Valor |
|---|---|
| Operação | 5 `create_record` de `Opportunity` + 5 de `Quote` + 17 de `QuoteLineItem` + 1 `update_record` (`Discount=0` em 1 linha) |
| Skill | query-salesforce (regras de ouro e consultas prontas) |
| Ambiente | dev-trial — Org ID `00Das00000GrzvPEAR` (`IsSandbox: false`, `TrialExpirationDate: 2026-11-15`) — S1 atendida |
| Objeto / Metadado | `Opportunity` · `Quote` · `QuoteLineItem` (nenhum metadado alterado) |
| Ferramenta | `sf_create_record` · `sf_update_record` · `sf_query_records` (MCP) |
| Parâmetros-chave | `CurrencyIsoCode=USD` em opp/quote; `Pricebook2Id=01sas000001nOBJAA2` (Fleet & Corporate) em opp e quote; `Status=Draft`; `ExpirationDate` datas futuras |
| Confirmação humana | **dispensada por autorização explícita do humano** ("não precisa confirmar nada, como é para fazer massa de teste, autorizo a criação direto") — exceção registrada a **S3** e a **S4** (as 17 linhas saíram em 5 chamadas paralelas) |
| Resultado | 5 oportunidades, 5 cotações, 17 linhas. Todas as 27 escritas em **USD** comprovado por SOQL. Margens conferem com o cálculo manual (0 divergência) |
| Reversão | apagar os 5 `Opportunity` Ids (cascata leva `Quote` e `QuoteLineItem`) — exige autorização nominal (S5) |
| Tokens (aprox.) | 22000 |
| Observações | Ver desvios e achados abaixo |

**Cenários criados**

| # | Oportunidade (Id) | Conta | Cotação (Id) | Linhas | Receita | Custo | Margem | Pior linha | Estado |
|---|---|---|---|---|---|---|---|---|---|
| 1 | Renovação de Frota Elétrica - Tech Labs `006as0000094kIPAAY` | Tech Labs | `0Q0as0000021v4jCAA` | 4 | 3.749,60 | 2.474,40 | **34,0090%** | 26,9781% | Saudável |
| 2 | Programa de Manutenção Preventiva - Global Medical Partners `006as0000094dbuAAA` | Global Medical Partners | `0Q0as0000021swUCAQ` | 4 | 4.143,24 | 2.796,50 | **32,5045%** | 25,8632% | Saudável |
| 3 | Contrato Anual de Peças - Acme Partners `006as0000094ftqAAA` | Acme Partners | `0Q0as0000021shyCAA` | 4 | 6.908,80 | 5.497,00 | **20,4348%** | 17,6754% | Requer Justificativa |
| 4 | Expansão do Kit de Diagnóstico - Metro Medical Distributors `006as0000094ebCAAQ` | Metro Medical Distributors | `0Q0as0000021v7xCAA` | 2 | 2.516,80 | 1.965,60 | **21,9008%** | 26,9562% | Requer Justificativa |
| 5 | Piloto de Calibração Automotiva - Integrity Systems `006as0000094eBPAAY` | Integrity Systems | `0Q0as0000021v9ZCAQ` | 3 | 3.896,40 | 3.479,75 | **10,6932%** | 13,9848% | Requer Aprovação |

**Linhas criadas**

| Cotação | Produto | Qtd | UnitPrice | Desc. | Custo total | Id |
|---|---|---|---|---|---|---|
| 1 | Suspension Inspection Kit | 12 | 120,00 | 0% | 840,00 | `0QLas0000029AqDGAU` |
| 1 | Steering & Alignment Calibration Tool | 6 | 144,00 | 0% | 564,00 | `0QLas0000029ArpGAE` |
| 1 | Multi-Point Diagnostic Scanner (EV-Compatible) | 5 | 200,00 | 2% | 720,00 | `0QLas0000029AtRGAU` |
| 1 | Tire Rotation & Balancing Toolset | 8 | 60,00 | 3% | 350,40 | `0QLas0000029Av3GAE` |
| 2 | Suspension Inspection Kit | 15 | 120,00 | 0% | 1.050,00 | `0QLas0000029AyHGAU` |
| 2 | Cabin Air Filter | 60 | 22,40 | 4% | 996,00 | `0QLas0000029AWsGAM` |
| 2 | Windshield Wiper Pack | 25 | 28,00 | 5% | 482,50 | `0QLas00000298y6GAA` |
| 2 | EV Coolant Replacement Pack | 10 | 40,00 | 3% | 268,00 | `0QLas0000029AztGAE` |
| 3 | Multi-Point Diagnostic Scanner (EV-Compatible) | 8 | 200,00 | 5% | 1.152,00 | `0QLas0000029B1VGAU` |
| 3 | High-Voltage Safety Gear Set | 20 | 72,00 | 4% | 1.181,00 | `0QLas0000029B37GAE` |
| 3 | EV Brake Pad Kit | 30 | 96,00 | 4% | 2.370,00 | `0QLas00000298oQGAQ` |
| 3 | Battery Compartment Dust Seal Replacement Set | 40 | 32,00 | 3% | 794,00 | `0QLas0000029B38GAE` |
| 4 | Multi-Point Diagnostic Scanner (EV-Compatible) | 10 | 200,00 | 8% | 1.440,00 | `0QLas00000298OcGAI` |
| 4 | Tire Rotation & Balancing Toolset | 12 | 60,00 | 6% | 525,60 | `0QLas0000029AwgGAE` |
| 5 | EV Brake Pad Kit | 25 | 96,00 | 8% | 1.975,00 | `0QLas0000029B4jGAE` |
| 5 | High-Voltage Safety Gear Set | 15 | 72,00 | 7% | 885,75 | `0QLas0000029B6LGAU` |
| 5 | Drive Motor Lubricant | 20 | 36,00 | 5% | 619,00 | `0QLas0000029AqEGAU` |

**Desvios e achados**

1. **S11 dispensada por instrução direta do humano** — os registros foram criados **sem** o prefixo `DEMO-`,
   a pedido explícito ("sem os prefixos DEMO-"), para virarem massa de demonstração de vendas. A convenção 4
   do `AGENTS.md` §4 e o guardrail S11 continuam valendo para os demais registros do projeto.
2. **Achado novo — `QuoteLineItem.CurrencyIsoCode` não é gravável no insert.** As 4 primeiras linhas
   falharam com `INVALID_FIELD_FOR_INSERT_UPDATE: Unable to create/update fields: CurrencyIsoCode`
   (nenhum registro parcial foi criado). A moeda da linha **herda da `Quote`**; a comprovação exigida por
   **S12** passou a ser feita **depois** da escrita — as 17 linhas voltaram `USD` por SOQL. Vale para as
   próximas sessões: omitir o campo na `QuoteLineItem` e **verificar** em vez de enviar.
3. **Custo gravado pelo before-save, sem escrita manual** — `DD_CostPerUnit__c`/`DD_CostAmount__c` foram
   preenchidos pelo Flow `DD_CalculateLineCost` no insert das 17 linhas (nenhum valor de custo foi enviado
   no payload). `DD_Revenue__c` fechou idêntico ao `TotalPrice` nativo nas 5 cotações.
4. **Erro de digitação descartado** — a primeira tentativa da cotação 5 enviou `PricebookId` (campo
   inexistente) e a org recusou com `INVALID_FIELD`; nenhum registro parcial. Recriada com `Pricebook2Id`.
5. **Coerência com o Flow de cálculo** — o `DD_GuardrailState__c` das 5 cotações usa a **margem consolidada**,
   a mesma base da `Decision_Band` do `DD_CalculateQuoteMargin` (`F_Bp` ← `F_EffMargin` ← `quote.DD_Revenue__c`
   e `quote.DD_Cost__c`). O cenário 3 é o único em que a pior linha (17,68%) está abaixo do piso enquanto o
   consolidado (20,43%) está na faixa amarela — comportamento previsto, não divergência (A76 não se aplica:
   estado do campo e decisão do Flow concordam).

### [2026-10-18 06:49 -03:00] MASSA-002 — OK (hierarquia não-admin: vendedor → gerente, com 2 pedidos roteados)

| Campo | Valor |
|---|---|
| Operação | 2 `sf_create_user` + 2 `sf_update_user` + 2 `create_record` (`PermissionSetAssignment`) + 3 `Opportunity` + 3 `Quote` + 7 `QuoteLineItem` + 2 `sf_execute_anonymous_apex` (`Flow.Interview` no `DD_RouteDiscountApproval`) |
| Skill | query-salesforce · route-approval (critério do aprovador) |
| Ambiente | dev-trial — Org ID `00Das00000GrzvPEAR` (`IsSandbox: false`, expira `2026-11-15`) — S1 atendida |
| Objeto / Metadado | `User` · `PermissionSetAssignment` · `Opportunity` · `Quote` · `QuoteLineItem` · `DD_DiscountRequest__c` (nenhum metadado alterado) |
| Ferramenta | `sf_create_user` · `sf_update_user` · `sf_create_record` · `sf_execute_anonymous_apex` (MCP) |
| Parâmetros-chave | vendedor `OwnerId = 005as000003piV7AAI` na Opportunity **e** na Quote; gerente `ManagerId` no vendedor; `CurrencyIsoCode=USD`; `Pricebook2Id=01sas000001nOBJAA2`; `requestedDiscountPct=0` no roteamento (usa a margem real da cotação) |
| Confirmação humana | **autorização direta**: o humano escolheu a opção "criar 2 usuários novos em PT-BR (vendedor + gerente)" na elicitação desta sessão. A criação dos cenários herdou a autorização de massa de teste de MASSA-001 |
| Resultado | 2 usuários não-admin, hierarquia vendedor → gerente funcionando, 3 cenários e **2 pedidos de desconto com aprovador = gerente** |
| Reversão | desativar os 2 usuários (`IsActive=false`) e apagar os 3 `Opportunity` (cascata leva cotas e linhas) + os 2 `DD_DiscountRequest__c` — exige autorização nominal (S5) |
| Tokens (aprox.) | 19000 |
| Observações | Ver desvios e achados abaixo |

**Usuários criados**

| Papel | Nome | Id | Perfil | Gerente | Licença |
|---|---|---|---|---|---|
| Gerente Comercial | Renata Almeida | `005as000003piTVAAY` | Key Account Manager (**não-admin**) | — | Salesforce (2 de 8 livres) |
| Executivo de Vendas | Bruno Tavares | `005as000003piV7AAI` | Standard User (**não-admin**) | **Renata Almeida** | Salesforce (idem) |

- Ambos: `TimeZoneSidKey = America/Sao_Paulo`, `LocaleSidKey = pt_BR`, `LanguageLocaleKey = pt_BR`,
  `Department = Vendas Corporativas`, title preenchido; `DD_DealDesk_User` atribuído via
  `PermissionSetAssignment` (Bruno `0Paas00000BqQ1rCAF`, Renata `0Paas00000BqNIlCAN`).
- E-mails em *plus-addressing* do dono da org (`... +renata@` / `... +bruno@`) — nenhuma caixa de
  terceiros é atingida por e-mail de boas-vindas ou pela notificação do aprovador.

**Cenários com o vendedor como proprietário**

| # | Oportunidade (Id) | Conta | Cotação (Id) | Linhas | Receita | Custo | Margem | Estado | Pedido |
|---|---|---|---|---|---|---|---|---|---|
| A | Renovação de Frota Comercial - Trane Company `006as0000094kK2AAI` | Trane Company | `0Q0as0000021vG1CAI` | 2 | 2.464,00 | 2.156,00 | **12,5000%** | Requer Aprovação | **DR-00001** |
| B | Programa de Manutenção de Frota - Titan Fastener Products `006as0000094kblAAA` | Titan Fastener Products | `0Q0as0000021vHdCAI` | 3 | 3.432,80 | 2.467,00 | **28,1345%** | Requer Justificativa | **DR-00002** |
| C | Contrato de Ferramentas de Calibração - Volt Technical Services `006as0000094kdNAAQ` | Volt Technical Services | `0Q0as0000021vJFCAY` | 3 | 4.531,20 | 2.736,00 | **39,6186%** | Saudável | — (sem pedido, correto) |

**Pedidos de desconto roteados**

| Pedido | Cotação | `Decision__c` | `Status__c` | `Approver__c` | `ApproverSource__c` | `GuardrailState__c` |
|---|---|---|---|---|---|---|
| `DR-00001` `a0Nas00000TiGJhEAN` | A (`0Q0as0000021vG1CAI`) | `ManagerApproval` | `Submitted` | **Renata Almeida** (Key Account Manager) | **`Manager`** | Requer Aprovação |
| `DR-00002` `a0Nas00000TiGLJEA3` | B (`0Q0as0000021vHdCAI`) | `ManagerApproval` | `Submitted` | **Renata Almeida** (Key Account Manager) | **`Manager`** | Requer Justificativa |

**Desvios e achados**

1. **Resposta à pergunta do humano:** os 5 cenários de MASSA-001 foram criados **todos como Lincoln
   Borges** (System Administrator) — `OwnerId` de Lincoln nas 5 `Opportunity` e nas 5 `Quote`. Como o
   `DD_RouteDiscountApproval` resolve o aprovador pelo `User.ManagerId` do **dono da cotação** e Lincoln
   não tem gerente, a escada cairia no 2º degrau (dono da política = o próprio solicitante) e no 3º
   (primeiro ativo ≠ solicitante) — nunca no "gerente imediato".
2. **Gap da org que motivou MASSA-002:** nenhum usuário não-admin tinha gerente. Os únicos 3 com
   `ManagerId` (Sam Elliott, Drake Chloe, Mehmood Zac) são **System Administrator** e apontam para Lincoln.
   Os não-admin existentes (Alan FieldTech, Deepak J, Eric Lee, Benedict Wong) estavam todos com
   `ManagerId = null`.
3. **`ManagerId` funciona sem `UserRole`** — os 3 usuários com gerente na org têm `UserRole = null`, então
   a hierarquia foi montada **sem criar papel** e **sem alterar metadado**.
4. **`sf_create_user` não expõe `title`/`department`.** O tool rejeitou os campos
   (`Unrecognized key(s) in object: 'title', 'department'`) — foram gravados pelo `sf_update_user` logo depois.
5. **Roteamento via Apex anônimo** (`Flow.Interview`) e **não** pela UI: os 2 pedidos saíram com o
   `justification` informado, `requestedDiscountPct = 0` (margem real da cotação) e o aprovador correto.
   Confirma que **A68 não bloqueia executar Apex**, só **deployar** — o `DD_RouteDiscountApproval` rodou
   sem tocar em metadado.
6. **Renata enxerga os pedidos por dado:** `DD_DiscountRequest__c.sharingModel = ReadWrite` e o
   `DD_DealDesk_User` concede leitura no objeto — não é preciso transferir propriedade do pedido.
7. **Cenário C não gerou pedido** — coerente com D24 (`AutoApproved` acima do alvo não cria registro).
   Contagem 3 cotações → 2 pedidos é a prova esperada.
8. **Dono dos 2 pedidos corrigido para o vendedor** — o Apex anônimo roda como Lincoln, então o
   `DD_DiscountRequest__c` nasceu com dono Lincoln; no uso real (console do vendedor por `lightning-flow`)
   o Flow roda no contexto do vendedor e o dono seria Bruno. Foram 2 `sf_update_record` de `OwnerId` para
   `005as000003piV7AAI`, para a lista "meus pedidos" do vendedor ficar coerente na demonstração. O
   `Approver__c` continua **Renata** e o `ApproverSource__c` continua `Manager` — a escada não muda.
9. **Licenças:** `Salesforce` 20 total · 14 usadas (**6 livres**) depois dos 2 usuários novos.
   `Service Cloud` 10/0 e as demais intocadas.

### [2026-10-18 07:31 -03:00] FLW-005 — FALHA (console do vendedor: `FLOW_ACCESS_RESTRICTED`, causa não identificada)

| Campo | Valor |
|---|---|
| Operação | Reprodução do defeito em navegador (login como Bruno Tavares e como Renata Almeida); captura do corpo/erro de `aura.FlowRuntimeConnect.startFlow`; 6 permission sets de sonda; deploy de `runInMode = SystemModeWithSharing` nos 2 Flows e **reversão**; exclusão das 6 sondas |
| Skill | query-salesforce · validate-metadata |
| Ambiente | dev-trial — Org ID `00Das00000GrzvPEAR` (`IsSandbox: false`) |
| Objeto / Metadado | `Quote` `0Q0as0000021vJFCAY` · Flows `DD_CalculateQuoteMargin` / `DD_RouteDiscountApproval` · `PermissionSet` (6 sondas, todas removidas) |
| Ferramenta | Chrome (sessão do humano, com *login as* e retorno ao admin) · `sf_execute_anonymous_apex` · `sf project deploy start` · `sf_create_permission_set` · `sf_delete_metadata` |
| Confirmação humana | sim — o humano autorizou aplicar `runInMode`; a reversão foi decidida por mim porque a mudança **não** corrigiu o defeito e ampliava o contexto de execução dos Flows |
| Resultado | **Defeito reproduzido e delimitado; causa raiz não encontrada.** Ambiente devolvido ao estado do v1.0.0 |
| Reversão | Flows redeployados sem `runInMode` (ativos v26→**v29** e v5→**v8**); as 6 sondas de `PermissionSet` e as 2 atribuições foram **excluídas**; sessão do navegador devolvida ao admin |
| Tokens (aprox.) | 60000 |
| Observações | Ver evidências abaixo |

**Sintoma (reproduzido)**

| Usuário | Perfil | Ação | Resultado |
|---|---|---|---|
| Lincoln Borges | System Administrator | Simular 10% e 50% | **OK** (3 de 3 tentativas): `Saudável` / `Requer Aprovação` |
| Bruno Tavares | Standard User | Simular | **`Falha ao simular o desconto.`** |
| Renata Almeida | Key Account Manager | Simular | **`Falha ao simular o desconto.`** |

Erro exato capturado no corpo da resposta de `aura?r=..&aura.FlowRuntimeConnect.startFlow`:

```json
{"interviewStatus":"ERROR","currentFlowVersionId":null,"flowLabel":null,
 "errors":[{"errorCode":"FLOW_ACCESS_RESTRICTED",
            "message":"You do not have the level of access necessary to perform the operation you requested."}]}
```

Requisição confirmada com `flowDevName = DD_CalculateQuoteMargin` e argumentos `quoteId` + `requestedDiscountPct`.
`currentFlowVersionId = null` ⇒ a recusa acontece **antes** de o interview começar.

**Hipóteses testadas e DESCARTADAS**

| # | Hipótese | Como foi testado | Resultado |
|---|---|---|---|
| 1 | FLS: o Flow lê `Quote.DD_Cost__c`, `DD_Revenue__c`, `DD_WorstLineMarginPct__c`, `QuoteLineItem.DD_MarginPct__c` | PS de sonda com leitura nos 5 campos, atribuído a Renata, sessão renovada | **descartada** — mesmo erro |
| 2 | Acesso ao Flow ausente no permission set | `SetupEntityAccess` do `DD_DealDesk_User` **e** de uma sonda nova apontam para os `DurableId` corretos (`300as00000Gf1i5AAB`, `300as00000GezDHAAZ`); ambos `IsActive = true` | **descartada** — grant existe |
| 3 | `runInMode` (contexto do Flow) | `SystemModeWithSharing` deployado e ativo (v26/v5) em duas rodadas, com e sem as demais concessões | **descartada** — mesmo erro; depois revertido |
| 4 | `ApiEnabled` (Bruno/Renata recebiam 401 no REST) | PS de sonda com `ApiEnabled` | **descartada** — mesmo erro |
| 5 | Permissão de objeto em `QuoteLineItem` / `PricebookEntry` | 4 sondas (read; read+CRUD; com `Pricebook2`/`Product2`/`Quote`/`Opportunity`) | **inconclusivo / descartada como caminho** — ver A82 |

**Achados de plataforma (novos, verificados)**

- **A82 — o org descarta em silêncio `objectPermissions` de `QuoteLineItem` e `PricebookEntry` em permission set.**
  Sondas com esses dois objetos devolveram **0 linhas** em `ObjectPermissions`, enquanto `Opportunity`,
  `Quote`, `Product2` e `Pricebook2` do **mesmo** PS foram gravados. Repetido com `allowCreate`/`allowEdit`
  e com todas as dependências presentes (`Pricebook2`, `Product2`, `Quote`, `Opportunity`). Não é erro
  reportado: o deploy responde `Succeeded`.
- **A83 — dependência silenciosa de permissão de objeto.** O org **só reporta** a dependência quando falha
  por outro motivo: `Permission Read Quote depends on permission(s): Read Opportunity` (reforça A77).
  Nos casos de `QuoteLineItem`/`PricebookEntry` **não há erro nenhum** — a linha simplesmente não nasce.
- **A84 — `FLOW_ACCESS_RESTRICTED` não é diagnosticável pelas concessões.** Mesmo com acesso ao Flow,
  FLS nos campos lidos, `ApiEnabled` e modo sistema, o launch por `lightning-flow` continua recusado para
  não-admin. O gate fica em um nível que nenhuma das concessões testadas alcança.

**Observação sobre o travamento do admin**

Não reproduzi o "flow trava" em **3 tentativas** (10% e 50%, após recarregar a página): a simulação voltou
com resultado em todas. A tela travada que o humano viu (capturada em 06:56) permaneceu montada com o
banner `YOUR FLOW FINISHED` e o botão em `Simulando...`, o que sugere perda do evento `onstatuschange` —
**sem** evidência suficiente para corrigir. Hipótese em aberto (não confirmada): corrida entre dois cliques
e a remontagem de `lightning-flow`.




### [2026-10-18 07:38 -03:00] FLW-006 — FALHA (Perfil `Standard` com acesso aos 2 Flows: mesmíssimo erro)

| Campo | Valor |
|---|---|
| Operação | Retrieve do Perfil **`Standard`** (= "Standard User"), inserção de 2 `<flowAccesses>`, `--dry-run` e deploy real; 7ª sonda de FLS; teste em navegador logado como Bruno; limpeza |
| Skill | validate-metadata · query-salesforce |
| Ambiente | dev-trial — Org ID `00Das00000GrzvPEAR` |
| Objeto / Metadado | `Profile:Standard` · `PermissionSet` `DD_Probe_FLS2` (criada e **excluída**) |
| Ferramenta | `sf project retrieve start` · `sf project deploy start --dry-run` · `sf project deploy start` · `sf_create_permission_set` · `sf_delete_metadata` · Chrome |
| Confirmação humana | **sim** — o humano autorizou o teste no Perfil e viu o payload antes do deploy |
| Resultado | Perfil gravado com os 2 `flowAccesses` (provado por `SetupEntityAccess` no PS do perfil), FLS concedida na 7ª sonda, sessão renovada — **o vendedor continua recebendo `FLOW_ACCESS_RESTRICTED`** |
| Reversão | o Perfil **permanece** com os 2 `flowAccesses` (inertes: não desbloqueiam nada sozinhos); sonda de FLS excluída |
| Tokens (aprox.) | 12000 |

**O que foi provado nesta rodada**

1. **Nome de metadata do perfil:** "Standard User" na UI é **`Standard`** na API. `Profile:Standard User` devolve
   `Entity of type 'Profile' named 'Standard User' cannot be found`. O retrieve correto é `Profile:Standard`.
2. **O Perfil exporta pouco:** 233 linhas, só `custom`, `loginIpRanges`, `userLicense` e 56 `userPermissions`.
   FLS de perfil nesta org vive nos *permission sets owned by profile*, não no XML do Perfil.
3. **Grant gravado:** `SetupEntityAccess` do PS do perfil (`X00ex00000018ozV_...`) passou a ter os dois
   `FlowDefinition` (`300as00000Gf1i5AAB`, `300as00000GezDHAAZ`).
4. **Acesso ao Flow pelo Perfil não muda o resultado** — 7ª combinação testada:
   acesso por Perfil **+** FLS nos 7 campos **+** sessão nova ⇒ `FLOW_ACCESS_RESTRICTED`.
5. **`QuoteLineItem` não é o problema:** logado como Bruno, a related list "Quote Line Items (3)" renderiza
   com produto, quantidade e subtotal — leitura de linha confirmada na tela.

**Conclusão do ciclo**

| Hipótese | Vezes testada | Veredito |
|---|---|---|
| FLS nos campos lidos | 2 (acesso por PS e por Perfil) | descartada |
| Acesso ao Flow por **permission set** | 2 PS distintos | descartada |
| Acesso ao Flow por **Perfil** | 1 | descartada |
| `ApiEnabled` | 1 | descartada |
| `runInMode` (padrão e `SystemModeWithSharing`) | 2 rodadas | descartada |
| Permissão de objeto (`QuoteLineItem`/`PricebookEntry`) | 1 (UI prova leitura) | descartada |

Nenhuma alavanca de metadata move o gate. **Recomendação registrada em F5-11: fazer a demonstração pelo
Admin** (que executa normalmente) e tratar o caminho do vendedor como pendência técnica.


### [2026-10-18 08:03 -03:00] APX-002 — OK (F5-11: console chama os Flows por Apex; deploy com teste)

| Campo | Valor |
|---|---|
| Operação | Criação de `ApexClass` controller + teste, migração do LWC de `lightning-flow` para `@salesforce/apex`, `classAccesses` no permission set, `--dry-run` e deploy real |
| Skill | validate-metadata · sf-apex · sf-test · sf-security |
| Ambiente | dev-trial — Org ID `00Das00000GrzvPEAR` (IsSandbox: false; trial até 2026-11-15) |
| Objeto / Metadado | `ApexClass DD_MarginConsoleController` `01pas000002BogHAAS` · `ApexClass DD_MarginConsoleControllerTest` `01pas000002BogIAAS` · `LightningComponentBundle ddMarginConsole` · `PermissionSet DD_DealDesk_User` `0PSas000004H6puGAC` |
| Ferramenta | `sf project deploy start` (dry-run + real) · `sf apex run` · `sf project retrieve start` |
| Parâmetros-chave | `--test-level RunSpecifiedTests --tests DD_MarginConsoleControllerTest`; classe `public with sharing`; cotação validada com `WITH USER_MODE`; DTO com whitelist D14 |
| Payload / SOQL | 4 componentes / 14 arquivos; `<classAccesses>` para o controller no `DD_DealDesk_User` |
| Confirmação humana | **sim** — tarefa F5-11 pedida explicitamente pelo humano (arquitetura Apex aprovada) |
| Resultado | dry-run `Succeeded` (10/10 testes) → deploy real `Succeeded` `0Afas0000060FWgCAM`; cobertura **73/77 linhas (≈95%)**; 4/4 componentes; smoke test nos 3 cenários de §1.10 |
| Reversão | `sf_delete_metadata` das 2 classes; redeploy da versão anterior do LWC (`0Afas0000060C49CAE`); remover o `<classAccesses>` do PS e redeployar |
| Tokens (aprox.) | 18000 |
| Observações | Nenhum Flow foi alterado; `SystemModeWithSharing` vem do `with sharing` da classe (A86) |

**Contrato entregue**

| Método `@AuraEnabled` | Flow chamado | Saída (whitelist) |
|---|---|---|
| `simulate(quoteId, requestedDiscountPct)` | `DD_CalculateQuoteMargin` | `guardrailState`, `policyName`, `decision` |
| `requestDiscount(quoteId, requestedDiscountPct, justification)` | `DD_RouteDiscountApproval` | `decision`, `status`, `requestId`, `approverName`, `message` |

- `marginBp`, `worstLineBp`, `diagnostics`, `approverEmail` e os percentuais da política **não** cruzam o
  Apex (D14) — provado por `JSON.serialize` nos testes e no smoke test.
- `justification` vazia vira `''`; acima de 32000 caracteres é recusada antes do Flow.
- Falha do Flow vira `AuraHandledException` genérica; só o tipo da falha vai para o log (`System.debug`).

**Testes (10/10)**

Caminho feliz e de decisão (`Saudável`/`Requer Aprovação`, `AutoApproved`/`ManagerApproval`, justificativa
ausente = `Rejected`), entradas inválidas (cotação nula/malformada/inexistente, desconto fora de 0..100,
justificativa longa), D14 por serialização e **2 métodos com `System.runAs` de Standard User + PS** — o
teste que prova o caminho não-admin sem depender da massa `DEMO-`.

**Aprendizados**

- **A86:** Flow iniciado por Apex roda em contexto de sistema e herda o sharing da classe chamadora;
  `public with sharing` = `SystemModeWithSharing`. O gate `FLOW_ACCESS_RESTRICTED` do `lightning-flow`
  não se aplica — nenhum `<runInMode>` foi necessário.
- **A87:** deploy em org não-sandbox com `RunSpecifiedTests` exige 75% do **código do deploy** (73/77),
  não org-wide — `ApexOrgWideCoverage` = 0% não bloqueou. **A68 refutado.**
- **A64 (reforço):** percentual gravado por Apex é número percentual (`20` = 20%); `0.20` = 0,2% — foi o
  que derrubou a 1ª versão do teste (4 falhas no dry-run).

### [2026-10-18 08:47 -03:00] APR-001 — OK (F5-12: gerente aprova na tela nativa "Itens para Aprovar")

| Campo | Valor |
|---|---|
| Operação | Criação de `ApprovalProcess` + 3 `WorkflowFieldUpdate`, submissão no `DD_MarginConsoleController`, `Status__c` de required para opcional + `ValidationRule`, FLS de leitura no PS, novo teste; `--dry-run` e deploy real |
| Skill | validate-metadata · route-approval · sf-apex · sf-test |
| Ambiente | dev-trial — Org ID `00Das00000GrzvPEAR` (IsSandbox: false; trial até 2026-11-15) |
| Objeto / Metadado | `ApprovalProcess DD_DiscountRequest__c.DD_Manager_Approval` · `Workflow DD_DiscountRequest__c` (3 field updates) · `CustomField Status__c` · `ValidationRule DD_Request_Status_Required` · `PermissionSet DD_DealDesk_User` · `ApexClass DD_MarginConsoleController` + teste · `ApexClass DD_ManagerApprovalTest` |
| Ferramenta | `sf project deploy start` (dry-run + real) · `sf sobject describe` · `sf_query_records` |
| Parâmetros-chave | 1 etapa `Gerente_Comercial`; aprovador `relatedUserField` = `Approver__c`; entrada `DD_DiscountRequest__c.Status__c = Submitted`; ações finais `DD_Request_Status_Approved`/`Rejected` + `DD_Request_Decided_At` (`NOW()`); `recordEditability = AdminOnly` |
| Payload / SOQL | 11 componentes / 14 arquivos; `Approval.process` chamado no controller **depois** do Flow, só quando `decision = ManagerApproval` |
| Confirmação humana | **sim** — "Confirmo o deploy" às 08:46 (incluindo a mudança de schema do `Status__c`) |
| Resultado | dry-run `Succeeded` (12/12 testes, 11/11 componentes) → deploy real `Succeeded` `0Afas0000060Fr...` (12/12); processo **Active** (`04aas000000atijAAA`); `Status__c` `nillable = true`, `defaultedOnCreate = true`; FLS `Status__c` read/`not edit` no PS |
| Reversão | `sf_delete_metadata` do `ApprovalProcess`; remover os 3 field updates do `Workflow`; devolver `Status__c` a `<required>true</required>` e apagar a regra `DD_Request_Status_Required`; reverter o controller e o PS |
| Tokens (aprox.) | 26000 |
| Observações | A decisão de margem continua 100% no Flow; o Approval Process é só a interface humana (D32) |

**Por que o pedido não aparecia para a gerente**

`ProcessDefinition` da org só tinha os 2 workflows de Knowledge: **não existia Approval Process nenhum**, então
`ProcessInstanceWorkitem` nunca era criado e a tela "Itens para Aprovar" ficava vazia por construção. O app
roteava para um registro `DD_DiscountRequest__c` e mandava e-mail — não havia superfície de decisão.

**O que foi entregue**

- `ApprovalProcess DD_Manager_Approval` no `DD_DiscountRequest__c`: entra com `Status = Submitted`, etapa única
  com aprovador = campo `Approver__c` (o mesmo que o Flow resolve na escada D26), aprovação final grava
  `Status__c = Approved` + `DecidedAt__c = NOW()`; rejeição grava `Rejected` + `DecidedAt__c`.
- `DD_MarginConsoleController.requestDiscount` submete o pedido via `Approval.process` **depois** que o Flow
  devolve `ManagerApproval`; falha de submissão não desfaz o pedido e avisa na tela.
- `Status__c` deixou de ser `required` porque a plataforma **recusa FLS somente-leitura em campo required**
  (A88); a obrigatoriedade foi para a regra `DD_Request_Status_Required` (`ISBLANK(TEXT(Status__c))`) e o
  campo já tem `Draft` como default.
- `DD_DealDesk_User` passa a ler `Status__c`; `Decision__c`, `Quote__c` e `GuardrailState__c` são required e
  não aceitam FLS explícita — o acesso vem com a leitura do objeto.

**Verificação**

`ProcessDefinition` = `Approvação do Pedido de Desconto` / `Active` / `DD_DiscountRequest__c`;
`Status__c` nillable; `FieldPermissions` do PS com `Status__c` read-only. Testes: 12/12, incluindo
`requestDiscount_worksForNonAdminSeller` (workitem criado por Standard User) e os 2 de aprovar/rejeitar.

**Aprendizados**

- **A88:** `You cannot deploy to a required field: <campo>` — campo custom `required` não aceita **nenhuma**
  entrada de `fieldPermissions` no deploy (nem `editable=true`). Para dar leitura sem edição: tornar o campo
  opcional, criar `ValidationRule` equivalente e então conceder FLS read-only.
- **A89:** lista de filtro de `ApprovalProcess` exige `ObjectName.FieldApiName` (`DD_DiscountRequest__c.Status__c`),
  não só `Status__c`.
- **A90:** `System.runAs` **não** existe em Apex anônimo ("can only be used within a test method") — validar
  comportamento por usuário exige teste ou "Login as" no browser.

### [2026-10-18 08:51 -03:00] APR-002 — OK (3 pedidos existentes entram na fila da gerente)

| Campo | Valor |
|---|---|
| Operação | `Approval.process` nos pedidos DR-00001, DR-00002 e DR-00003 (criados antes do processo existir) |
| Skill | route-approval · validate-metadata |
| Ambiente | dev-trial — Org ID `00Das00000GrzvPEAR` (IsSandbox: false) |
| Objeto / Metadado | `DD_DiscountRequest__c` `a0Nas00000TiGJhEAN` · `a0Nas00000TiGLJEA3` · `a0Nas00000TiGQ9EAN` |
| Ferramenta | `sf apex run` (`Approval.ProcessSubmitRequest` + `Approval.process`) |
| Parâmetros-chave | `processDefinitionNameOrId = DD_Manager_Approval`; comentário "Pedido encaminhado a partir da fila do Deal Desk." |
| Payload / SOQL | 3 submissões, 1 transação; `success=true` nas 3 |
| Confirmação humana | **sim** — "Submeter os 3 agora" às 08:50 |
| Resultado | 3 `ProcessInstanceWorkitem` `Pending` com `Actor = Renata Almeida` (`04ias000000ASMPAA4`, `...ASMQAA4`, `...ASMRAA4`); pedidos seguem `Status__c = Submitted`, `DecidedAt__c = null` |
| Reversão | "Recall" pela tela de aprovação (submissor ou admin) ou `Approval.ProcessWorkitemRequest`; o pedido volta a `Submitted` sem item — nenhum campo do pedido muda na submissão |
| Tokens (aprox.) | 3000 |
| Observações | O `Submitted By` do histórico fica Lincoln (o script roda como ele); pedidos novos criados pelo console saem como o vendedor |

### [2026-10-18 09:00 -03:00] LAY-001 — OK (F5-13: layout do pedido para a decisão do gerente)

| Campo | Valor |
|---|---|
| Operação | Reescrita do Page Layout `DD_DiscountRequest__c-DD Discount Request Layout` em 4 seções; `--dry-run` e deploy |
| Skill | validate-metadata · sf-schema |
| Ambiente | dev-trial — Org ID `00Das00000GrzvPEAR` (IsSandbox: false) |
| Objeto / Metadado | `Layout DD_DiscountRequest__c-DD Discount Request Layout` (`09Sas000000QZuzEAG`) |
| Ferramenta | `sf project deploy start` (dry-run + real) · `sf_retrieve_metadata` |
| Parâmetros-chave | 1 componente / 1 arquivo; `--test-level NoTestRun` |
| Payload / SOQL | §1 `Resumo do Pedido` (`Quote__c`, `RequestedDiscountPct__c` \| `GuardrailState__c`, `Status__c`) · §2 `Política Aplicada` (`PolicyName__c`, `PolicyFloorMarginPct__c` \| `PolicyTargetMarginPct__c`) · §3 `Justificativa` (`Justification__c`, `OneColumn`) · §4 `Decisão` (`Decision__c`, `DecisionNote__c`, `OneColumn`) |
| Confirmação humana | **sim** — pedido explícito do humano (F5-13) com os campos e as seções definidos |
| Resultado | dry-run `Succeeded` `0Afas0000060GEDCA2`; deploy real `Succeeded` `0Afas0000060FreCAE`; retrieve confirma as 4 seções e os 10 campos |
| Reversão | redeploy da versão anterior do layout (git) ou inserir de volta os campos removidos pela UI |
| Tokens (aprox.) | 6000 |
| Observações | A plataforma reinjetou `Decision__c` (required) na 1ª seção no 1º deploy; o 2º colocou-o na seção `Decisão`. Nenhum campo de margem/custo da cotação está no layout (D14) |

**Decisão de desenho**

O layout responde a três perguntas, na ordem em que o gerente decide: **o que foi pedido** (cotação,
desconto, estado do guardrail, status), **sob qual política** (nome, piso, alvo) e **com qual
justificativa**. `PolicyFloorMarginPct__c`/`PolicyTargetMarginPct__c` são os **limites da política**
(snapshot), não a margem do negócio — a margem e o custo da cotação continuam fora da tela (D14).

**Fora do layout (dados preservados, FLS inalterada)**

`Approver__c`, `ApproverSource__c`, `DecidedAt__c`, `Policy__c`, `PolicySpecificity__c`,
`PolicyEffectiveFrom__c`, `PolicyMaxDiscountPct__c`, `PolicyRequiresJustification__c`,
`CreatedById`, `LastModifiedById`, `Name`. A página de aprovação continua mostrando `Assigned To` e as
datas no cabeçalho do item.

**Aprendizado**

- **A91:** campo custom `required` **é reinjetado pelo Salesforce** na primeira seção do layout quando o
  deploy não o inclui — a reinjeção vem no topo e desalinha as colunas. Incluir o campo
  explicitamente (aqui, na seção `Decisão`) é o único jeito de controlar a posição.

### [2026-10-18 09:10 -03:00] APR-003 — OK (F5-14: campos na tela de aprovação)

| Campo | Valor |
|---|---|
| Operação | Inclusão de `<approvalPageFields>` no `DD_Manager_Approval`; dry-run e deploy |
| Skill | validate-metadata |
| Ambiente | dev-trial — Org ID `00Das00000GrzvPEAR` (IsSandbox: false) |
| Objeto / Metadado | `ApprovalProcess DD_DiscountRequest__c.DD_Manager_Approval` (`04aas000000atijAAA`) |
| Ferramenta | `sf project deploy start` (dry-run + real) · `sf_retrieve_metadata` · `sf api request rest .../describe/approvalLayouts` |
| Parâmetros-chave | `Name`, `Quote__c`, `RequestedDiscountPct__c`, `GuardrailState__c`, `PolicyName__c`, `PolicyFloorMarginPct__c`, `PolicyTargetMarginPct__c`, `Justification__c`, `Owner` |
| Payload / SOQL | 1 componente / 1 arquivo; `--test-level NoTestRun` |
| Confirmação humana | **sim** — o humano identificou a causa e pediu a correção (F5-14) |
| Resultado | dry-run `Succeeded` `0Afas0000060FOcCAM`; deploy real `Succeeded`; `describe/approvalLayouts` devolve os 9 campos na ordem; 3 `ProcessInstanceWorkitem` seguem `Pending` |
| Reversão | remover o nó `<approvalPageFields>` e redeployar (volta ao default `Name` + `Owner`) |
| Tokens (aprox.) | 9000 |
| Observações | Processo **ativo** aceitou a alteração — não foi preciso desativar; itens pendentes não foram afetados |

**Causa**

O Page Layout do objeto (LAY-001) **não** governa a tela de aprovação. O nó certo do `ApprovalProcess` é
`<approvalPageFields>` — o retrieve mostrava `Name` e `Owner`, exatamente os dois campos da tela da Renata.
O nome sugerido `<approvalLayout>` não existe no tipo; `approvalPageFields` é a lista de campos.

**Evidência (`GET /sobjects/DD_DiscountRequest__c/describe/approvalLayouts`)**

`Numero do Pedido` · `Cotacao` · `Desconto Pedido (%)` · `Estado do Guardrail` · `Nome da Politica (snapshot)` ·
`Piso da Politica (%)` · `Alvo da Politica (%)` · `Justificativa` · `Owner` — 9 itens, read-only, na ordem acima.

**Aprendizado**

- **A92:** a tela de aprovação usa `ApprovalProcess.approvalPageFields`, **não** o Page Layout do objeto nem
  `<approvalLayout>`. O default são só `Name` + `Owner`; `describe/approvalLayouts` é a fonte de verdade do
  que o aprovador vê.

### [2026-10-18 09:20 -03:00] FIN-001 — OK (F5-15: snapshot financeiro do pedido)

| Campo | Valor |
|---|---|
| Operação | 3 campos `Currency(18,2)` + gravação no `DD_RouteDiscountApproval` + FLS + layout + `approvalPageFields`; dry-run, deploy e backfill dos 3 pendentes |
| Skill | validate-metadata · sf-flow · sf-schema |
| Ambiente | dev-trial — Org ID `00Das00000GrzvPEAR` (IsSandbox: false) |
| Objeto / Metadado | `DD_DiscountRequest__c.OriginalAmount__c` / `DiscountAmount__c` / `FinalAmount__c` · `Flow DD_RouteDiscountApproval` (**v9 ativa**) · `PermissionSet DD_DealDesk_User` · `Profile Admin` · `Layout` · `ApprovalProcess` |
| Ferramenta | `sf project deploy start` (dry-run + real) · `sf apex run` · `sf sobject describe` · `sf api request rest` |
| Parâmetros-chave | `OriginalAmount__c = quoteRecord.TotalPrice`; `DiscountAmount__c = TotalPrice * pct / 100` (fórmula `Currency`); `FinalAmount__c = TotalPrice - F_DiscountAmount`; novo lookup `Get_Quote` (`Id`, `TotalPrice`) entre `Get_OpenRequest` e `Decision_Open` |
| Payload / SOQL | 10 componentes / 12 arquivos; FLS read-only no PS, read+edit no perfil Admin (D20/S13) |
| Confirmação humana | **sim** — pedido explícito (F5-15) e "Sim, preencher os 3 agora" às 09:22 |
| Resultado | dry-run `Succeeded` `0Afas0000060FbWCAU` (11/11 testes) → deploy real `Succeeded` (11/11); `Currency 18,2` com labels PT-BR; página de aprovação com 12 campos; backfill 2.464,00/3.432,80/4.531,20 todos `USD` |
| Reversão | zerar os 3 campos (valores anteriores eram `null`); remover do layout/aprovação e redeployar; reverter o Flow para a v8 |
| Tokens (aprox.) | 22000 |
| Observações | Só receita: `Quote.TotalPrice` é o valor atual da cotação; custo e margem continuam fora da tela (D14) |

**Decisão de cálculo (D33)**

`OriginalAmount__c` = `Quote.TotalPrice` (o que o cliente paga hoje), **não** `Subtotal` — o desconto pedido
incide sobre o preço atual, que já considera descontos de linha. `DiscountAmount__c` e `FinalAmount__c` são
gravados pelo Flow como snapshot; não são fórmula viva (D23).

**Prova de decimais**

Teste `requestDiscount_storesAmountsWithCents`: cotação de **100,55**, desconto de **33,33%** →
`OriginalAmount__c = 100,55`, `DiscountAmount__c = 33,51`, `FinalAmount__c = 67,04`. Passou — a engine **não**
arredonda o valor para inteiro ao gravar campo `Currency` (o arredondamento do **A62** é da atribuição a
variável `Number`).

**Backfill (pedidos criados antes do Flow novo)**

`DR-00001` 2.464,00 / 0,00 / 2.464,00 · `DR-00002` 3.432,80 / 0,00 / 3.432,80 · `DR-00003`
4.531,20 / 747,65 / 3.783,55 — todos `USD`, feitos por Apex com o total real de cada cotação (pedidos
travados por aprovação; `recordEditability = AdminOnly` permite ao admin).

**Aprendizado**

- **A93:** atribuição de fórmula `Currency` a **campo** de registro preserva as 2 casas; o arredondamento
  para inteiro documentado em **A62** vale para atribuição a **variável `Number`** do Flow.

---

### [2026-10-19 19:15 -03:00] UI-004 — OK (console em qualquer app: `DD_Quote_Record_Page` vira Org Default da `Quote`)

| Campo | Valor |
|---|---|
| Operação | Tornar `DD_Quote_Record_Page` a página **Org Default** do objeto `Quote` (desktop + mobile) via `CustomObject:Quote`; 2 dry-runs (o 1º falhou), deploy e verificação por retrieve |
| Skill | validate-metadata · chrome (leitura exploratória) |
| Ambiente | dev-trial — Org ID `00Das00000GrzvPEAR` (`IsSandbox: false`, `TrialExpirationDate: 2026-11-15`) |
| Objeto / Metadado | `CustomObject:Quote` (`actionOverrides` da ação `View`) · `FlexiPage DD_Quote_Record_Page` (**não alterada**) · `CustomApplication DD_DealDesk` (**mantido**) |
| Ferramenta | `sf project deploy start` (dry-run + real) · `sf project retrieve start` · `sf org list metadata` · `sf data query` |
| Parâmetros-chave | `--metadata CustomObject:Quote --test-level NoTestRun`; 39 `actionOverrides` do objeto preservados; das 3 de `View`, a genérica fica `Default`, `Large` e `Small` viram `Flexipage` + `DD_Quote_Record_Page` |
| Confirmação humana | **sim** — pedido direto: *"Faça o --dry-run e o deploy. Me avise quando terminar"* (2026-10-19) |
| Resultado | **dry-run 1** (`--source-dir objects/Quote`): `Failed` — `null is not a supported form factor.` (override `Flexipage` sem `<formFactor>`, **A94**) → **dry-run 2**: `Succeeded` `0Afas0000061741CAA` (6/6; `CustomObject:Quote` = `Changed`) → **deploy real**: `Succeeded` `0Afas00000615NDCAY` (6/6, 0 erro) → **retrieve**: `View/Large/Flexipage` e `View/Small/Flexipage` com `content = DD_Quote_Record_Page` e `skipRecordTypeSelect = false`; a genérica segue `Default`; **39/39** overrides e **53** campos do objeto intactos |
| Reversão | devolver as 2 entradas `View` de form factor para `<type>Default</type>` (sem `content`/`formFactor`) e redeployar `CustomObject:Quote`. Estado anterior: as 3 entradas de `View` eram `Default` — o objeto **não tinha** página org default |
| Tokens (aprox.) | 42000 |
| Observações | Os 5 `CustomField` de `Quote` entraram no pacote como `Unchanged` (a resolução de `CustomObject:Quote` arrasta a pasta `fields/`), sem escrita. O `skipRecordTypeSelect=false` foi gravado pela **própria org** (não foi enviado) — sinal de que ela interpretou o deploy como assignment de página. `Quote` não tem `RecordType` (0), então o org default vale para toda cotação |

**Por que não bastava o app nem o perfil**

O `actionOverrides` do `DD_DealDesk` só vale **dentro daquele app**; `profileActionOverrides` cobre app+perfil.
O `CustomObject` da `Quote` é o único lugar que expressa "padrão para toda a org" (**A94**) — e o org default
é o **menor** degrau de precedência, então o app `DD_DealDesk` continua com o override dele, apontando para a
mesma página (sem conflito).

**Verificação visual pendente (honesta)**

O Setup de "Páginas de registro do Lightning" **não** abriu nesta sessão: o Chrome está logado como
**Alan FieldTech** (Standard User, sem `Customize Application`) — a navegação do Object Manager aparece, o
conteúdo não. A prova usada foi o retrieve do `CustomObject:Quote` + o merge aceito pela org.

**Aprendizado**

- **A94:** o org default de Lightning Record Page vive no `CustomObject` (não na `FlexiPage`, não no app, não
  no perfil) e exige `formFactor` (`Large`/`Small`) — `Flexipage` sem form factor é recusado.

---

### [2026-10-19 19:48 -03:00] UI-005 — OK (RLM `AppUsageAssignment` bloqueava a edição da cotação: probe + limpeza em 16)

| Campo | Valor |
|---|---|
| Operação | **Delete** dos registros de `AppUsageAssignment` (`RevenueLifecycleManagement`) das cotações do projeto: 1 probe (`0Q0as0000021vHdCAI`) + 15 em lote autorizado. Diagnóstico do erro `You can't edit quotes with the Revenue Lifecycle Management or Subscription Management application usage assignment` |
| Skill | — (diagnóstico de org) |
| Ambiente | dev-trial — Org ID `00Das00000GrzvPEAR` (`IsSandbox: false`) |
| Objeto / Metadado | `AppUsageAssignment` (16 registros, todos `Name = Revenue Lifecycle Management`, `AppUsageType = RevenueLifecycleManagement`) |
| Ferramenta | `sf data query` · `sf api request rest` (describe) · `sf data delete record` |
| Parâmetros-chave | probe `-i 0j8as000003rCVzAAM`; lote = 15 registros das cotações com `CreatedDate >= 2026-10-17` (as 9 do seed de 2026-10-15 ficaram) |
| Confirmação humana | **sim** — exceção ao **S5** autorizada nominalmente em duas etapas: opção **A** (probe em 1) em 19:35 e "**Só as 15 do projeto**" em 19:52 |
| Resultado | probe: `success`, assignment 25 → 24, cotação intacta; **humano adicionou uma `QuoteLineItem` pela UI e salvou** (`1 Quote Line Item record was updated.`) → guard confirmado. **Nenhum re-tag** após o save (assignment da cotação = 0, total 24). Lote: **15/15** `success`, total 24 → **9** (só seed); nenhuma cotação do projeto tagueada; `DEMO-Quote-Demo-Abaixo` (192, Requer Aprovação) e `Renovação de Frota Elétrica` (3.749,60, Saudável) intactas |
| Reversão | recriar cada registro com `RecordId` = Id da cotação, `AppUsageType = RevenueLifecycleManagement`, `Name = Revenue Lifecycle Management` (objeto com `createable = true`). Snapshot completo na tabela abaixo |
| Tokens (aprox.) | 30000 |
| Observações | **Diagnóstico:** os assignments são criados pela **plataforma** no insert da cotação (timestamp idêntico ao `CreatedDate` da `Quote`); 9 são de 2026-10-15 (seed do trial, antes do projeto) e a `Teste cotação` (criada pelo humano) também tinha — logo **não é efeito de criação via MCP**. `ProductSellingModel`/`SalesTransactionType` têm **0** registros e `SalesTransaction` não existe: a org carrega o *assignment* do RLM **sem o motor provisionado**. O delete é **estável** (não re-tagueia ao salvar), mas o RLM pode re-taguear cotações **novas** criadas a partir de agora |

**Snapshot para rollback (16 registros removidos)**

| # | `AppUsageAssignment.Id` | Cotação (`RecordId`) | Nome da cotação | Removido em |
|---|---|---|---|---|
| 1 | `0j8as000003rCVzAAM` | `0Q0as0000021vHdCAI` | Cotação Programa de Manutenção de Frota - Titan | probe (19:48) |
| 2 | `0j8as000003qmmnAAA` | `0Q0as0000021hOLCAY` | DEMO-Quote-Margin-Bands | lote (19:54) |
| 3 | `0j8as000003qpSwAAI` | `0Q0as0000021j1xCAA` | DEMO-Quote-Guardrail-Green | lote |
| 4 | `0j8as000003qpfpAAA` | `0Q0as0000021j3ZCAQ` | DEMO-Quote-Guardrail-Generic | lote |
| 5 | `0j8as000003qrHpAAI` | `0Q0as0000021jtBCAQ` | Teste cotação | lote |
| 6 | `0j8as000003qr4yAAA` | `0Q0as0000021jlACAQ` | Cotação USD | lote |
| 7 | `0j8as000003qv8XAAQ` | `0Q0as0000021mHZCAY` | DEMO-Quote-Demo-Saudavel | lote |
| 8 | `0j8as000003qv6wAAA` | `0Q0as0000021mFyCAI` | DEMO-Quote-Demo-Limite | lote |
| 9 | `0j8as000003qv27AAA` | `0Q0as0000021mJBCAY` | DEMO-Quote-Demo-Abaixo | lote |
| 10 | `0j8as000003rDztAAE` | `0Q0as0000021v4jCAA` | Renovação de Frota Elétrica - Tech Labs | lote |
| 11 | `0j8as000003r74uAAA` | `0Q0as0000021swUCAQ` | Manutenção Preventiva - Global Medical | lote |
| 12 | `0j8as000003r9OQAAY` | `0Q0as0000021shyCAA` | Contrato Anual de Peças - Acme Partners | lote |
| 13 | `0j8as000003rE6LAAU` | `0Q0as0000021v7xCAA` | Expansão do Kit - Metro Medical | lote |
| 14 | `0j8as000003rDocAAE` | `0Q0as0000021v9ZCAQ` | Piloto de Calibração - Integrity Systems | lote |
| 15 | `0j8as000003rEO5AAM` | `0Q0as0000021vG1CAI` | Renovação de Frota Comercial - Trane | lote |
| 16 | `0j8as000003rEPhAAM` | `0Q0as0000021vJFCAY` | Contrato de Ferramentas - Volt Technical | lote |

**Achado colateral (bônus do teste)**

O print do humano mostra a cotação aberta no app **Manufacturing** já com o console (`Justificativa` + `Pedir desconto` + `DD Estado do Guardrail`) — prova visual de que o Org Default da `Quote` (UI-004) vale fora do app `DD_DealDesk`.

---

### [2026-10-19 20:35 -03:00] UI-006 — OK (coluna Desconto (%) no "Quote Line Items" da cotação)

| Campo | Valor |
|---|---|
| Operação | `Quote-Quote Layout`: related list `RelatedQuoteLineItemList` reduzida de **17** para **5** campos (Product, Sales Price, Quantity, Subtotal, **Discount** ao final). `DD_Quote_Record_Page`: troca do `force:relatedListContainer` (compacto) por **3 `force:relatedListSingleContainer`** com `relatedListComponentOverride = ADVGRID` — `QuoteLineItems`, `QuoteDocuments`, `CombinedAttachments`, `parentFieldApiName = Quote.Id` |
| Skill | validate-metadata |
| Ambiente | dev-trial — `00Das00000GrzvPEAR` |
| Ferramenta | `sf project deploy start` (dry-run + real) · retrieve da `FlexiPage`/`Layout` · Chrome (verificação do DOM) |
| Confirmação humana | **sim** — pedido direto: "deixa apenas o que era padrão e mais o campo de desconto ao final" |
| Resultado | dry-run `Succeeded` (2/2) → deploy `Succeeded` `0Afas00000618g1CAA` (2/2). DOM da página confirma a tabela com **Product · Sales Price · Quantity · Subtotal · Discount (Percentage)** e os 3 cards (QLI, Quote PDFs, Notes & Attachments) de volta |
| Reversão | devolver os 17 campos da related list no layout e o `force:relatedListContainer` na FlexiPage (`git show HEAD~1:...`) |
| Observações | **Armadilha:** o container padrão exibe só os **4 primeiros** campos do layout; com `relatedListSingleContainer` + `ADVGRID` a lista mostra **todos**. `parentFieldApiName` tem de ser `Quote.Id` (`QuoteLineItem.QuoteId` é recusado; `QuoteLineItem.Quote` também). A propriedade `fields` **não existe** no componente |

**Aprendizado**

- **A96:** as colunas da related list em LEX vêm da **page layout** (ordem incluída) e o `force:relatedListContainer` compacto mostra **4**; para exibir mais é preciso `force:relatedListSingleContainer` com `relatedListComponentOverride = ADVGRID`. O grid leva alguns segundos para renderizar — validar por DOM **depois** do `wait`, não na primeira leitura.

---

### [2026-10-19 20:52 -03:00] UI-007 — OK (campos de desconto do console iniciam com o desconto atual da cotação)

| Campo | Valor |
|---|---|
| Operação | `ddMarginConsole`: os inputs "Desconto a simular (%)" e "Desconto solicitado (%)" passam a iniciar com **`Quote.Discount`** (média ponderada nativa) formatado em 2 casas, em vez do valor fixo `10` |
| Skill | sf-lwc · validate-metadata |
| Ambiente | dev-trial — `00Das00000GrzvPEAR` |
| Objeto / Metadado | `LightningComponentBundle:ddMarginConsole` (js) — **Apex não foi alterado** |
| Ferramenta | `sf project deploy start` (dry-run + real) · retrieve de verificação · Chrome (DOM) |
| Parâmetros-chave | `QUOTE_FIELDS = [DD_GuardrailState__c, Quote.Discount]` no `getRecord` (sem Apex: o campo já está no layout da cotação e o usuário o vê); `initializeDiscounts()` formata `toFixed(2)` e roda **uma vez** (`discountInitialized`), para `refreshApex` não apagar o que o usuário digitou |
| Confirmação humana | **sim** — pedido direto (ajuste de UX) |
| Resultado | dry-run `Succeeded` → deploy `Succeeded` `0Afas0000061993CAA`; retrieve confirma o código novo na org (`initializeDiscounts`, `QUOTE_DISCOUNT_FIELD`). Cotação de teste `0Q0as0000021vHdCAI`: `Discount = 75.72778828` → **confirmado pelo humano no navegador: os dois campos abrem em `75,73`**. A primeira leitura no DOM ainda trazia `10` por cache do bundle — o F5 resolveu |
| Reversão | voltar `simDiscountPct`/`reqDiscountPct` para `10` e remover `Quote.Discount` de `QUOTE_FIELDS` |
| Tokens (aprox.) | 12000 |
| Observações | Não foi preciso mexer no Apex: `getRecord` já trazia a cotação para o estado do guardrail. `Quote.Discount` não é margem nem custo, então não conflita com D14. Requisito de FLS: o campo precisa ser legível pelo usuário (o Bruno o vê na tela da cotação) — se um dia o `getRecord` falhar, a causa será FLS, não o componente |

---

### [2026-10-20 00:25 -03:00] UI-008 — OK (botão "Create Order" habilitado nas ações Lightning da cotação)

| Campo | Valor |
|---|---|
| Operação | `Layout:Quote-Quote Layout`: remover `CreateOrder` de `<excludeButtons>` e incluir `CreateOrder` (`StandardButton`) na `<platformActionList>` (ações Lightning), `sortOrder = 29`. Base = layout retornado da org (que já tinha as mudanças feitas pelo humano na UI), não o arquivo local |
| Skill | validate-metadata |
| Ambiente | dev-trial — `00Das00000GrzvPEAR` |
| Ferramenta | `sf project deploy start` (dry-run + real) · retrieve de layout · `SetupAuditTrail` · Chrome |
| Parâmetros-chave | desligar "Advanced Order Creation From Quote" + limpar o campo do flow (feito pelo humano: audit trail `advCreateOrdersFromQuoteOnOff` e `value_ADV_Q2_O_SCREEN_FLOW` 00:11–00:17). O flow `revenue_adv_q2o__CreateOrdersFromQuote` é de **pacote gerenciado** e **não pode ser ativado** ("No actions available") — o campo do Revenue Settings espera um flow **do cliente** |
| Confirmação humana | **sim** — caminho **A** escolhido pelo humano ("desligar o modo avançado") |
| Resultado | dry-run `Succeeded` → deploy `Succeeded` `0Afas00000619llCAA`; retrieve confirma `excludeButtons = [GenerateKnowledge, Submit]` e `CreateOrder` na `platformActionList` (30 itens). DOM: o botão não aparece entre os 3 primeiros (vai para o menu "Show more actions"), verificação visual pendente do humano |
| Reversão | devolver `CreateOrder` para `excludeButtons` e remover o item da `platformActionList` |
| Tokens (aprox.) | 22000 |
| Observações | A UI do editor de layout não permitia arrastar o botão para "Salesforce Mobile and Lightning Experience Actions"; o caminho determinístico foi metadata. O botão `CreateOrder` estava **excluído** do layout — era por isso que não aparecia nem no Classic |

---

### [2026-10-19 21:40 -03:00] Q2O-001 — OK (pedido criado via API a partir da cotação aceita)

| Campo | Valor |
|---|---|
| Operação | Criar 1 `Order` + 4 `OrderItem` espelhando a cotação `0Q0as0000021vHdCAI` (Titan, `Accepted`). Botão "Create Order" não renderiza nesta org (ver UI-008) |
| Skill | query-salesforce · validate-metadata |
| Ambiente | dev-trial — `00Das00000GrzvPEAR` |
| Objeto / Metadado | `Order` `801as00000HH0OQAA1` (`00000637`) · `OrderItem` `802as000009JgBGAA0`, `802as000009JeNyAAK`, `802as000009Jg3CAAS`, `802as000009JgZRAA0` |
| Ferramenta | `sf data create record` · `sf data update record` · `sf data query` |
| Parâmetros-chave | Order: `AccountId=001as00000HCKx1AAH`, `Pricebook2Id=01sas000001nOBJAA2`, `QuoteId=0Q0as0000021vHdCAI`, `EffectiveDate=2026-10-19`, `Status=Draft`, `CurrencyIsoCode=USD` (explícito, A13); `TotalAmount` omitido (roll-up, A15). OrderItems com `PricebookEntryId`, `Product2Id`, `Quantity`, `UnitPrice`, `Discount` |
| Confirmação humana | **sim** — payload apresentado e "confirmo" em 21:33 |
| Resultado | `Order` criado (1º retorno `success`), 4/4 `OrderItem` criados. **Correção:** o `OrderItem.TotalPrice` veio **antes** do desconto (4.232,00), porque é `UnitPrice × Quantity` e não aplica `Discount` — `UnitPrice` foi ajustado para o **líquido** (2,24 / 11,20 / 24,00 / 16,00). Final: linhas 179,20 + 336,00 + 192,00 + 320,00 = **1.027,20**, `Order.TotalAmount = 1.027,20 USD`, todos `USD` |
| Reversão | apagar o `Order` (`801as00000HH0OQAA1`) — cascata leva os 4 `OrderItem`. Exige autorização nominal (S5) |
| Tokens (aprox.) | 14000 |
| Observações | `Order.Name` é autonumber → prefixo `DEMO-` inaplicável (exceção A14). O `Order` é `Draft`; ativar é decisão de negócio (não feita). O caminho do botão nativo segue sem solução nesta org (flow de pacote inativo + RLM híbrido) |

---

### [2026-10-19 21:52 -03:00] Q2O-002 — PARCIAL (desconto no cabeçalho do pedido: percentual grava, valor em moeda não)

| Campo | Valor |
|---|---|
| Operação | Preencher `Order.AppliedDiscount` (75,73%) e `Order.AppliedDiscountAmount` (3.204,80) no pedido `801as00000HH0OQAA1`, a pedido do humano |
| Skill | — |
| Ambiente | dev-trial — `00Das00000GrzvPEAR` |
| Objeto / Metadado | `Order` `801as00000HH0OQAA1` (`00000637`) |
| Ferramenta | `sf api request rest` (PATCH) · `sf data update record` · `sf data query` |
| Parâmetros-chave | 4 combinações testadas: (a) percent + valor + `AdjustmentDistributionLogic=null`; (b) só o valor; (c) só o percent — **única que passou**; (d) valor com percent nulo |
| Confirmação humana | **sim** — "preenche os dois campos do cabeçalho" |
| Resultado | `AppliedDiscount = 75.73` **gravado**. `AppliedDiscountAmount` **recusado em todas as tentativas** com `FIELD_INTEGRITY_EXCEPTION: The field Adjustment Distribution Logic must be empty when field Applied Discount is set to a value.` — mesmo com `AdjustmentDistributionLogic` nulo (confirmado por SOQL antes e depois). `DiscountPercent` (read-only) segue **0** |
| Reversão | `AppliedDiscount = null` (1 PATCH) |
| Tokens (aprox.) | 9000 |
| Observações | A mensagem cita um campo que já está vazio — comportamento incoerente da validação do Revenue Cloud nesta org, mesma família do `Order.DiscountPercent` read-only e do flow de Q2O inativo. Conclusão prática: o **percentual** é o único campo do cabeçalho gravável; o valor em moeda não. Nenhum total mudou (`TotalAmount = 1.027,20`) |

### [2026-10-20 18:45 -03:00] F7-001 — OK (campo-gate, Flow e 2 VRs deployados com dry-run)

| Campo | Valor |
|---|---|
| Operação | Criar `Quote.DD_HasApprovedRequest__c` + Flow `DD_SyncQuoteGate` + `ValidationRule` `Quote.DD_Block_Unapproved_Quote` e `Order.DD_Block_Unapproved_Order` + layout + FLS (F7-01/F7-02/F7-03) |
| Skill | validate-metadata |
| Ambiente | dev-trial — `00Das00000GrzvPEAR` (`IsSandbox=false`, `TrialExpirationDate=2026-11-15`) |
| Objeto / Metadado | Campo `Quote.DD_HasApprovedRequest__c` (Checkbox) · Flow `DD_SyncQuoteGate` (RecordAfterSave) · 2 `ValidationRule` · `Layout:Quote-Quote Layout` · `Profile:Admin` · `PermissionSet:DD_DealDesk_User` |
| Ferramenta | `sf project deploy start --dry-run` e `--metadata` (2 etapas) |
| Parâmetros-chave | **Dry-run 1** (campo): `Succeeded` 1/1. **Deploy 1** `0Afas0000061TfkCAE`. **Dry-run 2**: **falhou** nas 2 VRs com `Validation rule description cannot be longer than 255 characters long.` (A101) → descrições encurtadas → **dry-run 2 `Succeeded` 6/6** → **deploy 2 `0Afas0000061VhRCAU` `Succeeded` 6/6** |
| Confirmação humana | **sim** — ordem direta do humano em 2026-10-20 ("Execute a F7-01... F7-02 e F7-03... faça o --dry-run... Teste de Burlada Final") sobre as 4 decisões de D34 |
| Resultado | FLS: Admin `read+edit`, PS `read=true/edit=false`. Layout: `grep` do campo = **1** na seção Totals. Flow: `Active`, `RecordAfterSave`, versão **1** (sem `Obsolete`). VRs: **2 Active**. `FlowDefinitionView` 256 (220 ativos, 33 locais) |
| Reversão | Remover as 2 VRs, desativar/remover o Flow e o campo (exige autorização nominal, S5). O campo tem default `false` e nenhum dado histórico depende dele |
| Tokens (aprox.) | 30000 |
| Observações | A fórmula final da `Quote` diverge do plano em um ponto deliberado: `ISNEW()` bloqueia **qualquer** insert `Accepted` (sem linhas não há margem nem aprovação) e `ISCHANGED(DD_GuardrailState__c)` cobre a queda de faixa pós-aceite — D35. `AutoApproved` não existe no picklist de `Status__c` (é `Decision__c`): o gate usa `Approved` |

---

### [2026-10-20 18:53 -03:00] F7-002 — OK (teste de burlada: insert `Accepted`, transição vermelha e `Order` bloqueados)

| Campo | Valor |
|---|---|
| Operação | 3 tentativas de burlar o gate por DML/REST: (1) insert de `Quote` já `Accepted`; (2) `Draft` vermelha → `Accepted`; (3) insert de `Order` a partir de cotação vermelha sem aprovação |
| Skill | — |
| Ambiente | dev-trial — `00Das00000GrzvPEAR` |
| Objeto / Metadado | `Quote` · `Order` · campo-gate `DD_HasApprovedRequest__c` |
| Ferramenta | `sf data create record` · `sf data update record` · `sf apex run` |
| Parâmetros-chave | (1) `Name=DEMO-F7-Q-InsertAccepted`, `Status=Accepted`, `OpportunityId=006as0000094kK2AAI`, `Pricebook2Id=01sas000001nOBJAA2`, `CurrencyIsoCode=USD`; (2) `0Q0as0000021vG1CAI` (12,5%, `Requer Aprovação`) → `Status=Accepted`; (3) `Order` `QuoteId=0Q0as0000021vG1CAI`, `Status=Draft` |
| Confirmação humana | **sim** — teste pedido nominalmente ("O Salesforce DEVE retornar erro") |
| Resultado | (1) **`FIELD_CUSTOM_VALIDATION_EXCEPTION`** — "Cotação em faixa de risco exige pedido de desconto aprovado..."; (2) **mesmo erro**, cotação permaneceu `Draft`; (3) **`FIELD_CUSTOM_VALIDATION_EXCEPTION`** — "Pedido originado de cotação em faixa de risco exige pedido de desconto aprovado..." Nenhum registro criado |
| Reversão | Nenhuma necessária: as 3 operações falharam e não gravaram nada |
| Tokens (aprox.) | 8000 |
| Observações | O insert direto `Accepted` é bloqueado mesmo sem margem (a cotação nasce sem linha/custo). O requisito "com margem vermelha" no insert é estruturalmente impossível de montar num único DML (filhos exigem pai), por isso a prova da faixa usa a transição em (2) |

---

### [2026-10-20 18:55 -03:00] F7-003 — OK (gate pelo Flow, round-trip e regressão de faixa)

| Campo | Valor |
|---|---|
| Operação | Provar o Flow `DD_SyncQuoteGate` ponta a ponta e a regra de faixa em cotação já aceita, com dados `DEMO-` |
| Skill | — |
| Ambiente | dev-trial — `00Das00000GrzvPEAR` |
| Objeto / Metadado | `Quote` `0Q0as0000022fnVCAQ` e `0Q0as0000022fp7CAA` · `QuoteLineItem` `0QLas0000029vvbGAA` · `DD_DiscountRequest__c` `a0Nas00000UVFpWEAX` |
| Ferramenta | `sf apex run` (DML em Apex para gravar a linha; `QuoteLineItem.CurrencyIsoCode` é derivado da cotação — A81) |
| Parâmetros-chave | Q1: linha 20 × 96 com 75% → margem -229,17%; pedido `Submitted` → gate `false`; pedido `Approved` + `DecidedAt` → **gate `true`**; aceitar → **OK**; reverter pedido para `Submitted` → gate `false`; aceitar → **bloqueado**. Q2: linha saudável 33,02% → aceitar **OK**; linha para 75% → **bloqueado**, estado permaneceu `Saudável` e `Discount=0.00` |
| Confirmação humana | **sim** — mesma ordem de execução da F7 |
| Resultado | Flow grava `true`/`false` corretamente nas duas direções; VR bloqueia a queda de faixa em cotação aceita (**A100**); round-trip sem resíduo de estado (Q1 e Q2 terminaram `Draft`) |
| Reversão | Q1 e Q2 deixadas em `Draft`; o pedido `a0Nas00000UVFpWEAX` foi aprovado no teste F7-004 (fica `Approved`). Exclusão exige autorização (S5) |
| Tokens (aprox.) | 12000 |
| Observações | Varredura F7-04: **5** cotações `Accepted` — 4 `Pendente de Custo` e **1** `Requer Aprovação` com gate `false` (Titan `0Q0as0000021vHdCAI`, grandfathering). Nenhuma tocada. Ativação de `Order` e delete de pedido aprovado não exercitados → **F7-05** (A102) |

---

### [2026-10-20 19:00 -03:00] F7-004 — OK (aprovação pelo `ApprovalProcess` real atualiza o gate)

| Campo | Valor |
|---|---|
| Operação | Submeter e aprovar o pedido `a0Nas00000UVFpWEAX` pelo `ApprovalProcess` `DD_Manager_Approval` via `Approval.process` e conferir o gate da cotação |
| Skill | — |
| Ambiente | dev-trial — `00Das00000GrzvPEAR` |
| Objeto / Metadado | `DD_DiscountRequest__c` `a0Nas00000UVFpWEAX` · `Quote` `0Q0as0000022fnVCAQ` · `ApprovalProcess` `DD_Manager_Approval` |
| Ferramenta | `sf apex run` (`Approval.process` + `ProcessWorkitemRequest`) |
| Parâmetros-chave | `ProcessSubmitRequest` no pedido → 1 `ProcessInstanceWorkitem` → `ProcessWorkitemRequest` ação `Approve` |
| Confirmação humana | **sim** — mesmo escopo de teste da F7 |
| Resultado | `SUBMIT success=true`, `APPROVE success=true`; `Status__c = Approved`, `DecidedAt__c = 2026-10-20 22:00:04` (UTC) e **`Quote.DD_HasApprovedRequest__c = true`** |
| Reversão | O pedido fica `Approved` com `ProcessInstance` concluído (não há caminho limpo de volta); a cotação fica `Draft` e o gate `true` |
| Tokens (aprox.) | 4000 |
| Observações | Prova que o field update da ação final do `ApprovalProcess` **dispara** o Flow `RecordAfterSave` (**A103**). O caminho da UI do gerente está coberto; sem isso, aprovar pela fila não destravaria o aceite |

---

### [2026-10-20 19:12 -03:00] MASSA-003 — OK (6 oportunidades × 2 cotações para o vendedor Bruno)

| Campo | Valor |
|---|---|
| Operação | Criar massa de teste para o usuário Bruno Tavares: 6 `Opportunity` + 12 `Quote` + 27 `QuoteLineItem`, 2 oportunidades em cada faixa de margem |
| Skill | query-salesforce · validate-metadata |
| Ambiente | dev-trial — `00Das00000GrzvPEAR` |
| Objeto / Metadado | `Opportunity` `006as0000096MrtAAE`…`MryAAE` (6) · `Quote` `0Q0as0000022g21CAA`…`g2CCAQ` (12) · 27 `QuoteLineItem` |
| Ferramenta | `sf apex run` (DML em lote, autorizado pelo pedido explícito do humano) |
| Parâmetros-chave | `OwnerId=005as000003piV7AAI` (Bruno); `Pricebook2Id=01sas000001nOBJAA2`; `CurrencyIsoCode=USD`; `Status=Draft`; contas existentes com acesso do Bruno; descontos por linha para atingir as faixas |
| Confirmação humana | **sim** — "crie umas 6 oportunidades onde cada oportunidade tenha múltiplas cotações, sendo 2 ficando verde, 2 ficando amarelo e 2 ficando vermelho" (2026-10-20) |
| Resultado | 6/6 oportunidades e 12/12 cotações criadas, 27/27 itens. Faixas: **4 `Saudável`** (Titan 35,06/35,66%; Trane 33,01/33,01%), **4 `Requer Justificativa`** (Volt 23,70/24,22%; Metro 26,43/26,28%), **4 `Requer Aprovação`** (Integrity 13,48/8,72%; Acme 13,90/7,99%). Tudo `USD`, dono Bruno, `HasReadAccess`/`HasEditAccess` confirmados |
| Reversão | Apagar oportunidades (cascata nas cotações/itens) — exige autorização nominal (S5); IDs em `MEMORY.md` §1.13 |
| Tokens (aprox.) | 9000 |
| Observações | Estrutura escolhida: **2 oportunidades por faixa** (não 2 cotações no total), cada uma com 2 cotações na mesma faixa — atende "cada oportunidade com múltiplas cotações". Os `Name` nasceram com `DEMO-` (S11) e foram **renomeados na MASSA-004** para nomes comerciais reais, por autorização do humano (exceção ao S11, A81). Textos de `Description`/`NextStep` em PT-BR realista. Bruno está com moeda de usuário `BRL` na org, mas os registros são `USD` (S12) |

---

### [2026-10-20 19:16 -03:00] MASSA-004 — OK (nomes comerciais nas oportunidades e cotações do Bruno)

| Campo | Valor |
|---|---|
| Operação | Renomear 6 `Opportunity` e 12 `Quote` da MASSA-003, removendo o prefixo `DEMO-` e adotando nomes que um vendedor usaria |
| Skill | — |
| Ambiente | dev-trial — `00Das00000GrzvPEAR` |
| Objeto / Metadado | 6 `Opportunity` `006as0000096MrtAAE`…`MryAAE` · 12 `Quote` `0Q0as0000022g21CAA`…`g2CCAQ` |
| Ferramenta | `sf apex run` (update em lote) |
| Parâmetros-chave | Ex.: `Renovação do Contrato de Manutenção - Titan Fastener Products`, `Expansão da Frota Comercial - Trane Company`, `Retenção de Cliente - Integrity Systems`; cotações como `Renovação 2026 - Escopo Atual`, `Piloto de Peças - Volume Anual 30%` |
| Confirmação humana | **sim** — "nenhum vendedor vai dar o nome DEMO para uma oportunidade, tem como editar o nome?" (2026-10-20) |
| Resultado | 6/6 oportunidades e 12/12 cotações renomeadas; faixas e margens **inalteradas** (4 `Saudável`, 4 `Requer Justificativa`, 4 `Requer Aprovação`) |
| Reversão | Nomes anteriores (`DEMO-…`) registrados na MASSA-003; reaplicar o mapa inverso |
| Tokens (aprox.) | 3000 |
| Observações | Exceção ao S11 autorizada pelo humano (mesmo precedente do A81): massa de demonstração realista não deve carregar prefixo que denuncie o teste. `Name` de `Opportunity` e `Quote` é gravável (nenhuma limitação de plataforma) |

---

### [2026-10-20 19:22 -03:00] UI-009 — OK (RLM: limpeza dos 12 `AppUsageAssignment` da massa do Bruno)

| Campo | Valor |
|---|---|
| Operação | **Delete** dos 12 registros de `AppUsageAssignment` (`RevenueLifecycleManagement`) das cotações da MASSA-003, para liberar a edição pela UI clássica |
| Skill | — |
| Ambiente | dev-trial — `00Das00000GrzvPEAR` |
| Objeto / Metadado | `AppUsageAssignment` `0j8as000003sirxAAA`…`0j8as000003sis8AAA` (12) · `Quote` `0Q0as0000022g21CAA`…`g2CCAQ` |
| Ferramenta | `sf data delete record` (um a um) |
| Parâmetros-chave | 12 deletes individuais; IDs mapeados em [`MEMORY.md`](../MEMORY.md) §1.11/§1.13 |
| Confirmação humana | **sim** — "Confirmo que você remova os 12 AppUsageAssignment das cotações da massa do Bruno" (2026-10-20) |
| Resultado | **12/12 `OK`**. Nenhum assignment restante nas 12 cotações; total da org 21 → **11** (9 do seed ACME de 2026-10-15 + 2 cotações de teste da F7). Cotações e linhas intactas: **12** cotações e **27** `QuoteLineItem`; faixas inalteradas |
| Reversão | Recriar `AppUsageAssignment{ RecordId, AppUsageType = RevenueLifecycleManagement, Name = Revenue Lifecycle Management }` por cotação |
| Tokens (aprox.) | 4000 |
| Observações | Mesmo procedimento do UI-005 (A95): o delete é estável e não re-tagueia após o save. A restrição do RLM é da UI; update por Apex/API já funcionava com o assignment presente. As 2 cotações de teste da F7 continuam tagueadas de propósito (não autorizadas nesta limpeza) |

---

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
