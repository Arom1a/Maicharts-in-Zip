#!/usr/bin/env bash

set -euo pipefail # Fail if code 1
shopt -s nullglob
if ! command -v rg >/dev/null 2>&1; then
    echo "Error: \`rg\` (ripgrep) is required but not installed." >&2
    exit 1
fi

# Root directory containing all version folders
ROOT_DIR="."
OUTPUT_DIR="${ROOT_DIR}/output"
# Output levels greater than it, doesn't affect Utage
OUTPUT_LEVEL="13" # must be integer

# Detect if output dir exists;
# if exists, mv it to output_bak<unix_time_stamp>
if [ -e "${OUTPUT_DIR}" ]; then
    mv "${OUTPUT_DIR}" "${OUTPUT_DIR}_bak$(date +%s)"
fi
mkdir -p "${OUTPUT_DIR}"

# Loop for version_dir
for version_dir in "${ROOT_DIR}"/*; do
    [ -d "${version_dir}" ] && \
    [ "$(basename "${version_dir}")" != "output" ] || continue

    # Loop for song_dir
    for song_dir in "${version_dir}"/*; do
        [ -d "${song_dir}" ] # we should fail this because it's impossible

        # Get maidata.txt
        echo -n "$(basename "${song_dir}") " # "name "
        maidata_file="${song_dir}/maidata.txt"
        [ -f "${maidata_file}" ] # we should fail this too

        # Get rounded level, directly
        for diff in 2 3 4 5 6; do
            # removed "2>/dev/null || true", what does it do?
            leveln=$(rg --pcre2 -o "(?<=^&lv_${diff}=)[0-9.]+" "${maidata_file}") || continue
            int=${leveln%.*}
            frac=${leveln#*.}
            case ${frac} in
                [0-5]) level="${int}" ;;
                [6-9]) level="${int}+" ;;
            esac
            
            if [ "${int}" -ge "${OUTPUT_LEVEL}" ]; then
                echo -n "${level} " # "level "
                mkdir -p "${OUTPUT_DIR}/${level}"
                cp -r "${song_dir}" "${OUTPUT_DIR}/${level}/"
                echo -n ". "
            fi
        done

        # handle Utage charts (`&lv_7`)
        levelu=$(rg --pcre2 -o "(?<=^&lv_7=).+" "${maidata_file}") || true
        if [ -n "${levelu}" ]; then
            echo -n "Utage"
            mkdir -p "${OUTPUT_DIR}/Utage"
            cp -r "${song_dir}" "${OUTPUT_DIR}/Utage/"
            echo -n ". "
            echo
        fi
    done
done

echo "Sorting complete. Check ${OUTPUT_DIR}/"
