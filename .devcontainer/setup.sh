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

if [ -x "$HOME/.nf-test/bin/nf-test" ]; then
    append_once 'export PATH="$HOME/.nf-test/bin:$PATH"' "$HOME/.bashrc"
    export PATH="$HOME/.nf-test/bin:$PATH"
fi

command -v nextflow >/dev/null 2>&1 && printf 'nextflow: %s\n' "$(command -v nextflow)" || true
nf-core --version || true
nf-test version || true
mkdocs --version || true
cat /usr/local/etc/vscode-dev-containers/first-run-notice.txt || true
