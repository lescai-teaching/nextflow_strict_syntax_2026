#!/usr/bin/env bash
set -euo pipefail

printf "export PS1='\\[\\e[0;36m\\]\\W \\[\\e[0m\\]> '\n" >> "$HOME/.bashrc"
export PS1='\[\e[0;36m\]\W \[\e[0m\]> '

python -m pip install --upgrade pip
python -m pip install -r requirements.txt nf-core

nextflow self-update
nextflow -version

if ! command -v nf-test >/dev/null 2>&1; then
    curl -fsSL https://code.askimed.com/install/nf-test | bash
fi

if [ -d "$HOME/.nf-test/bin" ]; then
    printf 'export PATH="$HOME/.nf-test/bin:$PATH"\n' >> "$HOME/.bashrc"
    export PATH="$HOME/.nf-test/bin:$PATH"
fi

nf-test --version || true
cat /usr/local/etc/vscode-dev-containers/first-run-notice.txt || true
