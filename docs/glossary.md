# Glossário — DealDeskGuardrail

Termos de negócio e técnicos usados neste projeto. Ordem alfabética dentro de cada bloco.

---

## 1. Negócio

| Termo | Definição |
|---|---|
| **Deal Desk** | Função comercial (pessoas + processo) que avalia e aprova condições não-padrão de um negócio — desconto, prazo, condição de pagamento. É o "balcão" onde o vendedor pede exceção. |
| **Margin guardrail** | Regra que impede a concessão de desconto que derrube a margem abaixo de um piso definido, sem que alguém com alçada aprove. É o que este app implementa. |
| **Margem (de contribuição)** | `(Preço de venda − Custo) / Preço de venda`, em %. Neste app, `Custo = FixedCost__c + VariableCostPerUnit__c`. |
| **Custo fixo (`FixedCost__c`)** | Parcela do custo que não varia com a quantidade vendida (setup, ferramental, frete dedicado). Campo custom no `PricebookEntry`. |
| **Custo variável unitário (`VariableCostPerUnit__c`)** | Parcela do custo que se repete a cada unidade vendida (material, mão de obra direta). Campo custom no `PricebookEntry`. |
| **Desconto** | Diferença entre o preço de lista e o preço praticado. Neste app, `QuoteLineItem.Discount` (percentual) e `QuoteLineItem.DiscountAmount` (valor). |
| **Piso de margem (`FloorMarginPct__c`)** | Margem mínima aceitável para um conjunto família × price book. Abaixo dela, o pedido exige aprovação. |
| **Margem alvo (`TargetMarginPct__c`)** | Margem que o negócio quer atingir. Serve de referência para a recomendação do agente. |
| **Desconto máximo (`MaxDiscountPct__c`)** | Teto absoluto de desconto; acima dele, o pedido é bloqueado, não escalado. |
| **Price book** | Catálogo de preços. A mesma `Product2` pode ter preço diferente em cada price book — a org tem **9 ativos**. É o proxy de segmento/canal neste app. |
| **Família de produto (`Product2.Family`)** | Agrupamento comercial do produto (Generator, Parts, Medical Equipment…). A org tem **14 famílias**. É a dimensão principal da política de desconto. |
| **Cotação (`Quote`)** | Proposta comercial com preços, vinculada a uma `Opportunity`. É o objeto onde o app atua. |
| **Pedido de desconto** | Registro criado quando o vendedor pede uma condição fora do piso. Objeto `DD_DiscountRequest__c`. |
| **Alçada** | Quem pode aprovar cada faixa de exceção (gerente, diretor, pricing). |
| **Erosão de margem** | Perda acumulada de rentabilidade por descontos concedidos sem critério. É a dor que o app ataca. |
| **SLA de aprovação** | Prazo máximo para o aprovador responder antes de o pedido escalar. |
| **Human-in-the-loop** | Padrão de desenho em que o agente recomenda e o humano decide. Neste app, o agente **nunca** aprova. |

---

## 2. Salesforce — dados e objetos

| Termo | Definição |
|---|---|
| **`PricebookEntry`** | Preço de um `Product2` dentro de um `Pricebook2`. É onde vivem `UnitPrice` e os dois campos de custo. |
| **`QuoteLineItem`** | Linha da cotação. Onde o app calcula e grava margem (`UnitCost`, `Margin`, `MarginAmount`). |
| **`OpportunityLineItem`** | Linha da oportunidade. **Não tem campo `Discount`** nesta org — motivo pelo qual o app opera na `Quote`. |
| **`OpportunityLineItemSchedule`** | Cronograma de receita por linha. **Não** é caminho de faturamento: Billing não existe nesta org. |
| **Record-Triggered Flow** | Flow disparado por criação/atualização/exclusão de registro. Mantém o roll-up de margem atualizado. |
| **`AutoLaunchedFlow`** | Flow sem interface, chamável por outro Flow, Apex ou por um agente. **É o único tipo que um agente Agentforce consegue invocar.** |
| **`isInput` / `isOutput`** | Marcação de uma variável de Flow como entrada/saída. Define o schema da ação do agente — **declarar desde o início** (D8). |
| **`GenAiFunction`** | Metadado que descreve uma ação de agente. **É um bundle de 3 arquivos**, não um XML só: `-meta.xml` + `input/schema.json` + `output/schema.json`. |
| **`GenAiPlugin`** | Metadado de **tópico** de agente: agrupa ações e define escopo e instruções. |
| **Planner (`GenAiPlannerBundle`)** | Liga o agente aos seus tópicos. Sem ele o agente **não roteia nada**. |
| **`BotDefinition` / `BotVersion`** | O agente propriamente dito e sua versão publicada. |
| **`BotDefinition` (em `SetupEntityAccess`)** | O mecanismo real de **acesso** a um agente. Não é o permission set `AgentAccess1`. |
| **FLS (Field-Level Security)** | Permissão por campo. Verificar pelo `describe` efetivo do usuário, não pela tabela de permissões (A15/A41). |
| **Roll-up summary** | Campo calculado que soma valores dos filhos. **Não confundir** com campo computado do Flow: o app calcula em Flow. |

---

## 3. Salesforce — plataforma e operação

| Termo | Definição |
|---|---|
| **Metadata API** | API que lê/escreve a **definição** dos componentes (objetos, flows, LWCs). Um deploy pode ter sucesso e o componente ainda estar incompleto — por isso o **retrieve é o teste de integridade** (A45). |
| **Tooling API** | API de introspecção e operação sobre metadados ativos. Usada para ler versões de Flow e apagar versão `Obsolete`. |
| **mdapi (metadata format)** | Formato de diretório "achatado" (`genAiFunctions/<Nome>/…` + `package.xml`). É o formato que a org **devolve** — espelhá-lo elimina dúvida de convenção (A48). |
| **DX source format** | Formato do projeto (`force-app/main/default/<tipo>/…`), com `sfdx-project.json`. |
| **`--dry-run` (check-only)** | Valida um deploy sem gravar. **Obrigatório antes de todo deploy** (S7). Já pegou 4 erros que só apareceriam depois. |
| **`FlowDefinitionView`** | Visão de leitura sobre as definições de Flow (nome, tipo, `IsActive`, trigger). Usar **junto** com a Tooling API ao limpar Flow (A46). |
| **`Obsolete` (versão de Flow)** | Versão antiga que sobra após um redeploy. Não aparece na listagem de metadados, mas consome o nome e engana a conferência de resíduo. |
| **`INVALID_TYPE`** | Erro de "objeto/tipo não existe nesta org". Distinto de *"Cannot use … in this version"*, que significa que o tipo existe mas não naquela versão de API. |
| **Trial org** | Org de avaliação com `TrialExpirationDate`. **Não é produção** — é o alvo autorizado deste projeto (S1). |
| **`DEMO-` (prefixo)** | Marca obrigatória em todo registro criado pelo agente cujo `Name` seja gravável (S11), para separar do que é nativo da org. |
| **`DD_` (prefixo)** | Prefixo de todo metadado custom deste projeto. |
| **DPE (Data Processing Engine)** | Motor de agregação de dados da Salesforce. **Bloqueado nesta org** — nenhum componente do app pode depender dele. |
| **CRM Analytics (CRMA)** | Camada de analytics sobre a qual as DPEs executam. **Não provisionada de forma utilizável nesta org.** |
| **Resíduo** | Metadado que sobrevive a uma remoção (ex.: versão `Obsolete` de Flow). Conferir sempre após limpeza (A46). |

---

## 4. Referências

| Assunto | Arquivo |
|---|---|
| Regras e guardrails | [`AGENTS.md`](../AGENTS.md) |
| Arquitetura | [`architecture.md`](architecture.md) |
| Riscos | [`risks.md`](risks.md) |
| Conhecimento herdado | [`lessons-learned.md`](lessons-learned.md) |
