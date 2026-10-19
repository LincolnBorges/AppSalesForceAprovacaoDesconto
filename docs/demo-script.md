# Roteiro de Demonstração — Deal Desk Guardrail (30 min)

Roteiro de execução da demo do app, com cliques, falas e evidências. Escrito para ser seguido por
quem já conhece o produto (não é material de treinamento). Ambiente: org `personal`
(`00Das00000GrzvPEAR`), app **Deal Desk**.

**Objetivo da demo:** mostrar que o vendedor deixa de conceder desconto no escuro — o app dá o estado
do guardrail antes do pedido, sobe o caso ruim com contexto para a alçada e **nunca decide sozinho**.

**O que a demo prova, em uma frase por bloco:**

| Bloco | Prova |
|---|---|
| 1 | O Salesforce padrão mostra total e desconto, mas não mostra a margem nem a política |
| 2 | O console dá o estado (verde / amarelo / vermelho) sem expor custo ou margem numérica |
| 3 | O desconto que cruza o piso vira pedido rastreável, com snapshot da política e aprovador nomeado |
| 4 | Custo ausente não vira "margem 100%": vira `Pendente de Custo`, com alerta e envio bloqueado |
| 5 | A decisão é humana e fica registrada (quem, quando, por quê) |

---

## 1. Antes de começar (fora do relógio)

### 1.1 Checklist técnico

| # | Item | Como conferir |
|---|---|---|
| 1 | Login como administrador (`Lincoln Borges`) | avatar no canto superior direito |
| 2 | App **Deal Desk** abre | [abrir o app](https://personalproject.my.salesforce.com/lightning/app/c__DD_DealDesk) — não use o atalho de "Sales" |
| 3 | Console renderiza nas 4 cotações | abrir cada link da §1.3 e ver o card "Guardrail de desconto" |
| 4 | Aba **Console de Margem** visível | item na barra de navegação do app |
| 5 | Zoom do navegador em 100% | o card tem duas colunas no simulador |
| 6 | Uma aba já aberta em `DD_DiscountRequest__c` | §1.4 — para mostrar o pedido criado ao vivo |

### 1.2 Sessão: por que a demo roda como admin

O painel de detalhes padrão da cotação mostra `DD_Cost__c` e `DD_MarginPct__c` **para o
administrador** — isso é intencional e é o que D14 resolve do lado do vendedor: o perfil do vendedor
não tem FLS nesses campos (ver Anexo A). Se a demo for para uma plateia que vai perguntar "e o
vendedor vê isso?", use o Anexo A como resposta, não como bloco da demo.

### 1.3 As quatro cotações da demo

| Papel na demo | Cotação | Id | Receita / Custo | Margem | Estado |
|---|---|---|---|---|---|
| **A** — margem confortável | `DEMO-Quote-Demo-Saudavel` | `0Q0as0000021mHZCAY` | 264 / 164 | 37,88% (pior linha 34,72%) | Saudável |
| **B** — no limite | `DEMO-Quote-Demo-Limite` | `0Q0as0000021mFyCAI` | 160 / 124 | 22,50% | Requer Justificativa |
| **C** — abaixo do piso | `DEMO-Quote-Demo-Abaixo` | `0Q0as0000021mJBCAY` | 192 / 158 | 17,71% | Requer Aprovação |
| **D** — sem custo cadastrado | `Teste cotação` | `0Q0as0000021jtBCAQ` | 58.000 / 0 | não há | Pendente de Custo |

Todas as três `DEMO-Quote-Demo-*` estão no **Fleet & Corporate Pricebook** (`01sas000001nOBJAA2`),
família `Parts`, e resolvem para a política **`DEMO-Policy-Parts-Fleet`**: piso **20%**, alvo **30%**,
teto de desconto de referência **10%**, exige justificativa.

### 1.4 Onde ver o pedido de desconto criado

Não existe aba própria para `DD_DiscountRequest__c` nesta fase. Abra pelo Id que o console devolve ou
por esta consulta (Setup → Developer Console, ou CLI):

```sql
SELECT Id, Name, Quote__r.Name, GuardrailState__c, Decision__c, Status__c,
       Approver__r.Name, ApproverSource__c, PolicyName__c, RequestedDiscountPct__c, CreatedDate
FROM DD_DiscountRequest__c
ORDER BY CreatedDate DESC
LIMIT 5
```

### 1.5 Ajuste opcional (recomendado) para o aprovador ser você

Hoje o dono das cotações é `Lincoln Borges`, que **não tem gestor** na org. A escada de aprovação
(D26) então cai no 3º degrau e resolve o **primeiro usuário ativo por nome** — `Alan FieldTech`, que
não é gerente de ninguém. Para a demo ficar redonda, mude o dono da cotação **B** para uma usuária com
gestor cadastrado:

| Item | Valor |
|---|---|
| Registro | `DEMO-Quote-Demo-Limite` (`0Q0as0000021mFyCAI`) |
| Campo | `OwnerId` |
| Valor | `005as000003pCovAAE` (Mehmood Zac, gestora = Lincoln Borges) |
| Efeito | o pedido sobe pelo **1º degrau** (gestor do dono) e o aprovador exibido é **Lincoln Borges** |
| Reversão | `OwnerId` volta para `005as000003pCmzAAE` |

```bash
sf data update record --target-org personal --sobject Quote \
  --record-id 0Q0as0000021mFyCAI --values "OwnerId=005as000003pCovAAE"
```

Sem esse ajuste, a demo funciona igual — só reserve 30 segundos para explicar a escada de fallback
quando o nome do aprovador aparecer.

---

## 2. Agenda

| Tempo | Bloco | O que fica na tela |
|---|---|---|
| 0:00–0:04 | 1. O problema | Cotação A, painel padrão + console |
| 0:04–0:12 | 2. Estado e simulador | Console A: verde → amarelo na simulação |
| 0:12–0:20 | 3. Pedido e roteamento | Console B: pedido criado, aprovador nomeado |
| 0:20–0:25 | 4. Custo ausente | Console D: badge cinza, alerta, envio bloqueado |
| 0:25–0:30 | 5. A decisão humana | Registro do pedido + fechamento |

---

## 3. Bloco 1 — O problema (4 min)

**Tela:** cotação **A**, `0Q0as0000021mHZCAY`.

1. Abra a cotação. Aponte o painel **Detalhes** no alto: total, validade, status. **Não** há margem.
2. Role até o card **Guardrail de desconto**.

**Fala sugerida:**
> "O Salesforce padrão decide desconto por campo: `Amount`, `Discount`, alçada fixa. Ele não sabe se
> aquele desconto deixa o negócio abaixo do custo, porque o custo não mora no preço — mora no price
> book, e o Salesforce não tem campo de custo padrão. Então o vendedor negocia no escuro e a margem
> aparece depois, no fechamento, quando não há mais o que negociar."

**Ponto de credibilidade (fale, não mostre):** CPQ resolveria isso com *discount schedules*, mas é
licença separada e não está na org. O que está na tela é Flow + LWC + dados.

---

## 4. Bloco 2 — O estado e o simulador (8 min)

**Tela:** mesma cotação A.

1. Mostre o badge **Saudável** (verde) e a frase de orientação.
2. Diga o que **não** aparece: nenhum número de margem, nenhum valor de custo — de propósito (D14:
   número na tela convida o vendedor a negociar contra o custo).
3. No **Simulador de desconto**, digite `15` e clique **Simular**.
4. Resultado esperado: badge **Requer Justificativa** (amarelo), política `DEMO-Policy-Parts-Fleet`, e
   a decisão "Pedido de desconto encaminhado ao aprovador".
5. Reforce: a simulação **não grava nada** — nenhum pedido é criado, nenhum campo muda.

**Fala sugerida:**
> "37,88% de margem com o preço de hoje: saudável. E se o cliente pedir 15%? A margem cai para 26,9%,
> que continua acima do piso de 20%, mas abaixo do alvo de 30%. O app muda o estado na hora, antes de
> o vendedor responder ao cliente — é aqui que a decisão deixa de ser no escuro."

**Transição para o bloco 3:** "Amarelo ainda passa, mas com justificativa. Vamos ver o que acontece
quando o desconto cruza o piso."

---

## 5. Bloco 3 — Pedido de desconto e roteamento (8 min)

**Tela:** cotação **B**, `0Q0as0000021mFyCAI` (22,50% — já nasce amarela).

1. Mostre o estado **Requer Justificativa**.
2. No **Simulador**, digite `5` e clique **Simular**: o estado vira **Requer Aprovação** (vermelho).
   Fale: 18,4% de margem, abaixo do piso de 20%.
3. Volte ao card **Pedir desconto**: desconto `5`, justificativa — algo realista, ex.:
   `Cliente aceita fechar hoje se mantivermos 5% de desconto no volume.`
4. Clique **Pedir desconto**. Esperado:
   - toast de sucesso;
   - **Decisão**: "Pedido de desconto encaminhado ao aprovador";
   - **Pedido**: `DR-0000X` (Id do `DD_DiscountRequest__c`);
   - **Aprovador**: o nome resolvido pela escada (ver §1.5).
5. Abra o registro do pedido (§1.4) e mostre: estado do guardrail, decisão, status `Submitted`,
   `PolicyName__c`, piso/alvo/teto do momento, fonte do aprovador (`ApproverSource__c`).
6. Comente o e-mail: o aprovador é notificado por e-mail com o contexto (não com "aprovar isso").

**Fala sugerida:**
> "O pedido não é um e-mail solto: é um registro com o retrato da política no momento da decisão.
> Se a política mudar amanhã, este pedido continua contando a verdade de hoje. E olhe o que ele
> **não** guarda: custo, margem, receita. Quem aprova decide sobre o estado e a política, não sobre o
> segredo do custo."

**Ponto de honestidade (se perguntarem quem aprova):**
> "A aprovação em si é humana e hoje é registrada no pedido — Status, data e nota. A Ação de aprovação
> no Agentforce é a próxima fase; o guardrail desta fase termina no roteamento com contexto."

---

## 6. Bloco 4 — Quando o dado falta: `Pendente de Custo` (5 min)

**Tela:** cotação **D**, `0Q0as0000021jtBCAQ` (montada em um price book sem custo cadastrado).

1. Mostre o badge **cinza** `Pendente de Custo` e o **alerta** abaixo do estado.
2. Aponte o botão **Pedir desconto** desabilitado e a frase de bloqueio.
3. No simulador, digite `90` e clique **Simular**: o estado projetado continua `Pendente de Custo` —
   **não** vira "Saudável" nem "margem 100%".

**Fala sugerida (esta é a história real do produto):**
> "Este caso foi encontrado testando o app: uma cotação sem custo cadastrado aparecia como margem de
> 100% e passava como saudável — com 90% de desconto. Custo ausente não é margem perfeita, é dado
> ausente. O app passou a tratar isso como estado próprio: o Pricing cadastra o custo, e só então o
> guardrail avalia. Dado incompleto nunca mais vira sinal verde."

---

## 7. Bloco 5 — A decisão é humana (5 min)

**Tela:** pedido criado no bloco 3 (+ a lista de pedidos).

1. Leia em voz alta o par **decisão + aprovador**.
2. Registre a decisão no pedido (é o "aprovar" desta fase): `Status = Approved`, `DecidedAt`,
   `DecisionNote` com o motivo.
3. Feche com o desenho das camadas: dados (política e custo) → Flow (decisão) → LWC (visão do
   vendedor) → Agentforce (recomendação, Fase 6).

**Fala de fechamento:**
> "O app não decide desconto. Ele garante que a decisão aconteça com o número certo na mão de quem tem
> o direito de ver esse número, no momento em que ainda dá para negociar — e que fique registrada. O
> resto — faturamento, reconhecimento de receita, pagamento — está fora de escopo de propósito."

---

## 8. Perguntas esperadas

| Pergunta | Resposta curta |
|---|---|
| "O vendedor vê o custo?" | Não. O perfil dele não tem leitura nos campos de custo e margem; o permission set do app concede **só** o estado do guardrail (Anexo A) |
| "De onde vem o custo?" | `PricebookEntry.FixedCost__c` + `VariableCostPerUnit__c` — campos custom no price book, semeados por família |
| "Se o custo do catálogo mudar?" | Linhas já existentes mantêm o custo gravado; o recálculo acontece quando a linha é criada ou editada (limitação aceita e documentada) |
| "E se não houver política para a família?" | O guardrail **não inventa piso**: estado `Pendente de Política`, sem pedido |
| "Por que não CPQ?" | Licença separada, não provisionada na org. O app entrega o guardrail sem depender dela |
| "Muda a moeda?" | Dados do app em `USD`; a exibição acompanha a moeda do usuário. Nada de conversão silenciosa |
| "O agente aprova?" | Nunca. Ele recomenda e resume; a aprovação é humana e auditável (Fase 6) |

---

## 9. Anexo A — Como provar que o vendedor não vê custo/margem

**Prova por dado (não mexe em sessão):** os 7 campos sensíveis (`Quote.DD_MarginPct__c`,
`Quote.DD_Cost__c`, `Quote.DD_WorstLineMarginPct__c`, `QuoteLineItem.DD_MarginPct__c`,
`DD_MarginAmount__c`, `DD_CostAmount__c`, `DD_CostPerUnit__c`) têm FLS **apenas no perfil System
Administrator**; nenhum perfil de vendedor tem leitura. O permission set `DD_DealDesk_User` concede
exclusivamente `Quote.DD_GuardrailState__c` (mais os campos de política e de pedido, todos de leitura).

```sql
SELECT ParentId, Field, PermissionsRead FROM FieldPermissions
WHERE Field IN ('Quote.DD_MarginPct__c','Quote.DD_Cost__c','QuoteLineItem.DD_CostAmount__c')
ORDER BY ParentId
```

**Prova por tela (opcional, avise a plateia):** em Setup → Users, abra o usuário de teste do vendedor
e use **Login** para entrar como ele. Consequência: **a sua sessão de admin neste navegador termina** —
faça em janela anônima e tenha a senha à mão. Na sessão do vendedor, a cotação mostra o console com o
estado e **sem** os campos de custo/margem no painel de detalhes.

> Não há ação de "voltar a ser admin" além de sair e entrar de novo. Por isso o Anexo A é prova
> separada, não parte do roteiro.

---

## 10. Anexo B — Links

| O quê | URL |
|---|---|
| App Deal Desk | https://personalproject.my.salesforce.com/lightning/app/c__DD_DealDesk |
| Aba Console de Margem | https://personalproject.my.salesforce.com/lightning/n/DD_Margin_Console |
| Cotação A (saudável) | https://personalproject.my.salesforce.com/lightning/r/Quote/0Q0as0000021mHZCAY/view |
| Cotação B (limite) | https://personalproject.my.salesforce.com/lightning/r/Quote/0Q0as0000021mFyCAI/view |
| Cotação C (abaixo do piso) | https://personalproject.my.salesforce.com/lightning/r/Quote/0Q0as0000021mJBCAY/view |
| Cotação D (sem custo) | https://personalproject.my.salesforce.com/lightning/r/Quote/0Q0as0000021jtBCAQ/view |

---

## 11. Anexo C — Troubleshooting

| Sintoma | Causa provável | O que fazer |
|---|---|---|
| Card do console não aparece | a página pode ter deixado de ser org default, ou o usuário não tem o Apex/LWC | desde UI-004 a `DD_Quote_Record_Page` é **org default da `Quote`** (qualquer app): confira `CustomObject:Quote` (`View` `Large`/`Small` → `Flexipage`) e o `classAccesses` de `DD_MarginConsoleController` no `DD_DealDesk_User` |
| Badge não atualiza após a simulação | cache do componente | botão de atualizar ao lado do badge |
| "Pedido não encaminhado" | justificativa ausente com estado que exige, ou aprovador não resolvido | preencha a justificativa; se persistir, é o degrau `Blocked` — a mensagem diz o que falta |
| Nenhum aprovador razoável | dono da cotação sem gestor (D26) | ver §1.5 |
| Simulador fica em "Simulando…" | o Flow não concluiu | recarregue a página; se repetir, verifique se `DD_CalculateQuoteMargin` está `Active` |
| Estado "Pendente de Custo" em cotação que tem custo | entrada do price book sem `FixedCost__c`/`VariableCostPerUnit__c` | é o comportamento correto: cadastre o custo |
