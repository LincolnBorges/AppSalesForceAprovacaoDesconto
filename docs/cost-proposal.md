# Proposta de Tabela de Custos — Fase 0 (F0-06)

Deliverable de **F0-06**: custo proposto por `PricebookEntry` para as famílias em escopo (D17), de forma
que o guardrail tenha massa nas três faixas de margem (D12).

**Status: APROVADA em 2026-10-17 (F0-07) e EXECUTADA em 2026-10-17 (F0-08)** — 19 registros gravados,
validados por F0-09 (24 com custo · 10 verdes / 7 amarelos / 7 vermelhos · 0 não-`USD`).
Rollback por registro em `execution-log` **SED-001**.

- Famílias: **`Parts`** (14 produtos) e **`Medical Equipment`** (10 produtos).
- Faixas (D12): **VERDE** ≥ 30% · **AMARELO** 20% ≤ m < 30% · **VERMELHO** < 20%.
- Fórmula: `margem% = (UnitPrice − FixedCost__c − VariableCostPerUnit__c) / UnitPrice × 100`.
- Moeda: **USD** em todas as entradas (D5/A13).

---

## 1. Achados da descoberta que mudam o desenho

| # | Achado | Consequência |
|---|---|---|
| A | Existem **duas famílias parecidas**: `Parts` (14 produtos, coerentes com o Fleet) e `Part` (7 produtos: tinta, condensador, pistão — sem relação com o cenário) | Só `Parts` entra. `Part` fica fora; é armadilha de `IN` com string parecida |
| B | **`Medical Equipment` não existe no `Fleet & Corporate Pricebook`** — só no `Standard Price Book` (13 entradas: 10 produtos, 3 delas em BRL) | Não dá para semear os dois no mesmo book sem criar entradas novas → ver §4 (F0-11) |
| C | `Parts` está em 4 price books; no **Fleet & Corporate** são 14 entradas, das quais **5 já têm custo** (T3) | A proposta toca apenas as **9 restantes** no Fleet + **10** no Standard |
| D | As **31 `Quote` existentes têm `Pricebook2Id` nulo** | As cotações de demonstração (F5-02) terão de definir price book explicitamente; não há cotação herdada aproveitável |

---

## 2. Entradas já semeadas — **não serão alteradas**

| Família | Produto (Fleet & Corporate) | UnitPrice | FixedCost | VarCost | Margem | Faixa |
|---|---|---|---|---|---|---|
| Parts | Multi-Point Diagnostic Scanner (EV-Compatible) | 200.00 | 96.00 | 48.00 | 28.00% | AMARELO |
| Parts | Regenerative Braking Calibration Interface | 160.00 | 84.00 | 40.00 | 22.50% | AMARELO |
| Parts | Steering & Alignment Calibration Tool | 144.00 | 62.00 | 32.00 | 34.72% | VERDE |
| Parts | Suspension Inspection Kit | 120.00 | 46.00 | 24.00 | 41.67% | VERDE |
| Parts | EV Brake Pad Kit | 96.00 | 56.00 | 23.00 | 17.71% | VERMELHO |

---

## 3. Proposta — 19 entradas a semear

### 3.1 `Parts` — `Fleet & Corporate Pricebook` (9 entradas)

| Produto | UnitPrice | FixedCost | VarCost | Custo total | Margem | Faixa |
|---|---|---|---|---|---|---|
| Battery Compartment Dust Seal Replacement Set | 32.00 | 14.00 | 5.85 | 19.85 | 37.97% | VERDE |
| EV Coolant Replacement Pack | 40.00 | 19.00 | 7.80 | 26.80 | 33.00% | VERDE |
| Neo Wagon EV Software Update Module | 48.00 | 18.50 | 7.90 | 26.40 | 45.00% | VERDE |
| Windshield Wiper Pack | 28.00 | 13.50 | 5.80 | 19.30 | 31.07% | VERDE |
| Cabin Air Filter | 22.40 | 11.50 | 5.10 | 16.60 | 25.89% | AMARELO |
| Tire Rotation & Balancing Toolset | 60.00 | 30.50 | 13.30 | 43.80 | 27.00% | AMARELO |
| Drive Motor Lubricant | 36.00 | 21.50 | 9.45 | 30.95 | 14.03% | VERMELHO |
| High-Voltage Safety Gear Set | 72.00 | 41.50 | 17.55 | 59.05 | 17.99% | VERMELHO |
| Universal EV Fastener & Clip Kit | 17.60 | 10.50 | 4.30 | 14.80 | 15.91% | VERMELHO |

### 3.2 `Medical Equipment` — `Standard Price Book` (10 entradas)

| Produto | UnitPrice | FixedCost | VarCost | Custo total | Margem | Faixa |
|---|---|---|---|---|---|---|
| MediScan Imager | 90000.00 | 41600.00 | 17800.00 | 59400.00 | 34.00% | VERDE |
| MediScan Ventilator | 50000.00 | 24200.00 | 10300.00 | 34500.00 | 31.00% | VERDE |
| MediScan Sterilizer | 27000.00 | 12100.00 | 5180.00 | 17280.00 | 36.00% | VERDE |
| MediScan IV Stand | 650.00 | 270.00 | 113.50 | 383.50 | 41.00% | VERDE |
| MediScan Lab Analyzer | 35000.00 | 18400.00 | 7850.00 | 26250.00 | 25.00% | AMARELO |
| MediScan MedCart | 3500.00 | 1700.00 | 790.00 | 2490.00 | 28.86% | AMARELO |
| MediScan Hospital Bed | 4800.00 | 2600.00 | 1140.00 | 3740.00 | 22.08% | AMARELO |
| MediScan Infusion Pump | 2300.00 | 1300.00 | 590.00 | 1890.00 | 17.83% | VERMELHO |
| MediScan Pulse Oximeter | 700.00 | 415.00 | 180.00 | 595.00 | 15.00% | VERMELHO |
| MediScan Thermo Scanner | 400.00 | 245.00 | 107.00 | 352.00 | 12.00% | VERMELHO |

> As 3 entradas de `Medical Equipment` em **BRL** (Hospital Bed 15.000, Imager 30.000, Ventilator 50.000)
> **ficam intocadas**: semear em moeda diferente do pai é o erro do A13.

---

## 4. Distribuição final e critério da Fase 0

| Faixa | Já semeadas | Propostas | Total | % do total |
|---|---|---|---|---|
| VERDE (≥30%) | 2 | 8 | 10 | 41,7% |
| AMARELO (20–30%) | 2 | 5 | 7 | 29,2% |
| VERMELHO (<20%) | 1 | 6 | 7 | 29,2% |
| **Total** | **5** | **19** | **24** | |

| Critério da Fase 0 | Meta | Resultado com esta proposta |
|---|---|---|
| `PricebookEntry` com custo | ≥ 20 | **24** |
| Price books | ≥ 2 | **2** (Fleet & Corporate + Standard) |
| Famílias | 2 (revisado por D17) | **2** (`Parts`, `Medical Equipment`) |
| Todas em USD | sim | sim |

---

## 5. Decisão pendente — F0-11 (price book de `Medical Equipment`)

`Medical Equipment` não está no `Fleet & Corporate`. Três caminhos:

| Opção | O que faz | Custo da operação | Efeito no app |
|---|---|---|---|
| **A — recomendada** | Semeia custo no `Standard Price Book`, onde as entradas já existem em USD (10 updates) | Só atualização de campo; nenhum registro novo | 2 price books; a política usa `Pricebook__c` + precedência (família específica vence genérica) — exercita exatamente a regra da Fase 2 |
| B | Cria 10 `PricebookEntry` de `Medical Equipment` no `Fleet & Corporate` (copiando o preço do Standard) e semeia lá | 10 creates + 10 updates; preço do Fleet passa a ser cópia arbitrária do Standard | 1 price book com 2 famílias; demo mais simples, porém inventa preço no book comercial |
| C | Adia `Medical Equipment`; semeia só `Parts` agora | 9 updates | Perde a segunda família: a precedência da Fase 2 fica sem par para testar |

---

## 6. Escopo exato da escrita (F0-08, após o "OK")

- **Objeto:** `PricebookEntry` — somente os campos `FixedCost__c` e `VariableCostPerUnit__c`.
- **Registros:** 19 (9 no Fleet & Corporate, 10 no Standard), conforme §3 e a opção escolhida em F0-11.
- **Nenhum** create, delete, mudança de preço, de `IsActive` ou de `CurrencyIsoCode`.
- **Valor anterior:** `null`/`null` nos 19 → rollback = gravar `null` nos dois campos.
- **Lote:** autorizado por D16 (exceção registrada à S4), com cada registro logado individualmente.

## 7. Histórico

| Data | Mudança |
|---|---|
| 2026-10-17 | Proposta criada sobre 9 entradas do Fleet & Corporate e 10 do Standard Price Book |
