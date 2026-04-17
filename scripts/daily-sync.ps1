# THAUMA Daily Git Sync
# Executa git pull diario para manter o repositorio local sincronizado
# Agendado via Windows Task Scheduler

$repoPath = "C:\Users\User\thauma-staff"
$logFile = "$repoPath\scripts\sync.log"
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

function Write-Log {
    param([string]$Message)
    "$timestamp | $Message" | Out-File -Append -FilePath $logFile -Encoding UTF8
}

try {
    Set-Location $repoPath

    # Verificar se o diretorio e um repo git valido
    if (-not (Test-Path "$repoPath\.git")) {
        Write-Log "ERRO: $repoPath nao e um repositorio git"
        exit 1
    }

    # Verificar conectividade com o remoto
    $fetchResult = git fetch origin main 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Log "ERRO ao fetch: $fetchResult"
        exit 1
    }

    # Verificar se ha mudancas locais nao commitadas
    $status = git status --porcelain
    if ($status) {
        Write-Log "AVISO: Arquivos modificados localmente (nao commitados). Pull abortado para evitar conflito."
        Write-Log "Arquivos: $status"
        exit 0
    }

    # Executar pull com fast-forward only para seguranca
    $pullResult = git pull --ff-only origin main 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Log "OK: Pull realizado com sucesso. $pullResult"
    } else {
        # Se ff-only falhar, tenta merge normal
        Write-Log "AVISO: Fast-forward falhou, tentando merge padrao..."
        $pullResult = git pull origin main 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Log "OK: Merge realizado com sucesso. $pullResult"
        } else {
            Write-Log "ERRO: Pull falhou. $pullResult"
            exit 1
        }
    }
} catch {
    Write-Log "ERRO FATAL: $($_.Exception.Message)"
    exit 1
}
