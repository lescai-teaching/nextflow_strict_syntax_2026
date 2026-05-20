# Part 1: 26.04 Strict Parser

Nextflow 26.04 enables the strict parser by default. Existing DSL2 code that relied on broader Groovy compatibility now meets the parser in one of three ways: a hard parser error, a lint warning, or a silent acceptance that you should still migrate. Knowing which is which is the single most useful skill for the rest of the workshop.

<div class="timebox">
Target time: 15 minutes.
</div>

## Learning goals

- Distinguish what the strict parser **errors** on, **warns** on, and **silently accepts but should still be migrated**.
- Read a real `nextflow lint` output and act on the first error before everything else.
- Internalise the iterative migration loop: lint → fix first error → re-lint to surface warnings → re-lint until clean.

## Theory: three severities, not just "removed/deprecated"

The upstream guides describe rule classes (removed, restricted, deprecated). What you actually see in `nextflow lint` on 26.04.1 is a different and more practical three-tier picture:

| Tier | What lint shows | Example | Effect on this script |
| --- | --- | --- | --- |
| **Parser error** | `Error …: Unexpected input` | `defaultSampleSuffix(value = '_trimmed')` — assignment expression inside a call | Compilation stops. No process runs. |
| **Lint warning** | `Warn …: … is deprecated` | `Channel.of(...)`, implicit closure parameter `it` | Script still compiles and runs today. Will be removed in a future release. |
| **Silent (still wrong)** | nothing in lint, nothing at runtime | `String suffix = ...`, `List fastqs = ...`, `Integer count = 0` | Parses today. Migration guide says to replace with `def` because typed prefixes will not interact correctly with the upcoming static typing system (Part 6). |

The migration habit that follows from this table is mechanical and worth committing to muscle memory:

1. `nextflow lint -project-dir . main.nf` — read the first **error**. It blocks everything.
2. Fix that one error. Re-run lint.
3. Now any **warnings** surface (lint hides warnings while there is an unresolved parser error). Fix every warning.
4. Re-read the file by hand for the **silent tier** — typed prefixes, leftover imports, classes — because the tool will not flag them today.
5. `nextflow run main.nf -profile test` — runtime confirms the migration is behaviour-preserving, not just parse-clean.

The thing the upstream docs do not stress is point 3: warnings only appear once the script parses. A repository with many parser errors will look "clean of warnings" until you start fixing things — that is misleading and is the most common reason real migrations skip the deprecated-syntax sweep.

## 1. Demo: old script, new parser

Move to the demo folder:

```bash
cd code/01-strict-parser/demo
```

`legacy.nf` renames two sample IDs by appending a suffix. It mixes one parser error and three warnings on purpose:

```groovy
String suffix = defaultSampleSuffix(value = '_trimmed')   # parser error + silent typed prefix
Channel.of('sample_a', 'sample_b')                        # warning: uppercase Channel
    .map { it + suffix }                                  # warning: implicit it
    .view { "renamed: ${it}" }                            # warning: implicit it
```

Try to run it:

```bash
nextflow run legacy.nf -profile test
```

??? failure "Expected output"

    ```console
    Error legacy.nf:9:47: Unexpected input: '='
    │   9 |     String suffix = defaultSampleSuffix(value = '_trimmed')
    ╰     |                                               ^

    [ERROR] ERROR ~ Script compilation failed
    ```

    Only the parser error appears. The three warnings stay hidden until the parse succeeds.

Now run the migrated version:

```bash
nextflow run main.nf -profile test
```

??? success "Expected output"

    ```console
    renamed: sample_a_trimmed
    renamed: sample_b_trimmed
    ```

Lint the migrated version to confirm there are no warnings either:

```bash
nextflow lint -project-dir . main.nf
```

??? success "Expected output"

    ```console
    Linting Nextflow code..
    Linting: main.nf
    Nextflow linting complete!
     ✅ 1 file had no errors
    ```

To see the warning round in isolation, fix only the assignment expression in `legacy.nf` (replace `value = '_trimmed'` with `'_trimmed'`) and re-run `nextflow lint`. You will see three warnings appear that were hidden a moment ago:

```console
Warn  legacy.nf:10:5: The use of `Channel` to access channel factories is deprecated -- use `channel` instead
Warn  legacy.nf:11:16: Implicit closure parameter is deprecated, declare an explicit parameter instead
Warn  legacy.nf:12:29: Implicit closure parameter is deprecated, declare an explicit parameter instead
```

That hidden round is the point of this part.

## 2. Exercise

The exercise builds a tiny FASTQ-renaming pipeline over `HG002`, `HG003`, and a `control` sample. It contains the same three error classes but in different positions: typed declarations now sit on `List` and `String`, the assignment-in-call hides on a different helper, the implicit `it` is inside `.filter` and `.map` instead of `.map` and `.view`, and `Channel.fromList` replaces `Channel.of`.

```bash
cd ../exercise
nextflow lint -project-dir . main.nf
nextflow run main.nf -profile test
```

Fix the script step by step so that, when you re-run lint:

- the parser error on line 10 is gone (the assignment expression `trimmedName(value = …)`),
- the three deprecation warnings are gone (`Channel.fromList`, `.filter { it … }`, `.view { … ${it} }`),
- you also replace `List fastqs` and `String run_label` with `def` even though lint does not complain — they are the silent tier from the theory section.

When `nextflow run main.nf -profile test` succeeds, the expected output is:

```console
[run_trimmed.fastq.gz] HG002_trimmed.fastq.gz
[run_trimmed.fastq.gz] HG003_trimmed.fastq.gz
```

Compare with the worked solution only after you have tried the migration yourself:

```bash
cd ../solution
nextflow run main.nf -profile test
```

## Checkpoint

- [ ] I can name the three severity tiers I will meet in 26.04 lint (error, warning, silent) and give one example of each.
- [ ] I know that warnings only appear once the file parses, so the first parser error has to come out first.
- [ ] I can run `nextflow lint -project-dir . main.nf` and act on its output without running the workflow.

Continue to [Part 2](part2_script_syntax.md).
