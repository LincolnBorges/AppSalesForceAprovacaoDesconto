# Viabilidade de Moeda (USD vs BRL) — Investigação F0-12

**Data:** 2026-10-17 · **Tipo:** investigação, **nenhuma escrita na org**
**Pergunta do humano:** vale mudar a moeda corporativa da org `personal` de USD para BRL antes da F0-08?

---

## 1. Fatos verificados na org

| # | Fato | Evidência |
|---|---|---|
| 1 | **A moeda corporativa já é `USD`** (`IsCorporate = true`, taxa 1). `BRL` é moeda secundária, taxa **3,6995** | `SELECT IsoCode, IsCorporate, ConversionRate FROM CurrencyType` |
| 2 | **Advanced Currency Management está desligado** — 0 taxas datadas | `SELECT COUNT() FROM DatedConversionRate` = 0 |
| 3 | 30 moedas ativas; `BRL` com 2 casas decimais (sem perda de precisão de campo) | `CurrencyType.DecimalPlaces` |
| 4 | **Os 9 price books são `USD`** — inclusive o Standard | `SELECT CurrencyIsoCode FROM Pricebook2` |
| 5 | 241 `PricebookEntry`: 223 `USD` + 3 de cada (EUR, AUD, GBP, CAD, BRL, JPY) — as não-USD são do Standard | `GROUP BY CurrencyIsoCode` |
| 6 | **31 `Quote` = 100% `USD`**; 88 `Opportunity` = 83 `USD` + 5 em outras moedas | `GROUP BY CurrencyIsoCode` |
| 7 | **22 de 23 usuários ativos estão em `USD`** — a exceção é **Lincoln Borges, em `BRL`** | `User.DefaultCurrencyIsoCode` |
| 8 | `PricebookEntry.CurrencyIsoCode`: `createable = true`, **`updateable = false`** | `sf sobject describe` |
| 9 | `Quote.CurrencyIsoCode` e `Pricebook2.CurrencyIsoCode`: `createable` e `updateable = true` (no describe) | `sf sobject describe` |

> **Fato 7 é o mais importante para a decisão.** A preferência por BRL já está atendida na *exibição*:
> seu usuário tem moeda pessoal BRL, então o Salesforce já converte tudo para BRL na sua tela, usando a
> taxa da org. O que é USD são os **dados**, não a interface.

---

## 2. Pergunta 1 — É possível mudar a moeda corporativa via Setup?

**Pré-requisitos documentados:** multi-currency habilitado (✔ fato 3/6) e Advanced Currency Management
**desligado** (✔ fato 2). Nesta org, os dois pré-requisitos estão satisfeitos — a mudança seria possível
em princípio.

**Estado da página:** a página de Setup `CompanyCurrency` ("Manage Currencies") **existe** nesta org
(achei por busca do Setup), mas **o corpo não renderizou** na sessão de browser — só o cabeçalho. O botão
"Change Corporate Currency" **não foi confirmado visualmente**. Isso é uma limitação da investigação, não
uma prova de ausência (ver §6).

**Efeitos colaterais, se fosse feita:**

| Efeito | Detalhe |
|---|---|
| Dados existentes **não** são convertidos | `Quote`, `Opportunity` e `PricebookEntry` continuam `USD` — a moeda do registro não muda. Só muda a **base de conversão** |
| Re-taxação das 29 moedas | Todas as taxas passam a ser relativas ao BRL; qualquer valor convertido muda de número |
| Recálculo de convertidos | Relatórios, dashboards e **roll-ups que cruzam moedas** passam a somar em BRL. Fórmulas com `convertCurrency()` mudam de resultado |
| Precisão | Sem perda nos valores gravados (cada registro guarda o valor na sua moeda). O arredondamento aparece só nos valores **convertidos** (2 casas) |
| Blast radius | Org inteira: 5 `Opportunity` não-USD, 18 `PricebookEntry` não-USD e o time. Impacto no app: **zero** |

**Conclusão:** é possível (pré-requisitos OK), mas **não é o botão certo**: não transforma o app em BRL e
mexe na org inteira por nenhum ganho do projeto.

---

## 3. Pergunta 2 — Se mudar para BRL, as Fases 1–3 funcionam?

| Componente | Funciona em BRL? | Por quê |
|---|---|---|
| Cálculo de margem | **Sim, e é invariante à moeda** | `margem% = (preço − custo fixo − custo variável) / preço`. É uma **razão** — o resultado não depende da moeda. O mesmo produto em USD 100 ou BRL 370,00 dá exatamente a mesma margem |
| Faixas 30% / 20% (D12) | **Sim** | São percentuais, não valores monetários. Nenhuma comparação entre moedas |
| Campos de custo/margem | **Sim** | Campos `currency` guardam o valor na moeda do registro. BRL tem 2 casas (fato 3) — igual a USD |
| Flow de aprovação / Approval Process | **Sim** | Não há dependência de moeda. O agente/Flow compara percentual e resolve o aprovador por `User.ManagerId` |
| Limitação de org trial | **Nenhuma conhecida** | Multi-currency já está habilitado (não precisa de licença nova); `PricebookEntry`/`Quote`/`Flow` não têm gate de edição trial |

**A única armadilha real é de dados, não de motor:** `PricebookEntry.CurrencyIsoCode` é **imutável**
(fato 8). Não existe "converter" uma entrada USD para BRL — é preciso **criar outra entrada de preço**
(no mesmo price book? não: a moeda é do price book) ou **outro price book em BRL**. Como os 9 price books
são USD (fato 4), rodar o app em BRL exige criar um price book BRL e suas entradas.

---

## 4. Pergunta 3 — Risco de ficar em USD e migrar depois

| Cenário | Custo hoje | Custo depois | Simetria |
|---|---|---|---|
| Re-denominar dados **do app** (criar PB BRL + 24 entradas + semear custo) | ~49 escritas | Igual (o dado é demo, gerado por nós) | **Simétrica** — não existe conversão, existe criação; vale nos dois sentidos |
| Alinhamento com o resto da org | Total (100% dos dados são USD) | Piora a cada registro criado em USD | **Assimétrica** |
| Moeda corporativa (se algum dia você quiser a org em BRL) | Janela aberta (ACM off) | Fecha se alguém habilitar **ACM/taxas datadas** | Assimétrica |

**Leitura:** migrar o *app* para BRL depois custa o mesmo que custa hoje — porque entrada de preço não se
converte, se cria. Migrar a *org* para BRL (`Quote`/`Opportunity` existentes) é o que fica caro, e isso
já é caro hoje (31 cotações, 88 oportunidades). Ficar em USD agora **não fecha porta nenhuma** do app.

---

## 5. Veredito

**Manter `USD` nos dados do app. Não alterar a moeda corporativa.**

Razões, em ordem de peso:

1. **A mudança de moeda corporativa não entrega BRL no app** — só reordena conversões de relatório. É o
   botão errado (fato 1 + §2).
2. **Sua meta de ver BRL já está atendida** pela moeda pessoal do seu usuário (fato 7) — a tela já mostra
   BRL convertido, sem nenhuma escrita.
3. **A margem é invariante à moeda** — nenhuma fase do app depende da moeda dos dados (§3).
4. **USD é o alinhamento com 100% da org**; um price book BRL hoje seria uma ilha (§4).
5. **É reversível** — e o caminho reversível (price book BRL dedicado) continua disponível depois, com o
   mesmo custo, sem tocar na moeda corporativa.

**Se você quiser BRL nativo no app** (preços, custos e cotações de demonstração em reais), o caminho
seguro e escopado é a ação **F0-14**: criar um price book `DD Deal Desk BRL`, entradas BRL para os 24
produtos e semear custo nelas — sem mudar a moeda corporativa e sem tocar nas entradas USD existentes.
Custo: ~49 escritas em vez de 19, e a demo passa a misturar dois books no mesmo app.

---

## 6. Limites desta investigação (o que ela não prova)

- **O botão não foi confirmado visualmente:** a página `CompanyCurrency` existe, mas não renderizou o
  conteúdo na sessão de browser. A afirmação sobre pré-requisitos vem de comportamento documentado do
  Salesforce, **não** de observação direta nesta sessão (A19).
- **Não testei** habilitar ACM nem a mudança de moeda — ambos são escritas de configuração.
- **`Pricebook2.CurrencyIsoCode` aparece `updateable = true`** no describe, o que contraria a expectativa
  documentada ("a moeda do price book não muda depois de criado"). **Não confiar sem teste** (A15): a
  fonte estática já mentiu antes. Não usar esse caminho sem um probe.
- Documentação oficial consultada (Help e Trailhead renderizam por JavaScript e não retornaram texto
  legível ao fetch): [Manage Currencies (Salesforce Help)](https://help.salesforce.com/s/articleView?id=sf.admin_currency_manage.htm&type=5),
  [Discover Multiple Currency Settings (Trailhead)](https://trailhead.salesforce.com/content/learn/modules/company_wide_org_settings/org_settings_currency).

---

## 7. Histórico

| Data | Mudança |
|---|---|
| 2026-10-17 | Investigação criada: fatos verificados por SOQL/describe, veredito "manter USD" |
