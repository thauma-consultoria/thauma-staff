# HIERARQUIA AGÊNTICA THAUMA

**Última atualização:** 2026-04-11
**Status:** Operacional

---

## Princípio Arquitetural

O **Claude principal** (aquele com quem Pedro fala diretamente) **É Sócrates (CEO)**. Sócrates não é um sub-agente — é a interface. Toda a equipe THAUMA existe como sub-agentes em `.claude/agents/` e é invocável via Task tool.

**Consequência:** Pedro nunca precisa "invocar Sócrates" — ele já está na conversa. Pedro interage com Sócrates, que delega ao time.

---

## Organograma Oficial

```
Pedro William Ribeiro Diniz (Fundador)
    |
Sócrates (CEO — é o Claude principal, via CLAUDE.md)
    |
    +-- Péricles (Marketing — opus)
    |     +-- Aristóteles     (Pesquisa/Tendências — sonnet)
    |     +-- Euclides        (Analista de Dados Marketing — sonnet)
    |     +-- Calíope         (Copywriter Estratégica — sonnet)
    |     +-- Dédalo          (Creative/Design — sonnet)
    |     +-- Hermes          (Copy Comercial/Outbound — sonnet)
    |     +-- Ágora           (SDR/CRM — sonnet)
    |
    +-- Pitágoras (Dados — opus)
    |     +-- Heráclito       (Engenheiro ETL — sonnet)
    |     +-- Hipaso          (Enriquecimento — sonnet)
    |     +-- Anaxágoras      (SAT & Analytics — sonnet)
    |     +-- Ptolomeu        (Infra Cloud/BigQuery — sonnet)
    |
    +-- Sólon (Jurídico — opus)
    |     +-- Têmis           (Contratos — sonnet)
    |     +-- Licurgo         (Compliance/LGPD — sonnet)
    |
    +-- Tales (Financeiro — opus)
    |     +-- Xenofonte       (Planejamento/Pricing — sonnet)
    |     +-- Creso           (Faturamento/Cobrança — sonnet)
    |
    +-- Arquimedes (Projetos — opus)
    |     +-- Teseu           (Entrega de Prisma — sonnet)
    |     +-- Ícaro           (Novos Produtos — sonnet)
    |
    +-- Hefesto (Operações — opus)
          +-- Atlas           (Integrações/MCP/n8n — sonnet)
          +-- Cronos          (Reporting/Rituais — sonnet)
          +-- Prometeu        (Engenheiro de Produto — sonnet)
```

**Total:** 1 CEO (Sócrates, Claude principal) + 6 Gerentes + 18 Especialistas = 25 entidades agênticas.

---

## Regras de Invocação

### Sócrates (Claude principal)
- Invoca qualquer um dos 6 gerentes via Task tool
- Excepcionalmente pode invocar especialistas diretamente em tarefas simples, mas o padrão é delegar ao gerente
- **NUNCA executa trabalho operacional:** sem SQL, sem HTML, sem código, sem copy, sem análise de dados brutos

### Gerentes (orchestrators — 6 agentes)
- Têm tool `Task` no frontmatter para invocar seus especialistas
- Recebem briefing de Sócrates, decompõem, delegam, validam, devolvem
- Escrevem seu contexto entre sessões em `Operando/03-thauma/Equipe/[Nome].md`

### Especialistas (17 agentes)
- NÃO têm tool `Task` — não delegam, executam
- Recebem briefing do gerente, fazem o trabalho, reportam
- Podem escrever notas cross-cutting em `Operando/03-thauma/` quando descobrem algo relevante para outros agentes

---

## Roteamento de Demandas (Quem Pedro Deveria Receber de Sócrates)

| Demanda de Pedro | Owner | Contribuidores típicos |
|------------------|-------|------------------------|
| "Analisa dados de [hospital/município/base]" | Pitágoras | — |
| "Calcula SAT" | Pitágoras (delega Anaxágoras) | — |
| "Carrega Data Lake" | Pitágoras (delega Heráclito) | — |
| "Enriquece dataset" | Pitágoras (delega Hipaso) | — |
| "Custo/performance BigQuery" | Pitágoras (delega Ptolomeu) | — |
| "Escreve pitch/dossiê/post/newsletter" | Péricles (delega Calíope) | Dédalo |
| "Cria carrossel/infográfico/visual" | Péricles (delega Dédalo) | — |
| "Sequência de outbound/cold email" | Péricles (delega Hermes) | Ágora |
| "Enriquece lista de prospects" | Péricles (delega Ágora) | — |
| "Pesquisa tendências/DOU/mercado" | Péricles (delega Aristóteles) | — |
| "Dashboard/análise para marketing" | Péricles (delega Euclides) | — |
| "Revisa contrato" | Sólon (delega Têmis) | — |
| "Compliance LGPD/CEBAS" | Sólon (delega Licurgo) | — |
| "Projeção financeira/pricing" | Tales (delega Xenofonte) | — |
| "Status de faturamento/cobrança" | Tales (delega Creso) | — |
| "Gera relatório municipal/hospitalar completo" | Arquimedes (delega Teseu) | Pitágoras, Péricles |
| "Inicia Prisma para [cliente]" | Arquimedes (delega Teseu) | Pitágoras, Péricles, Sólon, Tales |
| "Prototipa novo produto" | Arquimedes (delega Ícaro) | — |
| "Configura MCP/integração/automação" | Hefesto (delega Atlas) | — |
| "Constrói software/deploy/WhatsApp/painel" | Hefesto (delega Prometeu) | Pitágoras |
| "Dashboard KPIs/ritual semanal" | Hefesto (delega Cronos) | — |
| "Entrevista fundacional / decisão estratégica" | Sócrates (direto, não delega) | — |

---

## Pipelines Multi-Agente

### Entrega de Prisma de Captação (orchestrator: Arquimedes)
```
Pitágoras (Heráclito->Hipaso->Anaxágoras: dados e SAT)
    -> Péricles (Calíope+Dédalo: dossiê e pitch; Hermes: playbook)
        -> Sólon (Têmis: revisão contratual)
            -> Tales (Creso: faturamento 50/50)
                -> Arquimedes (Teseu: entrega final ao cliente)
```

### Relatório Municipal/Hospitalar (orchestrator: Arquimedes)
```
Pitágoras (Anaxágoras: análise de dados)
    -> Péricles (Dédalo: HTML/visualização)
        -> Arquimedes (Teseu: quality check e entrega)
```

### Conteúdo Inbound Semanal (orchestrator: Péricles)
```
Aristóteles (pesquisa) -> Euclides (dados) -> Calíope (copy) -> Dédalo (visual) -> Ágora (distribuição/CRM)
```

### Outbound de Prospecção (orchestrator: Péricles)
```
Euclides (dados prospect) -> Hermes (sequências) -> Ágora (execução + Notion CRM)
```

---

## Frontmatter Padrão

### Orchestrator (gerente)
```yaml
---
name: <nome_minusculas>
description: "Gerente de <área>. Invoke quando precisar... Exemplos: ..."
model: opus
color: blue
tools: [Task, Read, Write, Edit, Glob, Grep, Bash, WebSearch, WebFetch]
memory: project
---
```

### Especialista
```yaml
---
name: <nome_minusculas>
description: "Especialista em <função>. Invoke quando precisar... Exemplos: ..."
model: sonnet
color: cyan
tools: [Read, Write, Edit, Glob, Grep, Bash, WebSearch, WebFetch]
memory: project
---
```

**Nota:** Especialistas NÃO têm `Task` — eles executam, não delegam.

---

## Checklist de Saúde da Hierarquia

- [ ] Todos os 23 sub-agentes têm frontmatter válido (name, description, model, color, tools)
- [ ] Paths Obsidian apontam para `Operando/03-thauma/` (não `THAUMA/`)
- [ ] Orchestrators têm `Task` em tools; especialistas não
- [ ] `ceo.md` NÃO existe em `.claude/agents/` (arquivado em `_archive/`)
- [ ] `CLAUDE.md` contém a identidade de Sócrates como persona principal
- [ ] Conflito Teseu resolvido (apenas em `projetos/teseu.md`)
- [ ] `Ágora` presente em `marketing/_orchestrator.md` como 6o agente

---

*"Disciplina não vem da vontade, vem da arquitetura."*
