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

Require-Command git
Require-Command gprbuild
Require-Command arm-eabi-objcopy
if (-not $SkipUf2) {
    Require-Command python
}

Write-Host 'Initializing pinned source dependencies...'
git submodule sync --recursive
if ($LASTEXITCODE -ne 0) { throw 'git submodule sync failed.' }
git submodule update --init --recursive
if ($LASTEXITCODE -ne 0) { throw 'git submodule update failed.' }

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
    $Actual = (git -C $Item.Key rev-parse HEAD).Trim()
    if ($LASTEXITCODE -ne 0 -or $Actual -ne $Item.Value) {
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
& gprbuild '-p' '-P' (Join-Path $Root 'motherlode.gpr') `
    "-XMOTHERLODE_BUILD=$Configuration" `
    "-XMOTHERLODE_BUILD_CHECKS=$Checks"
if ($LASTEXITCODE -ne 0) { throw "gprbuild failed with exit code $LASTEXITCODE." }

$Elf = Join-Path $Root 'obj_target/motherlode.elf'
if (-not (Test-Path $Elf)) {
    throw "Expected build output was not found: $Elf"
}

$BuildDirectory = Join-Path $Root 'build'
New-Item -ItemType Directory -Force -Path $BuildDirectory | Out-Null
$Binary = Join-Path $BuildDirectory 'motherlode.bin'
$Uf2 = Join-Path $BuildDirectory 'motherlode.uf2'

& arm-eabi-objcopy '-O' 'binary' $Elf $Binary
if ($LASTEXITCODE -ne 0) { throw 'arm-eabi-objcopy failed.' }

if (-not $SkipUf2) {
    $Uf2Converter = Join-Path $Root 'vendor/uf2/utils/uf2conv.py'
    & python $Uf2Converter '-c' '-b' '0x4000' '-f' 'SAMD51' '-o' $Uf2 $Binary
    if ($LASTEXITCODE -ne 0) { throw 'UF2 conversion failed.' }
    Write-Host "UF2 image: $Uf2"
}

Write-Host "ELF image: $Elf"
Write-Host "Binary image: $Binary"
