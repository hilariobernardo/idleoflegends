[CmdletBinding()]
param(
    [string]$GodotPath,
    [switch]$PrepareOnly
)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$gamePath = Join-Path $projectRoot 'game'
$toolsPath = Join-Path $projectRoot '.tools'
$version = '4.6.3'

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

function Install-PortableGodot {
    # SHA256 digests pinned from the official godot-builds 4.6.3-stable release assets.
    $processor = $env:PROCESSOR_ARCHITEW6432
    if (-not $processor) { $processor = $env:PROCESSOR_ARCHITECTURE }
    switch ($processor) {
        'ARM64' {
            $platform = 'windows_arm64'
            $expectedHash = 'd53b5b4c1d1e4f242d490a98a0da1b3579628e4d6f98a052542599862a96b10f'
        }
        'AMD64' {
            $platform = 'win64'
            $expectedHash = 'e39986a178d585ce7ac198fb8de6ea436366dc0cc00e594810c2e3e104c04b90'
        }
        'x86' {
            $platform = 'win32'
            $expectedHash = 'db7e2124ffc21e3f4ae765ca6fe152703afec52e291db2dc68b58c7530f45b02'
        }
        default { throw "Arquitetura Windows nao reconhecida: $processor" }
    }
    $asset = "Godot_v$version-stable_$platform.exe.zip"
    $uri = "https://github.com/godotengine/godot-builds/releases/download/$version-stable/$asset"
    $installPath = Join-Path $toolsPath 'godot'
    New-Item -ItemType Directory -Path $installPath -Force | Out-Null
    $archive = Join-Path $installPath ('download-' + [guid]::NewGuid().ToString('N') + '.zip')
    Write-Host "Preparando o Godot $version oficial (aproximadamente 80 MB). Aguarde..."
    Write-Host 'Nao precisa instalar nada manualmente nem executar como administrador.'
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
        $ProgressPreference = 'SilentlyContinue'
        Invoke-WebRequest -UseBasicParsing -Uri $uri -OutFile $archive -TimeoutSec 300
        if ((Get-FileHash -LiteralPath $archive -Algorithm SHA256).Hash -ne $expectedHash) {
            throw 'O download nao passou na verificacao SHA256. Nenhum executavel baixado foi iniciado. Abra Jogar.cmd novamente para tentar de novo.'
        }
        Expand-Archive -LiteralPath $archive -DestinationPath $installPath -Force
        $executable = Join-Path $installPath "Godot_v$version-stable_$platform.exe"
        if (-not (Test-GodotExecutable $executable)) {
            throw 'O Godot foi baixado, mas nao conseguiu iniciar neste Windows.'
        }
        return $executable
    } finally {
        if (Test-Path -LiteralPath $archive -PathType Leaf) { Remove-Item -LiteralPath $archive }
    }
}

try {
    if ($env:OS -ne 'Windows_NT') { throw 'Use Jogar.cmd em um computador Windows.' }
    if (-not (Test-Path -LiteralPath (Join-Path $gamePath 'project.godot') -PathType Leaf)) {
        throw 'A pasta game esta faltando. Extraia a pasta completa do jogo antes de abrir Jogar.cmd.'
    }
    $engine = Find-Godot
    if (-not $engine) { $engine = Install-PortableGodot }
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
    Write-Host 'Se o download falhou, confira a conexao com a internet e tente abrir Jogar.cmd novamente.'
    exit 1
}
