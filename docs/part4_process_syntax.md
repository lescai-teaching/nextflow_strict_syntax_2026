# Part 4: Process Syntax

Process migrations are the most mechanical part of the workshop — four small rules cover almost every real case — but they hide the migration footgun that bites people most often in production: string interpolation that compiles fine and corrupts data silently at runtime.

<div class="timebox">
Target time: 20 minutes.
</div>

## Learning goals

- Replace deprecated `shell:` blocks with `script:`.
- Quote process `env` input and output names.
- Predict which `${VAR}` / `"\$VAR"` choice runs and which one silently breaks the script body.
- Recognise typed process syntax when you see it in other people's code (typed migration itself is in Part 6).

## Theory: the four mechanical rules, plus the one that bites at runtime

The strict process rules are mechanical:

1. **`shell:` → `script:`.** The `shell:` block was a Groovy-with-`!{}`-interpolation variant. Strict syntax keeps only `script:` (and `exec:` for inline Groovy). Use single quotes around the script body if you want zero Nextflow interpolation; use double quotes if you want `${nextflow_var}` substitution.
2. **`env` names must be quoted.** Write `env 'RUN_ID'`, not `env RUN_ID`. The unquoted form is removed because it parses ambiguously with regular val/path inputs.
3. **Escape shell variables inside double-quoted script bodies.** `"\$RUN_ID"` reads the shell environment variable at runtime; `"${RUN_ID}"` tries to interpolate a Nextflow variable at compile time, fails to find one, and produces an empty string in the output file. Both *compile and run*. Only one is correct.
4. **Output paths can — and usually should — be interpolated.** `path "${sample_id}.summary.tsv"` lets each task emit a uniquely-named file. Hard-coded `path 'report.txt'` is fine for a single-record process but collides as soon as the channel has more than one element.

Rule 3 is the runtime footgun. It is the single piece of theory in this part that is not in the upstream migration guide.

!!! danger "Runtime footgun: `${VAR}` vs `"\$VAR"` inside `script:`"

    Both of these process bodies compile and run. Only the second one is correct:

    ```groovy
    script:
    """
    echo "run=${RUN_ID}" > out.txt          # WRONG — Nextflow tries to interpolate at compile time
    echo "run=\${RUN_ID}" > out.txt         # WRONG — `\$` only escapes the literal $ for the shell; same compile-time miss
    echo "run=\$RUN_ID" > out.txt            # RIGHT — Nextflow leaves $RUN_ID untouched; the shell reads it at runtime
    """
    ```

    Symptoms: the file is created, the workflow reports `SUCCESS`, every downstream check looks fine — but the value of `RUN_ID` is silently empty in the output. The strict migration changes nothing about this hazard; it just makes you rewrite every `script:` body, which is when you should re-check every `$VAR` reference.

### Typed process syntax (for recognition only)

In Part 6 you will see typed process declarations that look like this:

```groovy
process INDEX_SUMMARY {
    input:
    sample: Sample           // typed input, no qualifier

    output:
    record(
        id: sample.id,
        summary: file("${sample.id}.summary.tsv")
    )
}
```

You **do not** need to migrate to this style as part of the strict migration. A legacy-shaped `input: tuple val(...) ...` process is still valid in 26.04 and converts to typed syntax later, once the rest of the pipeline is strict-clean. Part 6 covers the typed style end-to-end.

## 1. Demo

The demo wraps a single sample (`HG002`) with a read count and an `env`-supplied `RUN_ID`, and writes a small TSV summary.

```bash
cd code/04-process-syntax/demo
nextflow run legacy.nf -profile test
```

??? failure "Expected output"

    ```console
    Error legacy.nf:7:9: Unexpected input: 'RUN_ID'
    ```

    The `env RUN_ID` declaration (unquoted) is the first parser error. `shell:` and the literal output path also need to change but lint stops at the first error, as Part 1 explained.

Now run the migrated version:

```bash
nextflow run main.nf -profile test
```

??? success "Expected output"

    ```console
    wrote HG002.summary.tsv
    ```

Inspect the file:

```bash
find work -name 'HG002.summary.tsv' -exec cat {} \;
```

??? success "Expected contents"

    ```console
    run_id	run_42
    sample	HG002
    reads	1500000
    ```

    If `run_id` were empty in your output, you triggered the runtime footgun: the `script:` body was written with `${RUN_ID}` (Nextflow interpolation at compile time) instead of `"\$RUN_ID"` (shell expansion at runtime). Re-read rule 3 above.

## 2. Migration targets

The four mechanical rules in compact form:

| Legacy pattern (severity) | Strict-syntax migration |
| --- | --- |
| `shell: ''' echo "!{var}" '''` (**error**) | `script: """ echo '${var}' """` (or `script: ''' echo "!{var}" '''` if you want the old interpolation style without `shell:`) |
| `env RUN_ID` (**error**) | `env 'RUN_ID'` |
| `"${RUN_ID}"` inside `script:` (**silent at runtime**) | `"\$RUN_ID"` |
| `path 'report.txt'` (**collides on multi-record channels**) | `path "${sample_id}.summary.tsv"` |

## 3. Exercise

The exercise processes a single mapping-stat record (`NA12878`, `2_400_000` reads) and an analysis namespace passed as `env ANALYSIS_NS`. It contains the four legacy patterns in different positions: the env declaration is `ANALYSIS_NS` not `RUN_ID`, the `shell:` body uses `!{}` interpolation, the output path is the hard-coded `flagstat.txt`, and the result is consumed with implicit `it`.

```bash
cd ../exercise
nextflow lint -project-dir . main.nf
nextflow run main.nf -profile test
```

Migrate so that:

- `env ANALYSIS_NS` is quoted,
- `shell:` becomes `script:` with `${...}` for Nextflow variables and `"\$ANALYSIS_NS"` for the shell variable,
- the output path becomes `"${sample_id}.flagstat.tsv"` so each task emits a uniquely-named file,
- the `view` closure names its parameter explicitly.

Then verify:

```bash
nextflow lint -project-dir . main.nf
nextflow run main.nf -profile test
```

Expected: `wrote NA12878.flagstat.tsv` and a TSV with `namespace`, `sample`, `total` lines. Compare with the worked solution:

```bash
cd ../solution
nextflow run main.nf -profile test
nf-test test tests/*.nf.test
```

The nf-test target asserts exactly one task ran — useful as a sanity check that the process did not get fan-out accidentally during migration.

## Checkpoint

- [ ] My migrated processes use `script:` and quoted `env` names.
- [ ] Every shell variable inside a double-quoted script body is escaped with `\$`.
- [ ] Multi-record-safe output paths use interpolation, not hard-coded filenames.
- [ ] I can read a typed process declaration without confusing it with the strict-legacy process I just migrated.

Continue to [Part 5](part5_nfcore_config.md).
