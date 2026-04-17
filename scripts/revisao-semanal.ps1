# revisao-semanal.ps1
# Rotina semanal de inteligencia estrategica da THAUMA
# Executa todo domingo as 19h30 via Windows Task Scheduler

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8
$env:PYTHONIOENCODING = "utf-8"

$logFile = "C:\Users\User\thauma-staff\scripts\revisao-semanal.log"
$date = Get-Date -Format "yyyy-MM-dd"
$outputPath = "C:\Users\User\Documents\mente\Operando\03-thauma\Revisoes Semanais\Revisao_$date.md"
$claudeExe = "C:\Users\User\AppData\Roaming\npm\claude.cmd"

Add-Content $logFile "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - Iniciando revisao semanal $date"

$prompt = @"
Hoje e domingo ($date). Gere a revisao semanal de inteligencia estrategica da THAUMA.

PASSO 1 - VARREDURA DO VAULT OBSIDIAN
Use as ferramentas Read e Glob para ler os seguintes arquivos em C:\Users\User\Documents\mente\Operando\03-thauma\:
- Socrates.md, Decisoes.md, Aprendizados.md
- Todos os arquivos em leads\quentes\, leads\mornos\, leads\frios\, leads\conectores\
- Todos os arquivos em Clientes\ e Produtos\
- Arquivos em Planos\ e projetos-andamento\

PASSO 2 - PESQUISA EXTERNA
Use WebSearch para buscar (com base no contexto encontrado):
- Noticias sobre saude publica, SUS, emendas parlamentares, DATASUS, CEBAS
- Movimentos publicos de leads quentes
- Tendencias que impactam o portfolio THAUMA

PASSO 3 - PRODUCAO DO DOCUMENTO
Apos ler o vault e fazer as pesquisas, produza o documento completo em markdown com esta estrutura exata:

# Revisao Semanal - $date

## Contexto da Semana
[resumo do estado atual da THAUMA com base no vault]

## Sinapses e Insights
[3 a 5 conexoes nao obvias entre dados do vault e contexto externo]

## Alertas
[o que pode estar sendo negligenciado ou em risco]

## Momentum
[o que esta ganhando tracao e merece aceleracao]

## Planejamento da Semana

### Prioridades Absolutas
[3 prioridades com owner e criterio de sucesso mensuravel]

### Agenda Diaria
[acoes por dia, segunda a sexta, como briefing para Pedro]

### Pipeline - Proximos Passos
[leads para mover esta semana com proximo passo especifico]

### Pendencias com Deadline
[ordenadas por urgencia]

IMPORTANTE: Retorne APENAS o conteudo markdown do documento, sem explicacoes adicionais, sem prefixos, sem texto fora do documento.
"@

Set-Location "C:\Users\User\thauma-staff"

# Capturar output do Claude e salvar diretamente no arquivo markdown
$output = & $claudeExe -p $prompt --allowedTools "Read,Glob,Grep,WebSearch,WebFetch" --output-format text 2>&1

if ($output -and $output.Length -gt 100) {
    [System.IO.File]::WriteAllText($outputPath, $output, [System.Text.Encoding]::UTF8)
    Add-Content $logFile "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - Revisao salva em $outputPath ($($output.Length) chars)"
} else {
    Add-Content $logFile "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - ERRO: output insuficiente ($($output.Length) chars)"
    Add-Content $logFile $output
}
