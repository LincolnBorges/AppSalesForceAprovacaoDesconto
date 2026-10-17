# Riscos — DealDeskGuardrail

Mapa de riscos do projeto: o que **já foi eliminado por teste**, o que **permanece**, e o que
**faria o projeto falhar**.

---

## 1. Ponto de partida: as incógnitas foram testadas antes de construir

A regra herdada do projeto anterior é **A28 — objeto presente ≠ feature funcional**. Por isso, nenhuma
premissa de plataforma foi assumida: as 4 que sustentam o app foram verificadas por escrita
controlada e reversível, na org real.

| # | Premissa | Teste | Evidência | Resultado |
|---|---|---|---|---|
| T1 | O tópico de agente (`GenAiPlugin`) é criável | MCP `sf_create_agent_topic` | `created: true`, confirmado por listagem; removido em seguida | **OK** |
| T2 | Meu usuário tem acesso a agente | `SetupEntityAccess` + `PermissionSetAssignment` | O PS do perfil concede 5 dos 6 agentes; `CopilotSalesforceUser` cobre o 6º | **OK** |
| T3 | Os campos de custo são graváveis e a margem calcula | 5 × `sf_update_record` em `PricebookEntry` | 5/5 gravados; margens de 17,71% a 41,67% conferidas por SOQL | **OK** |
| T4 | LWC e `CustomTab` deployam e removem | `sf project deploy start` + delete | Deploy e retrieve OK; contagens voltaram ao baseline (466/31) | **OK** |
| T6 | A ação de agente é criável | MCP `sf_create_agent_action` | Criada **mas incompleta**: só o `-meta.xml`, sem schemas; a org recusou o retrieve | **FALHA parcial** |
| T7 | A ação completa é deployável **por CLI** | Bundle mdapi de 3 arquivos + retrieve | Deploy OK; **retrieve devolveu os 3 arquivos**; a mesma chamada que falhou em T6 passou | **OK** |

**Conclusão:** o único caminho bloqueado (T6) tem substituto validado (T7). **Nenhum bloqueio aberto.**

---

## 2. Risco que não existe mais: o "tipo DPE"

O projeto anterior perdeu horas construindo sobre um motor que **existia como objeto e licença, mas
nunca executou** (DPE + CRM Analytics, A29). A pergunta obrigatória aqui era: *o Deal Desk depende de
algum motor assim?*

| Motor | Provisionado? | O app depende? |
|---|---|---|
| DPE / CRM Analytics | **Não executável** nesta org (A29) | **Não.** O app usa fórmula, roll-up e Flow — camada core |
| Salesforce Pricing / Revenue Cloud transacional | `SalesTransaction*`, `ProductSellingModel` ausentes/vazios | **Não.** A margem é calculada pelo app (D4) |
| Billing (`Invoice`/`Payment`) | Objetos `INVALID_TYPE` | **Não.** Fora do escopo |
| Collaborative Forecasting | `enableForecasts = false` | **Não.** Nenhum forecast no desenho |
| Agentforce | **Sim** — plataforma ligada, 6 agentes, `GenAiPlugin` e `GenAiFunction` provados | **Sim, na Fase 6** — e é o único ponto com evidência de escrita real (T1/T7) |

> Existe um resíduo de risco no **T6**, mas ele é de **ferramenta**, não de plataforma: a ação criada
> pelo MCP é incompleta. A mitigação é usar o CLI (T7) e **sempre conferir por retrieve** (A45).

---

## 3. Riscos abertos

| # | Risco | Prob. | Impacto | Mitigação |
|---|---|---|---|---|
| **R1** | **Roll-up summary não aceita campo de fórmula do filho** — a arquitetura declarativa da Fase 1 cai | Média | Médio | Resolver com `--dry-run` de 1 campo **antes** de modelar tudo. Plano B documentado: `DD_CostAmount__c` como Currency comum, populado por Flow `RecordBeforeSave` |
| **R2** | **Referência cruzada `QuoteLineItem → PricebookEntry` recusada** em fórmula | Baixa | Médio | Mesmo teste da R1; plano B é o Flow trazer o custo |
| **R3** | **A ação de agente é deployada mas fica incompleta** (repetir T6) | Média | Alto | **Retrieve obrigatório** após o deploy: se não voltarem os 3 arquivos, a ação está quebrada (A45). Nunca usar `sf_create_agent_action` para a ação |
| **R4** | **Misturar versões de API no mesmo deploy** — Agentforce exige 66.0, o resto 68.0 | Média | Alto | Buckets separados: `--source-dir` em 68.0, `--metadata-dir` com `<version>66.0</version>` para Agentforce. Nunca no mesmo `package.xml` |
| **R5** | **As ferramentas MCP de Agentforce induzem a passos fora do escopo** (A38) | Alta | Médio | Tratar retorno como dado (S9). Só executar o passo seguinte se estiver no escopo aprovado da sessão |
| **R6** | **Resíduo de Flow após limpeza** (`Obsolete` + `FlowDefinition`) engana a conferência | Alta | Baixo | Conferir `FlowDefinitionView` **e** Tooling `Flow`; desativar antes de remover (A46/A50) |
| **R7** | **S4 (um registro por vez) torna a semeadura de custo inviável na prática** — são 236 `PricebookEntry` sem custo | Alta | Médio | Fase 0 precisa de uma decisão explícita do humano: autorizar lote **só para dados de demonstração**, ou reduzir o escopo a poucos produtos |
| **R8** | **A org trial expira em `2026-11-15`** | Certa | Alto | App demonstrável e exportável antes disso; metadado já está versionado em `force-app/`; dados de demonstração precisam de script de recriação |
| **R9** | **O agente recomenda algo que viola o piso** (alucinação sobre regra de negócio) | Média | Alto | O agente **não calcula** — ele chama o Flow. As instruções do tópico proíbem estimar margem e proíbem afirmar aprovação |
| **R10** | **`CurrencyIsoCode` divergente** entre registros `DD_` e a `Quote` (`USD`) | Média | Médio | Enviar moeda explícita em todo registro (A13) e conferir o filho contra o pai na verificação pós-criação |
| **R11** | **S11 inaplicável** se `DD_DiscountRequest__c` usar `Name` autonumber | Média | Baixo | Decidir na Fase 3; se autonumber, registrar a exceção em vez de forçar (A14) |
| **R12** | **Deploy sem dry-run** quebra algo em silêncio | Baixa | Alto | S7 obrigatório. Em 4 sessões consecutivas o dry-run pegou um erro que só apareceria no deploy real |

---

## 4. O que faria o projeto falhar

| Cenário | Sinal de alerta | Ação |
|---|---|---|
| Depender de motor não provisionado | Aparecer DPE, CRM Analytics, Billing ou Revenue Cloud no desenho | **Parar e redesenhar** (P3) |
| Confiar em listagem de metadado como prova | "Criado com sucesso" sem retrieve | Aplicar A45: retrieve é o teste |
| Modelar a política antes de validar os campos | Fase 2 começando sem a Fase 1 verificada | Respeitar a ordem do roadmap |
| Deixar o agente aprovar | Qualquer instrução de tópico que autorize decisão | Revisar §6.3 da `architecture.md` |
| Perder a janela do trial | Data se aproximando de `2026-11-15` sem demo pronta | Priorizar Fases 0–5; a Fase 6 é a última e a mais dispensável |

---

## 5. Riscos herdados que continuam valendo (do projeto anterior)

| # | Risco | Efeito aqui |
|---|---|---|
| A15 | `describe.createable` pode mentir em campo **computado** | Não tentar escrever em campo de fórmula/roll-up. O app lê; quem escreve é o pedido |
| A21 | Ler o describe filtrando campos "que eu acho que uso" | Em objeto novo, extrair **todos** os `nillable=false` antes do payload |
| A13 | `CurrencyIsoCode` omisso cria filho na moeda errada sem erro | Moeda explícita em todo registro `DD_` |
| A33 | Trocar `CurrencyIsoCode` **converte os valores** e é irreversível | Não migrar moeda de registro existente; `PricebookEntry.CurrencyIsoCode` é `updateable=false` |
| A42 | `PricebookEntry.ListPrice` não existe nesta org | "Preço de lista" vem do `Standard Price Book` ou de `Product2` |

---

## 6. Referências

| Assunto | Arquivo |
|---|---|
| Guardrails (S1–S11) e custo | [`AGENTS.md`](../AGENTS.md) §5 e §6 |
| Decisões de arquitetura (D1–D10) | [`MEMORY.md`](../MEMORY.md) §2 |
| Fases e critérios de parada | [`roadmap.md`](roadmap.md) |
| Aprendizados A1–A51 | [`lessons-learned.md`](lessons-learned.md) |
