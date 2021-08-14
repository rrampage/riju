#!/usr/bin/env bash

set -euo pipefail

while read -t2 -r cmdline; do
    cmd=(${cmdline})
    for (( i=0; i<${#cmd[@]}; i++ )); do
        arg="${cmd[$i]}"

        arg="${arg}x"
        arg="$(sed 's/+s/ /g' <<< "${arg}")"
        arg="$(sed 's/+n/\n/g' <<< "${arg}")"
        arg="$(sed 's/+t/\t/g' <<< "${arg}")"
        arg="$(sed 's/+p/+/g' <<< "${arg}")"
        arg="${arg%x}"

        cmd[$i]="${arg}"
    done
    if (( "${#cmd[@]}" > 0 )); then
        case "${cmd[0]}" in
            ping) ;;
            exec|pty)
                if (( "${#cmd[@]}" < 3 )); then
                    echo >&2 "usage: (exec|pty) UUID ARG..."
                else
                    if [[ "${cmd[0]}" == pty ]]; then
                        maybe_pty=/var/cache/riju/share/riju-pty
                    fi
                    uuid="${cmd[1]}"
                    args=("${cmd[@]:2}")
                    input="/var/cache/riju/share/cmd-${uuid}-input"
                    output="/var/cache/riju/share/cmd-${uuid}-output"
                    mkfifo "${input}" "${output}"
                    ${maybe_pty:-} runuser -u riju -- bash -c 'exec "$@"' sentinel "${args[@]}" < "${input}" &> "${output}" &
                fi
                ;;
            *)
                echo >&2 "unrecognized command: ${cmd[0]}"
                ;;
        esac
    fi
done < /var/cache/riju/share/control
