# Help

## I am in the wrong folder

Return to the repository root:

```bash
cd /workspaces/nextflow_strict_syntax_2026
```

For local clones, use the path where you cloned the repository.

## I want a clean run

From the repository root:

```bash
make clean-work
```

This removes generated Nextflow work directories, result folders, and run logs under `code/`.

## An exercise fails immediately

That is expected before migration. Exercise folders intentionally contain legacy syntax. Use the failure message to identify the first construct to migrate.

## A solution fails

Check the installed Nextflow version:

```bash
nextflow -version
```

The workshop is pinned to `26.04.1`.

Then run the solution from its own folder:

```bash
cd code/01-strict-parser/solution
nextflow lint -project-dir . main.nf
nextflow run main.nf -profile test
```

## I want to inspect all validation targets

From the repository root:

```bash
make lint
make test
```
