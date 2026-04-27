# Nota Metodológica — Levantamento Nacional de Cirurgias Cardiovasculares SUS 2025

**Para:** Dr. Maikon Almeida — GSS Saúde
**De:** THAUMA Inteligência & Narrativa em Saúde
**Data de entrega:** 27/04/2026
**Documento de referência da entrega:** `cardio_sus_2025_gss.xlsx`

---

## 1. Apresentação

Este documento acompanha a planilha `cardio_sus_2025_gss.xlsx` e tem propósito único: tornar transparentes as decisões metodológicas adotadas na construção do levantamento, de modo que o senhor possa defendê-las em qualquer fórum técnico. Em síntese: extraímos do SIH-SUS, base oficial do Ministério da Saúde, todas as Autorizações de Internação Hospitalar (AIH) processadas no ano-calendário de 2025 cujo procedimento realizado pertença ao escopo de 23 códigos SIGTAP definidos em conjunto com o senhor; agregamos por hospital prestador (CNES); calculamos volume e taxa de mortalidade; e diagramamos o resultado em planilha de seis abas, com camada de defesa metodológica integrada. Tudo o que está nesse arquivo é rastreável até a fonte primária do DATASUS.

---

## 2. Escopo

| Dimensão | Definição |
|----------|-----------|
| **Período** | 1º de janeiro a 31 de dezembro de 2025 (ano-calendário completo) |
| **Geografia** | Brasil — todas as 27 unidades da federação |
| **Universo de prestadores** | Todos os hospitais que faturaram AIH ao SUS no período, independentemente da natureza jurídica (público, filantrópico, privado contratado) |
| **Base de dados primária** | SIH-SUS (Sistema de Informações Hospitalares do SUS), arquivos RD (Reduzidos), via pacote `microdatasus` |
| **Bases auxiliares** | CADGER do CNES (nome fantasia dos hospitais), CNES estabelecimentos (UF, município, natureza jurídica), tabela SIGTAP (descrição dos procedimentos), CID-10 (descrição dos diagnósticos) |
| **Universo de procedimentos** | 23 códigos SIGTAP organizados em três grupos (A, B e C — detalhados na aba Metodologia da planilha) |

---

## 3. Decisões Metodológicas

As decisões abaixo foram tomadas com critério único de **defensabilidade técnica**: cada uma é a escolha mais conservadora, replicável e transparente disponível dentro dos dados oficiais.

### 3.1. Definição de mortalidade

A taxa de mortalidade reportada é a razão entre **AIHs com óbito (`MORTE = 1`) e o total de AIHs** cujo *procedimento efetivamente realizado* (`PROC_REA`) pertence ao escopo de 23 códigos. Optamos pelo `PROC_REA` em vez do `PROC_SOLIC` (procedimento solicitado) porque o primeiro corresponde ao que foi de fato executado e remunerado pelo SUS — é o registro fiel da intervenção. Não varremos os campos de procedimentos especiais (`PROCEDIMENTOS_ESPECIAIS`) para evitar dupla contagem entre procedimentos do próprio escopo.

### 3.2. AIHs com múltiplos procedimentos do escopo

Quando uma mesma AIH registra mais de um procedimento do escopo (por exemplo, troca valvar associada a revascularização miocárdica), contamos **uma vez por AIH no procedimento principal**. Procedimentos secundários da mesma AIH não geram linha adicional. Essa regra evita inflar artificialmente o volume e contaminar a taxa de mortalidade. A limitação está documentada na aba 6 (Metodologia) da planilha.

### 3.3. Marcapassos sem CID associado

Três códigos do escopo — Marcapasso DDD (0406010650), Marcapasso VVI (0406010676) e Marcapasso temporário (0406010684) — não foram parametrizados pelo cliente com CID específico. Tratamos como **SIGTAP puro**, isto é, contamos toda AIH cujo `PROC_REA` é um desses três códigos, independentemente do diagnóstico principal. **Esta é a escolha mais ampla e defensável na ausência de orientação restritiva.** Caso o senhor deseje recortar para um subconjunto diagnóstico específico (por exemplo, distúrbios de condução cardíaca, CIDs I44–I49), a reextração é trivial e está prevista entre as quatro dúvidas residuais (item 5).

### 3.4. Cardiorrafia (0406010102) com dois CIDs

O código de cardiorrafia aparece duas vezes no escopo, associado a CIDs distintos (J94.2 — hemotórax; e I31.1 — pericardite constritiva). No detalhamento por hospital (Aba 5), preservamos a granularidade com **uma linha por par SIGTAP × CID**. No agregado (Abas 2, 3 e 4), a AIH é contada uma única vez, classificada pelo CID que aparece como diagnóstico principal na própria AIH. Isso preserva a possibilidade de o senhor recortar pelo motivo clínico sem inflar o agregado.

### 3.5. N mínimo para ranking de mortalidade

No ranking de hospitais por taxa de mortalidade (Aba 2 — Resumo Executivo), aplicamos o corte **N ≥ 12 cirurgias por ano** (uma cirurgia por mês em média). Sem esse corte, hospitais com volume ínfimo apareceriam com taxas de mortalidade espúrias de 0% ou 100%, distorcendo a leitura. **Para o ranking de hospitais por volume, não há corte** — todos os prestadores com pelo menos uma cirurgia no escopo aparecem. O corte está sinalizado na aba.

### 3.6. Filtro por CID

Onde o filtro composto SIGTAP + CID é aplicado (Grupo B do escopo), avaliamos exclusivamente o campo `DIAG_PRINC` da AIH (diagnóstico principal). Não varremos diagnósticos secundários. Esta é a escolha conservadora e replicável — alinhada com a prática estabelecida em estudos epidemiológicos sobre dados SIH.

---

## 4. Limitações Declaradas

A THAUMA opera sob o princípio da **Aletheia** — verdade desvelada. Por isso, declaramos abaixo todas as limitações que afetam a leitura dos dados.

### 4.1. Lag de competência DATASUS

Os dados foram extraídos em 26 de abril de 2026. O DATASUS tem lag típico de 30 a 45 dias para AIHs aprovadas; meses recentes (especialmente **dezembro de 2025**) podem apresentar completude parcial. **Recomendamos reextração após julho de 2026 para fechamento definitivo do ano-calendário.** Se o levantamento for usado em fórum sensível (auditoria, ação judicial, processo administrativo), o senhor deve declarar a data de extração.

### 4.2. Completude do CADGER

Em pequena parcela dos hospitais, o nome fantasia pode estar ausente no CADGER ou apresentar inconsistência com o nome de uso público. Nesses casos, a planilha exibe a razão social do CNES como fallback. A taxa de match nome fantasia × razão social está reportada na aba Metodologia.

### 4.3. Marcapassos sem filtro diagnóstico

Conforme item 3.3, os três códigos de marcapasso foram processados sem restrição de CID. Volumes e taxas de mortalidade desses códigos refletem o universo total de implantes/procedimentos no SUS em 2025, não um subconjunto clínico específico.

### 4.4. AIH como unidade de contagem

A unidade analítica é a AIH, não o paciente. Um mesmo paciente reinternado para outro procedimento do escopo no mesmo ano gera duas AIHs e, portanto, duas linhas no detalhamento. Essa é a granularidade nativa do SIH-SUS.

---

## 5. Quatro Dúvidas Residuais — para Confirmação

Sugerimos que o senhor confirme as quatro decisões abaixo conosco antes da reunião, ou ao longo dela, se preferir. **Qualquer ajuste é trivial e pode ser entregue em janela curta.**

1. **Marcapassos (0406010650 / 0406010676 / 0406010684)** — Manter SIGTAP puro (escolha atual) ou restringir a um subconjunto de CIDs (por exemplo, I44–I49 — distúrbios de condução)?
2. **Procedimentos secundários da AIH** — Manter contagem por procedimento principal apenas (escolha atual) ou expandir para também registrar AIHs cujo procedimento secundário esteja no escopo?
3. **N mínimo de 12 cirurgias/ano para ranking de mortalidade** — Adequado ao seu uso, ou prefere outro corte (8, 20, 24)?
4. **Lag de dezembro/2025** — Manter a presente extração como definitiva ou agendar reextração após julho de 2026?

---

## 6. Conteúdo da Planilha (`cardio_sus_2025_gss.xlsx`)

A planilha está organizada em seis abas. Recomendamos a leitura na ordem em que aparecem.

| Aba | Conteúdo | Para que serve |
|-----|----------|----------------|
| **1. Capa** | Identificação do projeto, cliente, autoria, data, nota de confidencialidade | Documento de capa formal |
| **2. Resumo Executivo** | Totais nacionais por procedimento, Top 10 hospitais por volume, Top 10 hospitais por taxa de mortalidade (com filtro N ≥ 12) | **Primeira aba a abrir na reunião.** Leitura escaneável em menos de dois minutos |
| **3. Consolidado por Procedimento** | Uma linha por procedimento, com totais Brasil e taxa nacional ponderada | Benchmark macro — útil para comparar procedimentos entre si |
| **4. Ranking por UF** | Hospitais agrupados por unidade da federação, com volume e mortalidade | Permite recortes regionais; útil se a discussão for territorial |
| **5. Detalhe por Hospital** | Granularidade máxima: uma linha por CNES × procedimento × CID (quando aplicável); colunas: CNES, nome fantasia, razão social, UF, município, natureza jurídica, código SIGTAP, descrição, CID associado, nº cirurgias, nº óbitos, taxa de mortalidade | **Núcleo do produto.** Permite cortar por qualquer dimensão |
| **6. Metodologia** | Versão sintética desta nota: fontes, filtros, regras, limitações, dúvidas residuais | Defesa metodológica integrada à planilha — sempre disponível ao lado dos dados |

A planilha aplica a identidade visual THAUMA — Azul Profundo (#001070), Branco Absoluto (#FFFFFF), Ciano Tecnológico (#40D7FF) — e formatação condicional na coluna de taxa de mortalidade para leitura imediata.

---

## 7. Anexo: Script R Reproduzível

Acompanha a entrega o arquivo `cardio_sus_2025_gss.R` — script R em pacote `microdatasus` que reproduz integralmente o levantamento, da extração à diagramação final. Qualquer terceiro com R instalado e acesso ao DATASUS pode rodar o script e chegar exatamente na mesma planilha. **O script é a prova máxima de rigor:** não há nada de "caixa-preta" entre o dado público e o número entregue.

---

## 8. Próximos Passos

Estamos à disposição do senhor para:

1. Esclarecer qualquer ponto desta nota antes ou depois da reunião.
2. Realizar reextração ou recorte adicional caso uma das quatro dúvidas residuais demande ajuste.
3. Prosseguir uma conversa de continuidade sobre serviços recorrentes — a THAUMA opera duas verticais consolidadas (Inteligência Política e Inteligência Assistencial — BI as a Service) e este levantamento é o tipo de produto que pode ser absorvido em assinatura mensal.

Permanecemos disponíveis no canal habitual.

---

*Cordialmente,*
**THAUMA — Inteligência & Narrativa em Saúde**
*"O espanto da descoberta. A ciência do resultado."*
