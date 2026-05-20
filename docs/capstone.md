# Capstone

The capstone closes the **core path** of the workshop. It is a small genomics-flavoured QC pipeline that combines every migration pattern from Parts 1–5: script-level syntax, module includes, process syntax, and strict-compatible nf-core-style config. Finish this exercise and you have the full strict-syntax migration habit; the extended path (Parts 6–8) is then optional.

<div class="timebox">
Target time: 25 minutes.
</div>

## Learning goals

- Apply the strict migration checklist across `main.nf`, modules, processes, and config in a single small pipeline.
- Keep the migrated pipeline behaviour-equivalent to the legacy version (same inputs, same per-sample outputs).
- Verify the migrated code with `nextflow lint`, a smoke run, and an `nf-test` smoke test.

## The pipeline

Two synthetic sample files (`data/sample_a.txt`, `data/sample_b.txt`) act as tiny placeholder inputs. The pipeline reads each one, counts lines as "reads", carries metadata (`id`, `cohort`), threads a `RUN_ID` env value through the process, and emits one TSV per sample:

```console
sample      sample_a
cohort      validation
suffix      _qc
run_id      exercise_run
reads       3
```

That is the *behaviour* you must preserve. Everything else is syntax.

## 1. Start from the exercise

```bash
cd code/06-capstone/exercise
nextflow lint -project-dir . main.nf
nextflow run main.nf -profile test
```

The starting point fails on the first parser error it meets (the `addParams` clause). Migrate it in deliberate small steps so that each step's failure mode is the next learning signal:

1. **Script-level syntax in `main.nf`** (Part 2): drop `String run_id = ...` to `def run_id`, lowercase `Channel`, use explicit closure parameters.
2. **Workflow / module boundary** (Part 3): remove `addParams` from the `include`, wrap the process in a named `QC_SUMMARIES` sub-workflow with `take: records, suffix, run_id`, stop reading `params.suffix` from inside the process.
3. **Process syntax** (Part 4): quote `env 'RUN_ID'`, replace `shell:` with `script:`, keep the `\$RUN_ID` escape so the shell expands the env at runtime — not at compile time.
4. **Config** (Part 5): replace the top-level `def user_label` and the `chooseQueue` helper with declarative `params` and an immediately-invoked closure; replace `${USER}` with `${System.getenv('USER') ?: 'user'}`; add `validation.ignoreParams` and the `nf-schema` plugin.
5. **Re-run the smoke** until lint is silent and the pipeline produces two `*.qc.tsv` files with the schema above.

## 2. Acceptance commands

Your migrated exercise is complete when these commands all pass from the exercise folder:

```bash
nextflow lint -project-dir . main.nf
nextflow run main.nf -profile test
```

The expected log lines include `QC_SUMMARIES:QC_SUMMARY` (the nested name proves the entry workflow now goes through the wrapper sub-workflow, not the bare process) and `completed=2` in the summary.

Compare with the worked solution:

```bash
cd ../solution
nextflow lint -project-dir . main.nf
nextflow run main.nf -profile test
nf-test test tests/*.nf.test
```

??? success "Expected per-sample TSV (sample_a)"

    ```console
    sample      sample_a
    cohort      validation
    suffix      _qc
    run_id      exercise_run
    reads       3
    ```

    If `run_id` is empty in your output, the `script:` body wrote `${RUN_ID}` (Nextflow tried to interpolate at compile time, found nothing) instead of `"\$RUN_ID"` (shell expansion at runtime). Re-read the Part 4 runtime-footgun callout.

## Checkpoint

- [ ] The migrated workflow has the same inputs and outputs as the legacy starting point — same TSV schema, same number of records per sample.
- [ ] No process reads `params.*` directly. All runtime configuration arrives through `take:` inputs or env values.
- [ ] No legacy syntax remains anywhere in the workflow, the module, or the config.
- [ ] `nf-test` passes.

---

**End of the core path.** If you have time and the group is still warm, continue to [Part 6: Static Typing and Records](part6_static_types.md). Otherwise the [Wrap-up](wrap_up.md) collects the strict migration checklist in one page.
