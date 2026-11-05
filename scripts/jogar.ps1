[CmdletBinding()]
param(
    [string]$GodotPath,
    [switch]$PrepareOnly
)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$gamePath = Join-Path $projectRoot 'game'
$toolsPath = Join-Path $projectRoot '.tools'

function Test-GodotExecutable([string]$Candidate) {
    if (-not $Candidate -or -not (Test-Path -LiteralPath $Candidate -PathType Leaf)) {
        return $false
    }
    try {
        $versionText = (& $Candidate --headless --version 2>$null | Out-String).Trim()
        return ($LASTEXITCODE -eq 0 -and $versionText -match '^4\.(\d+)\.' -and [int]$Matches[1] -ge 5)
    } catch {
        return $false
    }
}

function Find-Godot {
    if ($GodotPath) {
        if (Test-GodotExecutable $GodotPath) { return (Resolve-Path -LiteralPath $GodotPath).Path }
        throw 'O executavel informado nao e um Godot 4.5 ou superior compativel.'
    }
    foreach ($name in @('godot.exe', 'godot4.exe')) {
        $command = Get-Command $name -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($command -and (Test-GodotExecutable $command.Source)) { return $command.Source }
    }
    # Portable copies beside the launcher or prepared by an earlier opening.
    foreach ($folder in @($projectRoot, (Join-Path $toolsPath 'godot'))) {
        if (-not (Test-Path -LiteralPath $folder -PathType Container)) { continue }
        $candidates = Get-ChildItem -LiteralPath $folder -Filter 'Godot*.exe' -File -ErrorAction SilentlyContinue
        foreach ($candidate in $candidates) {
            if ($candidate.Name -notmatch '_console\.exe$' -and (Test-GodotExecutable $candidate.FullName)) {
                return $candidate.FullName
            }
        }
    }
    return $null
}

try {
    if ($env:OS -ne 'Windows_NT') { throw 'Use Jogar.cmd em um computador Windows.' }
    if (-not (Test-Path -LiteralPath (Join-Path $gamePath 'project.godot') -PathType Leaf)) {
        throw 'A pasta game esta faltando. Extraia a pasta completa do jogo antes de abrir Jogar.cmd.'
    }
    $engine = Find-Godot
    if (-not $engine) {
        throw 'Godot 4.5 ou superior nao encontrado. Instale uma vez com: winget install --exact --id GodotEngine.GodotEngine --version 4.6.3. Depois reabra o terminal ou use Jogar.cmd -GodotPath "C:\caminho\Godot.exe".'
    }
    New-Item -ItemType Directory -Path $toolsPath -Force | Out-Null
    $importLog = Join-Path $toolsPath 'godot-import.log'
    Write-Host 'Preparando os recursos do jogo...'
    # A clean clone has no imported map texture; prepare it before running.
    $importProcess = Start-Process -FilePath $engine -ArgumentList @('--headless', '--editor', '--path', ('"' + $gamePath + '"'), '--import', '--log-file', ('"' + $importLog + '"')) -WorkingDirectory $projectRoot -RedirectStandardOutput (Join-Path $toolsPath 'godot-import.stdout.log') -RedirectStandardError (Join-Path $toolsPath 'godot-import.stderr.log') -PassThru -Wait
    if ($importProcess.ExitCode -ne 0) { throw "Falha ao importar os recursos. Consulte $importLog" }
    if ($PrepareOnly) {
        Write-Host 'Godot e recursos prontos. Abra Jogar.cmd para jogar.'
        exit 0
    }
    Write-Host 'Abrindo Nexo Idle...'
    $process = Start-Process -FilePath $engine -ArgumentList @('--path', ('"' + $gamePath + '"')) -WorkingDirectory $projectRoot -PassThru -Wait
    if ($process.ExitCode -ne 0) { throw "O jogo encerrou com erro $($process.ExitCode). Godot utilizado: $engine" }
    exit 0
} catch {
    Write-Host "ERRO: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
