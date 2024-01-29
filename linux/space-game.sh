#!/bin/sh
echo -ne '\033c\033]0;Space Game\a'
base_path="$(dirname "$(realpath "$0")")"
"$base_path/space-game.x86_64" "$@"
