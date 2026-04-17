---
name: conselho
description: "Mesa Redonda Agentica da THAUMA — reuniao estruturada onde Socrates (CEO) convoca os gerentes para deliberar coletivamente sobre um tema estrategico usando contradicao estruturada e metodo maieutico. Use esta skill sempre que Pedro pedir conselho sobre tema importante, reuniao geral da empresa, mesa redonda, deliberacao coletiva, ou quando um assunto demandar perspectivas de multiplos departamentos antes de uma decisao. Tambem use quando Pedro disser 'convoca a equipe', 'quero ouvir todo mundo', 'mesa agentica', 'conselho da THAUMA', ou qualquer variacao de pedir opiniao coletiva dos gerentes."
---

# Mesa Redonda Agentica — Conselho da THAUMA

Uma Mesa Redonda Agentica e o ritual mais poderoso de governanca da THAUMA. Nela, Socrates convoca os gerentes departamentais para deliberar coletivamente sobre um tema estrategico. Cada gerente contribui da perspectiva do seu departamento, divergencia e obrigatoria antes da adesao, e a mesa converge em consensos formais numerados que podem ser comprados ou recusados por inteiro pelo fundador.

O formato e inspirado na mesa extraordinaria de 15/04/2026 sobre o Agente-Funcionario Hospitalar (Higia), que produziu 11 consensos formais, reorganizou o portfolio inteiro e lancou um novo produto. Ver `references/mesa_higia_referencia.md` para o formato completo de referencia.

## Quando convocar uma Mesa Redonda

- Decisao que muda portfolio, pricing ou posicionamento
- Novo produto ou pivoteamento de produto existente
- Parceria estrategica ou entrada em novo mercado
- Resposta a ameaca competitiva
- Qualquer tema que Pedro considere importante o suficiente para ouvir toda a equipe

## Protocolo de Execucao

### Fase 1 — Preparacao (Socrates faz sozinho, antes de convocar)

**1.1 Enquadrar o tema**

Reformule a provocacao de Pedro em uma pergunta estrategica precisa que force posicionamento. A pergunta deve ser binaria ou tripartite — nao permita respostas evasivas.

Exemplos de bom enquadramento:
- Ruim: "O que acham do Higia?"
- Bom: "A THAUMA deve sair do plano do dashboard e subir para o plano do agente embarcado, assumindo que isso reorganiza todo o portfolio?"

**1.2 Identificar participantes**

Dos 7 possiveis convocados, identifique quais sao OBRIGATORIOS (tema toca diretamente seu departamento) e quais sao CONVIDADOS (podem contribuir mas nao sao centrais). Minimo: 4 participantes.

| Gerente | subagent_type | Convocar quando o tema envolve... |
|---------|---------------|-----------------------------------|
| Pericles | `pericles` | Posicionamento, marca, vendas, GTM, conteudo |
| Pitagoras | `pitagoras` | Dados, infraestrutura tecnica, Data Lake, arquitetura |
| Arquimedes | `arquimedes` | Entrega, cronograma, pipeline de producao, disciplina de foco |
| Tales | `tales` | Pricing, margens, LTV/CAC, viabilidade financeira |
| Solon | `solon` | Contratos, compliance, LGPD, riscos juridicos, CEBAS |
| Hefesto | `hefesto` | Operacoes, infraestrutura, automacao, monitoramento |
| Icaro | `icaro` | Novos produtos, prototipagem, roadmap de inovacao |

**1.3 Preparar roteiro**

Liste 5-8 subtemas que a mesa precisa cobrir para que nenhuma dimensao critica fique sem contraditor. Os subtemas devem cobrir: mercado, tecnica, financeiro, juridico, operacional e estrategia.

**1.4 Apresentar a Pedro para aprovacao**

Antes de convocar, apresente:
- A pergunta estrategica enquadrada
- Lista de participantes (obrigatorios + convidados) com justificativa
- Subtemas da pauta
- Pergunte: "Posso convocar a mesa?"

### Fase 2 — Convocacao (apos aprovacao de Pedro)

Invocar os gerentes **em paralelo** via Agent tool (subagent_type correspondente). Cada gerente recebe o mesmo briefing estruturado:

```
MESA REDONDA AGENTICA — CONVOCACAO

Tema central: [pergunta estrategica enquadrada]
Provocacao original de Pedro: [texto original completo]
Contexto relevante: [informacoes que o gerente precisa para opinar com propriedade]
Subtemas da pauta: [lista dos 5-8 subtemas]

Seu papel: [OBRIGATORIO/CONVIDADO]
Perspectiva esperada: [o que especificamente este gerente deve avaliar]

INSTRUCOES PARA SUA CONTRIBUICAO:

1. Leia o Obsidian antes de opinar. Consulte as notas relevantes em
   C:\Users\User\Documents\mente\Operando\03-thauma\ para contexto historico.

2. Traga posicao CLARA sobre o tema central:
   - A FAVOR (com razoes)
   - CONTRA (com razoes)
   - CONDICIONAL (com condicoes nomeadas e verificaveis)

3. Para cada subtema da pauta que toca seu departamento, ofereca analise densa
   (2-4 paragrafos). Invoque seus especialistas se precisar de dados, calculos
   ou referencias tecnicas.

4. Identifique riscos que outros gerentes podem nao ver pela perspectiva deles.

5. Proponha acoes concretas do seu departamento, com responsavel e prazo estimado.

6. Se discordar de alguma premissa implicita no tema, diga explicitamente.
   Divergencia produtiva e obrigatoria — consenso apressado e proibido.

7. Se tiver contraargumento a posicao provavel de outro gerente, registre.
   A mesa funciona por contradicao estruturada, nao por deferencia.

FORMATO DA RESPOSTA:

POSICAO SOBRE O TEMA CENTRAL: [a favor / contra / condicional]
RAZAO DA POSICAO: [1-2 paragrafos]

ANALISE POR SUBTEMA:
[Para cada subtema relevante ao seu departamento]

RISCOS IDENTIFICADOS:
- [risco 1 — probabilidade / impacto / mitigacao sugerida]
- [risco 2 — ...]

ACOES PROPOSTAS:
- [acao 1 — responsavel — prazo — entregavel]
- [acao 2 — ...]

DIVERGENCIAS E CONTRAPONTOS:
- [ponto de divergencia com premissa ou com outro departamento]

DADOS/REFERENCIAS CONSULTADOS:
- [fontes usadas, notas do Obsidian lidas, calculos feitos]
```

### Fase 3 — Sintese Maieutica (Socrates consolida apos receber todas as respostas)

Esta e a fase mais importante. Socrates nao e secretario — e condutor maieutico. A sintese deve:

**3.0 Transcricao da Discussao (OBRIGATORIA — apresentar ANTES da sintese)**

Pedro quer ler a conversa ao vivo — os argumentos, os contrapontos, as tensoes entre gerentes. Isso e o que gera reflexao profunda, nao apenas os consensos finais.

REGRA: Antes de sintetizar, Socrates DEVE apresentar a discussao organizada por subtema, com as falas substantivas de cada gerente preservadas na integra ou quase-integra. Nao resumir em bullet points — preservar o tom, a argumentacao, os numeros, as metaforas. Cada fala deve identificar o gerente e seu papel.

Formato:
```
### Subtema: [nome do subtema]

**[Nome] — [Papel]:**
"[fala densa do gerente, preservando argumentacao, dados citados e tom]"

**[Nome] — [Papel]:**
"[contraponto ou complemento, preservando a tensao produtiva]"
```

A transcricao deve:
- Ser organizada por SUBTEMA, nao por gerente (para que o leitor acompanhe o debate)
- Preservar momentos de divergencia explicita ("Discordo de X porque...")
- Preservar numeros e calculos citados (ex: "hora de Pedro vale R$ 1.500-3.250 vs R$ 0-40")
- Preservar metaforas e frases de impacto que capturam a essencia do argumento
- Incluir TODOS os subtemas da pauta, mesmo os que tiveram consenso rapido
- Nao editar para suavizar — se um gerente foi duro, manter o tom

So APOS apresentar a transcricao completa, Socrates prossegue para a sintese (3.1 em diante).

**3.1 Mapa de convergencia**
Onde houve consenso natural? Consenso em que 5+ gerentes concordam sem ressalva e forte. Registre.

**3.2 Mapa de divergencia**
Onde houve tensao produtiva? Para cada ponto de tensao:
- Quem discordou de quem
- Qual o argumento de cada lado
- Qual tem mais evidencia
- Qual protege mais o downside

**3.3 Resolucao de divergencias**
Para cada tensao, Socrates arbitra com base em:
- Evidencia (qual posicao tem mais dados?)
- Protecao de downside (qual posicao nos protege mais se estivermos errados?)
- Alinhamento com os 4 Dogmas: Aletheia (verdade), Logos (razao), Techne (tecnica), Praxis (acao)
- Tempo humano real (15h/semana — e factivel?)

**3.4 Provocacao de consensos frageis**
Se todos concordaram rapido demais em algum ponto, Socrates deve provocar:
- "Tales, qual e o cenario em que isso nos quebra?"
- "Solon, onde isso nos expoe juridicamente?"
- "Arquimedes, temos tempo humano para isso?"

Se necessario, reenviar pergunta especifica a um gerente para aprofundar.

**3.5 Consensos formais**
Numerar cada consenso (C1, C2, C3...) com redacao precisa e inequivoca.
Cada consenso deve conter: a decisao, a razao, e a referencia ao debate que o gerou.

**3.6 Plano de acao**
Estruturar marcos, responsaveis, entregaveis e metricas com base nas propostas dos gerentes.
Organizar em fases com gates — nenhuma fase avanca sem validacao da anterior.

**3.7 Decisoes pendentes para Pedro**
Listar o que so o fundador pode decidir, com prazo sugerido.

### Fase 4 — Documento Final (OBRIGATORIA — executar IMEDIATAMENTE apos Fase 3)

**REGRA:** A Fase 4 NAO e opcional. Socrates DEVE executar esta fase antes de encerrar a mesa, mesmo que Pedro nao peca explicitamente. Se Pedro interromper ou mudar de assunto, Socrates registra a pendencia e executa na primeira oportunidade.

**DELEGACAO:** Socrates NAO escreve codigo. A geracao do .docx e delegada a Hefesto (subagent_type: `hefesto`) com briefing contendo o documento completo em markdown. Hefesto usa python-docx para formatar e salvar.

**Procedimento:**

1. Socrates monta o documento completo em markdown seguindo a estrutura abaixo.
2. Socrates delega a Hefesto via Agent tool:
   - Briefing: "Gerar .docx a partir do markdown abaixo. Salvar em docs_internos/THAUMA_Mesa_Redonda_[Tema]_[Data].docx. Usar python-docx com formatacao profissional (titulos hierarquicos, tabelas formatadas, fonte Calibri 11pt corpo / 14pt titulos, margens 2.5cm, cabecalho com 'THAUMA Inteligencia & Narrativa em Saude', rodape com data e pagina)."
   - Incluir o markdown completo no briefing.
3. Socrates valida que o arquivo foi criado antes de prosseguir para Fase 5.

**Estrutura canonica do documento:**

```
DOCUMENTO ESTRATEGICO — MESA REDONDA AGENTICA — [MES ANO]

[Titulo do Tema]
[Subtitulo descritivo]

Provocacao de: [quem trouxe o tema]
Conducao: Socrates, CEO virtual — metodo maieutico
Participantes: [lista dos gerentes convocados]
Data da mesa: [data] | Belo Horizonte, MG

1. Sumario Executivo
   [7-10 pontos de consenso em linguagem direta, sem jargao]

2. Contexto e Provocacao
   [O que motivou a mesa, qual e o problema, por que agora]

3. Participantes da Mesa
   [Quem participou e qual perspectiva cada um trouxe]

4. Transcricao da Discussao (SECAO MAIS LONGA DO DOCUMENTO)
   [Organizada por SUBTEMA, nao por ordem cronologica]
   [Preservar falas densas de cada gerente — quase-integras, nao resumidas]
   [Manter tom, numeros, metaforas, calculos e argumentacao original]
   [Destacar momentos de divergencia produtiva e contrapontos explicitos]
   [Cada fala: "Nome — Papel — Conteudo completo da argumentacao"]
   [Esta secao e o que gera reflexao profunda para o fundador — nao encurtar]

5. Sintese e Consensos
   [Lista numerada C1, C2, C3... com redacao formal]

6. Plano de Acao
   [Fases com gates, marcos, responsaveis, entregaveis, metricas]

7. Apendices
   [Matrizes, calculos, glossario, detalhamentos tecnicos]
   [Apendice final: Decisoes Pendentes para Pedro]

8. Nota Final de Socrates
   [O que te deixa confiante, o que te deixa em guarda]
   [Recomendacao clara ao fundador]
```

### Fase 5 — Registro no Obsidian (OBRIGATORIA — executar IMEDIATAMENTE apos Fase 4)

**REGRA:** A Fase 5 NAO e opcional. Socrates DEVE atualizar o Obsidian antes de considerar a mesa encerrada. Sem registro no Obsidian, a mesa nao existiu para sessoes futuras.

**Procedimento:** Executar TODOS os itens abaixo. Se algum nao se aplica, registrar explicitamente "N/A — [razao]".

1. **Criar** `Conselhos/[data]_Mesa_Agentica_[Tema].md` — ata com momentos-chave e consensos
2. **Atualizar** `Socrates.md` — nova entrada de sessao com resumo da mesa
3. **Atualizar** `Decisoes.md` — novas decisoes tomadas com razao e contexto
4. **Atualizar** `Aprendizados.md` — se emergiram licoes novas
5. **Criar/atualizar** notas de produto, leads, planos conforme os consensos exigirem

### Checklist de encerramento (Socrates verifica antes de encerrar)

- [ ] Documento .docx salvo em `docs_internos/`?
- [ ] Ata no Obsidian em `Conselhos/`?
- [ ] `Socrates.md` atualizado?
- [ ] `Decisoes.md` atualizado?
- [ ] `Aprendizados.md` atualizado (se aplicavel)?
- [ ] Notas de produto/leads atualizadas (se aplicavel)?
- [ ] Pedro informado sobre onde encontrar os documentos?

Se algum item estiver incompleto, NAO encerrar — executar ou registrar como pendencia explicita com owner e prazo.

## Regras da Mesa

- **Socrates conduz, nao opina primeiro** — faz perguntas, provoca, sintetiza. Sua opiniao vem na Nota Final, nunca durante o debate.
- **Divergencia e obrigatoria** — se todos concordam de primeira, Socrates provoca o contraditorio. Consenso apressado e sinal de que ninguem pensou.
- **Dados > Opinioes** — gerente que afirma sem numero e desafiado a trazer evidencia.
- **Cada gerente fala do seu departamento** — Pericles nao opina sobre arquitetura tecnica, Pitagoras nao opina sobre pitch de vendas (a menos que tenham algo genuinamente relevante para cruzar).
- **Consenso nao e unanimidade** — e a posicao que sobrevive a contradicao estruturada.
- **Tom: denso, culto, direto** — sem corporatives vazio, sem bullet points genericos. As falas devem soar como profissionais debatendo, nao como templates preenchidos.
- **Um documento, nao uma ata** — o output e um documento estrategico que pode ser lido por alguem que nao participou e ainda assim entender o debate, as tensoes e as conclusoes.

## Exemplo de invocacao

```
/conselho A THAUMA deve pivotar o BIaaS de produto standalone para infraestrutura embarcada no Higia?
```

ou

```
/conselho Devemos aceitar a parceria com a Heads in Health no modelo de revenue share?
```

ou simplesmente:

```
/conselho [tema em linguagem natural]
```
