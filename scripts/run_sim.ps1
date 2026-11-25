$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
Push-Location $root
try {
    iverilog -Wall -o cpu_sim testbench.v cpu.v
    vvp cpu_sim
} finally {
    Pop-Location
}
