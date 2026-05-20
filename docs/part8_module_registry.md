# Part 8: Module Registry and `nextflow module`

The `nextflow module` subcommand turns module dependencies into something you discover, install, inspect, and version-control — instead of copy-pasting `main.nf` files between repos. It is independent of strict syntax, but it is the part of 26.04 that nf-core maintainers will use most often after the strict migration settles, so it earns a place in the extended path.

<div class="timebox">
Target time: 15 minutes guided, or self-study after Part 7.
</div>

## Learning goals

- Run the read-only registry CLI (`search`, `view`, `list`, `--help`) without modifying anything.
- Install a module into a project, read what was created, and remove it cleanly.
- Recognise the include + call shape of a registry-installed module from inside a wrapper workflow.
- Decide *when* a registry change belongs in a strict-syntax PR and when it should be its own commit.

## Theory: registry modules are dependencies, not snippets

Pre-26.04, sharing modules across nf-core pipelines meant copying `main.nf` files around. The new model treats modules like any other versioned dependency:

- A module has a **name** (`nf-core/fastqc`), a **version** (`0.0.0-6c4ed3a`), and a **registry URL**.
- `nextflow module install` writes the module's files into `modules/<owner>/<name>/` in the current project and adds a `.module-info` file that pins the resolved version.
- `nextflow module list` reads those `.module-info` files to report what is installed.
- `nextflow module update` and `nextflow module remove` change those files and should be committed deliberately.
- `nextflow module run` downloads on demand without persisting — useful for one-off scripts, *not* for projects you want to be reproducible.

Three classes of subcommand, in order of risk:

| Class | Subcommands | Effect on the project |
| --- | --- | --- |
| Read-only | `--help`, `search`, `view`, `list` | none |
| Persisting writes | `install`, `update`, `remove`, `create` | adds, modifies, or deletes files under `modules/` |
| Non-persisting | `run` | downloads to a temporary cache, does not modify project files |

The single most important habit: **do not mix a `module update` into a strict-syntax migration PR**. Two changes in one diff make review impossible — you cannot tell whether a runtime regression is from the syntax migration or from the upstream module bump. Land them as separate commits, ideally separate PRs.

## What an installed module looks like

After `nextflow module install nf-core/fastqc`, the project gains:

```console
modules/
└── nf-core/
    └── fastqc/
        ├── .module-info       # registry pointer + pinned version
        ├── environment.yml    # conda spec for the tool
        ├── main.nf            # the process declaration
        └── meta.yml           # human-readable metadata
```

The `main.nf` is a normal Nextflow process declaration. It uses the same patterns you have already seen — `tag`, `label`, `container`, `conda`, typed-tuple inputs, multiple emits, and a `versions` topic. The only thing "registry" about it is that you did not write it by hand.

## 1. Demo

The demo is CLI-driven. The full instructor command sequence and verified outputs are in:

```bash
code/09-module-registry/demo/commands.md
```

The minimum read-only path during a workshop is:

```bash
nextflow module --help
nextflow module search fastqc
nextflow module view nf-core/fastqc
```

`view` is the single most useful pre-install command — it shows the inputs, outputs, and topics the module exposes, so you can decide whether to install at all.

## 2. Exercise

Hands-on instructions and prompts live in:

```bash
code/09-module-registry/exercise/tasks.md
```

Stage 1 is required and read-only: install `nf-core/fastqc` into a scratch directory, inspect the four files that landed on disk, answer the read-only-vs-writing-subcommand prompts, and remove the module. Stage 2 is optional and requires a container runtime or `conda` — it runs a wrapper workflow that consumes the installed module.

The wrapper itself is in:

```bash
code/09-module-registry/solution/wrapper.nf
```

Read it even if you do not run it. The whole content is:

```groovy
include { FASTQC } from './modules/nf-core/fastqc'

workflow {
    main:
    def samples = channel.of(
        tuple([id: 'sample_a', single_end: true], file('data/reads_a.fastq'))
    )
    FASTQC(samples)
    FASTQC.out.html.view { meta, html -> "html=${html.name}" }
}
```

That is the entire registry-consumer shape: include from `./modules/<owner>/<name>`, build the input tuple the module expects, call it, consume named emits.

## Checkpoint

- [ ] I can name the four read-only registry subcommands.
- [ ] I know which directory `install` modifies and what files it creates.
- [ ] I have read at least one registry module's `main.nf` and identified its inputs, outputs, and topic.
- [ ] I would not bundle a `module update` into a strict-syntax PR.

Continue to [Wrap-up](wrap_up.md).
