# Nextflow Strict Syntax Migration Workshop

Self-learning workshop material for medium and experienced Nextflow users who
need to migrate existing DSL2 workflows to the strict syntax parser enabled by
default in Nextflow 26.04.

The workshop is designed for a 2.5 hour session. It contains:

- MkDocs Material documentation in `docs/`
- Runnable migration examples in `code/<topic>/demo/`
- Learner exercises with intentional strict-syntax failures in `code/<topic>/exercise/`
- Worked solutions in `code/<topic>/solution/`
- A GitHub Codespaces configuration in `.devcontainer/`

## Quick Start

In GitHub Codespaces, the devcontainer uses the required training tools from
the base image and only installs missing tools during first setup.
For local use, install Java, Nextflow 26.04.1, nf-test, nf-core 4.0.2, and
MkDocs Material, then run:

```bash
make docs
make lint
make test
```

To preview the documentation locally:

```bash
make serve
```

This starts MkDocs in the background so the terminal remains usable. Use
`make serve-status`, `make serve-logs`, and `make serve-stop` to inspect or stop
the server. In Codespaces, open port `8000` with **Open in Browser** rather than
the embedded editor preview.

## Workshop Scope

This material assumes learners already understand DSL2 workflows, processes,
channels, modules, and configuration basics. It focuses only on migration
patterns introduced by the strict syntax parser and Nextflow 26.04.

All examples use synthetic placeholder data and generic sample names.
