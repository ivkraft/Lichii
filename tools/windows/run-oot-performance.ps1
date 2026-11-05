param([switch]$Profile, [string]$Executable)
$ErrorActionPreference = 'Stop'
if (Get-Process -Name lichii,lichii-oot-diagnostic -ErrorAction SilentlyContinue) {
    throw 'Close Lichii before starting this session.'
}
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$sessionDir = Join-Path $repoRoot ('artifacts\oot-performance\' + (Get-Date -Format 'yyyyMMdd-HHmmss'))
New-Item -ItemType Directory -Path $sessionDir -Force | Out-Null
foreach ($name in @('EDEN_NX2_SHADER_DUMP', 'EDEN_NX2_FRAME_DUMP', 'EDEN_NX2_FRAME_DUMP_AT',
                    'EDEN_NX2_FRAME_DUMP_SAMPLED', 'EDEN_NX2_RENDER_TRACE',
                    'EDEN_NX2_GPU_PROFILE', 'EDEN_DKB_FRAME_TRACE')) {
    [Environment]::SetEnvironmentVariable($name, $null, 'Process')
}
if ($Profile) { $env:EDEN_NX2_GPU_PROFILE = '1' }
if (-not $Executable) { $Executable = Join-Path $repoRoot 'build-windows\bin\lichii.exe' }
$exePath = (Resolve-Path -LiteralPath $Executable).Path
Write-Host 'Frame and shader captures are disabled. Play the same scene for 1-2 minutes.'
Write-Host "Session: $sessionDir; timing profile: $Profile"
"Started: $(Get-Date -Format o); profile=$Profile" | Set-Content (Join-Path $sessionDir 'launcher.txt')
try {
    $app = Start-Process -FilePath $exePath -WorkingDirectory (Split-Path $exePath) -Wait -PassThru `
        -RedirectStandardOutput (Join-Path $sessionDir 'stdout.txt') `
        -RedirectStandardError (Join-Path $sessionDir 'stderr.txt')
    "Exit code: $($app.ExitCode); time: $(Get-Date -Format o)" | Add-Content (Join-Path $sessionDir 'launcher.txt')
} catch {
    $_ | Out-String | Add-Content (Join-Path $sessionDir 'launcher.txt')
    throw
} finally {
    Get-ChildItem -LiteralPath (Join-Path $env:APPDATA 'eden\log') -Filter 'eden_log*' |
        Copy-Item -Destination $sessionDir
}
Write-Host "Log saved: $sessionDir"
