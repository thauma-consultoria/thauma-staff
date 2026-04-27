# Copy de Entrega — Dr. Maikon Almeida

## Mensagem WhatsApp

**[Mensagem 1]**

Dr. Maikon, entrega concluída dentro do prazo — material disponível esta manhã.

São 5 arquivos: planilha com 7 abas e identidade THAUMA (1.388 hospitais, 206.427 cirurgias, 27 UFs), script R reproduzível, nota metodológica para o senhor com as decisões que demandam sua confirmação, relatório de validação com 13 verificações realizadas e o one-pager executivo com guia de leitura.

---

**[Mensagem 2]**

Um ponto a chamar atenção antes de o senhor abrir a Aba 5 (Detalhe por Hospital): o código 0415020034 — "Outros sequenciais cardiovasculares" — representa 63% do volume total. Para uma análise clínica desagregada, a filtragem excluindo esse código entrega o recorte cirúrgico específico com muito mais granularidade. Está documentado na nota metodológica, mas preferi adiantar aqui.

---

**[Mensagem 3]**

O one-pager traz um convite à validação de campo — o senhor conhece hospitais e procedimentos que aparecem nos dados. Qualquer divergência que identificar em relação à realidade que observa pode orientar ajustes antes da reunião. Estou disponível para refinamentos em janela curta.

---

## E-mail formal

**Assunto:** Levantamento Cirurgias Cardiovasculares SUS 2025 — GSS Saúde | Entrega 27/04

**Corpo:**

Prezado Dr. Maikon,

Conforme acordado, encaminho o levantamento nacional de cirurgias cardiovasculares no SUS — ano-calendário 2025. O material cobre 1.388 hospitais prestadores, 206.427 cirurgias isoladas e todas as 27 unidades da federação, com extração direta do SIH-SUS e trilha metodológica auditável do dado bruto ao número final.

**Arquivos que acompanham esta mensagem:**

1. `cardio_sus_2025_gss.xlsx` — Planilha principal com 7 abas: capa, resumo executivo, consolidado por procedimento, ranking por UF, detalhe por hospital (granularidade máxima), metodologia integrada e dicionário de variáveis. Formatação com identidade THAUMA e AutoFilter ativo em todas as colunas.
2. `cardio_sus_2025_gss.R` — Script R reproduzível via pacote `microdatasus`. Qualquer analista com R instalado e acesso ao DATASUS replica o resultado do zero — nenhuma etapa em caixa-preta.
3. `nota_metodologica_cliente.md` — Nota técnica formal para o senhor com as seis decisões metodológicas adotadas e respectivas justificativas. Preparada para defesa em qualquer fórum técnico, administrativo ou judicial.
4. `relatorio_validacao.pdf` — Atestado de qualidade interno: 13 verificações realizadas, todas aprovadas, com quatro flags identificadas e devidamente explicadas.
5. `one_pager_executivo.pdf` — Peça executiva de uma página com a escala do processamento (14,6 milhões de AIHs, 470 mil estabelecimentos cruzados, 23 procedimentos) e guia de leitura da planilha.

Dois pontos merecem atenção antes da reunião.

Primeiro: o código SIGTAP 0415020034 ("Outros sequenciais cardiovasculares") representa 63% do volume total do levantamento. Para análise clínica desagregada — com foco nos procedimentos cirúrgicos específicos —, a filtragem com exclusão desse código na Aba 5 entrega o recorte mais granular e operacionalmente útil. O critério está documentado na nota metodológica, mas fica aqui explicitado para orientar a abertura da planilha.

Segundo: o one-pager inclui convite à validação de campo. Os números são resultado de processamento estatístico rigoroso sobre dados oficiais — mas o cruzamento com a realidade que o senhor conhece por experiência direta é a camada de validação que nenhum pipeline substitui. Sugerimos que o senhor identifique na Aba 5 os hospitais que acompanha e verifique se volume e taxa de mortalidade são compatíveis com o que observa. Divergências sinalizam ângulos de discussão para a reunião ou ajustes de escopo a realizar antes dela.

A nota metodológica lista quatro dúvidas residuais que aguardam confirmação do senhor — entre elas o tratamento dos códigos de marcapasso e o corte de N mínimo para o ranking de mortalidade. Qualquer ajuste pode ser entregue em janela curta, antes ou após a reunião, conforme a conveniência do senhor.

Permanecemos à disposição.

**Assinatura:**

Pedro William Ribeiro Diniz
THAUMA Inteligência & Narrativa em Saúde
pedro@thaumaconsultoria.com.br
