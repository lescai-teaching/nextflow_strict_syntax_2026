# Part 7: Topic Channels and Workflow Outputs

Topic channels and the new `publish:` / `output {}` blocks solve two different problems that legacy DSL2 code used to entangle:

- **Topic channels** collect *side streams* by name — versions, software banners, soft logs — without threading them through every workflow signature.
- **Workflow outputs** declare the *public output contract* of a pipeline in one place, replacing scattered `publishDir` directives in individual processes.

Real nf-core pipelines end up using both together: per-tool processes emit version files to a `versions` topic, the entry workflow `publish:`es one user-facing report channel, and the top-level `output {}` block describes where that report goes on disk.

<div class="timebox">
Target time: 15 minutes guided, or self-study after Part 6.
</div>

## Learning goals

- Use a topic channel to collect cross-cutting outputs from independent processes.
- Recognise (and avoid) topic-channel cycles.
- Declare a pipeline's public outputs through `publish:` and the top-level `output {}` block.
- Read the combined "publish one report + collect a `versions` topic" pattern.

## Theory: topics for side streams

A topic is a named bus that any process can write to:

```groovy
output:
path 'fastqc.version.txt', topic: 'versions'
```

Anywhere in the pipeline, you can consume the bus once:

```groovy
channel.topic('versions').view { file -> "version=${file.text.trim()}" }
```

The benefit is that the producing processes do not need to be wired into the workflow signature that consumes the side stream. A `FASTQC_VERSION` process and a `SAMTOOLS_VERSION` process can both write to `versions` without knowing about each other, and the entry workflow can collect them once at the end (typically to drive a MultiQC step).

!!! warning "Topic cycles will hang the workflow"

    Do not feed a topic channel into a process that **also** writes to the same topic. The producer waits for the consumer to drain it, the consumer's own emission keeps the topic non-empty, and the workflow never reaches a quiescent state. In practice this means: pick `versions` consumers that do not themselves emit to `versions`. A `MULTIQC_INPUTS` process that reads `channel.topic('versions')` must not also write a `multiqc.version.txt` to that same topic.

## Theory: `publish:` and `output {}` for the public contract

The `publish:` block inside the entry workflow names which channels are public outputs. The top-level `output {}` block then declares where each name goes on disk:

```groovy
workflow {
    main:
    report_ch = MULTIQC_INPUTS()
    ...

    publish:
    reports = report_ch
}

output {
    reports {
        path 'reports'
    }
}
```

Why this is better than `publishDir` inside processes:

1. **One place to read the contract.** A new contributor opens the entry workflow and sees the entire public-output surface.
2. **Process bodies stop carrying deployment concerns.** A process that needs to be deployed under three different layouts no longer needs three `publishDir` calls.
3. **It composes with `workflow.output.mode`.** Set it once (e.g. `'copy'`) and every `output { }` entry inherits.

## Combined pattern (the real nf-core shape)

The thing the upstream docs do not put on a single page is what a real pipeline ends up with: independent per-tool processes emitting to a `versions` topic, one report process whose output gets published, and the entry workflow tying them together without wiring versions through every signature.

```groovy
workflow {
    main:
    report_ch = MULTIQC_INPUTS()
    FASTQC_VERSION()
    BWAMEM2_VERSION()
    SAMTOOLS_VERSION()
    report_ch.view { file -> "report=${file.name}" }
    channel.topic('versions').view { file -> "version=${file.text.trim()}" }

    publish:
    reports = report_ch
}

output {
    reports {
        path 'reports'
    }
}
```

The version processes are independent. They could be added or removed without touching the workflow signature. The `publish:` block exposes only the user-facing report. The `versions` topic is consumed once, in this case for a `view {}` — in a real pipeline this would go into a `MULTIQC` step that builds the run report.

## 1. Demo

```bash
cd code/08-workflow-outputs/demo
nextflow run main.nf -profile test
```

??? success "Expected output"

    ```console
    [PROCESS  …] SAMTOOLS_VERSION
    [PROCESS  …] MULTIQC_INPUTS
    [PROCESS  …] FASTQC_VERSION
    [PROCESS  …] BWAMEM2_VERSION
    report=multiqc_inputs.tsv
    version=samtools	1.20
    version=fastqc	0.12.1
    version=bwa-mem2	2.2.1
    Outputs:
      reports: reports/multiqc_inputs.tsv
    [SUCCESS] completed=4 failed=0 cached=0
    ```

Inspect what was actually published:

```bash
find results -type f
```

You should see `results/reports/multiqc_inputs.tsv`. That single file is the entire public output of the pipeline.

## 2. Exercise

The exercise has the same processes and topic wiring, but the `publish:` block references a channel name that does not exist (`missing_report_ch`). Run it and read the failure:

```bash
cd ../exercise
nextflow run main.nf -profile test
```

??? failure "Expected output"

    ```console
    Error main.nf:59:15: `missing_report_ch` is not defined
    │  59 |     reports = missing_report_ch
    ```

Fix the entry workflow so that:

- `publish: reports = ...` references the actual report channel returned by `MULTIQC_INPUTS()`,
- the top-level `output { reports { path 'reports' } }` block stays as-is,
- the `versions` topic still drains independently, without being wired into the publish contract.

Compare with the worked solution:

```bash
cd ../solution
nextflow run main.nf -profile test
nf-test test tests/*.nf.test
```

The nf-test target asserts four tasks ran — that confirms the three version emitters and the report process all executed, and the `publish:` block did not accidentally short-circuit any of them.

## Checkpoint

- [ ] I know when a topic channel is the right tool (cross-cutting side streams) and when it would create a cycle.
- [ ] I can read an entry workflow `publish:` block and identify the public output channels.
- [ ] I can read a top-level `output {}` block and predict the published directory layout.
- [ ] I understand the combined pattern (per-tool `versions` topic + one published report) and can map it onto real nf-core pipelines.

Continue to [Part 8: Module Registry](part8_module_registry.md).
