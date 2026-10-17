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
