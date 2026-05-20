# Module Registry — Hands-on exercise

This part has two stages. Stage 1 is required and runs entirely with the read-only registry CLI. Stage 2 is optional and requires a container runtime (Docker / Singularity / Apptainer) or `conda` to actually execute the installed module.

## Stage 1 — Read, install, inspect, remove

Open a scratch directory, install `nf-core/fastqc`, and read the installed files.

```bash
mkdir -p /tmp/registry-exercise
cd /tmp/registry-exercise
nextflow module install nf-core/fastqc
find . -maxdepth 4 -type f | sort
```

Open `modules/nf-core/fastqc/main.nf` in your editor and identify, **without running anything**:

1. The process name, the `tag` expression, and the `label` (these affect logging and resource selection).
2. The `container` directive — what is the container image string, and what conditional logic picks between Singularity and Docker URLs?
3. The `conda` directive — which file does it point to, and why is that nicer than hard-coding a conda spec inline?
4. The `input:` block — what shape of tuple does the process expect? What does `stageAs: '?/*'` do to the input filenames at runtime?
5. The `output:` blocks — which emits are tuples, which is a topic, and what topic name?

Then answer these questions in your head:

- Which `nextflow module` subcommands are read-only (do not change anything in the current directory)?
- Which subcommands write files? Which files, in which directory?
- What is the difference between `nextflow module install <name>` (puts the module in `modules/<owner>/<name>/`) and `nextflow module run <name>` (downloads on demand, does not persist)?
- Why is mixing a `nextflow module update` into a strict-syntax migration risky?

Clean up:

```bash
nextflow module remove nf-core/fastqc
```

## Stage 2 — Wrap and run (optional)

The `solution/` folder contains a tiny `wrapper.nf` that demonstrates the include + call shape for an installed registry module, plus an `nextflow.config` with a `conda` profile. If you have a container runtime or `conda` available, you can drive it end-to-end:

```bash
cd /tmp/registry-exercise
nextflow module install nf-core/fastqc
cp <workshop-root>/code/09-module-registry/solution/wrapper.nf .
cp <workshop-root>/code/09-module-registry/solution/nextflow.config .
mkdir -p data
printf '@r1\nGATCGATCGATCGATC\n+\n!!!!!!!!!!!!!!!!\n' > data/reads_a.fastq
nextflow run wrapper.nf -profile conda
nextflow module remove nf-core/fastqc
```

If you do **not** have a container runtime or conda, read `wrapper.nf` and recognise the pattern: `include { FASTQC } from './modules/nf-core/fastqc'` followed by `FASTQC(samples_channel)`. That is the shape every real consumer of a registry module ends up with.

## Checkpoint

- [ ] I can list the read-only commands (`--help`, `search`, `view`, `list`).
- [ ] I know which commands modify project files (`install`, `update`, `remove`, `create`).
- [ ] I can read an installed module's `main.nf` and tell the input shape, output shape, and topic name from the declaration.
- [ ] I would not mix a `nextflow module update` into a strict-syntax PR unless I had explicitly planned it.
