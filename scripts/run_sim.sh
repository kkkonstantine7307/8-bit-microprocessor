#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
iverilog -Wall -o cpu_sim testbench.v cpu.v
vvp cpu_sim
