# LatticePoW (EVM)

`LatticePoW` is a standalone lattice-based challenge primitive for EVM.

This repository focuses on one thing: challenge/response verification for an LWE-style puzzle over `Z_q`.

## Scope

- Application-level anti-bot / Sybil throttling primitive
- Challenge-bound puzzle verification on EVM
- Benchmarked for on-chain verification cost

## Non-Goals

- Not a Bitcoin consensus replacement in current form
- Not a complete mining protocol (no retargeting, no p2p, no fork-choice)
- Not a low-entropy password hardening primitive by itself

## Contract

- `contracts/LatticePoWV1.sol`

## Quick Start

```bash
forge build
forge test -vv
```

## Benchmarking

Reproducible benchmark commands:

```bash
forge test --use 0.8.30 --match-test testGasVerifyReferenceSolution -vv
forge test --use 0.8.30 --gas-report
```

Or run both via:

```bash
./scripts/benchmark_verify.sh
```

Detailed benchmark notes: `docs/BENCHMARKS.md`.

## Security Note

`LatticePoWV1` uses deterministic challenge-derived targets for reproducible tests and integration.
If you need stronger production properties, use protocol-level challenge generation and rate limiting.
