# Part 2: Script-Level Syntax

Strict syntax removes several general Groovy constructs from Nextflow scripts. After this part you should be able to look at a legacy `main.nf`, predict which lines will error, which will warn, and which will be accepted silently — then rewrite each one without changing pipeline behaviour.

<div class="timebox">
Target time: 25 minutes.
</div>

## Learning goals

- Replace the script-level Groovy constructs that 26.04 errors on (`import`, `class`, `for`/`while`, `++`/`--`, `switch`, spread, assignment-in-call) with their strict equivalents.
- Clean up the lint-warning tier (uppercase `Channel`, implicit `it`) and the silent tier (typed declarations) in the same pass.
- Read a legacy script as a *set* of severity-tagged issues and migrate from the parser errors outward.

## Theory: why strict narrows the language

A Nextflow `.nf` file is a *pipeline declaration*: a few imports, a workflow, some processes, dataflow over channels. The pre-26.04 parser was tolerant of general Groovy on top of that — classes, imperative loops, switch statements, spread operators, assignment expressions as arguments — because Groovy parsed them. The strict parser narrows the language back to what actually belongs in a pipeline declaration. Three points are worth holding in mind during the migration:

1. **Every removed construct has a Nextflow-idiomatic replacement.** `for`/`while` over a list becomes `.each` / `.collect` / `.findAll` / `.inject`. `switch` becomes a ternary or `if`/`else if`. `++`/`--` become `+= 1`/`-= 1`. Spread `[*xs, y]` becomes explicit `[xs[0], xs[1], y]` or `(xs + [y])`. Assignment-in-call becomes assignment first, then call.
2. **Helpers belong in functions; library code belongs in `lib/`; types belong in upcoming static typing.** When the parser refuses `class Foo`, the message is not that classes are bad — it is that classes do not belong inline next to `workflow {}`. Move them to `lib/` (compiled before scripts) or wait for the typed-record syntax in Part 6.
3. **The three severity tiers from Part 1 all show up at once in real scripts.** A single legacy file commonly mixes hard errors, warnings, and silent typed declarations. The strategy is *errors first* (so the file parses), *warnings next* (so lint goes quiet), *silent tier last* (because no tool will remind you).

The migration tables below are not the lesson — running the demo file through `nextflow lint` and reading the actual classification is. Treat the tables as a glossary for after the demo.

## 1. Demo

The demo script reads a small JSON metadata snippet, normalises three sample IDs, counts them, decides whether the cohort is `ready` (3 samples) or `small`, drops a control sample, and prints a manifest. It packs nine legacy idioms into one workflow.

```bash
cd code/02-script-syntax/demo
nextflow lint -project-dir . legacy.nf
```

??? failure "Expected lint output (collapsed)"

    ```console
    Error legacy.nf:3:1: Groovy `import` declarations are not supported -- use fully-qualified name inline instead
    │   3 | import groovy.json.JsonSlurper
    ╰     | ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

    Error legacy.nf:5:1: `class` is not allowed as an identifier because it is a Groovy keyword
    │   5 | class CohortMeta {
    ╰     | ^^^^^

    Error legacy.nf:19:43: Unexpected input: '='     (the assignment expression inside normalizeSamples(...))
    Error legacy.nf:20:5:  `for` loops are no longer supported
    Error legacy.nf:21:23: Unexpected input: '\n'    (paired_count++ )
    Error legacy.nf:23:15: Unexpected input: ':'     (case 3: in the switch)
    Error legacy.nf:30:21: Unexpected input: '*'     (spread operator in [*discovery, ...])
    Warn  legacy.nf:10:22: Implicit closure parameter is deprecated
    Warn  legacy.nf:26:5:  The use of `Channel` to access channel factories is deprecated -- use `channel` instead
    ```

    Eight parser errors, seven warnings, and three silent typed declarations (`String cohort_status`, `Integer paired_count`, plus `String runId` inside the disallowed `class`). When you re-lint after each fix, the next error surfaces — lint hides everything past the first parser error.

Now run the migrated version:

```bash
nextflow run main.nf -profile test
```

??? success "Expected output"

    ```console
    na12878:hg002:_trimmed
    cohort_status=ready
    ```

Confirm that lint is fully clean on the migrated file:

```bash
nextflow lint -project-dir . main.nf
```

??? success "Expected output"

    ```console
    ✅ 1 file had no errors
    ```

## 2. Migration cheatsheet

For after the demo — these are the patterns to expect when you migrate real code:

| Legacy pattern (severity in 26.04) | Strict-syntax migration |
| --- | --- |
| `import groovy.json.JsonSlurper` (**error**) | inline FQN: `new groovy.json.JsonSlurper()` |
| `class CohortMeta { ... }` in `.nf` (**error**) | move to `lib/` for compiled helpers, or use a `record` in Part 6 |
| `String suffix = ...`, `Integer count = 0` (**silent**) | `def suffix = ...`, `def count = 0` (typed prefixes are removed in favour of static typing in Part 6) |
| `hello(value = x)` (**error**) | assign first: `def v = x; hello(v)` |
| `count++` / `count--` (**error**) | `count += 1` / `count -= 1` |
| `for (x in xs) { ... }` (**error**) | `xs.each { x -> ... }`, `xs.collect { x -> ... }`, `xs.findAll { x -> ... }`, `xs.inject(0) { acc, x -> ... }` |
| `while (cond) { ... }` (**error**) | recast as a collection method, or as a recursive helper in `lib/` if the loop is genuinely unbounded |
| `switch (x) { case ... }` (**error**) | ternary `x == 'a' ? 'foo' : 'bar'` for two branches; `if`/`else if`/`else` for more |
| `[*xs, y]` spread (**error**) | explicit elements `[xs[0], xs[1], y]`, or list concat `(xs + [y])` |
| `Channel.of(...)` (**warning**) | `channel.of(...)` |
| `{ it.toUpperCase() }` (**warning**) | `{ value -> value.toUpperCase() }` (use `_value` for parameters you do not read) |

## 3. Exercise

Move to the exercise. It is a different surface: a list of BAM filenames, a thresholds JSON snippet, a `while` loop, a typed `Path` declaration, and a `switch` on a string field. The same nine error/warning classes are present but at different positions in the file.

```bash
cd ../exercise
nextflow lint -project-dir . main.nf
```

Walk the file from the top:

1. Remove the `import` line and switch to `new groovy.json.JsonSlurper()`.
2. Remove `class ReadStats { ... }` — it is unused; leftover classes are common in real migrations.
3. Replace each typed declaration (`String library_label`, `Integer bam_count`, `Path manifest_path`) with `def`. Lint will not warn you, but the migration guide does.
4. Replace `stripExt(values = ...)` with assign-first.
5. Replace the `while` loop and `++` with `bams.each { _bam -> bam_count += 1 }`.
6. Replace the `switch` with a ternary on `thresholds.library`.
7. Replace `[thresholds.library, *keep, bam_count.toString()]` with explicit elements.
8. Lowercase `Channel`, name the closure parameters explicitly.

When you re-run lint after every fix, the next error or warning surfaces. When lint is silent, run:

```bash
nextflow run main.nf -profile test
```

The expected output is:

```console
WGS|HG002|HG003|3
library=whole-genome; manifest=manifest.txt
```

Compare with the worked solution only after attempting the migration:

```bash
cd ../solution
nextflow run main.nf -profile test
```

## Checkpoint

- [ ] I migrated each construct to its idiomatic replacement, not to a more elaborate workaround.
- [ ] I addressed the silent tier (typed declarations) even though lint did not warn me.
- [ ] My migrated script keeps the same inputs, outputs, and counts as the legacy version.

Continue to [Part 3](part3_workflows_modules.md).
