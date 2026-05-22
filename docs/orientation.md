# Orientation

The workshop is easiest to run in GitHub Codespaces. The repository includes a `.devcontainer/` configuration based on the official training environment, with Nextflow pinned to `26.04.1`.

## Start the environment

Open the repository in Codespaces. The container uses the official training
image without running package installation during startup, so opening a
Codespace should only pull and start the ready environment. When the container
finishes building, check the installed tools:

```bash
make check-tools
```

??? success "Expected output shape"

    ```console
    nextflow version 26.04.1
    nf-test ...
    nf-core, version 4.0.2
    mkdocs, version ...
    ```

## Explore the repository

Run:

```bash
tree . -L 3
```

??? abstract "Directory shape"

    ```console
    .
    ├── code
    │   ├── 01-strict-parser
    │   ├── 02-script-syntax
    │   ├── 03-workflows-modules
    │   ├── 04-process-syntax
    │   ├── 05-nfcore-config
    │   ├── 06-capstone
    │   ├── 07-static-types
    │   ├── 08-workflow-outputs
    │   └── 09-module-registry
    ├── docs
    ├── mkdocs.yml
    └── Makefile
    ```

## Run the documentation locally

```bash
make serve
```

This starts MkDocs in the background and returns control to the terminal. In
Codespaces, open port `8000` manually from the Ports panel and choose **Open in
Browser** rather than **Preview in Editor**.

Useful server commands:

```bash
make serve-status
make serve-logs
make serve-stop
```

## Working pattern

Every part is built the same way: a short theory section that explains *why* the rule exists (not just what changed), a demo that shows the failure → migration round-trip, an exercise with the same errors in a different surface, and a worked solution.

For each part:

1. Read the **theory** block at the top — it focuses on the *why* and the most common migration footgun, deliberately not paraphrasing the upstream Seqera or nf-core docs.
2. Inspect the legacy example in `demo/legacy.nf` or `demo/legacy.config` to see what the strict parser rejects.
3. Run the strict version in `demo/main.nf` to confirm the migrated behaviour.
4. Move to `exercise/`, run the failure commands, and migrate the code yourself.
5. Compare with `solution/` only after trying the exercise. Examples use genomics-flavoured names (sample IDs, FASTQ suffixes, cohort sizes, tool versions) so the migration patterns appear in code shapes you already recognise.

## Validation commands

Use these commands from the repository root:

```bash
make docs              # mkdocs build --strict
make serve             # start mkdocs in the background on port 8000
make serve-stop        # stop the background mkdocs server
make lint              # nextflow lint on every demo/ and solution/
make test              # nextflow run + nf-test on every solution/
make check-exercises   # guard: exercise/main.nf must differ from demo/legacy.nf
```

`make lint` and `make test` intentionally skip `exercise/` folders because they are supposed to fail before learners migrate them. `make check-exercises` is the opposite check — it verifies the exercises are not byte-clones of the corresponding legacy demo.

## Workshop timing

The material is built around two paths:

| Path | Coverage | Target duration |
| --- | --- | --- |
| **Core** | Orientation + Parts 1–5 + Capstone | 2.5 hours |
| **Extended** | Parts 6–8 (static typing, topics & outputs, registry CLI) | 45–60 minutes more |

Run the core path end-to-end during a live workshop; treat the extended path as either a follow-up session or self-study after the capstone. The transition is signposted at the bottom of the Capstone page.

## Timebox

<div class="timebox">
Orientation: 10 minutes.
</div>

Continue to [Part 1](part1_strict_parser.md).
