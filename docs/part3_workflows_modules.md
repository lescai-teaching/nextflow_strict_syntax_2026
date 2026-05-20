# Part 3: Workflows and Modules

Strict syntax removes the `addParams(...)` and `params(...)` clauses from `include` statements. A module's configuration must now be visible at the call site through explicit workflow inputs. This is the single most common change real nf-core PRs need to make.

<div class="timebox">
Target time: 25 minutes.
</div>

## Learning goals

- Remove `addParams` / `params` clauses from `include` statements.
- Expose a module's runtime knobs as `take:` inputs on a named sub-workflow.
- Stop reading `params.*` from inside processes — read inputs instead.

## Theory: includes import components, they do not configure them

Before 26.04 it was idiomatic to pass values *through* an `include` statement:

```groovy
include { RENAME_FASTQ } from './modules/rename_fastq' addParams(suffix: params.suffix)
```

This worked, but it hid the module's interface at import time and tied the caller to the importee's `params` namespace. Three concrete problems compound in real pipelines:

1. **The interface is invisible** at the call site. A reader has to open the included file to know which `params.*` it expects.
2. **Two callers cannot configure the same module differently** in the same script — both `include` statements share the same `params` map.
3. **Static typing cannot help.** Once Part 6's typed interfaces land, only inputs declared in `take:` get checked. Anything smuggled in through `params` stays unchecked.

Strict syntax forces the interface to surface: the module exports a named workflow with `take:` inputs, and the caller passes values explicitly — just like calling a function.

!!! tip "nf-core naming convention used in this workshop"

    Both processes and named (sub-)workflows are written in `UPPERCASE_WITH_UNDERSCORES`, matching the nf-core modules repository. To keep the two distinct in the same module file, this workshop uses **singular for the process** (one record at a time) and **plural for the workflow** (orchestrates many): `RENAME_FASTQ` is the process, `RENAME_FASTQS` is the workflow that fans it out. The folder under `modules/` stays lowercase, also matching nf-core.

### Side-by-side

Two things change at once in this migration, and both are visible in the diff below:

1. **The module file grows a new wrapper workflow.** The process `RENAME_FASTQ` (singular) stays where it is; a new sub-workflow `RENAME_FASTQS` (plural) is added next to it and becomes the module's public entrypoint.
2. **The entry `main.nf` switches what it imports.** Before, the only thing the module exported was the process, so `main.nf` imported `RENAME_FASTQ`. After, `main.nf` imports `RENAME_FASTQS` — the new workflow that takes `suffix` as a proper input.

So the rename in the import is **not cosmetic** — it reflects that the public surface of the module has changed from a process to a workflow.

=== "Legacy (parser error)"

    ```groovy title="main.nf"
    // imports the PROCESS directly — only thing this module exports today
    include { RENAME_FASTQ } from './modules/rename_fastq' addParams(suffix: params.suffix)

    workflow {
        main:
        RENAME_FASTQ(channel.of('NA12878', 'HG002'))
        RENAME_FASTQ.out.view { "created ${it.name}" }
    }
    ```

    ```groovy title="modules/rename_fastq/main.nf"
    // legacy: a process on its own; configuration is smuggled in via params.suffix
    process RENAME_FASTQ {
        input:
        val sample_id

        output:
        path "${sample_id}.fastq"

        script:
        """
        printf '%s\n' '${sample_id}_${params.suffix}' > ${sample_id}.fastq
        """
    }
    ```

    `params.suffix` is read **inside the process script**, hidden from the caller.

=== "Strict (passes lint and runs)"

    ```groovy title="main.nf"
    // imports the new WRAPPER WORKFLOW (plural), not the process — the module's public entrypoint moved
    include { RENAME_FASTQS } from './modules/rename_fastq'

    workflow {
        main:
        def samples = channel.of('NA12878', 'HG002')
        RENAME_FASTQS(samples, params.suffix)            // suffix is now an explicit argument
        RENAME_FASTQS.out.files.view { file -> "created ${file.name}" }
    }
    ```

    ```groovy title="modules/rename_fastq/main.nf"
    // unchanged unit of work — still the singular process that handles one sample
    process RENAME_FASTQ {
        input:
        tuple val(sample_id), val(suffix)

        output:
        path "${sample_id}${suffix}.fastq"

        script:
        """
        printf 'sample=%s\nsuffix=%s\n' '${sample_id}' '${suffix}' > ${sample_id}${suffix}.fastq
        """
    }

    // NEW: the plural wrapper workflow that the entry main.nf now imports
    workflow RENAME_FASTQS {
        take:
        samples
        suffix

        main:
        def records = samples.map { sample_id -> [sample_id, suffix] }
        RENAME_FASTQ(records)

        emit:
        files = RENAME_FASTQ.out
    }
    ```

    `suffix` is now a `take:` input on `RENAME_FASTQS`. The caller passes `params.suffix` explicitly; the process reads it from the tuple, not from a global.

The lint error you will see on the legacy version is unambiguous:

```console
Error legacy.nf:3:56: Unexpected input: 'addParams'
│   3 | include { RENAME_FASTQ } from './modules/rename_fastq' addParams(suffix: ...
╰     |                                                        ^
```

## 1. Demo

```bash
cd code/03-workflows-modules/demo
nextflow run legacy.nf -profile test
```

??? failure "Expected output"

    ```console
    Error legacy.nf:3:56: Unexpected input: 'addParams'
    ```

Now run the migrated entry point:

```bash
nextflow run main.nf -profile test
```

??? success "Expected output"

    ```console
    [PROCESS  …] RENAME_FASTQS:RENAME_FASTQ (1)
    [PROCESS  …] RENAME_FASTQS:RENAME_FASTQ (2)
    created NA12878_R1.fastq
    created HG002_R1.fastq
    [SUCCESS] completed=2 failed=0 cached=0
    ```

The process name appears nested as `RENAME_FASTQS:RENAME_FASTQ` because the entry workflow now calls the **named sub-workflow** rather than the process directly. That nesting is a useful sanity check during real migrations — if you see it in the log, your module is correctly hiding its process behind a workflow interface.

!!! note "Remote module include style"

    Nextflow 26.04 also improves include behaviour for remote repositories. The strict rule is the same regardless of where the module lives: an `include` statement may only name what is being imported, never what to configure it with. Part 8 covers the new `nextflow module` CLI that manages remote dependencies.

## 2. Exercise

The exercise pipeline merges three lane-tagged FASTQs per sample. The module folder is `modules/merge_lanes`, the single-record process is `MERGE_LANE`, and after migration you will add a `MERGE_LANES` plural workflow alongside it. The `params.suffix` defaults to `_merged`. The starting point fails for the same reason as the demo (the `include` clause), and the process reads `params.suffix` directly — which is the second piece you must remove.

Note that the migration also changes **which symbol you import**: today the entry workflow imports the process (`include { MERGE_LANE }`); after migration it imports the new sub-workflow (`include { MERGE_LANES }`).

```bash
cd ../exercise
nextflow lint -project-dir . main.nf
```

??? failure "Expected output"

    ```console
    Error main.nf:3:54: Unexpected input: 'addParams'
    ```

Migrate `main.nf` and `modules/merge_lanes/main.nf` so that:

- the `include` statement has no `addParams` clause,
- the module exposes a named sub-workflow `MERGE_LANES` with `take: samples` and `take: suffix`,
- the process reads `suffix` from a tuple input, not from `params.suffix` directly,
- the entry workflow passes `params.suffix` to `MERGE_LANES` explicitly.

Then verify:

```bash
nextflow run main.nf -profile test
```

The expected output is three `merged HG002_L1_merged.txt` / `HG002_L2_merged.txt` / `HG003_L1_merged.txt` lines and `completed=3` in the summary. Compare with the worked solution only after attempting the migration:

```bash
cd ../solution
nextflow run main.nf -profile test
nf-test test tests/*.nf.test
```

The nf-test target asserts that exactly three tasks ran — that confirms the entry workflow really did fan out to all three lane-tagged samples, not silently dropping any.

## Checkpoint

- [ ] Every `include` statement in my migrated code only names what is imported.
- [ ] Each module exposes a named sub-workflow whose `take:` block lists every runtime knob.
- [ ] No process reads `params.*` directly — values arrive through the tuple input.

Continue to [Part 4](part4_process_syntax.md).
