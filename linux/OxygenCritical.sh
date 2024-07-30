#!/bin/sh
echo -ne '\033c\033]0;Oxygen Critical\a'
base_path="$(dirname "$(realpath "$0")")"
"$base_path/OxygenCritical.x86_64" "$@"
