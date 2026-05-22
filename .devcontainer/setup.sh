#!/usr/bin/env bash
set -euo pipefail

append_once() {
    local line="$1"
    local file="$2"

    touch "$file"
    if ! grep -Fqx "$line" "$file"; then
        printf '%s\n' "$line" >> "$file"
    fi
}

append_once "export PS1='\\[\\e[0;36m\\]\\W \\[\\e[0m\\]> '" "$HOME/.bashrc"
export PS1='\[\e[0;36m\]\W \[\e[0m\]> '

NFCORE_VERSION="4.0.2"

if ! python -c "import material" >/dev/null 2>&1; then
    python -m pip install --disable-pip-version-check -r requirements.txt
fi

if ! command -v nf-core >/dev/null 2>&1 || [ "$(nf-core --version 2>/dev/null | awk '{print $NF}')" != "$NFCORE_VERSION" ]; then
    python -m pip install --disable-pip-version-check "nf-core==${NFCORE_VERSION}"
fi

if ! command -v nf-test >/dev/null 2>&1 && [ ! -x "$HOME/.nf-test/bin/nf-test" ]; then
    curl -fsSL https://code.askimed.com/install/nf-test | bash
fi

if [ -x "$HOME/.nf-test/bin/nf-test" ]; then
    append_once 'export PATH="$HOME/.nf-test/bin:$PATH"' "$HOME/.bashrc"
    export PATH="$HOME/.nf-test/bin:$PATH"
fi

command -v nextflow >/dev/null 2>&1 && printf 'nextflow: %s\n' "$(command -v nextflow)" || true
nf-test --version || true
mkdocs --version || true
cat /usr/local/etc/vscode-dev-containers/first-run-notice.txt || true
