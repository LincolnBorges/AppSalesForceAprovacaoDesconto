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
