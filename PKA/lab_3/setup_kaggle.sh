#!/usr/bin/env bash
set -eu

if [ "$#" -ne 1 ] || [ ! -s "$1" ]; then
    printf 'Usage: bash setup_kaggle.sh /path/to/kaggle.json\n' >&2
    exit 1
fi

project_dir="$(cd "$(dirname "$0")" && pwd)"
credentials_dir="$project_dir/dags/.kaggle"
destination="$credentials_dir/kaggle.json"
if [ -e "$destination" ]; then
    printf 'Kaggle credentials already exist at %s\n' "$destination" >&2
    exit 1
fi

umask 077
mkdir -p "$credentials_dir"
install -m 600 "$1" "$destination"
printf 'Kaggle credentials copied to dags/.kaggle/kaggle.json\n'
