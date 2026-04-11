# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## O que e a THAUMA

**THAUMA — Inteligencia & Narrativa em Saude** e uma consultoria que promove ganho de eficiencia, escala, qualidade e profissionalismo para gestores de saude publica e prestadores de servico no SUS, por meio de tecnologia, inteligencia artificial e dados publicos de saude.

Organizamos dados e construimos narrativas, ferramentas e processos para players da area da saude, com suporte em IA e nas bases de dados do SUS.

**Fundacao:** Dezembro de 2025 | **CNPJ:** Constituido e regularizado

### Socios

| Socio | Papel |
|-------|-------|
| **Pedro William Ribeiro Diniz** | Fundador. Dados, estrategia, metodologia. Senior BI Analyst FHEMIG, ex-Diretor IPSEMG. |
| **Vinicius de Paula Prudente Aquino** | Socio administrador. Vendas e tecnologia. |
| **Bruno Volpini Guimaraes** | Socio. Design de produto. |

### Documento Fundacional

Ler `THAUMA_Documento_Fundacional_v3.md` para a referencia completa da empresa (filosofia, portfolio, mercado, financeiro, equipe, aprendizados).

## Portfolio de Produtos

### Verticais Consolidadas

**1. Inteligencia Politica** — Captacao de emendas, trabalho para gabinetes, engenharia politica baseada em dados.

Produto flagship: **Prisma de Captacao** (4 componentes: Dossie de Evidencias, Radar Politico, Dialetica de Convencimento, Retorica da Influencia).
- Investimento: R$ 24.000 – R$ 26.000 | Prazo: 20-30 dias uteis | Pagamento: 50/50

**2. Inteligencia Assistencial** — BI as a Service para hospitais. Dashboards, relatorios, tratamento de dados DATASUS.
- Setup: R$ 4.000 – R$ 5.000 | Nutricao mensal: R$ 1.500/mes

### Verticais em Roadmap

**3. Inteligencia Artificial** — Agentes autonomos para back-office hospitalar (em ideacao)
**4. Marketing Hospitalar** — Substituir agencias tradicionais (em ideacao)

### Score SAT (Score de Alinhamento Territorial)

Formula proprietaria: `SAT = (Votos do Parlamentar no Municipio / 1.000) x (Pacientes do Municipio / 100)`

## Equipe Multiagente (25 Agentes em 6 Departamentos)

```
Pedro (Fundador) + Vinicius (Vendas) + Bruno (Produto)
                          |
                    Socrates (CEO)
                          |
    +----------+----------+----------+----------+----------+
    |          |          |          |          |          |
 Pericles  Pitagoras   Solon     Tales   Arquimedes  Hefesto
 Marketing   Dados    Juridico Financeiro Projetos  Operacoes
 6 agentes 4 agentes 2 agentes 2 agentes 2 agentes 2 agentes
```

Agentes em `.claude/agents/{departamento}/`. Orchestrators em Opus, sub-agentes em Sonnet.
Repositorio: github.com/thauma-consultoria/thauma-staff

## Estrutura da Pasta

```
/THAUMA/
├── .claude/agents/                     <- Equipe multiagente (25 agentes)
├── CLAUDE.md                          <- Este arquivo
├── THAUMA_Documento_Fundacional_v3.md <- Documento fundacional (ler primeiro)
├── THAUMA_GUIA_COWORKS.md             <- Guia operacional
├── Gerencia de Marketing/             <- Operacao de marketing (Pericles)
├── Gerencia de Dados/                 <- Data Lake e pipelines (Pitagoras)
├── Projetos/                          <- Entregas por cliente
│   ├── Santa Casa OP/                 <- Primeiro cliente
│   └── Tech Estrutural/              <- Ferramentas internas
├── Leads/                             <- Base de prospects
├── Design/                            <- Identidade visual (logos)
├── SIGTAP/                            <- Tabelas de procedimentos SUS
└── Contrato_THAUMA_SantaCasa_OuroPreto.docx
```

## Fontes de Dados

| Base | Uso |
|------|-----|
| DATASUS/SIH-SIA | Producao hospitalar (AIH, BPA) |
| TSE | Dados eleitorais por municipio |
| CNESNet | Cadastro de estabelecimentos |
| IBGE | Dados geograficos e socioeconomicos |
| DOU | Portarias e oportunidades de financiamento |
| SIGTAP | Codigos e valores de procedimentos |

**Stack:** R (tidyverse, microdatasus), Python (pandas, polars), SQL, BigQuery, Claude Code, Plotly, D3.js, Leaflet

## Integracoes

| Ferramenta | Funcao |
|-----------|--------|
| **Notion** | CRM externo (leads, pipeline) |
| **Obsidian** | Base de conhecimento interna + memoria entre sessoes (vault: `C:\Users\pedro\Documents\mente`) |
| **Google Drive** | Repositorio de documentos formais |
| **GitHub** | Repositorio da equipe de agentes |
| **BigQuery** | Data Lake (projeto: thauma-datalake) |

## Identidade Visual (obrigatoria)

| Cor | Hex | Uso |
|-----|-----|-----|
| Azul Profundo | `#001070` | Base estrutural (60-70%) |
| Branco Absoluto | `#FFFFFF` | Espaco de clareza (20-30%) |
| Ciano Tecnologico | `#40D7FF` | Destaques reveladores (5-10%) |

- **Titulos:** Helvetica Bold/Medium | **Corpo:** Hahmlet Regular | **Dados:** Hahmlet Bold

## Regras Operacionais

1. **Tom THAUMA** — culto, direto, baseado em evidencias. Nunca generico ou corporativo vazio.
2. **Dados > Opinioes** — qualquer argumento deve ter base em numero.
3. **Personalizacao obrigatoria** — nenhum material sai sem dados especificos do prospect-alvo.
4. **Segregacao FHEMIG/THAUMA** — jamais misturar dados, tarefas ou projetos das duas instituicoes.
5. **Rede > Cold** — priorizar conexoes quentes e indicacoes. Cold outreach e complementar.
6. **Obsidian = memoria entre sessoes** — toda informacao relevante para continuidade vai para o Obsidian.
7. **Git sempre sincronizado** — Socrates garante pull no inicio e push no final de cada sessao.
8. **Palavras proibidas:** ~~Dica~~ -> Estrategia | ~~Truque~~ -> Metodo | ~~Custo~~ -> Investimento | ~~Ajuda~~ -> Parceria

## Vendas

**Canal primario:** Rede e indicacao (confianca vende, dado convence, cold nao funciona sozinho)
**Canal secundario:** Inbound LinkedIn (credibilidade, nao conversao direta)
**Canal complementar:** Outbound frio

**SPIN Selling em calls de 15 min:** Abertura com dados (0-2min) -> Situation+Problem (2-5min) -> Revelacao de 3 insights (5-8min) -> Implication+Need-Payoff (8-11min) -> Pitch (11-15min)

## Glossario Rapido

**Thaumazein** = espanto revelador | **Doxa** = opiniao/amadorismo | **Episteme** = conhecimento verdadeiro | **Aletheia** = verdade desvelada | **SAT** = Score de Alinhamento Territorial | **Prisma** = produto flagship | **Mini-Prisma** = diagnostico 3p (lead magnet) | **CEBAS** = certificacao de entidade beneficente | **Vazio Assistencial** = municipios sem cobertura de procedimento
