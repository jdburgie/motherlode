[CmdletBinding()]
param(
    [ValidateSet('Debug', 'Production')]
    [string]$Configuration = 'Debug',

    [ValidateSet('Disabled', 'Enabled')]
    [string]$Checks = 'Enabled',

    [switch]$SkipUf2
)

$ErrorActionPreference = 'Stop'
$Root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
Set-Location $Root

function Require-Command([string]$Name) {
    if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
        throw "Required command '$Name' was not found on PATH."
    }
}

function Invoke-NativeCommand {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$FilePath,

        [string[]]$ArgumentList = @(),

        [Parameter(Mandatory)]
        [string]$Description
    )

    # Native tools such as GNAT write normal compiler warnings to stderr.
    # With ErrorActionPreference='Stop', Windows PowerShell can otherwise turn
    # those harmless warning lines into terminating NativeCommandError records.
    $PreviousErrorActionPreference = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        $CommandOutput = & $FilePath @ArgumentList 2>&1
        $ExitCode = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $PreviousErrorActionPreference
    }

    foreach ($Line in $CommandOutput) {
        if ($Line -is [System.Management.Automation.ErrorRecord]) {
            Write-Output $Line.Exception.Message
        }
        else {
            Write-Output $Line
        }
    }

    if ($ExitCode -ne 0) {
        throw "$Description failed with exit code $ExitCode."
    }
}

Require-Command git
Require-Command gprbuild
Require-Command arm-eabi-objcopy
if (-not $SkipUf2) {
    Require-Command python
}

Write-Host 'Initializing pinned source dependencies...'
Invoke-NativeCommand -FilePath 'git' `
    -ArgumentList @('submodule', 'sync', '--recursive') `
    -Description 'git submodule sync'
Invoke-NativeCommand -FilePath 'git' `
    -ArgumentList @('submodule', 'update', '--init', '--recursive') `
    -Description 'git submodule update'

$Expected = [ordered]@{
    'vendor/pygamer-bsp' = '2dba1dd3a9d9e8d5d5e441bdac37242a56ae048d'
    'vendor/samd51-hal'  = '3edd815bab9a8a4df15bd459f679a2465a9208ac'
    'vendor/cortex-m'    = '8c24b76979aa7fb86019006111007f4272dfe89c'
    'vendor/hal'         = '92eb1f60b352230352c41137b6983d0bb5e1b7ff'
    'vendor/geste'       = '9e99f066c49b3fccd02420b899d8ef95eeb0eb1b'
    'vendor/virtapu'     = 'bc5b7bf6cace9637208662e0dafb0b5c72b603f6'
    'vendor/uf2'         = '90e9741f217f5a40c98ba74d663e408041037578'
}

foreach ($Item in $Expected.GetEnumerator()) {
    $PreviousErrorActionPreference = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        $Actual = (& git -C $Item.Key rev-parse HEAD 2>&1 | Select-Object -Last 1).ToString().Trim()
        $GitExitCode = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $PreviousErrorActionPreference
    }

    if ($GitExitCode -ne 0 -or $Actual -ne $Item.Value) {
        throw "Dependency $($Item.Key) is at $Actual; expected $($Item.Value)."
    }
}

$VendorDirectories = @(
    (Join-Path $Root 'vendor/hal'),
    (Join-Path $Root 'vendor/cortex-m'),
    (Join-Path $Root 'vendor/samd51-hal'),
    (Join-Path $Root 'vendor/pygamer-bsp'),
    (Join-Path $Root 'vendor/geste'),
    (Join-Path $Root 'vendor/virtapu')
)

$ProjectPathEntries = @($VendorDirectories)
if ($env:GPR_PROJECT_PATH) {
    $ProjectPathEntries += $env:GPR_PROJECT_PATH
}
$env:GPR_PROJECT_PATH = $ProjectPathEntries -join [IO.Path]::PathSeparator

Write-Host "Building Motherlode ($Configuration, checks $Checks)..."
Invoke-NativeCommand -FilePath 'gprbuild' `
    -ArgumentList @(
        '-p',
        '-P', (Join-Path $Root 'motherlode.gpr'),
        "-XMOTHERLODE_BUILD=$Configuration",
        "-XMOTHERLODE_BUILD_CHECKS=$Checks"
    ) `
    -Description 'gprbuild'

$Elf = Join-Path $Root 'obj_target/motherlode.elf'
if (-not (Test-Path $Elf)) {
    throw "Expected build output was not found: $Elf"
}

$BuildDirectory = Join-Path $Root 'build'
New-Item -ItemType Directory -Force -Path $BuildDirectory | Out-Null
$Binary = Join-Path $BuildDirectory 'motherlode.bin'
$Uf2 = Join-Path $BuildDirectory 'motherlode.uf2'

Invoke-NativeCommand -FilePath 'arm-eabi-objcopy' `
    -ArgumentList @('-O', 'binary', $Elf, $Binary) `
    -Description 'arm-eabi-objcopy'

if (-not $SkipUf2) {
    $Uf2Converter = Join-Path $Root 'vendor/uf2/utils/uf2conv.py'
    Invoke-NativeCommand -FilePath 'python' `
        -ArgumentList @(
            $Uf2Converter,
            '-c',
            '-b', '0x4000',
            '-f', 'SAMD51',
            '-o', $Uf2,
            $Binary
        ) `
        -Description 'UF2 conversion'
    Write-Host "UF2 image: $Uf2"
}

Write-Host "ELF image: $Elf"
Write-Host "Binary image: $Binary"
