# Benchmarks

This repository provides a reproducible benchmark path for `LatticePoWV1.verify()`.

## Prerequisites

- Foundry installed (`forge --version`)
- Solc selected by Foundry profile (`0.8.30` in `foundry.toml`)

## Quick Benchmark (verify path)

Run the dedicated gas test:

```bash
forge test --use 0.8.30 --match-test testGasVerifyReferenceSolution -vv
```

This executes `testGasVerifyReferenceSolution()` in `test/LatticePoWV1.t.sol` and reports gas for the `verify()` path.

## Full Gas Report

Run gas report across the full suite:

```bash
forge test --use 0.8.30 --gas-report
```

## One-Command Script

```bash
./scripts/benchmark_verify.sh
```

The script runs both the quick benchmark and the full gas report.
