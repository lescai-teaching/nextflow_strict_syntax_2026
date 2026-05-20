# Part 6: Static Typing and Records

Static typing is preview-level in 26.04 — Nextflow prints a `Static typing is a preview feature` warning at every run. It is *not* required by the strict parser. Use it where it pays for itself: typing the records that flow between processes, especially the metadata maps nf-core users carry through entire pipelines.

<div class="timebox">
Target time: 15 minutes guided, or self-study after the capstone.
</div>

## Learning goals

- Tell strict syntax (required in 26.04) apart from static typing (optional, preview).
- Read typed process inputs, typed sub-workflow `take:`/`emit:` declarations, and `record` definitions.
- Use duck-typing intentionally: pass records that carry **extra** fields beyond what the type declares.
- Avoid the typical migration footguns (`.out` access on a typed workflow, `set`, `tap`, `|`/`&`).

## Theory: type the boundaries that hurt when they drift

Enable static typing per script:

```groovy
nextflow.enable.types = true
```

Then declare data shapes once at the top of the file:

```groovy
record Sample {
    id: String
    reads: Path
    single_end: Boolean
}

record Report {
    id: String
    qc: Path
}
```

A typed process declares inputs and outputs by name and type instead of qualifier:

```groovy
process MAKE_QC {
    input:
    sample: Sample

    output:
    record(
        id: sample.id,
        qc: file("${sample.id}.qc.tsv")
    )

    script:
    """
    ...
    """
}
```

A typed sub-workflow names the channels it consumes and emits:

```groovy
workflow MAKE_REPORTS {
    take:
    samples: Channel<Sample>

    main:
    reports_ch = MAKE_QC(samples)

    emit:
    reports: Channel<Report> = reports_ch
}
```

Three points are worth holding in mind when adopting this style on a strict-clean codebase:

1. **Type the boundaries, not the implementation.** The places where types help are workflow inputs, workflow emits, and process inputs — the spots where one team hands data to another. Internal map/filter chains usually do not need type annotations to be safer.
2. **Records are duck-typed.** A value is accepted where a record type is expected if it has the required fields with compatible types. Extra fields are **carried through** to downstream processes. This is the practical replacement for the "meta map plus path tuple" idiom in nf-core: declare the minimum required shape, let pipelines extend the meta map per their needs.
3. **Some idioms are restricted when typing is on.** Assign workflow calls to variables (`r = MAKE_REPORTS(samples)`) — do not chain `.out` on a typed sub-workflow whose `emit:` declares names. Avoid `set`, `tap`, `|`, `&`, and `each` input qualifiers; they all bypass the type system.

## Duck-typing in practice

The single most useful property of records is that the runtime carries extra fields through unchanged. Compare the two records below:

```groovy
record(id: 'sample_a', reads: file('reads_a.fastq.gz'), single_end: true)
record(id: 'sample_b', reads: file('reads_b.fastq.gz'), single_end: false, strandedness: 'forward')
```

Both are accepted by a `Channel<Sample>` because both have `id`, `reads`, and `single_end`. The second one also has `strandedness`, which `Sample {}` does not declare. The runtime accepts it and downstream code can access `sample.strandedness` even though the type did not promise it. This is the nf-core meta-map pattern formalised: declare the contract you want to enforce, let callers carry whatever extra context they need.

## 1. Demo

The demo defines `Sample`, `Report`, the `MAKE_QC` process, and the `MAKE_REPORTS` sub-workflow. The entry workflow feeds two records into the channel; one is exactly-typed, the other carries an extra `strandedness` field that `Sample {}` does not declare.

```bash
cd code/07-static-types/demo
nextflow run main.nf -profile test
```

??? success "Expected output"

    ```console
    [WARN] WARN: Static typing is a preview feature -- syntax and behavior may change in future releases
    [PROCESS  …] MAKE_REPORTS:MAKE_QC (1)
    [PROCESS  …] MAKE_REPORTS:MAKE_QC (2)
    qc=sample_a:sample_a.qc.tsv
    qc=sample_b:sample_b.qc.tsv
    [SUCCESS] completed=2 failed=0 cached=0
    ```

The preview warning is expected on every run with `nextflow.enable.types = true`. Both samples produce a QC TSV; `sample_b`'s extra `strandedness` field is silently accepted.

## 2. Exercise

The exercise has the same `Sample`, `Report`, process, and sub-workflow declarations, but the entry workflow has **two real migration footguns** in it. Run it and read the failure:

```bash
cd ../exercise
nextflow run main.nf -profile test
```

??? failure "Expected output"

    ```console
    ERROR ~ No such variable: out
     -- Check script 'main.nf' at line: 52 ...
    ```

    The first failure is the `.out` access on a typed sub-workflow that already declares a named `emit:`. Fix it (assign the workflow call to a variable directly: `reports_ch = MAKE_REPORTS(samples_ch)`) and re-run. The next failure surfaces the missing record fields.

Fix the exercise so that:

- the workflow call is assigned to a variable, **without** chaining `.out`,
- each record passed to `MAKE_REPORTS` has the three required fields `id`, `reads`, `single_end` (the missing fields are the second hidden failure),
- the typed channel returned by `MAKE_REPORTS` still carries `Report` records when consumed by `view`.

Compare with the worked solution:

```bash
cd ../solution
nextflow run main.nf -profile test
nf-test test tests/*.nf.test
```

## Checkpoint

- [ ] I can explain why static typing requires strict syntax but does not replace it.
- [ ] I can read a `record` declaration and a typed `take:` / `emit:` block.
- [ ] I know that records are duck-typed — extra fields are carried through.
- [ ] I avoid `.out`, `set`, `tap`, `|`, `&`, and `each` qualifiers when migrating typed code.

Continue to [Part 7: Topic Channels and Workflow Outputs](part7_workflow_outputs.md).
