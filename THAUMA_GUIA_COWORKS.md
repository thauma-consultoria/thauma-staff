# THAUMA — GUIA OPERACIONAL
## Inteligencia & Narrativa em Saude

**Versao:** 2.0 | Abril 2026
**Fundador:** Pedro William Ribeiro Diniz
**Uso:** Documento de orientacao para operar a equipe multiagente THAUMA via Claude Code

---

## 1. QUEM SOMOS

**THAUMA — Inteligencia & Narrativa em Saude** e uma consultoria que promove ganho de eficiencia, escala, qualidade e profissionalismo para gestores de saude publica e prestadores de servico no SUS, por meio de tecnologia, IA e dados publicos de saude.

**Fundacao:** Dezembro de 2025 | **CNPJ:** Constituido e regularizado

### Socios

| Socio | Papel | Dedicacao |
|-------|-------|-----------|
| **Pedro William Ribeiro Diniz** | Fundador. Dados, estrategia, metodologia. | 8-10h/semana |
| **Vinicius de Paula Prudente Aquino** | Administrador formal. Vendas e tecnologia. | Minima (por acordo) |
| **Bruno Volpini Guimaraes** | Design de produto. | 4-5h/semana |

### Filosofia: DOXA → EPISTEME

- **Doxa** = opiniao subjetiva, gestao por intuicao, pedidos emocionais
- **Episteme** = conhecimento verdadeiro, gestao por dados, argumentacao estruturada
- **Thaumazein** = o espanto revelador quando o gestor descobre o que nao sabia sobre seu proprio hospital

**Tagline:** *"O espanto da descoberta. A ciencia do resultado."*

---

## 2. EQUIPE MULTIAGENTE

A THAUMA opera com 25 agentes de IA organizados em 6 departamentos, coordenados por um CEO virtual (Socrates). Todos os agentes estao definidos em `.claude/agents/`.

### Organograma

```
Pedro + Vinicius + Bruno (Socios Humanos)
                |
          Socrates (CEO)
                |
    +-----------+-----------+-----------+-----------+-----------+
    |           |           |           |           |           |
 Pericles   Pitagoras    Solon      Tales     Arquimedes   Hefesto
 MARKETING    DADOS     JURIDICO  FINANCEIRO  PROJETOS   OPERACOES
```

### Departamentos

| Dept | Gerente (Opus) | Agentes (Sonnet) | Funcao |
|------|----------------|------------------|--------|
| **Marketing** | Pericles | Euclides, Aristoteles, Caliope, Dedalo, Hermes, Agora | Inbound, outbound, conteudo, prospeccao |
| **Dados** | Pitagoras | Heraclito, Hipaso, Anaxagoras, Ptolomeu | Data Lake, ETL, analytics, Score SAT |
| **Juridico** | Solon | Temis, Licurgo | Contratos, compliance, LGPD |
| **Financeiro** | Tales | Creso, Xenofonte | Faturamento, pricing, projecoes |
| **Projetos** | Arquimedes | Teseu, Icaro | Entrega de Prisma, novos produtos |
| **Operacoes** | Hefesto | Atlas, Cronos | Integracoes, automacoes, KPIs |

### Como Invocar

Os agentes sao invocados via `subagent_type` no Claude Code:
- Gerentes: `subagent_type: "pericles"`, `"pitagoras"`, `"solon"`, `"tales"`, `"arquimedes"`, `"hefesto"`
- CEO: `subagent_type: "ceo"`
- Sub-agentes: `subagent_type: "euclides"`, `"caliope"`, `"hermes"`, etc.

---

## 3. PORTFOLIO DE PRODUTOS

### Vertical 1: Inteligencia Politica (Consolidada)

**Prisma de Captacao** — Produto flagship. 4 componentes:

| # | Componente | Descricao |
|---|-----------|-----------|
| 1 | **Dossie de Evidencias** | Analise epidemiologica + impacto regional + ROI politico (40-60 pgs) |
| 2 | **Radar Politico** | Dashboard DATASUS x TSE + Top 10 Parlamentares via Score SAT |
| 3 | **Dialetica de Convencimento** | Pitch deck personalizado por parlamentar (15-20 slides) |
| 4 | **Retorica da Influencia** | Playbook com roteiros, objecoes, cronograma (20-30 pgs) |

**Investimento:** R$ 24.000 – R$ 26.000
**Prazo:** 20-30 dias uteis
**Pagamento:** 50% no inicio + 50% na entrega

**Mini-Prisma:** Diagnostico gratuito de 3 paginas com 3 insights — lead magnet.

### Vertical 2: Inteligencia Assistencial (Consolidada)

BI as a Service para hospitais. Dashboards, relatorios, tratamento de dados DATASUS.

| Entrega | Investimento |
|---------|-------------|
| Setup de dashboard completo | R$ 4.000 – R$ 5.000 |
| Nutricao mensal | R$ 1.500/mes |

**Logica:** Prisma abre a porta (projeto de impacto), BI constroi a recorrencia.

### Verticais em Roadmap

- **Inteligencia Artificial** — Agentes autonomos para back-office hospitalar
- **Marketing Hospitalar** — Substituir agencias tradicionais

### Score SAT (Score de Alinhamento Territorial)

```
SAT = (Votos do Parlamentar no Municipio / 1.000) x (Pacientes do Municipio / 100)
```

---

## 4. CLIENTE IDEAL (ICP)

**Camada 1 — Core:**
- Hospitais filantropicos certificados (CEBAS) / Santas Casas
- Porte medio a grande (50+ leitos)
- Interior de estados (alta dependencia regional)

**Camada 2 — Agentes publicos:**
- Parlamentares (deputados estaduais/federais)
- Secretarios municipais de saude

**Camada 3 — Prestadores de servico ao SUS:**
- Empresas de locacao de mao de obra medica
- Gestoras de UTIs terceirizadas
- Fornecedores de materiais e servicos hospitalares

**Decisor tipico:** Diretor/Gestor com formacao tecnica, frustrado com captacao amadora, dificil de acessar.

---

## 5. COMO VENDEMOS

### Canal Primario: Rede e Indicacao

O unico canal que converteu ate agora. Confianca vende, dado convence, cold nao funciona sozinho.

**Conectores ativos:**
- **Fabricio** — ja trouxe leads (Hospital Sao Joao de Deus de Vinopolis)
- **Dr. Rodrigo Kleinpaul** — conectando Manhuacu
- **Dr. Bernardo Ramos** — rede politica ampla
- **Claudia Herminia** — conselhos de gestao em BH

### Canal Secundario: Inbound LinkedIn

Producao de conteudo para construcao de autoridade. Gera credibilidade, nao conversao direta.

**3 Pilares de Conteudo:**
1. Gestao Hospitalar Baseada em Dados
2. Governanca, Contratualizacao e Sustentabilidade no SUS
3. Tecnologia, IA e Realidade da Gestao Publica

### Canal Complementar: Outbound Frio

Cold call/email. Conversao baixa. Complementar, nunca motor.

### Metodologia SPIN Selling (Calls de 15 min)

```
MIN 0-2:   ABERTURA + 1 insight especifico do hospital
MIN 2-5:   SITUATION + PROBLEM (perguntas diagnosticas)
MIN 5-8:   REVELACAO (3 insights: volume, SAT, custo evitado)
MIN 8-11:  IMPLICATION + NEED-PAYOFF (amplificar dor)
MIN 11-15: PITCH + proximo passo (Mini-Prisma ou reuniao tecnica)
```

---

## 6. FONTES DE DADOS

| Base | Uso | Acesso |
|------|-----|--------|
| **DATASUS / SIH-SIA** | Producao hospitalar (AIH, BPA) | datasus.saude.gov.br / microdatasus (R) |
| **TSE** | Dados eleitorais por municipio | dadosabertos.tse.jus.br |
| **CNESNet** | Cadastro de estabelecimentos | cnes.datasus.gov.br |
| **IBGE** | Dados geograficos e socioeconomicos | ibge.gov.br |
| **DOU** | Portarias e oportunidades de financiamento | in.gov.br |
| **SIGTAP** | Codigos e valores de procedimentos | sigtap.datasus.gov.br |

**Stack:** R (tidyverse, microdatasus), Python (pandas, polars), SQL, BigQuery, Claude Code, Plotly, D3.js, Leaflet

---

## 7. INTEGRACOES E INFRAESTRUTURA

| Ferramenta | Funcao | Acesso |
|-----------|--------|--------|
| **Obsidian** | Memoria persistente entre sessoes | Filesystem direto: `C:\Users\pedro\Documents\mente\THAUMA\` |
| **Notion** | CRM externo (leads, pipeline) | MCP Server |
| **Google Workspace** | Drive, Docs, Calendar | MCP Server (em configuracao) |
| **GitHub** | Repositorio da equipe | github.com/thauma-consultoria/thauma-staff |
| **BigQuery** | Data Lake | Projeto: thauma-datalake |
| **Brave Search** | Pesquisa web para agentes | MCP Server |
| **Firecrawl** | Web scraping | MCP Server |
| **Nano-Banana-Pro** | Geracao de imagens (Gemini) | MCP Server |

### Obsidian — Estrutura de Memoria

```
C:\Users\pedro\Documents\mente\THAUMA\
├── 10-CRM/           (prospects, clientes, pipeline)
├── 20-Projetos/      (entregas ativas)
├── 30-Reunioes/      (atas, call logs)
├── 40-Conhecimento/  (DATASUS, legislacao, metodologias)
├── 50-Tarefas/       (daily/weekly tracking)
├── 60-Estrategia/    (decisoes, aprendizados, roadmap)
└── 70-Equipe/        (diarios por gerente entre sessoes)
```

Protocolo completo: `.claude/agents/_protocolo_obsidian.md`

### Notion — CRM

- **Hub principal:** `2a865b5b-3f9e-802d-ba91-c6b5ecca2fc2`
- **Database Leads:** `2a865b5b-3f9e-803e-9d3b-e246d7a53f88`

---

## 8. COMANDOS DE ALTO NIVEL

### CEO (Socrates)
| Comando | O que faz |
|---------|-----------|
| `revisar pipeline` | Review estrategico de leads, conversoes, proximos passos |
| `priorizar semana` | 3 prioridades da semana, nao mais |
| `avaliar prospect [hospital]` | Analise estrategica: vale investir tempo? |
| `coordenar entrega [cliente]` | Orquestracao cross-departamento |
| `entrevistar [tema]` | Entrevista estruturada para documentos |

### Marketing (Pericles)
| Comando | O que faz |
|---------|-----------|
| `planejar semana` | Editorial + outbound + metricas |
| `produzir inbound` | Aristoteles → Euclides → Caliope → Dedalo |
| `executar outbound` | Hermes → Agora |
| `analisar [hospital]` | Euclides gera dados SAT |
| `preparar call [prospect]` | Briefing SPIN + dados + script |
| `prospectar [regiao]` | Agora enriquece lista |

### Dados (Pitagoras)
| Comando | O que faz |
|---------|-----------|
| `carregar data lake` | Pipeline completo de extracao |
| `atualizar [base] [periodo]` | Carga incremental |
| `analisar [hospital/CNES]` | SAT completo + perfil |
| `status data lake` | Freshness, completude, custos |
| `vazios [procedimento] [UF]` | Mapa de vazios assistenciais |

### Projetos (Arquimedes)
| Comando | O que faz |
|---------|-----------|
| `iniciar prisma [cliente]` | Cria projeto e aciona pipeline |
| `status entregas` | Report de todos os projetos ativos |

### Financeiro (Tales)
| Comando | O que faz |
|---------|-----------|
| `status financeiro` | Receita, pagamentos, cash flow |
| `precificar [produto]` | Analise de pricing |

### Operacoes (Hefesto)
| Comando | O que faz |
|---------|-----------|
| `ritual semanal` | Checklist da segunda-feira |
| `relatorio kpis [periodo]` | Dashboard consolidado |

---

## 9. PIPELINE DE ENTREGA DO PRISMA

```
Dia 0:     Contrato assinado + Parcela 1
               ↓
Dia 1-5:   [DADOS] Pitagoras extrai, enriquece, calcula SAT
               ↓
Dia 6-12:  [MARKETING] Caliope redige Dossie + Euclides gera dashboards
               ↓
Dia 13-18: [MARKETING] Pitch decks + Playbook
               ↓
Dia 19-22: [REVISAO] Arquimedes + Solon revisam qualidade e compliance
               ↓
Dia 23-25: [ENTREGA] Pedro apresenta ao cliente + Parcela 2
```

---

## 10. IDENTIDADE VISUAL

| Cor | Hex | Uso |
|-----|-----|-----|
| Azul Profundo | `#001070` | Base estrutural (60-70%) |
| Branco Absoluto | `#FFFFFF` | Espaco de clareza (20-30%) |
| Ciano Tecnologico | `#40D7FF` | Destaques reveladores (5-10%) |

**Tipografia:** Helvetica Bold/Medium (titulos) | Hahmlet Regular (corpo) | Hahmlet Bold (dados)

**Tom de voz:** Culto, direto, baseado em evidencias. Nunca generico ou corporativo vazio.

**Palavras proibidas:** ~~Dica~~ → Estrategia | ~~Truque~~ → Metodo | ~~Custo~~ → Investimento | ~~Ajuda~~ → Parceria

---

## 11. REGRAS OPERACIONAIS

1. **Tom THAUMA** — culto, direto, baseado em evidencias
2. **Dados > Opinioes** — sem numero, nao ha argumento
3. **Personalizacao obrigatoria** — nada sai sem dados do prospect-alvo
4. **Segregacao FHEMIG/THAUMA** — absoluta e inviolavel
5. **Rede > Cold** — priorizar indicacoes e conexoes quentes
6. **Obsidian = memoria** — toda informacao relevante para continuidade registrada
7. **Git sincronizado** — Socrates faz pull no inicio e push no final de cada sessao
8. **Identidade visual inegociavel** — #001070 / #FFFFFF / #40D7FF + Helvetica/Hahmlet

---

## 12. COMPLIANCE: FHEMIG x THAUMA

**Segregacao absoluta:**

| Dimensao | FHEMIG | THAUMA |
|----------|--------|--------|
| Software | TabWin, sistemas internos | R, Python, Claude Code |
| Dados | Bases internas das unidades | Bases publicas DATASUS |
| Equipamento | Maquinas e rede FHEMIG | Equipamentos pessoais |
| Horario | Expediente funcional | Fora do expediente |
| Prospects | NUNCA hospitais da rede FHEMIG | Hospitais externos |

**Cidades blacklist (hospitais FHEMIG):** Barbacena, Belo Horizonte, Juiz de Fora, Patos de Minas

**Resolucao definitiva:** Licenca do servico publico (meta: quando atingir R$ 25K/mes de renda recorrente).

---

## 13. GLOSSARIO

| Termo | Significado |
|-------|-------------|
| **Thaumazein** | O espanto filosofico — origem do nome THAUMA |
| **Doxa** | Opiniao subjetiva, abordagem amadora |
| **Episteme** | Conhecimento verdadeiro, abordagem cientifica |
| **Aletheia** | Verdade desvelada |
| **SAT** | Score de Alinhamento Territorial |
| **Prisma** | Produto flagship de inteligencia politica |
| **Mini-Prisma** | Diagnostico 3 paginas (lead magnet) |
| **Vazio Assistencial** | Municipios sem cobertura de procedimento |
| **CEBAS** | Certificacao de entidade beneficente |

---

*Documento atualizado em: Abril 2026*
*Proxima revisao recomendada: Outubro 2026*

---
**THAUMA Inteligencia & Narrativa em Saude**
*"O espanto da descoberta. A ciencia do resultado."*
