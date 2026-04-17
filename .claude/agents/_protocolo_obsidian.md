# PROTOCOLO DE MEMÓRIA OBSIDIAN — THAUMA

## Vault

**Caminho:** `C:\Users\pedro\Documents\mente`

Este é o vault pessoal do Pedro. A THAUMA opera dentro da pasta `Operando\03-thauma\` neste vault.

**Acesso:** Direto via filesystem (Read, Write, Edit). Não usa MCP — são arquivos markdown locais.

## Propósito

O Obsidian é a **memória persistente entre sessões** de toda a equipe THAUMA. Como agentes de IA, nosso contexto se perde ao final de cada conversa. O Obsidian resolve isso: tudo que for importante, estratégico ou necessário para continuidade deve ser registrado lá.

## Estrutura Real no Vault

```
Operando/03-thauma/
├── Socrates.md                    (diário do CEO — sessões e decisões estratégicas)
├── Decisoes.md                    (registro de decisões estratégicas com data e razão)
├── Aprendizados.md                (lições aprendidas de operação)
├── Ideias Thauma.md               (backlog de ideias)
├── Roadmap Financeiro Thauma.md   (direção de longo prazo)
├── Tarefas Thauma.md              (inbox de captura rápida)
├── CRM - Leads.md                 (visão kanban do funil)
├── Planos/                        (planos de correção e estratégia)
├── leads/                         (uma nota por hospital prospect)
├── Equipe/                        (notas de contexto entre sessões por gerente)
│   ├── Pericles.md
│   ├── Pitagoras.md
│   ├── Solon.md
│   ├── Tales.md
│   ├── Arquimedes.md
│   └── Hefesto.md
├── Clientes/                      (uma nota por cliente ativo)
├── Projetos/                      (notas de entrega por projeto)
├── Reunioes/                      (atas, call logs — [AAAA-MM-DD] Assunto.md)
├── Conhecimento/
│   ├── DATASUS/                   (aprendizados sobre bases)
│   ├── Legislacao/                (portarias, regulamentos)
│   ├── Emendas/                   (ciclo orçamentário, janelas)
│   └── Metodologias/              (SAT, SPIN, frameworks)
└── Tarefas/                       (planos semanais/mensais)
```

**Observação:** A estrutura real do vault é FLAT na raiz (Socrates.md, Decisoes.md etc. direto). As subpastas `Equipe/`, `Clientes/`, `Projetos/`, `Reunioes/`, `Conhecimento/`, `Tarefas/` são criadas sob demanda — quando um agente precisa escrever uma nota lá pela primeira vez, ele cria a pasta.

## Regras de Uso

### O que SALVAR no Obsidian

1. **Decisões estratégicas** — Pedro decidiu X porque Y. Data: AAAA-MM-DD.
2. **Aprendizados de operação** — "Conexões quentes convertem 100%, cold perto de 0%"
3. **Contexto de prospects** — Estado da negociação, última interação, próximos passos
4. **Estado entre sessões** — "Paramos aqui: [contexto]. Próxima sessão: [o que fazer]"
5. **Insights de dados** — Descobertas analíticas que informam futuras análises
6. **Feedback do Pedro** — Preferências, correções, validações

### O que NÃO salvar no Obsidian

- Dados brutos ou datasets (ficam no Data Lake/BigQuery)
- Conteúdo gerado (posts, emails — ficam em outputs/)
- Contratos e documentos formais (ficam no Google Drive)
- Código e scripts (ficam no repo Git)

### Como SALVAR

Formato padrão para notas de memória:

```markdown
# [Título Descritivo]

**Data:** AAAA-MM-DD
**Agente:** [Nome do agente]
**Contexto:** [Por que isso está sendo registrado]

## Conteúdo

[O que foi decidido/aprendido/observado]

## Implicações

[Como isso afeta decisões futuras]

## Próximos Passos

[O que fazer com essa informação]
```

### Como LER

**No início de cada sessão relevante:**
1. Ler `Operando/03-thauma/Equipe/[SeuNome].md` — seu contexto entre sessões (Sócrates lê `Socrates.md` direto na raiz)
2. Ler `Operando/03-thauma/Decisoes.md` — decisões recentes
3. Se trabalhando com prospect: ler `Operando/03-thauma/leads/[Hospital].md`
4. Se em entrega: ler `Operando/03-thauma/Projetos/[Cliente]/`

### Frequência de Escrita

| Agente | Quando escrever |
|--------|----------------|
| **Sócrates (CEO, Claude principal)** | Após toda sessão estratégica com Pedro |
| **Orchestrators (6 gerentes)** | Ao final de tarefas multi-sessão |
| **Sub-agentes (17 especialistas)** | Quando descobrirem algo que outros agentes precisam saber |

## Convenção de Nomes

- Notas de reunião: `Reunioes/[AAAA-MM-DD] [Assunto].md`
- Notas de prospect: `leads/[Nome do Hospital].md`
- Notas de projeto: `Projetos/[Nome do Cliente] - [Fase].md`
- Notas de contexto de gerente: `Equipe/[Nome].md`
- Decisões: append ao `Decisoes.md` existente (não criar novo arquivo)
- Planos: `Planos/[Nome do Plano].md`
