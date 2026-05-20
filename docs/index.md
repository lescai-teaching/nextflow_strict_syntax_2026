# Nextflow Strict Syntax Migration Workshop

This workshop is for Nextflow users who already write DSL2 workflows and now need to migrate existing code to the strict syntax parser enabled by default in Nextflow 26.04.

The goal is practical: identify old syntax, make a focused migration, and verify the migrated workflow with `nextflow lint`, a smoke run, and small tests.

!!! info "Two paths through the material"

    - **Core path (≈2.5 hours):** Orientation → Parts 1–5 → Capstone. This is the strict-syntax migration you need to run today on existing DSL2 code.
    - **Extended path (≈45–60 minutes more):** Parts 6–8 cover 26.04-era modernization (static typing and records, topic channels and workflow outputs, the `nextflow module` registry CLI). They build on the core path but do not replace it.

    The two paths are signposted in the sidebar and at the bottom of the Capstone page.

## What you will practice

**Core path (strict migration):**

- Reading strict parser error messages produced by `nextflow lint`.
- Replacing unsupported script-level Groovy idioms (imports, classes, typed declarations, `for`/`switch`/`++`, spread, implicit `it`).
- Moving parameters out of `include ... addParams(...)` into explicit `take:` inputs.
- Migrating process syntax (`shell:` → `script:`, quoted `env` names, escaping shell variables).
- Updating nf-core-style configuration files (free variables, helper functions, `switch` selectors, `validation.ignoreParams`).
- Completing a small end-to-end migration capstone on a samples/QC mini-pipeline.

**Extended path (26.04 modernization, optional after capstone):**

- Reading typed processes, workflows, and record types — and recognising when a duck-typed record carries extra fields without breaking downstream code.
- Using topic channels for cross-cutting streams (versions) and `publish:` / `output {}` blocks for the pipeline's public output contract.
- Driving the `nextflow module` registry CLI to install, inspect, and run remote modules without touching legacy `include` paths.

## What this workshop does not teach

- Nextflow fundamentals.
- DSL1 to DSL2 migration.
- Container engineering.
- Production-scale nf-core pipeline development.

## How each module is built

Every part follows the same shape so you can switch between reading and running without losing your place:

1. **Theory** — a focused "why this rule exists" paragraph that goes beyond the upstream Seqera and nf-core docs (pipeline-engineering rationale, the failure mode it prevents, the most common migration footgun).
2. **Demo** — run `legacy.nf` first to see the strict parser reject it, then run the migrated `main.nf` and read the diff. The legacy file is for reading, not for re-using.
3. **Exercise** — a *different* starting point with the same class of errors in different surface positions. You migrate it yourself before peeking at the solution.
4. **Solution** — one possible migrated version, plus an `nf-test` smoke test where useful.
5. **Checkpoint** — three boxes you should be able to tick before moving on.

```console
code/<topic>/
├── demo       # legacy.nf (reads as failure) + main.nf (strict, runs)
├── exercise   # main.nf you migrate yourself
└── solution   # one strict version + optional tests/
```

## Reference sources

- [Migrating to Nextflow 26.04](https://docs.seqera.io/nextflow/migrations/26-04)
- [Preparing for strict syntax](https://docs.seqera.io/nextflow/strict-syntax)
- [nf-core strict syntax migration guide](https://nf-co.re/docs/developing/migration-guides/strict-syntax)
- [Official Nextflow training](https://training.nextflow.io/latest/)

## Readiness checklist

- [ ] I can open a terminal in the workshop repository.
- [ ] `nextflow -version` reports `26.04.1`.
- [ ] I already understand DSL2 processes, workflows, channels, modules, and config basics.
- [ ] I know this workshop focuses on migration patterns, not Nextflow fundamentals.

Continue to [Orientation](orientation.md).
