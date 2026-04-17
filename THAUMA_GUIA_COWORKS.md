# THAUMA — GUIA OPERACIONAL
## Inteligência & Narrativa em Saúde

**Versão:** 2.0 | Abril 2026
**Fundador:** Pedro William Ribeiro Diniz
**Uso:** Documento de orientação para operar a equipe multiagente THAUMA via Claude Code

---

## 1. QUEM SOMOS

**THAUMA — Inteligência & Narrativa em Saúde** é uma consultoria que promove ganho de eficiência, escala, qualidade e profissionalismo para gestores de saúde pública e prestadores de serviço no SUS, por meio de tecnologia, IA e dados públicos de saúde.

**Fundação:** Dezembro de 2025 | **CNPJ:** Constituído e regularizado

### Sócios

| Sócio | Papel | Dedicação |
|-------|-------|-----------|
| **Pedro William Ribeiro Diniz** | Fundador. Dados, estratégia, metodologia. | 8-10h/semana |
| **Vinícius de Paula Prudente Aquino** | Administrador formal. Vendas e tecnologia. | Mínima (por acordo) |
| **Bruno Volpini Guimarães** | Design de produto. | 4-5h/semana |

### Filosofia: DOXA → EPISTEME

- **Doxa** = opinião subjetiva, gestão por intuição, pedidos emocionais
- **Episteme** = conhecimento verdadeiro, gestão por dados, argumentação estruturada
- **Thaumazein** = o espanto revelador quando o gestor descobre o que não sabia sobre seu próprio hospital

**Tagline:** *"O espanto da descoberta. A ciência do resultado."*

---

## 2. EQUIPE MULTIAGENTE

A THAUMA opera com 25 agentes de IA organizados em 6 departamentos, coordenados por um CEO virtual (Sócrates). Todos os agentes estão definidos em `.claude/agents/`.

### Organograma

```
Pedro + Vinícius + Bruno (Sócios Humanos)
                |
          Sócrates (CEO)
                |
    +-----------+-----------+-----------+-----------+-----------+
    |           |           |           |           |           |
 Péricles   Pitágoras    Sólon      Tales     Arquimedes   Hefesto
 MARKETING    DADOS     JURÍDICO  FINANCEIRO  PROJETOS   OPERAÇÕES
```

### Departamentos

| Dept | Gerente (Opus) | Agentes (Sonnet) | Função |
|------|----------------|------------------|--------|
| **Marketing** | Péricles | Euclides, Aristóteles, Calíope, Dédalo, Hermes, Ágora | Inbound, outbound, conteúdo, prospecção |
| **Dados** | Pitágoras | Heráclito, Hipaso, Anaxágoras, Ptolomeu | Data Lake, ETL, analytics, Score SAT |
| **Jurídico** | Sólon | Têmis, Licurgo | Contratos, compliance, LGPD |
| **Financeiro** | Tales | Creso, Xenofonte | Faturamento, pricing, projeções |
| **Projetos** | Arquimedes | Teseu, Ícaro | Entrega de Prisma, novos produtos |
| **Operações** | Hefesto | Atlas, Cronos | Integrações, automações, KPIs |

### Como Invocar

Os agentes são invocados via `subagent_type` no Claude Code:
- Gerentes: `subagent_type: "pericles"`, `"pitagoras"`, `"solon"`, `"tales"`, `"arquimedes"`, `"hefesto"`
- CEO: `subagent_type: "ceo"`
- Sub-agentes: `subagent_type: "euclides"`, `"caliope"`, `"hermes"`, etc.

---

## 3. PORTFÓLIO DE PRODUTOS

### Vertical 1: Inteligência Política (Consolidada)

**Prisma de Captação** — Produto flagship. 4 componentes:

| # | Componente | Descrição |
|---|-----------|-----------|
| 1 | **Dossiê de Evidências** | Análise epidemiológica + impacto regional + ROI político (40-60 pgs) |
| 2 | **Radar Político** | Dashboard DATASUS x TSE + Top 10 Parlamentares via Score SAT |
| 3 | **Dialética de Convencimento** | Pitch deck personalizado por parlamentar (15-20 slides) |
| 4 | **Retórica da Influência** | Playbook com roteiros, objeções, cronograma (20-30 pgs) |

**Investimento:** R$ 24.000 – R$ 26.000
**Prazo:** 20-30 dias úteis
**Pagamento:** 50% no início + 50% na entrega

**Mini-Prisma:** Diagnóstico gratuito de 3 páginas com 3 insights — lead magnet.

### Vertical 2: Inteligência Assistencial (Consolidada)

BI as a Service para hospitais. Dashboards, relatórios, tratamento de dados DATASUS.

| Entrega | Investimento |
|---------|-------------|
| Setup de dashboard completo | R$ 4.000 – R$ 5.000 |
| Nutrição mensal | R$ 1.500/mês |

**Lógica:** Prisma abre a porta (projeto de impacto), BI constrói a recorrência.

### Verticais em Roadmap

- **Inteligência Artificial** — Agentes autônomos para back-office hospitalar
- **Marketing Hospitalar** — Substituir agências tradicionais

### Score SAT (Score de Alinhamento Territorial)

```
SAT = (Votos do Parlamentar no Município / 1.000) x (Pacientes do Município / 100)
```

---

## 4. CLIENTE IDEAL (ICP)

**Camada 1 — Core:**
- Hospitais filantrópicos certificados (CEBAS) / Santas Casas
- Porte médio a grande (50+ leitos)
- Interior de estados (alta dependência regional)

**Camada 2 — Agentes públicos:**
- Parlamentares (deputados estaduais/federais)
- Secretários municipais de saúde

**Camada 3 — Prestadores de serviço ao SUS:**
- Empresas de locação de mão de obra médica
- Gestoras de UTIs terceirizadas
- Fornecedores de materiais e serviços hospitalares

**Decisor típico:** Diretor/Gestor com formação técnica, frustrado com captação amadora, difícil de acessar.

---

## 5. COMO VENDEMOS

### Canal Primário: Rede e Indicação

O único canal que converteu até agora. Confiança vende, dado convence, cold não funciona sozinho.

**Conectores ativos:**
- **Fabrício** — já trouxe leads (Hospital São João de Deus de Vinópolis)
- **Dr. Rodrigo Kleinpaul** — conectando Manhuaçu
- **Dr. Bernardo Ramos** — rede política ampla
- **Cláudia Hermínia** — conselhos de gestão em BH

### Canal Secundário: Inbound LinkedIn

Produção de conteúdo para construção de autoridade. Gera credibilidade, não conversão direta.

**3 Pilares de Conteúdo:**
1. Gestão Hospitalar Baseada em Dados
2. Governança, Contratualização e Sustentabilidade no SUS
3. Tecnologia, IA e Realidade da Gestão Pública

### Canal Complementar: Outbound Frio

Cold call/email. Conversão baixa. Complementar, nunca motor.

### Metodologia SPIN Selling (Calls de 15 min)

```
MIN 0-2:   ABERTURA + 1 insight específico do hospital
MIN 2-5:   SITUATION + PROBLEM (perguntas diagnósticas)
MIN 5-8:   REVELAÇÃO (3 insights: volume, SAT, custo evitado)
MIN 8-11:  IMPLICATION + NEED-PAYOFF (amplificar dor)
MIN 11-15: PITCH + próximo passo (Mini-Prisma ou reunião técnica)
```

---

## 6. FONTES DE DADOS

| Base | Uso | Acesso |
|------|-----|--------|
| **DATASUS / SIH-SIA** | Produção hospitalar (AIH, BPA) | datasus.saude.gov.br / microdatasus (R) |
| **TSE** | Dados eleitorais por município | dadosabertos.tse.jus.br |
| **CNESNet** | Cadastro de estabelecimentos | cnes.datasus.gov.br |
| **IBGE** | Dados geográficos e socioeconômicos | ibge.gov.br |
| **DOU** | Portarias e oportunidades de financiamento | in.gov.br |
| **SIGTAP** | Códigos e valores de procedimentos | sigtap.datasus.gov.br |

**Stack:** R (tidyverse, microdatasus), Python (pandas, polars), SQL, BigQuery, Claude Code, Plotly, D3.js, Leaflet

---

## 7. INTEGRAÇÕES E INFRAESTRUTURA

| Ferramenta | Função | Acesso |
|-----------|--------|--------|
| **Obsidian** | Memória persistente entre sessões | Filesystem direto: `C:\Users\pedro\Documents\mente\THAUMA\` |
| **Notion** | CRM externo (leads, pipeline) | MCP Server |
| **Google Workspace** | Drive, Docs, Calendar | MCP Server (em configuração) |
| **GitHub** | Repositório da equipe | github.com/thauma-consultoria/thauma-staff |
| **BigQuery** | Data Lake | Projeto: thauma-datalake |
| **Brave Search** | Pesquisa web para agentes | MCP Server |
| **Firecrawl** | Web scraping | MCP Server |
| **Nano-Banana-Pro** | Geração de imagens (Gemini) | MCP Server |

### Obsidian — Estrutura de Memória

```
C:\Users\pedro\Documents\mente\THAUMA\
├── 10-CRM/           (prospects, clientes, pipeline)
├── 20-Projetos/      (entregas ativas)
├── 30-Reunioes/      (atas, call logs)
├── 40-Conhecimento/  (DATASUS, legislação, metodologias)
├── 50-Tarefas/       (daily/weekly tracking)
├── 60-Estrategia/    (decisões, aprendizados, roadmap)
└── 70-Equipe/        (diários por gerente entre sessões)
```

Protocolo completo: `.claude/agents/_protocolo_obsidian.md`

### Notion — CRM

- **Hub principal:** `2a865b5b-3f9e-802d-ba91-c6b5ecca2fc2`
- **Database Leads:** `2a865b5b-3f9e-803e-9d3b-e246d7a53f88`

---

## 8. COMANDOS DE ALTO NÍVEL

### CEO (Sócrates)
| Comando | O que faz |
|---------|-----------|
| `revisar pipeline` | Review estratégico de leads, conversões, próximos passos |
| `priorizar semana` | 3 prioridades da semana, não mais |
| `avaliar prospect [hospital]` | Análise estratégica: vale investir tempo? |
| `coordenar entrega [cliente]` | Orquestração cross-departamento |
| `entrevistar [tema]` | Entrevista estruturada para documentos |

### Marketing (Péricles)
| Comando | O que faz |
|---------|-----------|
| `planejar semana` | Editorial + outbound + métricas |
| `produzir inbound` | Aristóteles → Euclides → Calíope → Dédalo |
| `executar outbound` | Hermes → Ágora |
| `analisar [hospital]` | Euclides gera dados SAT |
| `preparar call [prospect]` | Briefing SPIN + dados + script |
| `prospectar [região]` | Ágora enriquece lista |

### Dados (Pitágoras)
| Comando | O que faz |
|---------|-----------|
| `carregar data lake` | Pipeline completo de extração |
| `atualizar [base] [período]` | Carga incremental |
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
| `precificar [produto]` | Análise de pricing |

### Operações (Hefesto)
| Comando | O que faz |
|---------|-----------|
| `ritual semanal` | Checklist da segunda-feira |
| `relatório kpis [período]` | Dashboard consolidado |

---

## 9. PIPELINE DE ENTREGA DO PRISMA

```
Dia 0:     Contrato assinado + Parcela 1
               ↓
Dia 1-5:   [DADOS] Pitágoras extrai, enriquece, calcula SAT
               ↓
Dia 6-12:  [MARKETING] Calíope redige Dossiê + Euclides gera dashboards
               ↓
Dia 13-18: [MARKETING] Pitch decks + Playbook
               ↓
Dia 19-22: [REVISÃO] Arquimedes + Sólon revisam qualidade e compliance
               ↓
Dia 23-25: [ENTREGA] Pedro apresenta ao cliente + Parcela 2
```

---

## 10. IDENTIDADE VISUAL

| Cor | Hex | Uso |
|-----|-----|-----|
| Azul Profundo | `#001070` | Base estrutural (60-70%) |
| Branco Absoluto | `#FFFFFF` | Espaço de clareza (20-30%) |
| Ciano Tecnológico | `#40D7FF` | Destaques reveladores (5-10%) |

**Tipografia:** Helvetica Bold/Medium (títulos) | Hahmlet Regular (corpo) | Hahmlet Bold (dados)

**Tom de voz:** Culto, direto, baseado em evidências. Nunca genérico ou corporativo vazio.

**Palavras proibidas:** ~~Dica~~ → Estratégia | ~~Truque~~ → Método | ~~Custo~~ → Investimento | ~~Ajuda~~ → Parceria

---

## 11. REGRAS OPERACIONAIS

1. **Tom THAUMA** — culto, direto, baseado em evidências
2. **Dados > Opiniões** — sem número, não há argumento
3. **Personalização obrigatória** — nada sai sem dados do prospect-alvo
4. **Segregação FHEMIG/THAUMA** — absoluta e inviolável
5. **Rede > Cold** — priorizar indicações e conexões quentes
6. **Obsidian = memória** — toda informação relevante para continuidade registrada
7. **Git sincronizado** — Sócrates faz pull no início e push no final de cada sessão
8. **Identidade visual inegociável** — #001070 / #FFFFFF / #40D7FF + Helvetica/Hahmlet

---

## 12. COMPLIANCE: FHEMIG x THAUMA

**Segregação absoluta:**

| Dimensão | FHEMIG | THAUMA |
|----------|--------|--------|
| Software | TabWin, sistemas internos | R, Python, Claude Code |
| Dados | Bases internas das unidades | Bases públicas DATASUS |
| Equipamento | Máquinas e rede FHEMIG | Equipamentos pessoais |
| Horário | Expediente funcional | Fora do expediente |
| Prospects | NUNCA hospitais da rede FHEMIG | Hospitais externos |

**Cidades blacklist (hospitais FHEMIG):** Barbacena, Belo Horizonte, Juiz de Fora, Patos de Minas

**Resolução definitiva:** Licença do serviço público (meta: quando atingir R$ 25K/mês de renda recorrente).

---

## 13. GLOSSÁRIO

| Termo | Significado |
|-------|-------------|
| **Thaumazein** | O espanto filosófico — origem do nome THAUMA |
| **Doxa** | Opinião subjetiva, abordagem amadora |
| **Episteme** | Conhecimento verdadeiro, abordagem científica |
| **Aletheia** | Verdade desvelada |
| **SAT** | Score de Alinhamento Territorial |
| **Prisma** | Produto flagship de inteligência política |
| **Mini-Prisma** | Diagnóstico 3 páginas (lead magnet) |
| **Vazio Assistencial** | Municípios sem cobertura de procedimento |
| **CEBAS** | Certificação de entidade beneficente |

---

*Documento atualizado em: Abril 2026*
*Próxima revisão recomendada: Outubro 2026*

---
**THAUMA Inteligência & Narrativa em Saúde**
*"O espanto da descoberta. A ciência do resultado."*
