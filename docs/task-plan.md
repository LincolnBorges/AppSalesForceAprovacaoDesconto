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

---

## 2. Progresso por fase

| Fase | Nome | Ações | Concluídas | Status |
|---|---|---|---|---|
| 0 | Fundação e base de custo | 11 | 1 | EM ANDAMENTO |
| 1 | Cálculo de margem | 8 | 0 | PENDENTE |
| 2 | Política de desconto | 7 | 0 | PENDENTE |
| 3 | Guardrail e roteamento | 9 | 0 | PENDENTE |
| 4 | Console LWC | 7 | 0 | PENDENTE |
| 5 | Acesso, dados e demo | 6 | 0 | PENDENTE |
| 6 | Camada Agentforce | 9 | 0 | PENDENTE |
| — | Transversais (contínuas) | 4 | 1 | EM ANDAMENTO |
| **Total** | | **61** | **2** | |

*Atualizado em 2026-10-17.*

---

## 3. Fila de decisões humanas

Só estas ações exigem decisão de negócio. Enquanto estiverem `PENDENTE`, as fases seguintes ficam
paradas no ponto indicado.

| ID | Decisão | Bloqueia | Efeito se não houver resposta |
|---|---|---|---|
| F0-02 | Semeadura de custo em lote está autorizada? | F0-08 | 15+ confirmações individuais (S4) ou Fase 0 travada |
| F0-03 | Quais famílias de produto no escopo inicial? | F0-05, F2-04 | Não se sabe onde semear custo nem criar política |
| F0-04 | Piso, alvo e teto de desconto por família | F0-06, F3-01, F2-04 | O semáforo não tem referência: app sem regra de negócio |
| F0-07 | A tabela de custos proposta é aceitável? | F0-08 | Sem validação, custo entra na org com número não acordado |
| F3-01 | Quem aprova a faixa intermediária e o que é bloqueio? | F3-02, F3-05 | Pedido sobe sem alçada definida |
| F4-01 | O console pode exibir custo absoluto ao vendedor? | F4-02 | Componente nasce com premissa de visibilidade errada (o custo é dado sensível) |
| F6-02 | O que o agente pode e não pode dizer/fazer? | F6-03, F6-05 | Risco de o agente parecer que aprova desconto |

---

## 4. Ações

### Fase 0 — Fundação e base de custo

| ID | Ação | Predecessores | O que faz | Quem decide | Status |
|---|---|---|---|---|---|
| F0-00 | Estrutura e documentação do projeto | — | Projeto DX, `AGENTS.md`, `MEMORY.md`, 6 skills e `docs/` criados (INIT-001, sem escrita na org) | IA | CONCLUÍDO (2026-10-16) |
| F0-01 | Baseline de metadados reconferido | — | Recontar `FlowDefinitionView` (total/ativos/locais), LWC, `FlexiPage`, `CustomTab`, `GenAiFunction`/`GenAiPlugin`, `Bot`/Planner e `PricebookEntry` com custo; regravar em `MEMORY.md` §1.6 com a data, porque o baseline de 2026-10-16 já pode ter mudado | IA | PENDENTE |
| F0-02 | Autorizar semeadura em lote | — | Decidir se os custos de demonstração podem ser tratados como **uma** escrita aprovada em lote, com exceção registrada à S4; sem isso são 15+ confirmações uma a uma | HUMANO | PENDENTE |
| F0-03 | Famílias de produto em escopo | — | Quais `ProductFamily` entram no piloto e em qual price book cada uma é semeada (mínimo: 3 famílias em 2 price books, critério da Fase 0) | HUMANO | PENDENTE |
| F0-04 | Piso, alvo e teto por família | **F0-03** | Números de negócio: piso de margem (bloqueio), alvo (auto-aprovação) e teto de desconto permitido; insumo direto de `DD_DiscountPolicy__c` | HUMANO | PENDENTE |
| F0-05 | Levantar base de custo faltante | **F0-03** | Listar as `PricebookEntry` alvo (as 17 do `Fleet & Corporate Pricebook` + 1 família de outro PB) com `Product2`, `UnitPrice`, família e custo atual nulo | IA | PENDENTE |
| F0-06 | Propor tabela de custos | **F0-04**, **F0-05** | Calcular `FixedCost__c` + `VariableCostPerUnit__c` por entrada para produzir margens coerentes com o piso aprovado, cobrindo faixa alta, média e baixa (necessárias para os testes das fases 1 e 3) | IA | PENDENTE |
| F0-07 | Aprovar a tabela de custos | **F0-06** | Validar os números antes de qualquer escrita; última barreira antes do seeding | HUMANO | PENDENTE |
| F0-08 | Semear custo no price book | **F0-02**, **F0-07** | Gravar `FixedCost__c` e `VariableCostPerUnit__c` com `CurrencyIsoCode = USD`, um registro por vez, registrando o valor anterior para rollback (S10) | IA | PENDENTE |
| F0-09 | Validar a semeadura | **F0-08** | Conferir ≥20 entradas com custo, ≥2 price books, ≥3 famílias, todas `USD`; bater a margem de 3 amostras contra o cálculo manual | IA | PENDENTE |
| F0-10 | Fechar a Fase 0 | **F0-09** | Atualizar `MEMORY.md` §1.3/§1.6, `execution-log`, este plano e o `roadmap`; commit e tag `fase-0` | IA | PENDENTE |

### Fase 1 — Cálculo de margem

| ID | Ação | Predecessores | O que faz | Quem decide | Status |
|---|---|---|---|---|---|
| F1-01 | Probe: roll-up sobre fórmula | **F0-10** | `--dry-run` de 1 campo de roll-up na `Quote` somando campo de fórmula do `QuoteLineItem` — responde **Q1** da [`architecture.md`](architecture.md) §9 | IA | PENDENTE |
| F1-02 | Probe: fórmula com referência ao preço/custo | **F0-10** | `--dry-run` de 1 fórmula em `QuoteLineItem` lendo `FixedCost__c`/`VariableCostPerUnit__c` do `PricebookEntry` — responde **Q2** | IA | PENDENTE |
| F1-03 | Escolher a abordagem de cálculo | **F1-01**, **F1-02** | Definir: fórmula nativa + roll-up (preferida, sem Flow) ou plano B com Flow; registrar a decisão e o porquê em `MEMORY.md` §2 | IA | PENDENTE |
| F1-04 | Campos de margem na `QuoteLineItem` | **F1-03** | Criar `DD_CostPerUnit__c`, `DD_CostAmount__c`, `DD_MarginAmount__c`, `DD_MarginPct__c` (nomes a validar), com `--dry-run` antes (S7) | IA | PENDENTE |
| F1-05 | Campos consolidados na `Quote` | **F1-04** | Criar `DD_Revenue__c`, `DD_Cost__c`, `DD_MarginPct__c`, `DD_WorstLineMarginPct__c`, `DD_GuardrailState__c` | IA | PENDENTE |
| F1-06 | Plano B: Flow de cálculo | **F1-03** | Só se os probes falharem: Flow `RecordBeforeSave` recalculando custo/margem por linha; confirmação dupla (S6) e `--dry-run` | IA | PENDENTE |
| F1-07 | Validar as 3 faixas de margem | **F1-04** a **F1-06** | Bater 41,67% / 28,00% / 17,71% contra cálculo manual e conferir que o total da `Quote` fecha com a soma das linhas | IA | PENDENTE |
| F1-08 | Fechar a Fase 1 | **F1-07** | Atualizar `MEMORY.md` §4 (cache dos campos criados), `execution-log`, este plano e o `roadmap`; commit e tag `fase-1` | IA | PENDENTE |

### Fase 2 — Política de desconto

| ID | Ação | Predecessores | O que faz | Quem decide | Status |
|---|---|---|---|---|---|
| F2-01 | Modelar `DD_DiscountPolicy__c` | **F0-10** | Definir campos (família, price book, piso, alvo, teto, alçada, vigência, ativa), tipos, obrigatoriedade e a chave de precedência | IA | PENDENTE |
| F2-02 | Criar objeto e campos da política | **F2-01** | Deploy do objeto custom + campos + layout; `--dry-run` obrigatório (S7) | IA | PENDENTE |
| F2-03 | Implementar a precedência | **F2-02** | Mecanismo que resolve a política aplicável: família + price book específico vence família genérica | IA | PENDENTE |
| F2-04 | Criar políticas `DEMO-` | **F2-02**, **F0-04** | ≥3 políticas ativas cobrindo as famílias semeadas, com prefixo `DEMO-` no `Name` (S11) e `CurrencyIsoCode` explícito (A13) | IA | PENDENTE |
| F2-05 | Validar a skill `create-discount-policy` | **F2-04** | Criar 1 política real usando a skill e corrigir as divergências do `SKILL.md` encontradas na prática | IA | PENDENTE |
| F2-06 | Testar a precedência | **F2-04** | Uma família com política específica e genérica ao mesmo tempo; conferir qual vence e registrar a evidência | IA | PENDENTE |
| F2-07 | Fechar a Fase 2 | **F2-05**, **F2-06** | Atualizar `MEMORY.md`, `execution-log`, este plano e o `roadmap`; commit e tag `fase-2` | IA | PENDENTE |

### Fase 3 — Guardrail e roteamento

| ID | Ação | Predecessores | O que faz | Quem decide | Status |
|---|---|---|---|---|---|
| F3-01 | Regras de decisão e alçadas | **F0-04** | Definir quem aprova a faixa intermediária (papel ou usuário), o que conta como bloqueio e se existe exceção acima do teto | HUMANO | PENDENTE |
| F3-02 | Modelar `DD_DiscountRequest__c` | **F3-01** | Campos do pedido: cotação, desconto pedido, margem calculada, **snapshot** da política aplicada, decisão, status, aprovador, justificativa | IA | PENDENTE |
| F3-03 | Criar `DD_DiscountRequest__c` | **F3-02** | Deploy do objeto + campos + numeração; `--dry-run` antes (S7) | IA | PENDENTE |
| F3-04 | Flow invocável de cálculo | **F1-08** | `DD_CalculateQuoteMargin` (`AutoLaunchedFlow`, **Active**, com `isInput`/`isOutput` explícitos) — é a base da ação de agente da Fase 6 (D8) | IA | PENDENTE |
| F3-05 | Flow de roteamento | **F3-01**, **F3-03**, **F3-04** | `DD_RouteDiscountApproval`: cria o pedido, define `Decision__c`/`Status__c`/`Approver__c` e notifica a alçada | IA | PENDENTE |
| F3-06 | Regra de bloqueio sem pedido | **F3-05** | Abaixo do piso **não** cria pedido: devolve o motivo e não grava nada | IA | PENDENTE |
| F3-07 | Canal de notificação do aprovador | **F3-01** | Definir como o aprovador é avisado (template de e-mail ou notificação in-app) sem depender de licença ausente na org | IA | PENDENTE |
| F3-08 | Testar 3 cenários ponta a ponta | **F3-05** a **F3-07** | Auto-aprovado, aprovação de gerente e bloqueado; evidência com timestamps distintos, contadores e correlação com os dados produzidos (A28) | IA | PENDENTE |
| F3-09 | Fechar a Fase 3 | **F3-08** | Atualizar `MEMORY.md`, `execution-log`, este plano e o `roadmap`; commit e tag `fase-3` | IA | PENDENTE |

### Fase 4 — Console LWC

| ID | Ação | Predecessores | O que faz | Quem decide | Status |
|---|---|---|---|---|---|
| F4-01 | Desenhar o console | **F3-09** | Definir o que aparece na tela: margem atual, piso, alvo, desconto praticado, semáforo e simulador; e o que o vendedor NÃO vê (custo absoluto) | HUMANO | PENDENTE |
| F4-02 | Criar LWC `ddMarginConsole` | **F4-01** | Componente (`.js`, `.html`, `.css`, `.js-meta.xml`) com `targets` `lightning__RecordPage` e `lightning__Tab`, sem DML no simulador | IA | PENDENTE |
| F4-03 | FlexiPage da `Quote` | **F4-02** | Página de registro da cotação com o componente na região principal; ativar para o app do Deal Desk | IA | PENDENTE |
| F4-04 | Tab e app Deal Desk | **F4-02** | `CustomTab` **com `<motif>`** (A39/A47) e `CustomApplication` do Deal Desk | IA | PENDENTE |
| F4-05 | Ação "Pedir desconto" | **F4-02**, **F3-05** | Botão do console chama o Flow de roteamento e mostra o resultado na tela (sem aprovar nada por conta própria) | IA | PENDENTE |
| F4-06 | Testar os 3 estados e o simulador | **F4-03** a **F4-05** | Verde/âmbar/vermelho com dados reais; conferir que o simulador não grava (nenhum DML) | IA | PENDENTE |
| F4-07 | Fechar a Fase 4 | **F4-06** | Atualizar `MEMORY.md`, `execution-log`, este plano e o `roadmap`; commit e tag `fase-4` | IA | PENDENTE |

### Fase 5 — Acesso, dados e demo

| ID | Ação | Predecessores | O que faz | Quem decide | Status |
|---|---|---|---|---|---|
| F5-01 | Permission set `DD_DealDesk_User` | **F4-07** | Acesso a objetos `DD_`, campos, tab, Flows e LWC — mínimo necessário para vendedor e gerente; confirmação dupla (S6) | IA | PENDENTE |
| F5-02 | Massa de demonstração | **F4-07** | 3 cotações: margem confortável, no limite e abaixo do piso, com linhas e custo reais | IA | PENDENTE |
| F5-03 | Validar acesso sem admin | **F5-01**, **F5-02** | Conferir o que um usuário não-admin enxerga e executa; ajustar o permission set para o mínimo viável | IA | PENDENTE |
| F5-04 | Roteiro de demo (30 min) | **F5-02** | Sequência de cliques e falas, terminando numa decisão de negócio clara | IA | PENDENTE |
| F5-05 | Ensaiar a demo | **F5-04** | Rodar ponta a ponta, medir o tempo e corrigir os atritos encontrados | IA | PENDENTE |
| F5-06 | Fechar a Fase 5 | **F5-03**, **F5-05** | Atualizar `MEMORY.md`, `execution-log`, este plano e o `roadmap`; commit e tag `fase-5` | IA | PENDENTE |

### Fase 6 — Camada Agentforce

| ID | Ação | Predecessores | O que faz | Quem decide | Status |
|---|---|---|---|---|---|
| F6-01 | Checar pré-requisitos do agente | **F3-09** | Confirmar Flows `Active` com `isInput`/`isOutput` e que o tipo `GenAiFunction` responde em **API 66.0** (regra das duas versões) | IA | PENDENTE |
| F6-02 | Escopo e limites do agente | **F6-01** | Que perguntas responde, o que **nunca** faz (jamais aprovar sozinho), tom e limites da resposta | HUMANO | PENDENTE |
| F6-03 | Deploy da `GenAiFunction` | **F6-02** | Bundle mdapi de 3 arquivos (`-meta.xml` + `input/schema.json` + `output/schema.json`) em API 66.0, pela skill `deploy-agentforce-action`; **não** usar `sf_create_agent_action` (A44) | IA | PENDENTE |
| F6-04 | Retrieve de integridade | **F6-03** | Conferir que os 3 arquivos voltam e fazem parse (A45); se faltar schema, corrigir antes de seguir | IA | PENDENTE |
| F6-05 | Tópico do agente (`GenAiPlugin`) | **F6-02**, **F6-04** | Criar o tópico via MCP com as ações e as instruções do §6.3 da [`architecture.md`](architecture.md) | IA | PENDENTE |
| F6-06 | Planner | **F6-05** | Criar/atualizar o planner via MCP com a lista **completa** de tópicos | IA | PENDENTE |
| F6-07 | Ligar o agente | **F6-06** | `sf_create_agent` com `plannerName`; registrar os IDs em `MEMORY.md` §1.5 | IA | PENDENTE |
| F6-08 | Testar 3 perguntas reais | **F6-07** | O agente calcula, cita a política aplicada, dá a decisão e **não** afirma que aprovou | IA | PENDENTE |
| F6-09 | Fechar a Fase 6 | **F6-08** | Atualizar `MEMORY.md`, `execution-log`, este plano, `roadmap` e `README`; commit e tag `fase-6` | IA | PENDENTE |

### Transversais (contínuas)

| ID | Ação | Predecessores | O que faz | Quem decide | Status |
|---|---|---|---|---|---|
| X-01 | Rastreio por git | — | Convenção D11: toda mudança de arquivo termina em commit descritivo, um assunto por commit | IA | CONCLUÍDO (2026-10-17) |
| X-02 | Manter este plano vivo | — | Atualizar status ao fim de cada ação; novas ações entram com ID novo; progresso (§2) em sincronia com §4 | IA | EM ANDAMENTO (contínuo) |
| X-03 | Rotação do `execution-log` | — | Ao passar de ~500 linhas, rotacionar para `execution-log-AAAA.md` mantendo o índice no arquivo atual | IA | PENDENTE |
| X-04 | Tag `fase-N` ao fechar fase | F0-10 e equivalentes | Criar tag git `fase-N` no commit de fechamento, marcando o marco no histórico | IA | PENDENTE |

---

## 5. Histórico de mudanças deste plano

| Data | Mudança |
|---|---|
| 2026-10-17 | Criação: 61 ações (Fases 0–6 + transversais), 7 decisões humanas identificadas |
