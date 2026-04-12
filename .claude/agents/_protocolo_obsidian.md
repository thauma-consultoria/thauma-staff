# PROTOCOLO DE MEMORIA OBSIDIAN — THAUMA

## Vault

**Caminho:** `C:\Users\pedro\Documents\mente`

Este e o vault pessoal do Pedro. A THAUMA opera dentro da pasta `Operando\03-thauma\` neste vault.

**Acesso:** Direto via filesystem (Read, Write, Edit). Nao usa MCP — sao arquivos markdown locais.

## Proposito

O Obsidian e a **memoria persistente entre sessoes** de toda a equipe THAUMA. Como agentes de IA, nosso contexto se perde ao final de cada conversa. O Obsidian resolve isso: tudo que for importante, estrategico ou necessario para continuidade deve ser registrado la.

## Estrutura Real no Vault

```
Operando/03-thauma/
├── Socrates.md                    (diario do CEO — sessoes e decisoes estrategicas)
├── Decisoes.md                    (registro de decisoes estrategicas com data e razao)
├── Aprendizados.md                (licoes aprendidas de operacao)
├── Ideias Thauma.md               (backlog de ideias)
├── Roadmap Financeiro Thauma.md   (direcao de longo prazo)
├── Tarefas Thauma.md              (inbox de captura rapida)
├── CRM - Leads.md                 (visao kanban do funil)
├── Planos/                        (planos de correcao e estrategia)
├── leads/                         (uma nota por hospital prospect)
├── Equipe/                        (notas de contexto entre sessoes por gerente)
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
│   ├── Emendas/                   (ciclo orcamentario, janelas)
│   └── Metodologias/              (SAT, SPIN, frameworks)
└── Tarefas/                       (planos semanais/mensais)
```

**Observacao:** A estrutura real do vault e FLAT na raiz (Socrates.md, Decisoes.md etc. direto). As subpastas `Equipe/`, `Clientes/`, `Projetos/`, `Reunioes/`, `Conhecimento/`, `Tarefas/` sao criadas sob demanda — quando um agente precisa escrever uma nota la pela primeira vez, ele cria a pasta.

## Regras de Uso

### O que SALVAR no Obsidian

1. **Decisoes estrategicas** — Pedro decidiu X porque Y. Data: AAAA-MM-DD.
2. **Aprendizados de operacao** — "Conexoes quentes convertem 100%, cold perto de 0%"
3. **Contexto de prospects** — Estado da negociacao, ultima interacao, proximos passos
4. **Estado entre sessoes** — "Paramos aqui: [contexto]. Proxima sessao: [o que fazer]"
5. **Insights de dados** — Descobertas analiticas que informam futuras analises
6. **Feedback do Pedro** — Preferencias, correcoes, validacoes

### O que NAO salvar no Obsidian

- Dados brutos ou datasets (ficam no Data Lake/BigQuery)
- Conteudo gerado (posts, emails — ficam em outputs/)
- Contratos e documentos formais (ficam no Google Drive)
- Codigo e scripts (ficam no repo Git)

### Como SALVAR

Formato padrao para notas de memoria:

```markdown
# [Titulo Descritivo]

**Data:** AAAA-MM-DD
**Agente:** [Nome do agente]
**Contexto:** [Por que isso esta sendo registrado]

## Conteudo

[O que foi decidido/aprendido/observado]

## Implicacoes

[Como isso afeta decisoes futuras]

## Proximos Passos

[O que fazer com essa informacao]
```

### Como LER

**No inicio de cada sessao relevante:**
1. Ler `Operando/03-thauma/Equipe/[SeuNome].md` — seu contexto entre sessoes (Socrates le `Socrates.md` direto na raiz)
2. Ler `Operando/03-thauma/Decisoes.md` — decisoes recentes
3. Se trabalhando com prospect: ler `Operando/03-thauma/leads/[Hospital].md`
4. Se em entrega: ler `Operando/03-thauma/Projetos/[Cliente]/`

### Frequencia de Escrita

| Agente | Quando escrever |
|--------|----------------|
| **Socrates (CEO, Claude principal)** | Apos toda sessao estrategica com Pedro |
| **Orchestrators (6 gerentes)** | Ao final de tarefas multi-sessao |
| **Sub-agentes (17 especialistas)** | Quando descobrirem algo que outros agentes precisam saber |

## Convencao de Nomes

- Notas de reuniao: `Reunioes/[AAAA-MM-DD] [Assunto].md`
- Notas de prospect: `leads/[Nome do Hospital].md`
- Notas de projeto: `Projetos/[Nome do Cliente] - [Fase].md`
- Notas de contexto de gerente: `Equipe/[Nome].md`
- Decisoes: append ao `Decisoes.md` existente (nao criar novo arquivo)
- Planos: `Planos/[Nome do Plano].md`
