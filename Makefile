SHELL := /usr/bin/env bash

NEXTFLOW ?= nextflow
NFTEST ?= nf-test
NFCORE ?= nf-core
MKDOCS ?= mkdocs
MKDOCS_PORT ?= 8000
SERVE_DOCS := .devcontainer/serve-docs.sh

STRICT_DIRS := $(shell find code \( -path '*/demo/main.nf' -o -path '*/solution/main.nf' \) 2>/dev/null | sed 's|/main.nf$$||' | sort)
SOLUTION_DIRS := $(shell find code -path '*/solution/main.nf' 2>/dev/null | sed 's|/main.nf$$||' | sort)
NFTEST_DIRS := $(shell find code -mindepth 3 -maxdepth 3 -name tests 2>/dev/null | sed 's|/tests$$||' | sort)
LEGACY_PAIRS := $(shell find code -path '*/demo/legacy.nf' 2>/dev/null | sort)

.PHONY: docs serve serve-foreground serve-stop serve-status serve-logs lint test clean-work check-tools check-exercises

docs:
	$(MKDOCS) build --strict

serve:
	MKDOCS=$(MKDOCS) MKDOCS_PORT=$(MKDOCS_PORT) $(SERVE_DOCS) start

serve-foreground:
	$(MKDOCS) serve --dev-addr 0.0.0.0:$(MKDOCS_PORT)

serve-stop:
	MKDOCS=$(MKDOCS) MKDOCS_PORT=$(MKDOCS_PORT) $(SERVE_DOCS) stop

serve-status:
	MKDOCS=$(MKDOCS) MKDOCS_PORT=$(MKDOCS_PORT) $(SERVE_DOCS) status

serve-logs:
	MKDOCS=$(MKDOCS) MKDOCS_PORT=$(MKDOCS_PORT) $(SERVE_DOCS) logs

lint:
	@set -euo pipefail; \
	for dir in $(STRICT_DIRS); do \
		echo "Linting $$dir"; \
		(cd "$$dir" && $(NEXTFLOW) lint -project-dir . main.nf); \
	done

test:
	@set -euo pipefail; \
	for dir in $(SOLUTION_DIRS); do \
		echo "Running $$dir"; \
		(cd "$$dir" && $(NEXTFLOW) run main.nf -profile test); \
	done; \
	for dir in $(NFTEST_DIRS); do \
		echo "nf-test $$dir"; \
		(cd "$$dir" && $(NFTEST) test tests/*.nf.test); \
	done

clean-work:
	find code -type d \( -name work -o -name results -o -name .nextflow -o -name .nf-test \) -prune -exec rm -rf {} +
	find code -type f \( -name '.nextflow.log*' -o -name '.nf-test.log*' -o -name 'trace.txt' -o -name 'timeline.html' -o -name 'report.html' \) -delete
	rm -rf site .nf-test.log

check-tools:
	$(NEXTFLOW) -version
	$(NFTEST) version
	$(NFCORE) --version
	$(MKDOCS) --version

check-exercises:
	@set -euo pipefail; \
	fail=0; \
	for legacy in $(LEGACY_PAIRS); do \
		exercise="$$(dirname $$(dirname $$legacy))/exercise/main.nf"; \
		if [ ! -f "$$exercise" ]; then continue; fi; \
		if diff -q "$$legacy" "$$exercise" >/dev/null 2>&1; then \
			echo "FAIL: $$exercise is byte-identical to $$legacy"; \
			fail=1; \
		fi; \
	done; \
	if [ "$$fail" -ne 0 ]; then \
		echo "Each exercise/main.nf must differ from the matching demo/legacy.nf."; \
		exit 1; \
	fi; \
	echo "check-exercises: OK"
