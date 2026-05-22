#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/.." && pwd)"
port="${MKDOCS_PORT:-8000}"
mkdocs_cmd="${MKDOCS:-mkdocs}"
pid_file="${TMPDIR:-/tmp}/workshop-mkdocs-${port}.pid"
log_file="${TMPDIR:-/tmp}/workshop-mkdocs-${port}.log"

is_running() {
    [ -s "$pid_file" ] && kill -0 "$(cat "$pid_file")" >/dev/null 2>&1
}

start_server() {
    if is_running; then
        printf 'MkDocs is already running on port %s (pid %s).\n' "$port" "$(cat "$pid_file")"
        printf 'Log: %s\n' "$log_file"
        return 0
    fi

    if ! command -v "$mkdocs_cmd" >/dev/null 2>&1; then
        printf 'mkdocs is not installed in this environment.\n' >&2
        printf 'Run: python -m pip install -r requirements.txt\n' >&2
        return 1
    fi

    cd "$repo_root"
    if command -v setsid >/dev/null 2>&1; then
        nohup setsid "$mkdocs_cmd" serve --dev-addr "0.0.0.0:${port}" >"$log_file" 2>&1 &
    else
        nohup "$mkdocs_cmd" serve --dev-addr "0.0.0.0:${port}" >"$log_file" 2>&1 &
    fi
    server_pid="$!"
    printf '%s\n' "$server_pid" >"$pid_file"
    disown "$server_pid" >/dev/null 2>&1 || true

    for _ in 1 2 3 4 5 6 7 8 9 10; do
        if ! is_running; then
            rm -f "$pid_file"
            printf 'MkDocs failed to start. Last log lines:\n' >&2
            tail -n 40 "$log_file" >&2 || true
            return 1
        fi
        if grep -Fq 'Serving on' "$log_file" 2>/dev/null; then
            printf 'MkDocs started on http://127.0.0.1:%s (pid %s).\n' "$port" "$(cat "$pid_file")"
            printf 'Log: %s\n' "$log_file"
            return 0
        fi
        sleep 1
    done

    printf 'MkDocs is still starting on http://127.0.0.1:%s (pid %s).\n' "$port" "$(cat "$pid_file")"
    printf 'Log: %s\n' "$log_file"
}

stop_server() {
    if ! is_running; then
        printf 'MkDocs is not running.\n'
        rm -f "$pid_file"
        return 0
    fi

    kill "$(cat "$pid_file")"
    rm -f "$pid_file"
    printf 'MkDocs stopped.\n'
}

status_server() {
    if is_running; then
        printf 'MkDocs is running on port %s (pid %s).\n' "$port" "$(cat "$pid_file")"
        printf 'Log: %s\n' "$log_file"
    else
        printf 'MkDocs is not running.\n'
    fi
}

case "${1:-start}" in
    start)
        start_server
        ;;
    stop)
        stop_server
        ;;
    restart)
        stop_server
        start_server
        ;;
    status)
        status_server
        ;;
    logs)
        if [ -f "$log_file" ]; then
            tail -n "${2:-80}" "$log_file"
        else
            printf 'No MkDocs log exists yet: %s\n' "$log_file"
        fi
        ;;
    *)
        printf 'Usage: %s {start|stop|restart|status|logs [lines]}\n' "$0" >&2
        exit 2
        ;;
esac
