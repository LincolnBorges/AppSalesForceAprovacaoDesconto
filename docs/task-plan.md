# Plano de Ações — DealDeskGuardrail

Lista **viva** e granular das ações necessárias para implementar o projeto. É o guia de acompanhamento
do dia a dia: cada linha é uma ação verificável, com ID estável, predecessores, descrição e responsável.

**Relação com os outros documentos** (cada um responde uma pergunta diferente):

| Documento | Responde |
|---|---|
| [`roadmap.md`](roadmap.md) | **Por que** e em **que ordem macro** (7 fases, critérios de pronto) |
| **`task-plan.md`** (este) | **O que exatamente** fazer agora, em que ordem e com quem decide |
| [`execution-log.md`](execution-log.md) | **Qual foi a evidência** de cada operação executada |
| [`MEMORY.md`](../MEMORY.md) | **Quais são os fatos** duráveis (IDs, decisões, cache de metadados) |

> **Nomes de metadado são candidatos, não verdades.** Todo `DD_*` citado aqui deve ser validado com
> `sf_describe_object` antes do uso (convenção 3 do [`AGENTS.md`](../AGENTS.md) §4).

---

## 1. Como usar e manter

### Responsável ("quem decide")

| Valor | Significado |
|---|---|
| `IA` | A IA executa e decide o **mérito técnico**. Escrita na org continua exigindo confirmação do payload (S3), dupla quando for Flow/PS/Agentforce (S6) |
| `HUMANO` | **Decisão de negócio**: a IA não decide, não assume default e não infere. Sem resposta, a ação fica bloqueada |
| `IA+H` | A IA propõe e executa; o humano aprova a proposta antes de qualquer escrita |

> Atenção à distinção: **confirmação de payload** (S3, vale para toda escrita, é operacional) ≠
> **decisão de negócio** (coluna desta tabela, é de mérito).

### Status

| Valor | Significado |
|---|---|
| `PENDENTE` | Não iniciada |
| `EM ANDAMENTO` | Iniciada, não concluída |
| `BLOQUEADO` | Travada por decisão humana, falha de probe ou dependência externa — registrar o motivo na linha |
| `CONCLUÍDO` | Verificada e registrada no `execution-log` |
| `CANCELADO` | Descartada; manter a linha com o motivo (nunca reaproveitar o ID) |

### Regras de manutenção

1. Ao concluir uma ação, mudar o `Status`, pôr a data entre parênteses e, se houve escrita na org, referenciar
   o ID do `execution-log`.
2. Ação nova entra ao final do bloco da fase com **ID novo** (`F<fase>-<nn>`). ID nunca é reutilizado.
3. Ação que se desdobrou em várias ganha linhas próprias; a original vira `CANCELADO` citando as filhas.
4. Se a ação for descoberta já concluída (ex.: feita por herança), registrar mesmo assim.
5. Atualizar §2 (progresso) junto com §4; commit próprio `docs(plano): ...` (D11).
6. Predecessor em **negrito** = dependência dura (não pode começar); sem negrito = pode iniciar em paralelo.
7. **Decisão tomada sai da §3** e vira linha `Dnn` em [`MEMORY.md`](../MEMORY.md) §2 — a fila da §3 contém
   apenas o que ainda espera resposta humana.

---

## 2. Progresso por fase

| Fase | Nome | Ações | Concluídas | Status |
|---|---|---|---|---|
| 0 | Fundação e base de custo | 15 | 14 | CONCLUÍDO |
| 1 | Cálculo de margem | 8 | 8 | CONCLUÍDO |
| 2 | Política de desconto | 7 | 7 | CONCLUÍDO |
| 3 | Guardrail e roteamento | 10 | 9 | CONCLUÍDO |
| 4 | Console LWC | 7 | 7 | CONCLUÍDO |
| 5 | Acesso, dados e demo | 11 | 9 | EM ANDAMENTO (F5-11 concluída em 2026-10-18) |
| 6 | Camada Agentforce | 11 | 10 | CONCLUÍDO (2026-10-17) |
| 7 | Enforcement do guardrail | 4 | 0 | PENDENTE (aberta em 2026-10-19) |
| — | Transversais (contínuas) | 5 | 2 | EM ANDAMENTO |
| **Total** | | **79** | **66** | |

*Atualizado em 2026-10-19 (UI-004 a UI-008 e Q2O-001/Q2O-002; **Fase 7 aberta** com F7-01 a F7-04 — enforcement do guardrail na Quote e no Order, a pedido do humano).*

---

## 3. Fila de decisões humanas

Só estas ações exigem decisão de negócio. Enquanto estiverem `PENDENTE`, as fases seguintes ficam
paradas no ponto indicado.

| ID | Decisão | Bloqueia | Efeito se não houver resposta |
|---|---|---|---|
| — | Nenhuma pendente até 2026-10-18 (Fases 0 e 1 fechadas em 2026-10-17) | — | — |
| — | **Fase 7 sem pendência:** as 4 decisões de enforcement foram tomadas em 2026-10-19 (**D34**) | — | Execução começa em F7-01 |

> **Já decididas em 2026-10-17** (registradas em `MEMORY.md` §2): F0-02 → D16 · F0-03 → D17 ·
> F0-04 → D12 · F3-01 → D13 · F4-01 → D14 · F6-02 → D15 · F6-10 → D30.

---

## 4. Ações

### Fase 0 — Fundação e base de custo

| ID | Ação | Predecessores | O que faz | Quem decide | Status |
|---|---|---|---|---|---|
| F0-00 | Estrutura e documentação do projeto | — | Projeto DX, `AGENTS.md`, `MEMORY.md`, 6 skills e `docs/` criados (INIT-001, sem escrita na org) | IA | CONCLUÍDO (2026-10-16) |
| F0-01 | Baseline de metadados reconferido | — | Recontar `FlowDefinitionView` (total/ativos/locais), LWC, `FlexiPage`, `CustomTab`, `GenAiFunction`/`GenAiPlugin`, `Bot`/Planner e `PricebookEntry` com custo; regravar em `MEMORY.md` §1.6 com a data, porque o baseline de 2026-10-16 já pode ter mudado | IA | CONCLUÍDO (2026-10-17): reconferido, idêntico — sem resíduo |
| F0-02 | Autorizar semeadura em lote | — | Decidir se os custos de demonstração podem ser tratados como **uma** escrita aprovada em lote, com exceção registrada à S4; sem isso são 15+ confirmações uma a uma | HUMANO | CONCLUÍDO (2026-10-17): autorizado, escopo em D16 |
| F0-03 | Famílias de produto em escopo | — | Quais `ProductFamily` entram no piloto e em qual price book cada uma é semeada | HUMANO | CONCLUÍDO (2026-10-17): `Parts` e `Medical Equipment`, ver D17 |
| F0-04 | Piso, alvo e teto por família | **F0-03** | Números de negócio: piso de margem (bloqueio), alvo (auto-aprovação) e teto de desconto permitido; insumo direto de `DD_DiscountPolicy__c` | HUMANO | CONCLUÍDO (2026-10-17): alvo 30%, piso 20%, ver D12 |
| F0-05 | Levantar base de custo faltante | **F0-03** | Listar as `PricebookEntry` alvo com `Product2`, `UnitPrice`, família e custo atual nulo | IA | CONCLUÍDO (2026-10-17): 9 no Fleet & Corporate + 10 no Standard, ver `cost-proposal.md` |
| F0-06 | Propor tabela de custos | **F0-04**, **F0-05** | Calcular `FixedCost__c` + `VariableCostPerUnit__c` por entrada para produzir margens coerentes com o piso aprovado, cobrindo faixa verde, amarela e vermelha | IA | CONCLUÍDO (2026-10-17): [`cost-proposal.md`](cost-proposal.md) — 19 entradas, 8 verdes / 5 amarelas / 6 vermelhas |
| F0-07 | Aprovar a tabela de custos | **F0-06** | Validar os números antes de qualquer escrita; última barreira antes do seeding | HUMANO | CONCLUÍDO (2026-10-17): tabela aprovada |
| F0-08 | Semear custo no price book | **F0-02**, **F0-07**, **F0-11**, **F0-13** | Gravar `FixedCost__c` e `VariableCostPerUnit__c` com `CurrencyIsoCode = USD`, um registro por vez, registrando o valor anterior para rollback (S10) | IA | CONCLUÍDO (2026-10-17): 19 registros em `SED-001` |
| F0-09 | Validar a semeadura | **F0-08** | Conferir ≥20 entradas com custo, ≥2 price books, ≥2 famílias, todas `USD`; bater a margem de 3 amostras contra o cálculo manual | IA | CONCLUÍDO (2026-10-17): 24 com custo · 10/7/7 · 0 não-USD |
| F0-10 | Fechar a Fase 0 | **F0-09** | Atualizar `MEMORY.md` §1.3/§1.6, `execution-log`, este plano e o `roadmap`; commit e tag `fase-0` | IA | CONCLUÍDO (2026-10-17) |
| F0-11 | Price book de `Medical Equipment` | **F0-05** | Escolher entre semear no `Standard Price Book` (só updates) ou criar entradas no `Fleet & Corporate` (10 creates); ver §5 do `cost-proposal.md` | HUMANO | CONCLUÍDO (2026-10-17): opção A — `Standard Price Book` |
| F0-12 | Viabilidade de moeda (USD × BRL) | — | Verificar moeda corporativa, ACM, moeda de price books/entradas/cotações, efeito em roll-ups e limites de org trial; emitir veredito | IA | CONCLUÍDO (2026-10-17): manter USD, não tocar na moeda corporativa — [`currency-feasibility.md`](currency-feasibility.md) |
| F0-13 | Moeda dos dados do app | **F0-12** | Confirmar `USD` nos dados (BRL só na exibição, via moeda do usuário) ou optar por BRL nativo pelo caminho F0-14 | HUMANO | CONCLUÍDO (2026-10-17): manter `USD` — D18 |
| F0-14 | Price book BRL dedicado (condicional) | **F0-13** | **Só se F0-13 escolher BRL:** criar price book `DD Deal Desk BRL`, entradas em BRL para os 24 produtos e semear custo nelas — sem tocar na moeda corporativa nem nas entradas USD | IA | CANCELADO (2026-10-17): F0-13 manteve `USD`; price book BRL não será criado |

### Fase 1 — Cálculo de margem

| ID | Ação | Predecessores | O que faz | Quem decide | Status |
|---|---|---|---|---|---|
| F1-01 | Probe: roll-up sobre fórmula | **F0-10** | `--dry-run` de 1 campo de roll-up na `Quote` somando campo de fórmula do `QuoteLineItem` — responde **Q1** da [`architecture.md`](architecture.md) §9 | IA | CONCLUÍDO (2026-10-17): **depende** — fórmula **determinística** é agregável (OK); fórmula com **referência cruzada** é recusada (`The summarized field in not deterministic.`). Ver A53 e PRB-002 |
| F1-02 | Probe: fórmula com referência ao preço/custo | **F0-10** | `--dry-run` de 1 fórmula em `QuoteLineItem` lendo `FixedCost__c`/`VariableCostPerUnit__c` do `PricebookEntry` — responde **Q2** | IA | CONCLUÍDO (2026-10-17): **Succeeded** — referência cruzada aceita em Formula Currency. Ver PRB-001 |
| F1-03 | Escolher a abordagem de cálculo | **F1-01**, **F1-02** | Definir: fórmula nativa + roll-up (preferida, sem Flow) ou plano B com Flow; registrar a decisão e o porquê em `MEMORY.md` §2 | IA | CONCLUÍDO (2026-10-17): **híbrido** — fórmula onde é determinística + 1 Flow só para `DD_CostAmount__c`. Decisão **D21** |
| F1-04 | Campos de margem na `QuoteLineItem` | **F1-03** | Criar `DD_CostPerUnit__c`, `DD_CostAmount__c`, `DD_MarginAmount__c`, `DD_MarginPct__c` (nomes a validar), com `--dry-run` antes (S7) | IA | CONCLUÍDO (2026-10-17): 4 campos + FLS + layout, deploy `0Afas00000606y2CAA`. Ver FLD-001 |
| F1-05 | Campos consolidados na `Quote` | **F1-04** | Criar `DD_Revenue__c`, `DD_Cost__c`, `DD_MarginPct__c`, `DD_WorstLineMarginPct__c`, `DD_GuardrailState__c` (este último alimenta o semáforo do console — D14) | IA | CONCLUÍDO (2026-10-17): 5 campos + FLS + layout, mesmo deploy de F1-04 |
| F1-06 | Plano B: Flow de cálculo | **F1-03** | Só se os probes falharem: Flow `RecordBeforeSave` recalculando custo/margem por linha; confirmação dupla (S6) e `--dry-run` | IA | CONCLUÍDO (2026-10-17): `DD_CalculateLineCost` **Active**, `Get Records` no `PricebookEntry` (A55), deploy `0Afas00000604zTCAQ`. Ver FLW-001 |
| F1-07 | Validar as 3 faixas de margem | **F1-04** a **F1-06** | Bater 41,67% / 28,00% / 17,71% contra cálculo manual e conferir que o total da `Quote` fecha com a soma das linhas | IA | CONCLUÍDO (2026-10-17): 41,6667% / 28,0000% / 17,7083%; receita 416 = 416 nativo, custo 293 = soma das linhas. Ver VAL-001 |
| F1-08 | Fechar a Fase 1 | **F1-07** | Atualizar `MEMORY.md` §4 (cache dos campos criados), `execution-log`, este plano e o `roadmap`; commit e tag `fase-1` | IA | CONCLUÍDO (2026-10-17) |

### Fase 2 — Política de desconto

| ID | Ação | Predecessores | O que faz | Quem decide | Status |
|---|---|---|---|---|---|
| F2-01 | Modelar `DD_DiscountPolicy__c` | **F0-10** | Definir campos (família, price book, piso, alvo, teto, alçada, vigência, ativa), tipos, obrigatoriedade e a chave de precedência; piso/alvo vêm de D12 | IA | CONCLUÍDO (2026-10-17): 12 campos; precedência é campo de fórmula `Specificity__c` (3/2/1/0). Decisão **D22** |
| F2-02 | Criar objeto e campos da política | **F2-01** | Deploy do objeto custom + campos + layout; `--dry-run` obrigatório (S7) | IA | CONCLUÍDO (2026-10-17): 12 campos + 2 validações + FLS + layout, deploy `0Afas00000606GVCAY`. **Dry-run pegou 2 erros** (A56, A57). Ver DPM-001 |
| F2-03 | Implementar a precedência | **F2-02** | Mecanismo que resolve a política aplicável: família + price book específico vence família genérica | IA | CONCLUÍDO (2026-10-17): `Specificity__c` derivado + query canônica com `ORDER BY Specificity__c DESC, EffectiveFrom__c DESC LIMIT 1` |
| F2-04 | Criar políticas `DEMO-` | **F2-02**, **F0-04** | Políticas ativas cobrindo as 2 famílias × (genérica + específica por price book), com prefixo `DEMO-` no `Name` (S11) e `CurrencyIsoCode` explícito (A13) | IA | CONCLUÍDO (2026-10-17): 4 políticas, teto 15 genérica / 10 específica. Ver POL-001 e `MEMORY.md` §1.7 |
| F2-05 | Validar a skill `create-discount-policy` | **F2-04** | Criar 1 política real usando a skill e corrigir as divergências do `SKILL.md` encontradas na prática | IA | CONCLUÍDO (2026-10-17): a skill dirigiu as 4 criações; 6 divergências corrigidas (§1 decisão já tomada, §3 nível `All`, §4 nome da genérica, §5 `Specificity__c`, §7 percentual, §8 novo) |
| F2-06 | Testar a precedência | **F2-04** | Uma família com política específica e genérica ao mesmo tempo; conferir qual vence e registrar a evidência | IA | CONCLUÍDO (2026-10-17): 4 cenários — específica vence em `Parts`@Fleet e `Medical`@Standard; genérica resolve sozinha em `Parts`@Retail; família sem política devolve 0 linhas. Ver PRE-001 |
| F2-07 | Fechar a Fase 2 | **F2-05**, **F2-06** | Atualizar `MEMORY.md`, `execution-log`, este plano e o `roadmap`; commit e tag `fase-2` | IA | CONCLUÍDO (2026-10-17) |

### Fase 3 — Guardrail e roteamento

| ID | Ação | Predecessores | O que faz | Quem decide | Status |
|---|---|---|---|---|---|
| F3-01 | Regras de decisão e alçadas | **F0-04** | Definir quem aprova a faixa intermediária, o que conta como bloqueio e se existe exceção acima do teto | HUMANO | CONCLUÍDO (2026-10-17): vermelho sobe ao gerente imediato via `User.ManagerId`, ver D13 |
| F3-02 | Modelar `DD_DiscountRequest__c` | **F3-01** | Campos do pedido: cotação, desconto pedido, **estado do guardrail** (não a margem), snapshot da política aplicada, decisão, status, aprovador, justificativa | IA | CONCLUÍDO (2026-10-17): 18 campos + 3 validações; 8 campos `Policy*__c` de snapshot gravado e **zero** margem/custo/receita. Decisões **D23** (sem número) e **D24** (`Blocked` = falha de roteamento) |
| F3-03 | Criar `DD_DiscountRequest__c` | **F3-02** | Deploy do objeto + campos + numeração; `--dry-run` antes (S7) | IA | CONCLUÍDO (2026-10-17): `Name` AutoNumber `DR-{00000}`; 18 campos + 3 regras + FLS + layout, deploy `0Afas00000606d4CAA` (24/24). **Dry-run pegou 1 erro** de ordem de elemento no Profile. Ver DRE-001 |
| F3-04 | Flow invocável de cálculo | **F1-08** | `DD_CalculateQuoteMargin` (`AutoLaunchedFlow`, **Active**, com `isInput`/`isOutput` explícitos) — é a base da ação de agente da Fase 6 (D8) | IA | CONCLUÍDO (2026-10-17): reescrito com 29 elementos e **5/5 cenários validados** (verde, amarelo, vermelho, precedência nível 1, sem política). Saídas em pontos-base (D27/A62). Ver FLW-003 |
| F3-05 | Flow de roteamento | **F3-01**, **F3-03**, **F3-04** | `DD_RouteDiscountApproval`: cria o pedido, define `Decision__c`/`Status__c`/`Approver__c` e notifica a alçada | IA | CONCLUÍDO (2026-10-17): 28 elementos, subflow do cálculo, cria **ou atualiza** o pedido aberto. Ver RTE-001 |
| F3-06 | Regra de bloqueio sem pedido | **F3-05** | Abaixo do piso **não** cria pedido: devolve o motivo | IA | CANCELADO (2026-10-17): D12 definiu vermelho = **pede aprovação**, não bloqueia; a lógica equivalente é F3-05/F3-10 |
| F3-07 | Canal de notificação do aprovador | **F3-01** | Definir como o aprovador é avisado (template de e-mail ou notificação in-app) sem depender de licença ausente na org | IA | CONCLUÍDO (2026-10-17): ação padrão `emailSimple` (texto plano, sem template, sem ID de org). Falha de envio **não desfaz o pedido** e a mensagem admite a falha |
| F3-08 | Testar 3 cenários ponta a ponta | **F3-05** a **F3-07**, **F3-10** | Verde (auto-aprovado), amarelo (justificativa) e vermelho (aprovação do gestor); evidência com timestamps distintos, contadores e correlação com os dados produzidos (A28) | IA | CONCLUÍDO (2026-10-17): 3/3 OK — verde sem pedido; amarelo criou `DR-00000`; vermelho **atualizou o mesmo pedido** (contagem 1). Ver RTE-001 |
| F3-09 | Fechar a Fase 3 | **F3-08** | Atualizar `MEMORY.md`, `execution-log`, este plano e o `roadmap`; commit e tag `fase-3` | IA | CONCLUÍDO (2026-10-17) — **com ressalva:** a limpeza das 24 versões `Obsolete` ficou bloqueada (CLN-001); a operação não é afetada e as definições estão no baseline |
| F3-10 | Aprovação pelo gerente imediato | **F3-01** | Resolver o aprovador por `User.ManagerId` do dono da cotação e definir o comportamento quando for nulo (hoje **20 de 23** usuários ativos não têm gestor): bloquear o envio ou escalar para fila — D13 | IA | CONCLUÍDO (2026-10-17): escada gerente → dono da política → 1º ativo ≠ solicitante → `Blocked`. **Limitação:** `Profile.Name` não é filtrável (A65), então o 3º degrau não garante admin |

### Fase 4 — Console LWC

| ID | Ação | Predecessores | O que faz | Quem decide | Status |
|---|---|---|---|---|---|
| F4-01 | Desenhar o console | **F3-09** | Definir o que aparece na tela: estado do guardrail, política aplicável e simulador — **sem** margem em % e **sem** custo em valor | HUMANO | CONCLUÍDO (2026-10-17): só `Saudável` / `Requer Justificativa` / `Requer Aprovação`, ver D14 |
| F4-02 | Criar LWC `ddMarginConsole` | **F4-01** | Componente (`.js`, `.html`, `.css`, `.js-meta.xml`) com `targets` `lightning__RecordPage` e `lightning__Tab`; renderiza estado, nunca número de margem; simulador sem DML | IA | CONCLUÍDO (2026-10-17): estado por `getRecord` (só `DD_GuardrailState__c`), simulador e pedido por `lightning-flow`; deploy final `0Afas0000060AiHCAU`. **A67** (status `FINISHED_SCREEN` + `outputVariables` em array) e **A68** (Apex vetado). Ver UI-001 |
| F4-03 | FlexiPage da `Quote` | **F4-02** | Página de registro da cotação com o componente na região principal; ativar para o app do Deal Desk | IA | CONCLUÍDO (2026-10-17): `DD_Quote_Record_Page` (highlights + console + related list + detalhe), ativada **só no app** via `actionOverrides`. **A71** (região sem `<mode>`) e **A72** (app inacessível). Ver UI-001 |
| F4-04 | Tab e app Deal Desk | **F4-02** | `CustomTab` **com `<motif>`** (A39/A47) e `CustomApplication` do Deal Desk | IA | CONCLUÍDO (2026-10-17): aba `DD_Margin_Console` e app `DD_DealDesk`; **A69** (`lwcComponent` sem `c:`) e **A70** (`Custom61` = Castle → `Custom41: Stack of Cash`). Ver UI-001 |
| F4-05 | Ação "Pedir desconto" | **F4-02**, **F3-05** | Botão do console chama o Flow de roteamento e mostra o resultado na tela (sem aprovar nada por conta própria) | IA | CONCLUÍDO (2026-10-17): `lightning-flow` → `DD_RouteDiscountApproval`; decisão, mensagem, pedido e aprovador na tela. Plano A (Apex) barrado por A68/APX-001. Ver UI-002 |
| F4-06 | Testar os 3 estados e o simulador | **F4-03** a **F4-05** | Verde/âmbar/vermelho com dados reais; conferir que o simulador não grava (nenhum DML) e que nenhum número de margem aparece na tela | IA | CONCLUÍDO (2026-10-17): 6/6 no navegador; `DD_DiscountRequest__c` 1→1 e `LastModifiedDate` inalterado; zero número de margem no card. **Achado aberto:** o layout padrão mostra margem/custo ao **admin** → fechar na F5-01. Ver UI-002 |
| F4-07 | Fechar a Fase 4 | **F4-06** | Atualizar `MEMORY.md`, `execution-log`, este plano e o `roadmap`; commit e tag `fase-4` | IA | CONCLUÍDO (2026-10-17) |

### Fase 5 — Acesso, dados e demo

| ID | Ação | Predecessores | O que faz | Quem decide | Status |
|---|---|---|---|---|---|
| F5-01 | Permission set `DD_DealDesk_User` | **F4-07** | Acesso a objetos `DD_`, campos, tab, Flows e LWC — mínimo necessário para vendedor e gerente, **negando leitura** de `DD_MarginPct__c`/`DD_Cost__c`/`DD_CostAmount__c` (D14); confirmação dupla (S6) | IA | CONCLUÍDO (2026-10-17): PS `0PSas000004H6puGAC`, deploy `0Afas0000060D6fCAE` — 22 FLS de leitura (só `DD_GuardrailState__c` entre os campos de número), 5 objetos read-only, aba e app visíveis, 2 Flows habilitados. **Achado A75:** `FieldPermissions` com `readable=false` é descartado pela org em permission set — a negação é do perfil, provada por SOQL (F5-03). Dry-run pegou 3 erros antes da escrita. Ver FLS-001 |
| F5-02 | Massa de demonstração | **F4-07** | 3 cotações: margem confortável, no limite e abaixo do piso, com `Pricebook2Id` explícito (as 31 existentes têm nulo) e linhas com custo real | IA | CONCLUÍDO (2026-10-17): `DEMO-Quote-Demo-Saudavel` `0Q0as0000021mHZCAY` (37,88%) · `DEMO-Quote-Demo-Limite` `0Q0as0000021mFyCAI` (22,50%) · `DEMO-Quote-Demo-Abaixo` `0Q0as0000021mJBCAY` (17,71%), 4 linhas, custo gravado pelo before-save. Ver DEM-001 |
| F5-03 | Validar acesso sem admin | **F5-01**, **F5-02** | Conferir o que um usuário não-admin enxerga e executa, inclusive que a margem numérica não é legível | IA | CONCLUÍDO (2026-10-17): **validação visual feita pelo humano** — como Admin, os campos de custo e margem aparecem; como `Alan FieldTech` (Standard User, janela anônima), os campos **desaparecem por completo** e resta apenas o semáforo. Prova por dado (SOQL de FLS) + prova funcional concordam. Ver FLS-001 e ACES-001 |
| F5-04 | Roteiro de demo (30 min) | **F5-02** | Sequência de cliques e falas, terminando numa decisão de negócio clara | IA | CONCLUÍDO (2026-10-17): [`demo-script.md`](demo-script.md) — 5 blocos cronometrados, falas, Q&A, anexo de prova de FLS e troubleshooting |
| F5-05 | Ensaiar a demo | **F5-04** | Rodar ponta a ponta, medir o tempo e corrigir os atritos encontrados | IA | CONCLUÍDO (2026-10-17): roteiro documentado e dados validados ponta a ponta por API (estados 37,88% / 22,50% / 17,71%, simulações e roteamento); o ensaio de tempo fica com o humano, por decisão dele. Ver ACES-001 |
| F5-06 | Fechar a Fase 5 | **F5-03**, **F5-05** | Atualizar `MEMORY.md`, `execution-log`, este plano e o `roadmap`; commit e tag `fase-5` | IA | CONCLUÍDO (2026-10-17): docs atualizados, commit de fechamento e tag `fase-5` |
| F5-07 | Custo ausente não pode parecer margem perfeita | **F4-07** | Hoje `DD_CostAmount__c` nulo vira margem 100% e a cotação passa **verde** — inclusive com desconto de 90% (achado do teste do humano em 2026-10-17). Tratar dado incompleto como estado próprio (ex.: `Pendente de Custo`) no Flow de cálculo e no campo `DD_GuardrailState__c`, em vez de margem máxima | IA+H | CONCLUÍDO (2026-10-17): literal `Pendente de Custo` na fórmula da `Quote`, checagem **antes** da política no `DD_CalculateQuoteMargin` (decisão `CostPending`), `DD_RouteDiscountApproval` encerra sem pedido, LWC com badge cinza + alerta + envio bloqueado. 5 cenários testados; cotação do teste do humano saiu de `Saudável` para `Pendente de Custo`. Ver FLW-004/UI-003 |
| F5-08 | Custo das entradas BRL | **F5-07** | As 3 entradas **BRL** do Standard Price Book (`MediScan Ventilator`, `Imager`, `Hospital Bed`) não têm `FixedCost__c`/`VariableCostPerUnit__c`; o custo foi semeado só em USD (24 entradas). Decidir entre semear custo proporcional (31% / 34% / 22,08%) ou restringir os testes a cotações USD | HUMANO | CANCELADO (2026-10-17, decisão do humano): não semear BRL — o humano já opera cotações em USD e a F5-07 protege o caso de uma cotação sem custo (estado `Pendente de Custo`, nunca verde). Semear BRL não paga o esforço |
| F5-09 | Massa de demonstração realista (sem `DEMO-`) | F5-06 | Criar 5 cenários completos Oportunidade → Cotação → Itens com nomes em PT-BR, contas reais da org, produtos do `Fleet & Corporate` com custo e `USD` explícito — massa de **demonstração de vendas**, sem o prefixo `DEMO-` (exceção autorizada pelo humano a S11 e a S3/S4). Idempotência por nome da `Opportunity` antes de criar | IA | CONCLUÍDO (2026-10-18): 5 opps · 5 cotações · 17 linhas, 2 Saudável / 2 Requer Justificativa / 1 Requer Aprovação, todas `USD`, custo gravado pelo before-save. Novo aprendizado **A81** (`QuoteLineItem.CurrencyIsoCode` não é gravável). Ver MASSA-001 e `MEMORY.md` §1.9 |
| F5-10 | Hierarquia não-admin e cenários do vendedor | F5-09 | Criar 1 vendedor (Standard User) e 1 gerente comercial (Key Account Manager) em PT-BR, com `ManagerId` do vendedor apontando para o gerente, `DD_DealDesk_User` nos dois, e 3 cenários com o vendedor como dono — para exercitar o **1º degrau** da escada de aprovador (D26), que a massa anterior nunca tocava | IA+H | CONCLUÍDO (2026-10-18): `Renata Almeida` `005as000003piTVAAY` (gerente) e `Bruno Tavares` `005as000003piV7AAI` (vendedor, `ManagerId` = Renata). 3 cenários: 12,5000% (Requer Aprovação), 28,1345% (Requer Justificativa) e 39,6186% (Saudável). Roteamento gerou **DR-00001** e **DR-00002** com `ApproverSource__c = Manager` e aprovador Renata — o 1º degrau provado. Sem `UserRole` e sem metadado novo. Ver MASSA-002 e `MEMORY.md` §1.10 |

### Fase 6 — Camada Agentforce

| ID | Ação | Predecessores | O que faz | Quem decide | Status |
|---|---|---|---|---|---|
| F6-01 | Checar pré-requisitos do agente | **F3-09** | Confirmar Flows `Active` com `isInput`/`isOutput` e que o tipo `GenAiFunction` responde em **API 66.0** (regra das duas versões) | IA | CONCLUÍDO (2026-10-17): `DD_CalculateQuoteMargin` **`Active` v25** com **2** `isInput` e **17** `isOutput`, provados por retrieve da org (não só pelo arquivo local); tipos Agentforce respondem em 66.0 com `GenAiFunction` 1 · `GenAiPlugin` 0 · `GenAiPlannerBundle` 6 |
| F6-02 | Escopo e limites do agente | **F6-01** | Que perguntas responde, o que **nunca** faz (jamais aprovar, jamais exibir margem numérica), tom e limites da resposta | HUMANO | CONCLUÍDO (2026-10-17): nunca aprova, nunca cita margem, ver D15 |
| F6-03 | Deploy da `GenAiFunction` | **F6-02** | Bundle mdapi de 3 arquivos (`-meta.xml` + `input/schema.json` + `output/schema.json`) em API 66.0, pela skill `deploy-agentforce-action`; **não** usar `sf_create_agent_action` (A44) | IA | CONCLUÍDO (2026-10-17): `DD_CalculateMargin` `172as000008FaHtAAK`; dry-run `0Afas0000060DOPCA2` + deploy `0Afas0000060DQ1CAM`. Schema com `marginBp`/`worstLineBp`/`diagnostics` invisíveis ao planner (D15) e `CostPending`/`Pendente de Custo` documentados. Ver AF-001 |
| F6-04 | Retrieve de integridade | **F6-03** | Conferir que os 3 arquivos voltam e fazem parse (A45); se faltar schema, corrigir antes de seguir | IA | CONCLUÍDO (2026-10-17): retrieve 66.0 devolveu os **3 arquivos**, todos fazem parse; input 2/2 e output **17/17** casando com as variáveis da org. Ver AF-001 |
| F6-05 | Tópico do agente (`GenAiPlugin`) | **F6-02**, **F6-04** | Criar o tópico via MCP com as ações e as instruções do §6.3 da [`architecture.md`](architecture.md) | IA | CONCLUÍDO (2026-10-17): `DD_DealDesk_Guardrail` (`179as000000E0rNAAS`) via MCP, com a ação `DD_CalculateMargin` e **11 instruções** (não aprovar, não citar margem, tratar `CostPending`). Ver AF-003 |
| F6-06 | Planner | **F6-05** | Criar/atualizar o planner via MCP com a lista **completa** de tópicos | IA | CONCLUÍDO (2026-10-17): `DDDealDeskPlanner` (`16jas00000061avAAA`), `AiCopilot__ReAct`, com o tópico. **Desvio:** saiu por mdapi, no mesmo bundle do bot, para o vínculo ser atômico e não redeployar o bot com o tipo errado (AF-003). `GenAiPlannerBundle` 6 → **7** |
| F6-07 | Ligar o agente | **F6-06** | `sf_create_agent` com `plannerName`; registrar os IDs em `MEMORY.md` §1.5 | IA | CONCLUÍDO (2026-10-17): o MCP **falhou** (AF-002, erro literal); o agente saiu por bundle mdapi `Bot`+`BotVersion` com `agentType = AgentforceEmployeeAgent` (**D30**). `DDDealDeskAgent` `0Xxas000000AJpNCAW`, v1 `0X9as000000F9kXCAS` **`Active`** (ativação no Builder, **A80**). `Bot` 6 → **7** |
| F6-08 | Testar 3 perguntas reais | **F6-07** | O agente resume o cenário, indica o próximo passo e **não** afirma que aprovou nem cita margem numérica | IA | CONCLUÍDO (2026-10-17): **4/4** no Conversation Preview — `Saudável`/`AutoApproved`, `Requer Aprovação`/`ManagerApproval`, `Pendente de Custo`/`CostPending` e a adversaria de margem/custo, em que o agente **recusou** dar números. Desvio menor: não citou o nome da política → **F6-11**. Ver AF-004 |
| F6-09 | Fechar a Fase 6 | **F6-08** | Atualizar `MEMORY.md`, `execution-log`, este plano, `roadmap` e `README`; commit e tag `fase-6` | IA | CONCLUÍDO (2026-10-17): `MEMORY.md` §1.2/§1.5/§1.6/§2 (D30)/§3 (A79/A80), `execution-log` (AF-003/AF-004), este plano, `roadmap` e `README`; tag `fase-6` |
| F6-10 | Destravar a criação do agente | — | Decidir entre: (a) habilitar/provisionar o template de Service Agent no Setup e repetir F6-07; (b) aceitar a Fase 6 só com a ação de agente; (c) autorizar probe de `Bot` tipo `Employee` via bundle mdapi (a ferramenta MCP não expõe esse tipo) | HUMANO | CONCLUÍDO (2026-10-17): humano autorizou a opção (c); probe executado em AF-003 com sucesso — decisão **D30** |
| F6-11 | Agente deve citar a política e o piso na resposta | **F6-08** | Nas respostas 1 e 2 o agente não citou o nome da política nem o piso no texto (instrução 3 do tópico), embora o trace os exiba. Reforçar a instrução e revalidar as 3 perguntas | IA | PENDENTE — **dívida conhecida, não bloqueia a v1.0** (cosmético: decisão, estado e D15 corretos) |
| F5-11 | Console não roda para usuário não-admin | F5-10 | O `lightning-flow` recusa a execução para não-admin com `FLOW_ACCESS_RESTRICTED` (`currentFlowVersionId` nulo), mesmo com acesso ao Flow, FLS nos campos lidos, `ApiEnabled` e modo sistema. Sem isso a demo "vendedor pede desconto" **não funciona** — F5-03 validou só a tela, nunca o simulador. Resolver por arquitetura: o LWC chama os Flows por Apex | IA+H | **CONCLUÍDO (2026-10-18):** `DD_MarginConsoleController` (`with sharing`, `WITH USER_MODE`, DTOs com whitelist) chama `DD_CalculateQuoteMargin`/`DD_RouteDiscountApproval` por `Flow.Interview`; LWC republicado sem `lightning-flow`; `classAccesses` no `DD_DealDesk_User`. Dry-run e deploy `0Afas0000060FWgCAM`: **10/10 testes**, **73/77 linhas (≈95%)**. `System.runAs` de Standard User no teste prova o caminho não-admin. Nenhum Flow alterado. A causa raiz do gate do componente segue não identificada (A84) — o Apex a contorna. Ver APX-002, D31, A86/A87 |
| F4-08 | Console em qualquer app — FlexiPage como Org Default | **F4-03** | A tela da cotação só aparecia dentro do app Deal Desk (o override vivia no `CustomApplication`). Tornar `DD_Quote_Record_Page` **org default do objeto `Quote`** (desktop + mobile) para valer em qualquer app, sem o vendedor trocar de app | IA | **CONCLUÍDO (2026-10-19):** `CustomObject:Quote` com `View` `Large`/`Small` → `Flexipage`. Dry-run 1 falhou com `null is not a supported form factor.` (**A94**); dry-run 2 + deploy `0Afas00000615NDCAY` passaram 6/6. O `actionOverrides` do `DD_DealDesk` foi mantido. Ver UI-004 |

### Fase 7 — Enforcement do guardrail (aberta em 2026-10-19, a pedido do humano)

> **Origem:** a cotação `0Q0as0000021vHdCAI` foi aceita com **75,73% de desconto** e um
> `DD_DiscountRequest__c` **`Submitted`** (DR-00002) e mesmo assim gerou pedido — pela API e, na UI,
> nada impediria. Verificado: **0** `ApprovalProcess` sobre `Quote` e **0** `ValidationRule` no objeto.
> O guardrail hoje **aconselha e roteia, mas não impede**. O humano escolheu fechar esse gap pelas
> opções 1 (Quote) e 3 (Order) de Q2O-003.
>
> **Restrição técnica que define a solução:** `Validation Rule` **não consulta registros filhos**. Não
> existe fórmula que pergunte "há um `DD_DiscountRequest__c` aprovado para esta cotação?" — é preciso um
> **campo-gate na `Quote`**, mantido por automação, e as validações leem esse campo. Além disso,
> `Quote.Syncing` (`IsSyncing`) é **read-only de plataforma**: não há como validar transição nele; o
> alvo de enforcement é o `Status`.

| ID | Ação | Predecessores | O que faz | Quem decide | Status |
|---|---|---|---|---|---|
| F7-01 | Campo-gate de aprovação na `Quote` | — | Criar `Quote.DD_HasApprovedRequest__c` (Checkbox, default `false`) + Flow record-triggered no `DD_DiscountRequest__c` que o mantém: `true` quando existir request `Status__c = Approved` para a cotação, `false` caso contrário. Entregar na mesma operação: FLS no perfil (D20/S13) e no `DD_DealDesk_User`, e o campo no Page Layout | IA | PENDENTE |
| F7-02 | `ValidationRule` `DD_Block_Unapproved_Quote` | **F7-01** | Bloquear `Status = 'Accepted'` quando `DD_GuardrailState__c` ∈ {`Requer Aprovação`, **`Requer Justificativa`**} **e** `DD_HasApprovedRequest__c = false` (decisões 1 e 2). Gatilho `OR(ISNEW(), ISCHANGED(Status))` — sem grandfathering (decisão 3), e o `ISNEW()` cobre insert direto via API com `Status = Accepted`, que `ISCHANGED` sozinho não pega. Mensagem PT-BR nomeando a pendência | IA | PENDENTE |
| F7-03 | `ValidationRule` `DD_Block_Unapproved_Order` | **F7-01** | Bloquear `Order` com `QuoteId` preenchido quando `Quote.DD_GuardrailState__c` é de risco **e** `Quote.DD_HasApprovedRequest__c = false` (decisão 4: `OR(ISNEW(), AND(ISCHANGED(Status), ISPICKVAL(Status,'Activated')))`). Pedido **sem** cotação de origem não é bloqueado | IA | PENDENTE |
| F7-04 | Varredura de dados + ativação controlada | **F7-02**, **F7-03** | Contar cotações já `Accepted` que violariam a regra (grandfathering), decidir tratamento, e ativar as duas VRs com `--dry-run` + teste em 1 registro de cada tipo | IA+H | PENDENTE |

**Decisões de negócio — TOMADAS em 2026-10-19 para execução em 2026-10-20 (registradas como D34):**

| # | Pergunta | Decisão |
|---|---|---|
| 1 | `Requer Justificativa` também bloqueia? | **Sim** — as duas faixas de risco bloqueiam aceitar; o objetivo é forçar aprovação/justificativa em ambas |
| 2 | O que conta como "aprovado"? | `Status__c` ∈ {**`Approved`, `AutoApproved`**} |
| 3 | Cotações já aceitas? | **Sem tratamento retroativo** — usar `ISCHANGED(Status)` para atuar só em novas transições |
| 4 | `Order`: insert ou ativação? | **Os dois** — `ISNEW()` e transição para `Status = 'Activated'` |

> **Refinamento técnico da decisão 3:** `ISCHANGED(Status)` é falso num **insert**, então uma cotação
> criada já como `Accepted` (via API) passaria. A regra nasce com `OR(ISNEW(), ISCHANGED(Status))` —
> continua sem grandfathering (registros existentes não são tocados, porque nenhum dos dois é verdade
> neles) e fecha o insert direto. Ajuste a validar na execução da F7-02.

### Transversais (contínuas)

| ID | Ação | Predecessores | O que faz | Quem decide | Status |
|---|---|---|---|---|---|
| X-01 | Rastreio por git | — | Convenção D11: toda mudança de arquivo termina em commit descritivo, um assunto por commit | IA | CONCLUÍDO (2026-10-17) |
| X-02 | Manter este plano vivo | — | Atualizar status ao fim de cada ação; novas ações entram com ID novo; progresso (§2) em sincronia com §4 | IA | EM ANDAMENTO (contínuo) |
| X-03 | Rotação do `execution-log` | — | Ao passar de ~500 linhas, rotacionar para `execution-log-AAAA.md` mantendo o índice no arquivo atual | IA | PENDENTE |
| X-04 | Tag `fase-N` ao fechar fase | F0-10 e equivalentes | Criar tag git `fase-N` no commit de fechamento, marcando o marco no histórico | IA | PENDENTE |
| X-05 | FLS + layout obrigatórios ao criar campo | — | D20/S13: todo campo custom novo entrega, **na mesma operação**, `Visible`+`Editable` ao perfil System Administrator **e** entrada no Page Layout padrão; verificação pós-deploy obrigatória | IA | CONCLUÍDO (2026-10-17): convenção 12, guardrail S13, D20 e skill `validate-metadata` atualizada |

---

## 5. Histórico de mudanças deste plano

| Data | Mudança |
|---|---|
| 2026-10-17 | Criação: 61 ações (Fases 0–6 + transversais), 7 decisões humanas identificadas |
| 2026-10-17 | 6 decisões respondidas pelo humano (F0-02, F0-03, F0-04, F3-01, F4-01, F6-02). Fila da §3 caiu para 2 (F0-07, F0-11) |
| 2026-10-17 | F3-06 **cancelada** (D12: vermelho não bloqueia) e criada **F3-10** (aprovação via `User.ManagerId`). Criada **F0-11** (price book de `Medical Equipment`) após a descoberta de que a família não existe no Fleet & Corporate. Total: 61 → 63 ações |
| 2026-10-17 | F0-05/F0-06 concluídas: [`cost-proposal.md`](cost-proposal.md) com 19 entradas propostas |
| 2026-10-17 | F0-12 (viabilidade de moeda) concluída: veredito "manter USD". Criadas **F0-13** (decisão humana) e **F0-14** (price book BRL, condicional). F0-08 passou a depender de F0-13. Total: 63 → 66 ações |
| 2026-10-17 | **Fase 0 fechada:** F0-07 (tabela aprovada), F0-11 (opção A), F0-13 (USD), F0-08 (19 registros), F0-09 (validação), F0-10 (fechamento) e F0-01 (baseline) concluídos. F0-14 cancelada. Criada a **S12** (moeda comprovada). 18 de 66 ações concluídas |
| 2026-10-17 | Criada **X-05** (D20/S13: FLS + layout na mesma operação de criação de campo) e atualizada a skill `validate-metadata`. Verificação de `FixedCost__c`/`VariableCostPerUnit__c`: já estavam com FLS e layout corretos. Total: 66 → 67 ações |
| 2026-10-17 | **F1-01 e F1-02 concluídas** por dry-run: referência cruzada ao `PricebookEntry` é aceita; roll-up sobre fórmula determinística é aceito, mas sobre fórmula com referência cruzada é recusado (A53) |
| 2026-10-17 | **Fase 1 fechada:** 9 campos de margem + FLS + layout (FLD-001), Flow `DD_CalculateLineCost` ativo (FLW-001), 3 faixas validadas (VAL-001). Novos aprendizados A54/A55 e decisão D21. Fase 1: 8 de 8 ações |
| 2026-10-17 | **Fase 2 fechada:** objeto `DD_DiscountPolicy__c` com 12 campos + 2 validation rules + FLS + layout (DPM-001) · 4 políticas `DEMO-` (POL-001) · precedência provada em 4 cenários (PRE-001) · skill `create-discount-policy` validada com 6 correções. Novos aprendizados A56/A57 e decisão D22. Fase 2: 7 de 7 ações |
| 2026-10-17 | **F5-07 concluída** (custo ausente ≠ margem 100%): `Pendente de Custo` na `Quote`, `CostPending` nos dois Flows, badge/alerta no LWC. **F5-08 cancelada** por decisão do humano (operação em USD + F5-07 cobre o caso) |
| 2026-10-17 | **F5-01, F5-02 e F5-04 concluídas:** permission set `DD_DealDesk_User`, 3 cotações de demonstração e o roteiro de 30 min. F5-03 em andamento (prova por dado feita; falta a visual com usuário não-admin). Aprendizado **A75** registrado |
| 2026-10-17 | **Fase 5 fechada:** F5-03 (validação visual do humano), F5-05 (ensaio) e F5-06 (fechamento) concluídas; tag `fase-5`. Fase 6 (Agentforce) liberada |
| 2026-10-17 | **F6-01, F6-03 e F6-04 concluídas:** pré-requisitos provados por retrieve (Flow v25 ativo, 2 `isInput`/17 `isOutput`), bundle mdapi de 3 arquivos deployado (`DD_CalculateMargin`, `172as000008FaHtAAK`) e retrieve de integridade devolvendo os 3 arquivos. Ver AF-001 |
| 2026-10-17 | **F6-05/F6-06/F6-07 bloqueadas** por falha de plataforma: `sf_create_agent` recusa o tipo `EinsteinServiceAgent` (sem acesso ao template), sem deixar resíduo. Criada **F6-10** (decisão humana de desbloqueio) e registrado **A78**. Fase 6: 4 de 10 ações concluídas |
| 2026-10-17 | **v1.0.0 entregue:** F6-11 registrada como dívida conhecida (não bloqueia a v1.0); README com status `v1.0.0 - Entregue`; tag `v1.0.0` |
| 2026-10-17 | **F6-10 decidida e F6-05 a F6-09 concluídas:** humano autorizou o probe de `Bot` Employee; agente `DDDealDeskAgent` criado por mdapi, tópico via MCP, planner no bundle, ativação no Builder. **4/4 perguntas reais** validadas (AF-004). Novas decisões/aprendizados **D30/A79/A80**; aberta **F6-11** (citar a política). Fase 6: 10 de 11 ações |
| 2026-10-18 | **F5-09 criada e concluída:** massa de demonstração realista (5 cenários Oportunidade → Cotação → Itens, PT-BR, sem `DEMO-`, `USD`) por autorização explícita do humano; novo aprendizado **A81**. Total: 71 → 72 ações |
| 2026-10-18 | **F5-10 criada e concluída:** hierarquia não-admin (vendedor Standard User → gerente Key Account Manager) e 3 cenários com o vendedor como dono; roteamento provou o 1º degrau da escada (`ApproverSource__c = Manager`). Total: 72 → 73 ações |
| 2026-10-18 | **F5-11 bloqueada após FLW-006:** acesso aos 2 Flows também concedido no Perfil `Standard` (payload aprovado e dry-run `Succeeded`) — mesmo `FLOW_ACCESS_RESTRICTED`. Nenhuma alavanca de metadata move o gate; **demo será feita pelo Admin**. Aprendizado **A85** (nome de metadata do perfil é `Standard`). |
| 2026-10-18 | **F5-11 aberta e BLOQUEADA:** o console não executa o Flow para usuário não-admin (`FLOW_ACCESS_RESTRICTED`); hipóteses de FLS, acesso ao Flow, `ApiEnabled` e `runInMode` foram descartadas com evidência (FLW-005). Novos aprendizados **A82/A83/A84**. Fase 5 volta a EM ANDAMENTO. Total: 73 → 74 ações |
| 2026-10-18 | **F5-11 CONCLUÍDA (arquitetura Apex):** `DD_MarginConsoleController` + teste cobrem 73/77 linhas (≈95%); LWC migrado de `lightning-flow` para `@salesforce/apex`; `classAccesses` no `DD_DealDesk_User`; deploy `0Afas0000060FWgCAM` com 10/10 testes. Nenhum Flow tocado (`SystemModeWithSharing` vem do `with sharing` da classe — A86). A68 refutado (A87). Ver APX-002 |
| 2026-10-18 | **F5-12 criada e concluída:** tela de aprovação do gerente. `ApprovalProcess DD_Manager_Approval` (aprovador = `Approver__c`, ações finais gravam `Status`/`DecidedAt`), submissão automática no `DD_MarginConsoleController`, `Status__c` opcional + `DD_Request_Status_Required` (A88), FLS de leitura no PS e `DD_ManagerApprovalTest`. Deploy `0Afas0000060Fr...` com 12/12 testes. Total: 74 → 75 ações |
| 2026-10-19 | **UI-004:** `DD_Quote_Record_Page` vira **org default** da `Quote` (desktop `Large` + mobile `Small`) — o console passa a abrir em qualquer app. Aprendizado **A94** |
| 2026-10-19 | **UI-005:** diagnosticado e removido o `AppUsageAssignment` de RLM de 16 cotações (não era efeito de MCP); delete estável, sem re-tag. Aprendizado **A95**, `MEMORY.md` §1.11 |
| 2026-10-19 | **UI-006/UI-007:** related list de itens com coluna **Discount (Percentage)** (layout + `relatedListSingleContainer`/`ADVGRID`, A96) e campos do console iniciando com o desconto atual da cotação |
| 2026-10-19 | **UI-008:** `CreateOrder` habilitado na `platformActionList` e removido de `excludeButtons` — botão não renderiza mesmo assim (Revenue Cloud híbrido) |
| 2026-10-19 | **Q2O-001/Q2O-002:** pedido `00000637` criado via API a partir da cotação aceita (A98: `OrderItem.TotalPrice` não aplica `Discount`); `AppliedDiscount` grava, `AppliedDiscountAmount` não |
| 2026-10-19 | **Fase 7 aberta (F7-01 a F7-04):** enforcement do guardrail — campo-gate na `Quote`, VR `DD_Block_Unapproved_Quote` e VR `DD_Block_Unapproved_Order`. Decisão do humano pelas opções 1 e 3 de Q2O-003. Total: 75 → **79** ações |
