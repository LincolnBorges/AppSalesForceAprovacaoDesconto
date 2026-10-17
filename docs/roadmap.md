# Roadmap — DealDeskGuardrail

Plano de construção em 7 fases (0 a 6). Cada fase tem objetivo, entregáveis, critério de verificação e
definição de pronto. **Uma fase por sessão** (`new_session_after_task: true`, C3).

> **Estado geral:** nenhuma fase iniciada. As 4 incógnitas de plataforma foram eliminadas por teste
> antes de começar — ver [`risks.md`](risks.md).
>
> **Acompanhamento fino:** este roadmap guarda os critérios macro de cada fase. O passo a passo
> executável — IDs, predecessores, responsável (IA ou humano) e status — está em
> [`task-plan.md`](task-plan.md), que é a lista viva de acompanhamento.

| Fase | Nome | Depende de | Status |
|---|---|---|---|
| 0 | Fundação e base de custo | — | PENDENTE |
| 1 | Cálculo de margem | 0 | PENDENTE |
| 2 | Política de desconto | 1 | PENDENTE |
| 3 | Guardrail e roteamento | 2 | PENDENTE |
| 4 | Console LWC | 3 | PENDENTE |
| 5 | Acesso, dados e demo | 4 | PENDENTE |
| 6 | Camada Agentforce | 5 | PENDENTE |

---

## Fase 0 — Fundação e base de custo

**Objetivo:** deixar o projeto pronto para receber metadado e a base de cálculo com massa suficiente.

**Entregáveis**
1. (`OK` — feito na sessão de estruturação) Estrutura do projeto, `AGENTS.md`, `MEMORY.md`, skills.
2. Pergunta ao humano: **qual o piso de margem padrão** e **quais famílias** entram no escopo inicial.
3. Estender a semeadura de custo nas `PricebookEntry`: hoje **5 de 241** têm `FixedCost__c`. Meta
   mínima: as 17 entradas do `Fleet & Corporate Pricebook` + 1 família completa de outro price book.
4. Confirmar a **moeda** das entradas-alvo (`USD`) e a política de moeda (D5).

**Verificação**
```sql
SELECT COUNT() FROM PricebookEntry WHERE FixedCost__c != null
-- esperado: > 5 (hoje 5)
SELECT Pricebook2Id, CurrencyIsoCode, COUNT(Id)
FROM PricebookEntry WHERE FixedCost__c != null GROUP BY Pricebook2Id, CurrencyIsoCode
```

**Pronto quando:** ≥ 20 `PricebookEntry` com custo, todas em `USD`, distribuídas em ≥ 2 price books e
≥ 2 famílias de produto — o suficiente para a política ter o que comparar.

> **Revisão de 2026-10-17:** a meta original era "≥ 3 famílias"; o humano definiu **2 famílias**
> (`Parts` e `Medical Equipment`, D17). O critério passa a ser 2 famílias — a precedência da Fase 2
> continua testável porque são 2 famílias em 2 price books diferentes.

**Atenção:** S4 manda **um registro por vez**. Semear 15+ registros = 15+ confirmações. Definir com o
humano se a semeadura de dados de demonstração pode ser autorizada em lote (é a única forma prática).

---

## Fase 1 — Cálculo de margem

**Objetivo:** a margem por linha e por cotação existe e está correta, sem Flow se for possível.

**Entregáveis**
1. Resolver **Q1 e Q2** de [`architecture.md`](architecture.md) §9: a org aceita roll-up summary
   sobre campo de fórmula do filho? `QuoteLineItem` aceita fórmula com referência cruzada ao
   `PricebookEntry`? (`--dry-run` de 1 campo responde.)
2. Campos em `QuoteLineItem`: `DD_CostPerUnit__c`, `DD_CostAmount__c`, `DD_MarginPct__c`.
3. Campos em `Quote`: `DD_Revenue__c`, `DD_Cost__c`, `DD_MarginPct__c`, `DD_WorstLineMarginPct__c`,
   `DD_GuardrailState__c`.
4. Se o roll-up sobre fórmula **não** for aceito: plano B com Flow `RecordBeforeSave`.

**Verificação:** criar/atualizar 1 `QuoteLineItem` nas 18 `Quote` em `Draft`, calcular na mão
(`(UnitPrice − FixedCost − VariableCost) / UnitPrice`) e comparar com o campo. Testar com 1 linha em
cada faixa: margem alta (41,67%), média (28%) e baixa (17,71%).

**Pronto quando:** os 3 cenários batem com o cálculo manual e o roll-up da `Quote` fecha com a soma
das linhas.

**Risco principal:** A15 — campo computado que o describe diz gravável. Aqui o risco é o inverso
(fórmula que a org recusa criar), e o `--dry-run` resolve.

---

## Fase 2 — Política de desconto

**Objetivo:** existir a política que define o piso, e uma forma confiável de criá-la.

**Entregáveis**
1. Objeto `DD_DiscountPolicy__c` com os campos de [`architecture.md`](architecture.md) §3.1.
2. Skill `create-discount-policy` validada na prática (criar 1 política real via skill).
3. Regra de **precedência** documentada e implementada: família + price book específico vence
   família genérica.
4. Dados: no mínimo 1 política por família em escopo, com `DEMO-` no `Name` (S11).

**Verificação**
```sql
SELECT Name, ProductFamily__c, Pricebook__c, FloorMarginPct__c, MaxDiscountPct__c, IsActive__c
FROM DD_DiscountPolicy__c ORDER BY ProductFamily__c
```

**Pronto quando:** ≥ 3 políticas ativas, cobrindo as famílias semeadas na Fase 0, e a precedência
testada (uma família com política específica e uma genérica ao mesmo tempo).

---

## Fase 3 — Guardrail e roteamento

**Objetivo:** a decisão existe e o pedido abaixo do piso sobe com contexto.

**Entregáveis**
1. Objeto `DD_DiscountRequest__c` (§3.2) — com **snapshot** de política e margem.
2. Flow `DD_CalculateQuoteMargin` (`AutoLaunchedFlow`, **Active**, com `isInput`/`isOutput` — D8).
3. Flow `DD_RouteDiscountApproval` (`AutoLaunchedFlow`, **Active**) — cria o pedido, define
   `Decision__c` / `Status__c` / `Approver__c`, notifica a alçada.
4. Três estados de saída, definidos em 2026-10-17 (D12/D13/D14):
   `Saudável` (verde, ≥ alvo) · `Requer Justificativa` (amarelo, piso ≤ m < alvo) ·
   `Requer Aprovação` (vermelho, < piso, aprovador = `User.ManagerId` do dono).
   **Não há mais estado `Blocked`** — o vermelho sobe para aprovação, não é impedido.

**Verificação:** 3 cenários ponta a ponta —
| Cenário | Margem | Esperado |
|---|---|---|
| Acima do alvo | ≥ `TargetMarginPct__c` | `Saudável`: envio liberado, notifica o vendedor |
| Entre piso e alvo | `Floor` ≤ m < `Target` | `Requer Justificativa`: cria pedido com justificativa obrigatória |
| Abaixo do piso | < `FloorMarginPct__c` | `Requer Aprovação`: cria pedido e notifica o **gerente imediato** (`User.ManagerId`) |

**Pronto quando:** os 3 cenários produzem o resultado esperado, o pedido registra a política aplicada
e o `--dry-run` dos dois Flow passou antes do deploy (S6/S7).

---

## Fase 4 — Console LWC

**Objetivo:** o vendedor enxerga o impacto antes de pedir.

**Entregáveis**
1. LWC `ddMarginConsole` (`.js`, `.html`, `.js-meta.xml`) com `targets` `lightning__RecordPage` e
   `lightning__Tab`.
2. `FlexiPage` da `Quote` com o componente na região principal.
3. `CustomTab` — **com `<motif>`** (A39/A47) — e `CustomApplication` do Deal Desk.
4. Semáforo visual: verde (≥ alvo), âmbar (entre piso e alvo), vermelho (< piso).
5. Simulador: campo de desconto pretendido que mostra a margem resultante **sem gravar nada**.

**Verificação:** deploy com `--dry-run` primeiro; abrir uma `Quote` na FlexiPage e conferir os 3
estados; conferir que o simulador não escreve (nenhum DML no componente).

**Pronto quando:** o console renderiza os 3 estados com dados reais e o botão *Pedir desconto*
dispara o Flow da Fase 3.

---

## Fase 5 — Acesso, dados e demo

**Objetivo:** o app é utilizável por outra pessoa e demonstrável em 30 minutos.

**Entregáveis**
1. Permission set `DD_DealDesk_User` com acesso a: objetos `DD_`, campos, LWC, tab e Flow.
2. Massa de demonstração: 1 cotação com margem confortável, 1 no limite e 1 abaixo do piso.
3. Roteiro de demo escrito (o que clicar, em que ordem, o que dizer).
4. Revisão da `FlexiPage`/`CustomTab` para o app abrir direto no que importa.

**Verificação:** atribuir o permission set a um usuário de teste (ou conferir por describe efetivo) e
percorrer os 3 cenários como um vendedor faria, sem acesso de admin.

**Pronto quando:** a demo roda de ponta a ponta em ≤ 30 min, terminando numa decisão de negócio clara.

---

## Fase 6 — Camada Agentforce

**Objetivo:** o vendedor pergunta em linguagem natural e recebe o cálculo com a política aplicável.

**Entregáveis**
1. Verificar que os Flow das fases 1 e 3 estão **Active** e com `isInput`/`isOutput` (D8).
2. `GenAiFunction` em bundle de 3 arquivos, **mdapi, API 66.0** — usar a receita de
   [`artifacts/`](artifacts) e a skill `deploy-agentforce-action`.
3. **Retrieve de validação** — se voltarem os 3 arquivos, está íntegro (A45/A49).
4. Tópico `GenAiPlugin` via MCP (`sf_create_agent_topic`) com ações + instruções (§6.3 da
   `architecture.md`).
5. Planner via MCP (`sf_create_agent_planner`) com a lista **completa** de tópicos.
6. Link final com `sf_create_agent` + `plannerName`.

**Verificação:** perguntar ao agente, em linguagem natural, sobre o desconto de uma cotação real dos 3
cenários. O agente deve: calcular, citar a política aplicada, dar a decisão e **não** afirmar que
aprovou.

**Pronto quando:** as 3 perguntas produzem resposta correta e o agente nunca aprova sozinho.

**Riscos desta fase:** A38 (instruções imperativas das ferramentas MCP — ignorar), A43/A44 (não usar
`sf_create_agent_action`), A46/A50 (conferir resíduo de Flow ao limpar), e a **regra das duas versões
de API** (66.0 só para Agentforce).

---

## Critérios de parada (quando NÃO avançar)

| Situação | Ação |
|---|---|
| `--dry-run` falha | Corrigir e repetir; **nunca** deployar sem dry-run limpo (S7) |
| Retrieve do `GenAiFunction` não devolve os 3 arquivos | Parar; a ação está incompleta (A45). Corrigir o bundle antes de seguir |
| Alguma fase exige DPE, CRM Analytics, Billing ou Revenue Cloud transacional | Parar e redesenhar (P3/A28/A29) |
| Aparece objeto/campo que só existe com licença não provisionada | Parar e reportar; não improvisar alternativa |
| A org exibe `TrialExpirationDate` no passado | A org expirou: nenhuma escrita; reportar e replanejar |
