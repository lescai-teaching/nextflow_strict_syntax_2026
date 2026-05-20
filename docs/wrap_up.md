# Wrap-up

<div class="timebox">
Target time: 5 minutes (or come back to this page when migrating real code).
</div>

This page is built for two moments: the end of the workshop, and every later moment when you are looking at a real-world Nextflow file and need to remember which part of the workshop covered that exact error message.

## Migration checklist

Use this checklist when migrating real workflows. The order mirrors the recommended migration sequence.

- [ ] Run `nextflow lint -project-dir . main.nf` before running the workflow. Fix the **first parser error** that appears.
- [ ] Re-run lint to surface deprecation warnings that were hidden behind the parser error.
- [ ] Sweep the **silent tier** by hand (typed declarations like `String x`, `Integer count`) — lint will not warn you.
- [ ] In scripts: replace `import`, `class`, `for`/`while`, `++`/`--`, `switch`, spread `*`, and assignment-in-call. Use lowercase `channel` and explicit closure parameters.
- [ ] In modules: remove `addParams` / `params` clauses from `include`. Expose runtime knobs through `take:` on a named sub-workflow. Stop reading `params.*` from inside processes.
- [ ] In processes: replace `shell:` with `script:`, quote `env 'NAME'`, escape shell variables with `\$` inside double-quoted bodies, interpolate output paths so multi-record channels do not collide.
- [ ] In config: move free `def` variables to `params`, replace helper functions and `switch` with immediately-invoked closures, use `System.getenv('USER') ?: 'user'` instead of bare `${USER}`, list helper params in `validation.ignoreParams`.
- [ ] Treat static typing, records, topic channels, workflow outputs, and `nextflow module` as **optional modernization** *after* the strict-syntax migration is stable.
- [ ] Re-run lint, the smoke profile, and `nf-test` before opening the PR.

## Reverse index: which part fixes which message

Find the message you are seeing, jump to that part.

| What lint or the runtime tells you | Where it was covered |
| --- | --- |
| `Error: Unexpected input: '='` (assignment expression inside a call) | [Part 1](part1_strict_parser.md) and [Part 2](part2_script_syntax.md) |
| `Error: Groovy 'import' declarations are not supported` | [Part 2](part2_script_syntax.md) |
| `Error: 'class' is not allowed as an identifier` | [Part 2](part2_script_syntax.md) |
| `Error: 'for' loops are no longer supported` / `while` errors | [Part 2](part2_script_syntax.md) |
| `Error: Unexpected input: '++'` / `'--'` | [Part 2](part2_script_syntax.md) |
| `Error: Unexpected input: ':'` near `case` (a `switch` block) | [Part 2](part2_script_syntax.md) and [Part 5](part5_nfcore_config.md) |
| `Error: Unexpected input: '*'` inside a list literal (spread) | [Part 2](part2_script_syntax.md) |
| `Warn: 'Channel' to access channel factories is deprecated` | [Part 1](part1_strict_parser.md) |
| `Warn: Implicit closure parameter is deprecated` | [Part 1](part1_strict_parser.md) |
| Silent: `String x = ...`, `Integer count = 0`, `List xs = ...` | [Part 1](part1_strict_parser.md) (theory) and [Part 2](part2_script_syntax.md) |
| `Error: Unexpected input: 'addParams'` on an `include` line | [Part 3](part3_workflows_modules.md) |
| `Error: Unexpected input: 'RUN_ID'` (unquoted `env` declaration) | [Part 4](part4_process_syntax.md) |
| `Error: Unexpected input: '''` (uses of `shell:`) | [Part 4](part4_process_syntax.md) |
| Output file silently empty `run_id=` line | [Part 4](part4_process_syntax.md) (runtime footgun — `${VAR}` vs `\$VAR`) |
| `Error: Variable declarations cannot be mixed with config statements` | [Part 5](part5_nfcore_config.md) |
| `Error: 'USER' is not defined` in a config file | [Part 5](part5_nfcore_config.md) |
| `WARN: Static typing is a preview feature` | [Part 6](part6_static_types.md) (expected — not a problem) |
| `Error: No such variable: out` after a typed workflow call | [Part 6](part6_static_types.md) |
| `Error: <name> is not defined` inside a `publish:` block | [Part 7](part7_workflow_outputs.md) |
| Workflow hangs after enabling a `versions` topic | [Part 7](part7_workflow_outputs.md) (cycle warning) |
| Unsure whether `nextflow module install` belongs in this PR | [Part 8](part8_module_registry.md) |

## Next steps

- Read the full [strict syntax documentation](https://docs.seqera.io/nextflow/strict-syntax).
- Review [Nextflow 26.04 migration notes](https://docs.seqera.io/nextflow/migrations/26-04).
- For nf-core configs, use the [nf-core strict syntax migration guide](https://nf-co.re/docs/developing/migration-guides/strict-syntax).
- When you start using static typing, topic channels, workflow outputs, or registry modules in production, come back to Parts 6–8 — they are written as forward references on purpose.
