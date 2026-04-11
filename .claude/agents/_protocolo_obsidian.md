# PROTOCOLO DE MEMORIA OBSIDIAN — THAUMA

## Vault

**Caminho:** `C:\Users\pedro\Documents\mente`

Este e o vault compartilhado do Pedro. A THAUMA opera dentro da pasta `THAUMA/` neste vault.

## Proposito

O Obsidian e a **memoria persistente entre sessoes** de toda a equipe THAUMA. Como agentes de IA, nosso contexto se perde ao final de cada conversa. O Obsidian resolve isso: tudo que for importante, estrategico ou necessario para continuidade deve ser registrado la.

## Estrutura no Vault

```
THAUMA/
├── 10-CRM/
│   ├── Prospects/          (uma nota por hospital)
│   ├── Clientes/           (uma nota por cliente ativo)
│   └── Pipeline.md         (visao kanban do funil)
├── 20-Projetos/
│   ├── [Nome do Cliente]/  (notas de entrega por projeto)
│   └── Backlog.md          (proximos projetos)
├── 30-Reunioes/
│   └── [AAAA-MM-DD] [Assunto].md  (atas, call logs)
├── 40-Conhecimento/
│   ├── DATASUS/            (aprendizados sobre bases)
│   ├── Legislacao/         (portarias, regulamentos)
│   ├── Emendas/            (ciclo orcamentario, janelas)
│   └── Metodologias/       (SAT, SPIN, frameworks)
├── 50-Tarefas/
│   ├── Inbox.md            (captura rapida)
│   └── Semanal/            (planos semanais)
├── 60-Estrategia/
│   ├── Decisoes.md         (registro de decisoes estrategicas com data e razao)
│   ├── Aprendizados.md     (licoes aprendidas de operacao)
│   ├── Pipeline_Review.md  (reviews mensais de pipeline)
│   └── Roadmap.md          (direcao de longo prazo)
└── 70-Equipe/
    ├── Socrates.md         (notas do CEO entre sessoes)
    ├── Pericles.md         (contexto de Marketing entre sessoes)
    ├── Pitagoras.md        (estado do Data Lake entre sessoes)
    ├── Solon.md            (questoes juridicas pendentes)
    ├── Tales.md            (estado financeiro entre sessoes)
    ├── Arquimedes.md       (status de entregas entre sessoes)
    └── Hefesto.md          (estado das integracoes entre sessoes)
```

## Regras de Uso

### O que SALVAR no Obsidian

1. **Decisoes estrategicas** — Pedro decidiu X porque Y. Data: DD/MM/AAAA.
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

**Data:** DD/MM/AAAA
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
1. Ler `THAUMA/70-Equipe/[SeuNome].md` — seu contexto entre sessoes
2. Ler `THAUMA/60-Estrategia/Decisoes.md` — decisoes recentes
3. Se trabalhando com prospect: ler `THAUMA/10-CRM/Prospects/[Hospital].md`
4. Se em entrega: ler `THAUMA/20-Projetos/[Cliente]/`

### Frequencia de Escrita

| Agente | Quando escrever |
|--------|----------------|
| **Socrates (CEO)** | Apos toda sessao estrategica com Pedro |
| **Orchestrators** | Ao final de tarefas multi-sessao |
| **Sub-agentes** | Quando descobrirem algo que outros agentes precisam saber |

## Convencao de Nomes

- Notas de reuniao: `[AAAA-MM-DD] [Assunto].md`
- Notas de prospect: `[Nome do Hospital].md`
- Notas de projeto: `[Nome do Cliente] - [Fase].md`
- Decisoes: append ao `Decisoes.md` existente (nao criar novo arquivo)
