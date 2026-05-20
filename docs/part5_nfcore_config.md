# Part 5: nf-core and Config Migration

Config files are where the strict parser hurts nf-core pipelines the most. Years of helper variables, ad-hoc functions, and `switch` statements have accumulated next to `params {}` blocks, and the strict parser refuses all of it. The migration goal is a config file that is *declarative* — values, not code paths — with parser-acceptable closures for the few cases that need to defer evaluation.

<div class="timebox">
Target time: 25 minutes.
</div>

## Learning goals

- Migrate top-level config variables and helper functions to strict-compatible `params` and inline closures.
- Replace direct environment references (`USER`, `HOME`) with explicit `System.getenv(...)` lookups with a fallback.
- Use `validation.ignoreParams` to silence nf-schema warnings on helper params, and know what `ignoreParams` does *not* do.

## Theory: config is not a general script anymore

A real nf-core config file usually contains four kinds of statements that strict syntax now rejects:

- Free top-level variables: `def scratch_root = "/tmp/${USER}"`.
- Helper functions: `def queueLabel(size) { switch(size) { ... } }`.
- Direct environment references: `"/tmp/${USER}"` (Groovy used to resolve `USER` against `System.getenv`; strict parsing makes the reference explicit).
- `switch` statements inside scope selectors.

Each one has a strict-compatible replacement, and the replacements compose:

| Legacy pattern | Strict nf-core-style migration |
| --- | --- |
| `def scratch_root = ...` at the top of the file | `params.cohort_scratch = ...` inside the `params {}` block |
| direct `${USER}` reference | `${System.getenv('USER') ?: 'user'}` or `${env('USER')}` |
| helper function in the config file | inline closure at the point of use, or move the function to `lib/` if it is real logic shared by code |
| simple dynamic `if` variable | a ternary assigned directly to `params`: `params.x = cond ? 'a' : 'b'` |
| more complex dynamic value | a closure that is **immediately invoked**: `params.x = { ... }.call()` |
| `switch` in a process selector or helper | the same closure wrapping an `if`/`else if` chain |

The reason this matters specifically for nf-core: nf-core projects ship a single `nextflow.config` that grows organically across many tools. Free variables and helper functions are the natural way to factor that growth in Groovy, but they will not survive strict parsing. The migration cost is concentrated in `nextflow.config` and `conf/*.config` — `main.nf` and modules are usually less affected.

### `validation.ignoreParams` interaction (the part the upstream docs scatter)

If your project loads `nf-schema`, the plugin will warn about every param it does not recognise from the schema. Helper params like `cohort_scratch` and `cohort_queue` are typical sources of these warnings.

```groovy
validation {
    ignoreParams = [
        'cohort_size',
        'cohort_label',
        'cohort_scratch',
        'cohort_queue'
    ]
}
```

Three things to know about `ignoreParams` that the upstream pages mention separately:

1. **It only silences nf-schema warnings.** It does not affect the strict parser. A param that fails to resolve at parse time still errors regardless of what is in `ignoreParams`.
2. **Every helper param must still resolve to a value** when the config is loaded. Listing a name in `ignoreParams` does not let you reference an undefined variable; it only tells nf-schema "do not validate this name against the schema".
3. **Use neutral helper names.** Names like `cohort_scratch` are unlikely to collide with future schema entries. Names like `mode` or `label` will.

## 1. Demo

The demo config drives a small `REPORT_COHORT` process. The pipeline reads `params.cohort_size` and `params.cohort_queue` and writes them out — so the migration is purely in the config, not in `main.nf`.

```bash
cd code/05-nfcore-config/demo
nextflow run main.nf -c legacy.config -profile test
```

??? failure "Expected output"

    ```console
    Error legacy.config:1:1: ...
    ```

    The first parser error sits on `def requested_size = 'panel'` because top-level variable declarations are no longer allowed next to scope statements. The class of error is "variable declarations cannot be mixed with config statements" — the same hint Part 1 introduced.

Now run with the strict config:

```bash
nextflow run main.nf -profile test
```

??? success "Expected output"

    ```console
    cohort_size=panel
    cohort_queue=short
    ```

Inspect how the strict config builds the same values declaratively:

```bash
sed -n '1,30p' nextflow.config
```

Notice three things:

- `cohort_label` is a **ternary assigned directly to a param**, not a free `def` with an `if` after it.
- `cohort_scratch` reads `System.getenv('USER')` with a `?: 'user'` fallback, replacing the bare `${USER}` of the legacy file.
- `cohort_queue` is a **closure called immediately** (`{...}.call()`), which keeps the multi-branch logic readable inside the declarative `params {}` block.

## 2. Migration cheatsheet (for reference)

| Legacy config pattern (severity) | Strict nf-core-style migration |
| --- | --- |
| `def scratch_root = ...` outside any block (**error**) | `params.cohort_scratch = ...` inside `params {}` |
| `${USER}` bare reference (**error**) | `${System.getenv('USER') ?: 'user'}` or `${env('USER')}` |
| `def queueLabel(size) { switch(...) }` (**error**) | inline closure at the call site, or move to `lib/` |
| simple dynamic `if` variable (**error**) | ternary directly on `params` |
| more complex dynamic variable (**error**) | `params.value = { ... }.call()` |
| `switch` in selectors (**error**) | closure-wrapped `if`/`else if` |
| helper params triggering nf-schema warnings (**warning**) | add to `validation.ignoreParams` |

## 3. Exercise

The exercise has the same structure but a different surface. `selected_size` is `'trio'` instead of `'panel'`; the dynamic branch picks a `'cohort'` instead of `'wgs'`; the helper function is `memProfile(tier)` returning `'high'` / `'standard'`; the free variable is `tmp_root` instead of `scratch_root`. The same six migration patterns apply.

```bash
cd ../exercise
nextflow run main.nf -profile test
```

Migrate `nextflow.config` until the workflow runs without strict parser errors. The migrated config should:

- declare `cohort_size`, `cohort_label`, `cohort_scratch`, and `cohort_queue` directly under `params {}`,
- use `System.getenv('USER')` with a `?: 'user'` fallback for `cohort_scratch`,
- replace `memProfile(...)` with an immediately-invoked closure,
- declare the `nf-schema` plugin and list the four helper params in `validation.ignoreParams`,
- keep the `test` profile.

Then verify:

```bash
nextflow run main.nf -profile test
```

Expected output: `cohort_size=trio` and `cohort_queue=standard`. Compare with the worked solution:

```bash
cd ../solution
nextflow run main.nf -profile test
```

## Checkpoint

- [ ] My migrated config has no top-level `def` variables and no top-level functions.
- [ ] Every environment lookup uses `System.getenv(...)` or `env(...)`, with a fallback for missing values.
- [ ] Every helper param is listed in `validation.ignoreParams`, and I understand that this only suppresses nf-schema warnings — the strict parser still has to be satisfied independently.

Continue to [Capstone](capstone.md).
