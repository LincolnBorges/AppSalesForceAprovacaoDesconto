# DealDeskGuardrail

App Salesforce que impede a erosão de margem por desconto em cotações de venda.

> **Status: v1.1.0 - Entregue** (2026-10-20). Fases 0 a 7 concluídas. O app está na org `personal`:
> política, flows de margem e roteamento, console LWC, permission set, massa de demonstração, o agente
> Agentforce `DDDealDeskAgent` **ativo** e o **enforcement do guardrail**: aceitar cotação em faixa de
> risco sem pedido aprovado é bloqueado na `Quote` e no `Order` (campo-gate + Flow + 2 Validation Rules).
> **Dívidas conhecidas (não bloqueiam a v1.1):** F6-11 — o agente não cita o nome da política no texto;
> F7-05 — ativação de `Order`/delete de pedido aprovado ainda não cobertos.
> Plano completo em [`docs/roadmap.md`](docs/roadmap.md) e o histórico de operações em
> [`docs/execution-log.md`](docs/execution-log.md).

---

## O problema

O vendedor monta uma cotação, ouve do cliente um pedido de desconto e decide — sem enxergar o custo
do produto. A margem do negócio só aparece depois, no fechamento financeiro, quando não há mais o que
negociar.

O Salesforce padrão não resolve isso:

| O que existe | Por que não basta |
|---|---|
| `Approval Process` | Decide por **campos do registro** (`Amount`, `Discount`), não por **margem**. Não sabe o custo do produto |
| `PricebookEntry` | **Não tem campo de custo padrão.** O preço existe; o custo, não |
| `CPQ` | Resolveria com *discount schedules* — mas é **licença separada** e não está instalada na org |
| Relatórios | Mostram o desconto **depois** de concedido, não no momento da decisão |

## A solução

Quatro camadas, cada uma resolvendo uma parte:

| Camada | O que entrega | Tecnologia |
|---|---|---|
| **Dados** | Política de desconto (piso de margem por família × price book) e o registro do pedido de desconto | Objetos custom `DD_*__c` + os campos de custo já existentes no `PricebookEntry` |
| **Lógica** | Calcula a margem por linha, compara com o piso e decide em **4 desfechos**: `Saudável`, `Requer Justificativa`, `Requer Aprovação` e `Pendente de Custo` | Flow (`AutoLaunchedFlow` com `isInput`/`isOutput`) |
| **UI** | Console na cotação: margem por linha, semáforo de desconto e simulador | LWC + `FlexiPage` na `Quote` |
| **IA** | O vendedor pergunta em linguagem natural; o agente calcula, aponta a política e recomenda — o humano decide | Agentforce (`GenAiFunction` + `GenAiPlugin` + planner) |

**Princípio de design:** o agente nunca aprova. Ele calcula, contextualiza e recomenda. A decisão
continua com o gerente, e fica registrada.

## Por que este app é viável nesta org

Todas as premissas foram verificadas por teste controlado antes de escrever a primeira linha:

| Premissa | Como foi validada | Resultado |
|---|---|---|
| Os campos de custo são graváveis | Escrita real em 5 `PricebookEntry` (T3) | OK |
| O cálculo de margem fecha | Fórmula conferida por SOQL: 17,71% a 41,67% | OK |
| LWC + `CustomTab` deployam | Deploy e retrieve de um componente de teste (T4) | OK |
| O tópico do agente é criável | `GenAiPlugin` criado e removido (T1) | OK |
| A ação do agente é deployável | Bundle de 3 arquivos deployado **e recuperado** por CLI (T7) | OK |
| Nada depende de motor bloqueado | DPE/CRM Analytics, Billing e Revenue Cloud transacional estão fora do desenho | OK |

Detalhamento e evidências: [`docs/risks.md`](docs/risks.md).

## Estrutura do repositório

```
DealDeskGuardrail/
├── AGENTS.md              # regras, guardrails, convenções (leitura automática)
├── PREFERENCES.md         # idioma, tom, formato (leitura automática)
├── SKILLS.md              # índice de skills e tools MCP (leitura automática)
├── MEMORY.md              # IDs, decisões, aprendizados, cache de metadados
├── .dsh/
│   ├── config.yaml        # política de custo e segurança do projeto
│   └── skills/            # 6 skills operacionais
├── docs/
│   ├── architecture.md    # camadas e decisões de arquitetura
│   ├── roadmap.md         # fases 0 a 6
│   ├── risks.md           # riscos e mitigações (o que já caiu, o que resta)
│   ├── lessons-learned.md # aprendizados A1–A51 herdados, contextualizados
│   ├── glossary.md        # termos de negócio e técnicos
│   ├── execution-log.md   # auditoria de toda operação
│   └── artifacts/         # receitas e templates validados
├── force-app/             # metadados versionados (DX)
├── mdapi/                 # bundle mdapi da ação de agente (GenAiFunction, API 66.0)
├── mdapi-f6bot/           # bundle mdapi do agente (Bot + BotVersion + GenAiPlannerBundle)
├── config/                # definição de scratch org (não usada — ver AGENTS.md §3)
├── scripts/               # SOQL e Apex de apoio
└── sfdx-project.json      # manifesto DX (sourceApiVersion 68.0)
```

## Org alvo

| Item | Valor |
|---|---|
| Alias | `personal` |
| Org ID | `00Das00000GrzvPEAR` |
| Tipo | Enterprise Edition **trial** (`IsSandbox = false`) |
| Expira em | **2026-11-15** |
| Moeda de trabalho | `USD` |

Nunca operar em produção (guardrail S1). A org é trial e expira — o app precisa estar demonstrável e
exportável dentro dessa janela.

## Começando

```bash
# 1. Confirmar a org (nunca escrever sem isto)
sf org display --target-org personal

# 2. Conferir a identidade e o trial
sf data query -o personal \
  -q "SELECT Id, IsSandbox, OrganizationType, TrialExpirationDate FROM Organization"

# 3. Ler as regras antes de qualquer operação
#    AGENTS.md §5 (guardrails) e §6 (custo)
```

O agente segue o fluxo: **elicitação → descoberta → validação → confirmação → execução → registro**
([`AGENTS.md`](AGENTS.md) §7).

## Documentação

| Assunto | Arquivo |
|---|---|
| Regras, guardrails, convenções | [`AGENTS.md`](AGENTS.md) |
| Arquitetura do app | [`docs/architecture.md`](docs/architecture.md) |
| Fases de construção | [`docs/roadmap.md`](docs/roadmap.md) |
| Riscos e mitigações | [`docs/risks.md`](docs/risks.md) |
| Conhecimento herdado (A1–A51) | [`docs/lessons-learned.md`](docs/lessons-learned.md) |
| Glossário | [`docs/glossary.md`](docs/glossary.md) |
| Auditoria de operações | [`docs/execution-log.md`](docs/execution-log.md) |
