#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

echo "== LatticePoW benchmark: verify() gas on reference challenge =="
forge test --use 0.8.30 --match-test testGasVerifyReferenceSolution -vv

echo ""
echo "== LatticePoW benchmark: full gas report =="
forge test --use 0.8.30 --gas-report
