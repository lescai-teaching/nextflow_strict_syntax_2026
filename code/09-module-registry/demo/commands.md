# Module Registry — Instructor-led demo commands

These commands query the public registry and a scratch directory. None of them modify the workshop repository. Run them from anywhere — the workshop root is fine.

## 1. Discovery (read-only)

```bash
nextflow module --help
```

The first lines of the help output list the subcommands you will use today:

```console
Usage: nextflow module <command> [options]

Commands:
  create      Create a new module skeleton
  install     Install a module from the registry
  run         Run a module directly from the registry
  list        List all installed modules
  remove      Remove an installed module
  search      Search for modules in the registry
  view        Show module information and usage template
```

Search the registry:

```bash
nextflow module search fastqc
```

Inspect a specific module — this is the single most useful pre-install command:

```bash
nextflow module view nf-core/fastqc
```

??? success "Excerpt of expected output"

    ```console
    Module:      nf-core/fastqc
    Version:     0.0.0-6c4ed3a
    URL:         https://registry.nextflow.io/modules/nf-core/fastqc@0.0.0-6c4ed3a
    Description: Run FastQC on sequenced reads
    Authors:     @drpatelh, @grst, @ewels, @FelixKrueger

    Tools:
      - fastqc

    Input:
    - (tuple)
        - meta (map)
            Groovy Map containing sample information e.g. [ id:'test', single_end:false ]
        - reads (file)
            List of input FastQ files...

    Output:
    - zip   (tuple)
    - html  (tuple)
    - versions  (topic)
    ```

Read the **Input/Output/topics** block before installing. If the shape does not match what your pipeline produces upstream, you save yourself an install + remove round-trip.

## 2. Project-mutating commands in a scratch directory

```bash
mkdir -p /tmp/registry-demo
cd /tmp/registry-demo
nextflow module install nf-core/fastqc
```

??? success "Expected output"

    ```console
    Installing module nf-core/fastqc@0.0.0-6c4ed3a...
    Module nf-core/fastqc@0.0.0-6c4ed3a installed successfully at .../tmp/registry-demo/modules/nf-core/fastqc
    Module nf-core/fastqc@0.0.0-6c4ed3a installed and configured successfully
    ```

Inspect what landed on disk:

```bash
find . -maxdepth 4 -type f | sort
```

??? success "Expected file layout"

    ```console
    ./modules/nf-core/fastqc/.module-info
    ./modules/nf-core/fastqc/environment.yml
    ./modules/nf-core/fastqc/main.nf
    ./modules/nf-core/fastqc/meta.yml
    ```

    Four files: the process declaration (`main.nf`), the conda environment spec (`environment.yml`), human-readable metadata (`meta.yml`), and a registry pointer (`.module-info`) that `nextflow module list` reads.

List + remove:

```bash
nextflow module list
nextflow module remove nf-core/fastqc
nextflow module list
```

The remove leaves an empty `modules/` directory; the registry pointer is gone, so a subsequent `list` reports `No modules installed`.
